-- ~/.hammerspoon/modules/lid_bluetooth.lua
local M = {}

-- ===== Config =====
M._maxRetries = 6 -- maximum number of retries
M._baseDelay = 0.9 -- base backoff delay (s)
local CLOSE_DELAY = 0.4 -- after detecting lid close
local OPEN_DELAY = 1.2 -- after detecting lid open (allow wake time)
local POLL_INTERVAL = 2.0 -- lid polling interval

-- ===== Internals =====
M._wantBTOn = false -- desired Bluetooth state
M._unlocked = true -- session is usable (updated by caffeinate watcher)
M._inflight = false -- toggle attempt in progress
M._retryCount = 0
M._cafWatcher = nil
local timer = nil
local lastBuiltInPresent = nil

-- ===== Utils =====
local function urlEncode(s)
    return (s:gsub("([^%w%-_%.~ ])", function(c)
        return string.format("%%%02X", string.byte(c))
    end):gsub(" ", "%%20"))
end

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

-- ===== Bluetooth helpers =====
local function btReadState()
    -- returns true/false or nil if unknown
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

local function btSetViaBlueutil(targetOn)
    if not BLUEUTIL then
        return false, "no-blueutil"
    end
    local cmd = string.format("%q --power %d", BLUEUTIL, targetOn and 1 or 0)
    local out, ok, _, rc = hs.execute(cmd, true)
    if ok and rc == 0 then
        return true
    end
    return false, out or ("rc=" .. tostring(rc))
end

-- Run via Shortcuts Events (background, no UI)
local function runShortcutOSA(name)
    local ok, _, err = hs.osascript.applescript(string.format([[
    tell application "Shortcuts Events"
      run shortcut "%s"
    end tell
  ]], name))
    return ok, err
end

-- Run via CLI (background, no UI)
local function runShortcutCLI(name)
    local cmd = string.format('/usr/bin/shortcuts run %q --show-errors 2>&1', name)
    local out, ok, _, rc = hs.execute(cmd, true)
    return ok and rc == 0, out or "", rc
end

-- Run via URL scheme (may open UI; hide app and restore focus)
local function runShortcutURL(name, restoreApp)
    local ok = hs.urlevent.openURL("shortcuts://run-shortcut?name=" .. urlEncode(name))
    if ok then
        hs.timer.doAfter(0.25, function()
            local sh = hs.application.get("Shortcuts")
            if sh then
                sh:hide()
            end
            if restoreApp then
                restoreApp:activate(true)
            end
        end)
    end
    return ok
end

-- Try applying the state and confirm (prefer blueutil)
local function trySetBluetooth(targetOn)
    local target = targetOn and "Bluetooth On" or "Bluetooth Off"
    local prevApp = hs.application.frontmostApplication()

    -- 0) Use blueutil first if available
    if BLUEUTIL then
        local okB, errB = btSetViaBlueutil(targetOn)
        if not okB then
            print(string.format("⚠️ blueutil failed (%s). Falling back to Shortcuts…", tostring(errB)))
        else
            -- confirm actual state
            local deadline = now() + 5.0
            while now() < deadline do
                local st = btReadState()
                if st ~= nil and st == targetOn then
                    return true
                end
                hs.timer.usleep(200000) -- 200ms
            end
            print("⚠️ blueutil applied but state not confirmed; will try Shortcuts fallback.")
        end
    end

    -- 1) Shortcuts Events
    local okOSA, errOSA = runShortcutOSA(target)
    if okOSA then
        local st = btReadState()
        if st == nil then
            return true
        end
        local deadline = now() + 6.0
        while now() < deadline do
            st = btReadState()
            if st ~= nil and st == targetOn then
                return true
            end
            hs.timer.usleep(200000)
        end
    end

    -- 2) CLI
    local okCLI, outCLI = runShortcutCLI(target)
    if okCLI then
        local st = btReadState()
        if st == nil then
            return true
        end
        local deadline = now() + 6.0
        while now() < deadline do
            st = btReadState()
            if st ~= nil and st == targetOn then
                return true
            end
            hs.timer.usleep(200000)
        end
    end

    -- 3) URL (only if unlocked, to avoid showing UI at login screen)
    if M._unlocked then
        local okURL = runShortcutURL(target, prevApp)
        if okURL then
            local st = btReadState()
            if st == nil then
                return true
            end
            local deadline = now() + 6.0
            while now() < deadline do
                st = btReadState()
                if st ~= nil and st == targetOn then
                    return true
                end
                hs.timer.usleep(200000)
            end
        end
    end

    print(string.format("❌ Failed to set '%s' (all methods). unlocked=%s", target, tostring(M._unlocked)))
    return false
