-- luacheck: globals hs
-- luacheck: max line length 120
-- ~/.hammerspoon/modules/move_window_space.lua
-- Module: move_window_space
-- Purpose: Sends the focused window to the next/previous Space (desktop) on its screen and follows it.
-- Usage: require this module and call M.bindHotkey() to enable Alt+Right / Alt+Left.
-- Last updated: 2026-10-14

local M = {}

--- Moves the focused window `step` Spaces away (+1 right, -1 left) and switches to that Space.
local function moveFocusedWindow(step)
    local win = hs.window.focusedWindow()
    if not win then return end
    local spaces = hs.spaces.spacesForScreen(win:screen())
    local current = (hs.spaces.windowSpaces(win) or {})[1]
    if not spaces or not current then return end
    for i, id in ipairs(spaces) do
        if id == current then
            local target = spaces[i + step]
            if not target then return end
            -- ponytail: fullscreen windows live in their own Space and cannot be moved
            if hs.spaces.moveWindowToSpace(win, target) then
                hs.spaces.gotoSpace(target)
                win:focus()
            else
                hs.alert.show("⚠️ Couldn’t move window to that Space")
            end
            return
        end
    end
end

--- Binds Alt+Right / Alt+Left to send the focused window to the adjacent Space.
function M.bindHotkey()
    hs.hotkey.bind({"alt"}, "right", function() moveFocusedWindow(1) end)
    hs.hotkey.bind({"alt"}, "left", function() moveFocusedWindow(-1) end)
end

return M
