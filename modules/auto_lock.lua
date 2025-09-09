-- ~/.hammerspoon/modules/lid_bluetooth.lua
local M = {}

-- ===== Config =====
M._maxRetries = 6 -- maximum retries for full apply cycle
M._baseDelay = 0.9 -- base backoff delay (seconds)

local CLOSE_DELAY = 0.4 -- after detecting lid close
local OPEN_DELAY = 1.6 -- after detecting lid open (allow wake)
local POLL_INTERVAL = 1.5 -- lid polling interval (a bit tighter)

-- Confirmation timings (async polling)
local CONTROLLER_TIMEOUT = 8.0 -- wait for BT controller to come up
local CONFIRM_TIMEOUT = 7.0 -- wait to confirm target state
local CONFIRM_INTERVAL = 0.25

-- Post-wake safety net (extra ensures)
local SAFETY_ENSURE_OFFSETS = {0.0, 3.0, 9.0}

-- Watchdog window: continuously ensure BT ON after wake/unlock
local WATCHDOG_WINDOW = 30.0
local WATCHDOG_PERIOD = 1.0

-- Fallback: force a power cycle if ON fails
local POWER_CYCLE_ON_FAIL = true
local POWER_CYCLE_DELAY = 0.6

-- Optional: auto-connect known devices once BT is ON
local KNOWN_DEVICE_MACS = {
    -- "AA:BB:CC:DD:EE:FF",
}

-- ===== Internals =====
M._wantBTOn = false
M._unlocked = true
M._inflight = false
M._retryCount = 0
M._cafWatcher = nil
M._safetyTimers = {}
M._watchdog = nil

local timer = nil
local lastClamshellClosed = nil

-- ===== Paths / helpers =====
local function now()
    return hs.timer.secondsSinceEpoch()
end

local function backoffDelay(n)
    local d = M._baseDelay * (2 ^ math.max(0, n - 1))
    if d > 7.0 then
        d = 7.0
    end
    return d
end

local function urlEncode(s)
    return (s:gsub("([^%w%-_%.~ ])", function(c)
        return string.format("%%%02X", string.byte(c))
    end):gsub(" ", "%%20"))
end

-- Locate blueutil (Homebrew on Intel/ARM)
local function blueutilPath()
    local candidates = {"/opt/homebrew/bin/blueutil", "/usr/local/bin/blueutil"}
    for _, p in ipairs(candidates) do
        if hs.fs.attributes(p) then
            return p
        end
    end
    return nil
end
local BLUEUTIL = blueutilPath()

-- ===== Lid state via IOKit (robust) =====
-- Returns true if lid/clam is closed, false if open, or nil if unknown.
local function readClamshellClosed()
    -- AppleClamshellState appears under IOPMrootDomain; “Yes” = closed
    local out = hs.execute(
        "/usr/sbin/ioreg -r -k AppleClamshellState 2>/dev/null | /usr/bin/grep -i AppleClamshellState | tail -n1", true)
    if not out or #out == 0 then
        return nil
    end
    out = out:lower()
    if out:find("= yes") then
        return true
    end
    if out:find("= no") then
        return false
    end
    return nil
end

-- ===== Bluetooth state (read/confirm/controller) =====
-- Returns true/false or nil if unknown
local function btReadStateSync()
    if BLUEUTIL then
        local out = hs.execute(string.format("%q --power", BLUEUTIL), true)
        if out then
            out = out:gsub("%s+", "")
            if out == "1" then
                return true
            elseif out == "0" then
                return false
            end
        end
    end
    return nil
end

-- Wait until the controller responds sanely to --power (non-blocking)
local function waitControllerAsync(timeout, interval, onDone)
    local deadline = now() + (timeout or CONTROLLER_TIMEOUT)
    local t
    t = hs.timer.doEvery(interval or 0.3, function()
        if BLUEUTIL then
            local out = hs.execute(string.format("%q --power", BLUEUTIL), true) or ""
            local ok = out:find("0") or out:find("1")
            if ok then
                t:stop();
                onDone(true);
                return
            end
        end
        if now() >= deadline then
            t:stop();
            onDone(false)
        end
    end)
end

local function confirmDesiredAsync(desired, timeout, interval, onDone)
    local deadline = now() + (timeout or CONFIRM_TIMEOUT)
    local t
    t = hs.timer.doEvery(interval or CONFIRM_INTERVAL, function()
        local st = btReadStateSync()
        if st ~= nil and st == desired then
            t:stop();
            onDone(true);
            return
        end
        if now() >= deadline then
            t:stop();
            onDone(false)
        end
    end)
