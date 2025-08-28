-- ~/.hammerspoon/modules/lid_bluetooth.lua
local M = {}

-- ===== Utils =====
local function urlEncode(s)
    return (s:gsub("([^%w%-_%.~ ])", function(c)
        return string.format("%%%02X", string.byte(c))
    end):gsub(" ", "%%20"))
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

-- Run via URL scheme (may open UI; we hide and restore focus)
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

-- ===== Desired state + retry machinery =====
M._wantBTOn = false -- last desired state (true to turn on)
M._unlocked = true -- session is usable (set by caffeinate watcher)
M._inflight = false -- a toggle attempt is running
M._retryCount = 0 -- retry counter
M._maxRetries = 5
M._baseDelay = 0.8 -- seconds
M._lastAttemptAt = 0

local function now()
    return hs.timer.secondsSinceEpoch()
end

local function backoffDelay(n)
    -- simple exponential backoff with cap
    local d = M._baseDelay * (2 ^ math.max(0, n - 1))
    if d > 6.0 then
        d = 6.0
    end
    return d
end

local function tryBluetooth(targetOn)
    local target = targetOn and "Bluetooth On" or "Bluetooth Off"
    local prevApp = hs.application.frontmostApplication()

    -- 1) Shortcuts Events
    local okOSA, errOSA = runShortcutOSA(target)
    if okOSA then
        return true
    end

    -- 2) CLI
    local okCLI, outCLI, rcCLI = runShortcutCLI(target)
    if okCLI then
        return true
    end

    -- 3) URL scheme (evitar antes do unlock para não abrir UI na tela de login)
    if M._unlocked then
        local okURL = runShortcutURL(target, prevApp)
        if okURL then
            return true
        end
    end

    print(string.format("❌ Bluetooth '%s' failed. OSA=%s | CLI rc=%s out=%s | unlocked=%s", target,
        tostring(errOSA or "nil"), tostring(rcCLI or "nil"), outCLI or "", tostring(M._unlocked)))
    return false
end

local function scheduleRetry()
    if M._retryCount >= M._maxRetries then
        print("⚠️ Reached max retries for Bluetooth toggle; giving up for now.")
        M._inflight = false
        return
    end
    M._retryCount = M._retryCount + 1
    local delay = backoffDelay(M._retryCount)
    hs.timer.doAfter(delay, function()
        -- only retry if the desire didn't change
        local desired = M._wantBTOn
        if not M._unlocked and desired then
            -- still locked; push again a bit later
            M._retryCount = M._retryCount - 1 -- don't count this one
            scheduleRetry()
            return
        end
        local ok = tryBluetooth(desired)
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
    M._lastAttemptAt = now()

    local ok = false
    if M._wantBTOn and not M._unlocked then
        -- não tentar antes de unlock para evitar “falhas falsas”
        scheduleRetry()
        return
    end

    ok = tryBluetooth(M._wantBTOn)
    if ok then
        print(string.format("✅ Bluetooth '%s' (first attempt).", M._wantBTOn and "On" or "Off"))
        M._inflight = false
        M._retryCount = 0
    else
        scheduleRetry()
    end
end

-- ===== Lid detection (polling) =====
local timer = nil
local lastBuiltInPresent = nil

local CLOSE_DELAY = 0.3
local OPEN_DELAY = 0.8 -- ligeiramente maior para dar tempo de wake
local POLL_INTERVAL = 2

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
        print("🔒 Lid closed — want BT OFF + lock screen.")
    end)
end

local function onLidOpened()
    hs.timer.doAfter(OPEN_DELAY, function()
        M._wantBTOn = true
        ensureBluetoothState()
        print("🔓 Lid opened — want BT ON (will retry if locked).")
    end)
end

local function checkLidState()
    local builtInPresent = isBuiltInDisplayPresent()

    if lastBuiltInPresent == nil then
        lastBuiltInPresent = builtInPresent
        return
    end

    -- Transition open -> closed
    if lastBuiltInPresent and not builtInPresent then
        onLidClosed()
    end

    -- Transition closed -> open
    if (not lastBuiltInPresent) and builtInPresent then
        onLidOpened()
    end

    lastBuiltInPresent = builtInPresent
end

-- ===== Caffeinate watcher: sincroniza com unlock/wake =====
M._cafWatcher = nil

local function handleCaffeinateEvent(event)
    if event == hs.caffeinate.watcher.screensDidUnlock or event == hs.caffeinate.watcher.sessionDidBecomeActive or event ==
        hs.caffeinate.watcher.systemDidWake or event == hs.caffeinate.watcher.screensDidWake then
        M._unlocked = true
        -- Se queríamos BT ON, agora é uma boa hora para tentar/retentar
        if M._wantBTOn then
            hs.timer.doAfter(0.6, function()
                ensureBluetoothState()
            end)
        end
    elseif event == hs.caffeinate.watcher.screensDidLock or event == hs.caffeinate.watcher.sessionDidResignActive or
        event == hs.caffeinate.watcher.systemWillSleep or event == hs.caffeinate.watcher.screensDidSleep then
        M._unlocked = false
    end
end

-- ===== Public API =====
function M.bindHotkey()
    -- Optional for manual testing:
    -- hs.hotkey.bind({"ctrl","alt","cmd"}, "9", function() M._wantBTOn=false; ensureBluetoothState() end)
    -- hs.hotkey.bind({"ctrl","alt","cmd"}, "0", function() M._wantBTOn=true;  ensureBluetoothState() end)
end

function M.start()
    if not timer then
        M._unlocked = true -- assume unlocked on start; watcher ajusta depois
        lastBuiltInPresent = isBuiltInDisplayPresent()
        timer = hs.timer.doEvery(POLL_INTERVAL, checkLidState)
        print(string.format("✅ Lid monitoring started (poll %ss).", POLL_INTERVAL))
    end
    if not M._cafWatcher then
        M._cafWatcher = hs.caffeinate.watcher.new(handleCaffeinateEvent)
        M._cafWatcher:start()
        print("✅ Caffeinate watcher started for unlock/wake sync.")
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
