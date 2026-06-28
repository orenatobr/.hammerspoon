-- luacheck: globals hs
-- luacheck: max line length 120
local M = {}

local HOTKEY_MODS = {"alt"}
local HOTKEY_KEY  = "f"

local function relaunchTerminal()
    local app = hs.application.find("Code")
    if not app then
        hs.alert.show("VS Code not running")
        return
    end
    app:activate()
    hs.timer.doAfter(0.2, function()
        hs.eventtap.keyStroke({"cmd", "shift"}, "p")
        hs.timer.doAfter(0.3, function()
            hs.eventtap.keyStrokes("relaunch active terminal")
            hs.timer.doAfter(0.3, function()
                hs.eventtap.keyStroke({}, "return")
            end)
        end)
    end)
end

function M.bindHotkey()
    hs.hotkey.bind(HOTKEY_MODS, HOTKEY_KEY, relaunchTerminal)
end

return M
