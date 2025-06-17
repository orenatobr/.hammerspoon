local M = {}

local timer = nil
local lastBuiltInPresent = true

local function isBuiltInDisplayPresent()
    for _, screen in ipairs(hs.screen.allScreens()) do
        if screen:name():lower():match("built%-in") then
            return true
        end
    end
    return false
end

local function checkLidState()
    local builtInPresent = isBuiltInDisplayPresent()

    if lastBuiltInPresent and not builtInPresent then
        hs.timer.doAfter(0.3, function()
            hs.caffeinate.lockScreen()
            print("🔒 Lid closed detected — screen locked.")
        end)
    end

    lastBuiltInPresent = builtInPresent
end

function M.bindHotkey()
    -- Placeholder in case you want to add hotkeys later
end

function M.start()
    if not timer then
        timer = hs.timer.doEvery(2, checkLidState)
        print("✅ Lid monitoring started (polling mode).")
    end
end

function M.stop()
    if timer then
        timer:stop()
        timer = nil
        print("🛑 Lid monitoring stopped.")
    end
end

return M