end

-- ===== Async runners =====
local function runBlueutilSetAsync(targetOn, cb)
    if not BLUEUTIL then
        cb(false, "no-blueutil");
        return
    end
    local task = hs.task.new(BLUEUTIL, function(exitCode, stdOut, stdErr)
        cb(exitCode == 0, stdOut, stdErr)
    end, {"--power", targetOn and "1" or "0"})
    if not task then
        cb(false, "task-new-failed");
        return
    end
    task:start()
end

local function runBlueutilConnectAsync(mac, cb)
    if not BLUEUTIL then
        cb(false, "no-blueutil");
        return
    end
    local task = hs.task.new(BLUEUTIL, function(exitCode, stdOut, stdErr)
        cb(exitCode == 0, stdOut, stdErr)
    end, {"--connect", mac})
    if not task then
        cb(false, "task-new-failed");
        return
    end
    task:start()
end

local function connectKnownDevicesAsync()
    if not BLUEUTIL or #KNOWN_DEVICE_MACS == 0 then
        return
    end
    local i = 1
    local function step()
        local mac = KNOWN_DEVICE_MACS[i];
        if not mac then
            return
        end
        runBlueutilConnectAsync(mac, function()
            hs.timer.doAfter(0.2, function()
                i = i + 1;
                step()
            end)
        end)
    end
    step()
end

local function runShortcutOSA(name, cb)
    hs.timer.doAfter(0, function()
        local ok, _, err = hs.osascript.applescript(string.format([[
      tell application "Shortcuts Events"
        run shortcut "%s"
      end tell
    ]], name))
        cb(ok, err)
    end)
end

local function runShortcutCLI(name, cb)
    local bin = "/usr/bin/shortcuts"
    if not hs.fs.attributes(bin) then
        cb(false, "shortcuts-cli-missing");
        return
    end
    local task = hs.task.new(bin, function(exitCode, stdOut, stdErr)
        cb(exitCode == 0, stdOut or "", stdErr or "")
    end, {"run", name, "--show-errors"})
    if not task then
        cb(false, "task-new-failed");
        return
    end
    task:start()
end

local function runShortcutURL(name, restoreApp, cb)
    local ok = hs.urlevent.openURL("shortcuts://run-shortcut?name=" .. urlEncode(name))
    if ok then
        hs.timer.doAfter(0.25, function()
            local sh = hs.application.get("Shortcuts");
            if sh then
                sh:hide()
            end
            if restoreApp then
                restoreApp:activate(true)
            end
        end)
    end
    cb(ok)
end

