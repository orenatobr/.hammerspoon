-- ~/.hammerspoon/modules/lid_control.lua
-- Locks the screen on lid close. No Bluetooth toggling.
local M = {}

-- ===== Config =====
local OPEN_DELAY = 1.0 -- wait after lid open (for stability/logs only)
local CLOSE_DELAY = 0.4 -- wait after lid close before locking
local INTERNAL_HINTS = {"built%-in", "liquid retina", "color lcd"}

-- ===== Internal =====
local lastInternalPresent = nil
M._screenWatcher = nil
M._debouncer = nil

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

-- ===== Actions =====
local function onLidClosed()
    debounce(CLOSE_DELAY, function()
        hs.caffeinate.lockScreen()
        print("🔒 Lid closed — screen locked")
    end)
end

local function onLidOpened()
    debounce(OPEN_DELAY, function()
        print("🔓 Lid opened")
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
        print("✅ lid_control started (lock on lid close; no Bluetooth)")
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
    print("🛑 lid_control stopped")
end

return M
