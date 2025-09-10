-- ~/.hammerspoon/modules/lid_control.lua
-- Locks the screen AND toggles Bluetooth (via Shortcuts) on lid events.
local M = {}

-- ===== Config =====
local OPEN_DELAY = 1.0 -- wait after lid open before BT ON
local CLOSE_DELAY = 0.4 -- wait after lid close before BT OFF/lock
local RETRIES = 1 -- retry toggle attempts
local RETRY_BACKOFF = 0.8

local SHORTCUT_ON = "Bluetooth On"
local SHORTCUT_OFF = "Bluetooth Off"
local INTERNAL_HINTS = {"built%-in", "liquid retina", "color lcd"}

-- ===== Internal =====
local lastInternalPresent = nil
M._screenWatcher = nil
M._debouncer = nil
M._inflight = false

-- ===== Helpers =====
local function internalDisplayPresent()
    for _, s in ipairs(hs.screen.allScreens()) do
        local nm = (s:name() or ""):lower()
        for _, pat in ipairs(INTERNAL_HINTS) do
            if nm:match(pat) then
                return true
            end
        end
    end
    return false
end

local function debounce(delay, fn)
    if M._debouncer then
        M._debouncer:stop()
    end
    M._debouncer = hs.timer.doAfter(delay, function()
        M._debouncer = nil
        fn()
    end)
end

local function runShortcutOSA(name)
    local ok = false
    local success, _, err = hs.osascript.applescript(string.format([[
    tell application "Shortcuts Events"
      run shortcut "%s"
    end tell
  ]], name))
    ok = success == true
    if not ok then
        hs.printf("[lid_control] Shortcut OSA failed: %s", tostring(err))
    end
    return ok
end

local function runShortcutCLI(name)
    local bin = "/usr/bin/shortcuts"
    if not hs.fs.attributes(bin) then
        return false
    end
    local out, success, _, rc = hs.execute(string.format("%q run %q --show-errors 2>&1", bin, name), true)
    return success and rc == 0
end

local function toggleBluetooth(desiredOn)
    local sc = desiredOn and SHORTCUT_ON or SHORTCUT_OFF
    return runShortcutOSA(sc) or runShortcutCLI(sc)
end

local function ensureBluetooth(desiredOn)
    if M._inflight then
        return
    end
    M._inflight = true
    local tries = 0
    local function step()
        tries = tries + 1
        local ok = toggleBluetooth(desiredOn)
        if ok or tries > (1 + RETRIES) then
            hs.printf("✅ Bluetooth %s", desiredOn and "ON" or "OFF")
            M._inflight = false
            return
        end
        hs.timer.doAfter(RETRY_BACKOFF, step)
    end
    step()
end

-- ===== Actions =====
local function onLidClosed()
    debounce(CLOSE_DELAY, function()
        ensureBluetooth(false)
        hs.caffeinate.lockScreen()
        print("🔒 Lid closed — BT OFF + screen locked")
    end)
end

local function onLidOpened()
    debounce(OPEN_DELAY, function()
        ensureBluetooth(true)
        print("🔓 Lid opened — BT ON")
    end)
end

-- ===== Screen watcher =====
local function onScreensChanged()
    local present = internalDisplayPresent()
    if lastInternalPresent == nil then
        lastInternalPresent = present
        return
    end
    if lastInternalPresent and not present then
        onLidClosed()
    end
    if (not lastInternalPresent) and present then
        onLidOpened()
    end
    lastInternalPresent = present
end

-- ===== Public API =====
function M.start()
    if not M._screenWatcher then
        M._screenWatcher = hs.screen.watcher.new(onScreensChanged)
        M._screenWatcher:start()
        lastInternalPresent = internalDisplayPresent()
        print("✅ lid_control started (lock + BT via Shortcuts)")
    end
end

function M.stop()
    if M._screenWatcher then
        M._screenWatcher:stop()
        M._screenWatcher = nil
    end
    if M._debouncer then
        M._debouncer:stop()
        M._debouncer = nil
    end
    M._inflight = false
    print("🛑 lid_control stopped")
end

return M