-- ===== Apply methods in order, with controller wait + confirmation =====
local function applyWithMethod(desired, methodIdx, cb)
    local targetName = desired and "Bluetooth On" or "Bluetooth Off"
    local methods = {}

    -- 1) blueutil set (with controller wait & optional power-cycle)
    if BLUEUTIL then
        table.insert(methods, function(nextStep)
            local function attemptSet()
                runBlueutilSetAsync(desired, function(ok)
                    if not ok then
                        print("⚠️ blueutil failed; trying next method…")
                        return nextStep(false)
                    end
                    confirmDesiredAsync(desired, 5.5, 0.2, function(confirmed)
                        if confirmed then
                            if desired then
                                connectKnownDevicesAsync()
                            end
                            cb(true)
                        else
                            if POWER_CYCLE_ON_FAIL and desired then
                                -- OFF → ON cycle
                                runBlueutilSetAsync(false, function()
                                    hs.timer.doAfter(POWER_CYCLE_DELAY, function()
                                        runBlueutilSetAsync(true, function()
                                            confirmDesiredAsync(true, 6.0, 0.25, function(c2)
                                                if c2 then
                                                    connectKnownDevicesAsync()
                                                    cb(true)
                                                else
                                                    nextStep(false)
                                                end
                                            end)
                                        end)
                                    end)
                                end)
                            else
                                nextStep(false)
                            end
                        end
                    end)
                end)
            end

            if desired then
                -- Wait for controller to be ready before turning ON
                waitControllerAsync(CONTROLLER_TIMEOUT, 0.3, function(ready)
                    if not ready then
                        print("⚠️ BT controller not ready; deferring to next method…")
                        nextStep(false)
                    else
                        attemptSet()
                    end
                end)
            else
                attemptSet()
            end
        end)
    end

    -- 2) Shortcuts Events (OSA)
    table.insert(methods, function(nextStep)
        runShortcutOSA(targetName, function(ok)
            if not ok then
                return nextStep(false)
            end
            local st = btReadStateSync();
            if st == nil then
                return cb(true)
            end
            confirmDesiredAsync(desired, CONFIRM_TIMEOUT, CONFIRM_INTERVAL, function(confirmed)
                if confirmed then
                    if desired then
                        connectKnownDevicesAsync()
                    end
                    cb(true)
                else
                    nextStep(false)
                end
            end)
        end)
    end)

    -- 3) Shortcuts CLI
    table.insert(methods, function(nextStep)
        runShortcutCLI(targetName, function(ok)
            if not ok then
                return nextStep(false)
            end
            local st = btReadStateSync();
            if st == nil then
                return cb(true)
            end
            confirmDesiredAsync(desired, CONFIRM_TIMEOUT, CONFIRM_INTERVAL, function(confirmed)
                if confirmed then
                    if desired then
                        connectKnownDevicesAsync()
                    end
                    cb(true)
                else
                    nextStep(false)
                end
            end)
        end)
    end)

    -- 4) URL (only if unlocked)
    table.insert(methods, function(nextStep)
        if not M._unlocked then
            return nextStep(false)
        end
        local prevApp = hs.application.frontmostApplication()
        runShortcutURL(targetName, prevApp, function(ok)
            if not ok then
                return nextStep(false)
            end
            local st = btReadStateSync();
            if st == nil then
                return cb(true)
            end
            confirmDesiredAsync(desired, CONFIRM_TIMEOUT, CONFIRM_INTERVAL, function(confirmed)
                if confirmed then
                    if desired then
                        connectKnownDevicesAsync()
                    end
                    cb(true)
                else
                    nextStep(false)
                end
            end)
        end)
    end)

    -- iterator
    local function step(i)
        if i > #methods then
            cb(false);
            return
        end
        methods[i](function()
            step(i + 1)
        end)
    end
    step(methodIdx or 1)
end

-- ===== Watchdog =====
local function startWatchdog(duration)
    if M._watchdog then
        M._watchdog:stop();
        M._watchdog = nil
    end
    local deadline = now() + (duration or WATCHDOG_WINDOW)
    M._watchdog = hs.timer.doEvery(WATCHDOG_PERIOD, function()
        if not M._wantBTOn then
            return
        end
        if now() > deadline then
            M._watchdog:stop();
            M._watchdog = nil;
            return
        end
        local st = btReadStateSync()
        if st ~= nil and not st and not M._inflight and M._unlocked then
            M._retryCount = 0
            M._inflight = true
            applyWithMethod(true, 1, function()
                M._inflight = false
            end)
        end
    end)
end

local function stopWatchdog()
    if M._watchdog then
        M._watchdog:stop();
        M._watchdog = nil
    end
end

-- ===== Retry + orchestration =====
local function clearSafetyTimers()
    for _, t in ipairs(M._safetyTimers) do
        if t then
            t:stop()
        end
    end
    M._safetyTimers = {}
end

local function scheduleSafetyEnsures()
    clearSafetyTimers()
    for _, off in ipairs(SAFETY_ENSURE_OFFSETS) do
        local t = hs.timer.doAfter(off, function()
            if M._wantBTOn and not M._inflight then
                M._retryCount = 0
                M._inflight = true
                applyWithMethod(true, 1, function()
                    M._inflight = false
                end)
            end
        end)
        table.insert(M._safetyTimers, t)
    end
end

local function scheduleRetry()
    if M._retryCount >= M._maxRetries then
        print("⚠️ Reached max retries for Bluetooth toggle; giving up.")
        M._inflight = false
        return
    end
    M._retryCount = M._retryCount + 1
    local delay = backoffDelay(M._retryCount)
    hs.timer.doAfter(delay, function()
        local desired = M._wantBTOn
        if desired and not M._unlocked then
            M._retryCount = M._retryCount - 1
            scheduleRetry()
            return
        end
        applyWithMethod(desired, 1, function(ok)
            if ok then
                print(string.format("✅ Bluetooth '%s' after %d retries.", desired and "On" or "Off", M._retryCount))
                M._inflight = false
                M._retryCount = 0
            else
                scheduleRetry()
            end
        end)
    end)