end

-- Retry wrapper
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
            -- still locked; retry later without counting
            M._retryCount = M._retryCount - 1
            scheduleRetry()
            return
        end
        local ok = trySetBluetooth(desired)
        if ok then
            print(string.format("✅ Bluetooth '%s' after %d retries.", desired and "On" or "Off", M._retryCount))
            M._inflight = false
            M._retryCount = 0
        else
            scheduleRetry()
        end
    end)
end

local function ensureBluetoothState()
    if M._inflight then
        return
    end
    M._inflight = true
    M._retryCount = 0

    if M._wantBTOn and not M._unlocked then
        scheduleRetry()
        return
    end

    local st = btReadState()
    if st ~= nil and st == M._wantBTOn then
        M._inflight = false
        return
    end

    local ok = trySetBluetooth(M._wantBTOn)
    if ok then
        print(string.format("✅ Bluetooth '%s' (first attempt).", M._wantBTOn and "On" or "Off"))
        M._inflight = false
        M._retryCount = 0
    else
        scheduleRetry()
    end
end

-- ===== Lid detection (polling) =====
local function isBuiltInDisplayPresent()
    for _, screen in ipairs(hs.screen.allScreens()) do
        local nm = (screen:name() or ""):lower()
        if nm:match("built%-in") or nm:find("liquid retina") or nm:find("color lcd") then
            return true
        end
    end
    return false
end

local function onLidClosed()
    hs.timer.doAfter(CLOSE_DELAY, function()
        M._wantBTOn = false
        ensureBluetoothState()
        hs.caffeinate.lockScreen()
        print("🔒 Lid closed — Bluetooth OFF + screen locked.")
    end)
end

local function onLidOpened()
    hs.timer.doAfter(OPEN_DELAY, function()
        M._wantBTOn = true
        ensureBluetoothState()
        print("🔓 Lid opened — Bluetooth ON (with verification & retries).")
    end)
end

local function checkLidState()
    local builtInPresent = isBuiltInDisplayPresent()

    if lastBuiltInPresent == nil then
        lastBuiltInPresent = builtInPresent
        return
    end

    if lastBuiltInPresent and not builtInPresent then
        onLidClosed()
    end

    if (not lastBuiltInPresent) and builtInPresent then
        onLidOpened()
    end

    lastBuiltInPresent = builtInPresent
end

-- ===== Caffeinate watcher: sync with unlock/wake =====
local function handleCaffeinateEvent(event)
    if event == hs.caffeinate.watcher.screensDidUnlock or event == hs.caffeinate.watcher.sessionDidBecomeActive or event ==
        hs.caffeinate.watcher.systemDidWake or event == hs.caffeinate.watcher.screensDidWake then
        M._unlocked = true
        if M._wantBTOn then
            hs.timer.doAfter(0.8, ensureBluetoothState)
        end
    elseif event == hs.caffeinate.watcher.screensDidLock or event == hs.caffeinate.watcher.sessionDidResignActive or
        event == hs.caffeinate.watcher.systemWillSleep or event == hs.caffeinate.watcher.screensDidSleep then
        M._unlocked = false
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
        lastBuiltInPresent = isBuiltInDisplayPresent()
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
    M._inflight = false
    print("🛑 Lid monitoring stopped.")
end

return M