end

local function ensureBluetoothState()
    if M._inflight then
        return
    end
    M._inflight = true
    M._retryCount = 0

    if M._wantBTOn and not M._unlocked then
        M._inflight = false
        scheduleRetry()
        return
    end

    local st = btReadStateSync()
    if st ~= nil and st == M._wantBTOn then
        M._inflight = false
        return
    end

    applyWithMethod(M._wantBTOn, 1, function(ok)
        if ok then
            print(string.format("✅ Bluetooth '%s' (first attempt).", M._wantBTOn and "On" or "Off"))
            M._inflight = false
            M._retryCount = 0
        else
            M._inflight = false
            scheduleRetry()
        end
    end)
end

-- ===== Lid detection =====
local function onLidClosed()
    stopWatchdog()
    clearSafetyTimers()
    hs.timer.doAfter(CLOSE_DELAY, function()
        M._wantBTOn = false
        ensureBluetoothState()
        -- Force displays off to avoid external staying on in clamshell
        hs.execute("/usr/bin/pmset displaysleepnow", true)
        hs.caffeinate.lockScreen()
        print("🔒 Lid closed — Bluetooth OFF + displays sleeping + screen locked.")
    end)
end

local function onLidOpened()
    hs.timer.doAfter(OPEN_DELAY, function()
        M._wantBTOn = true
        ensureBluetoothState()
        scheduleSafetyEnsures()
        startWatchdog(WATCHDOG_WINDOW)
        print("🔓 Lid opened — Bluetooth ON (controller-aware + watchdog).")
    end)
end

local function checkLidState()
    local clam = readClamshellClosed()
    if clam == nil then
        return
    end -- unknown: skip this tick
    if lastClamshellClosed == nil then
        lastClamshellClosed = clam
        return
    end
    if (not lastClamshellClosed) and clam then
        onLidClosed()
    end -- open -> closed
    if lastClamshellClosed and (not clam) then
        onLidOpened()
    end -- closed -> open
    lastClamshellClosed = clam
end

-- ===== Caffeinate watcher =====
local function handleCaffeinateEvent(event)
    if event == hs.caffeinate.watcher.screensDidUnlock or event == hs.caffeinate.watcher.sessionDidBecomeActive or event ==
        hs.caffeinate.watcher.systemDidWake or event == hs.caffeinate.watcher.screensDidWake then
        M._unlocked = true
        if M._wantBTOn then
            -- On wake, also wait for controller before first ON attempt via ensure()
            hs.timer.doAfter(0.8, function()
                ensureBluetoothState()
                scheduleSafetyEnsures()
                startWatchdog(WATCHDOG_WINDOW)
            end)
        end
    elseif event == hs.caffeinate.watcher.screensDidLock or event == hs.caffeinate.watcher.sessionDidResignActive or
        event == hs.caffeinate.watcher.systemWillSleep or event == hs.caffeinate.watcher.screensDidSleep then
        M._unlocked = false
        stopWatchdog()
        clearSafetyTimers()
    end
end

-- ===== Public API =====
function M.bindHotkey()
    -- hs.hotkey.bind({"ctrl","alt","cmd"}, "9", function() M._wantBTOn=false; ensureBluetoothState() end)
    -- hs.hotkey.bind({"ctrl","alt","cmd"}, "0", function() M._wantBTOn=true;  ensureBluetoothState() end)
end

function M.start()
    if not timer then
        M._unlocked = true -- assume unlocked; watcher will adjust
        lastClamshellClosed = readClamshellClosed()
        timer = hs.timer.doEvery(POLL_INTERVAL, checkLidState)
        print(string.format("✅ Lid monitoring started (poll %ss). blueutil=%s", POLL_INTERVAL,
            tostring(BLUEUTIL ~= nil)))
    end
    if not M._cafWatcher then
        M._cafWatcher = hs.caffeinate.watcher.new(handleCaffeinateEvent)
        M._cafWatcher:start()
        print("✅ Caffeinate watcher started.")
    end
end

function M.stop()
    if timer then
        timer:stop();
        timer = nil
    end
    if M._cafWatcher then
        M._cafWatcher:stop();
        M._cafWatcher = nil
    end
    stopWatchdog()
    clearSafetyTimers()
    M._inflight = false
    print("🛑 Lid monitoring stopped.")
end

return M
