-- luacheck: globals hs
-- luacheck: max line length 120
-- ~/.hammerspoon/modules/cmd_d_and_4.lua
-- Module: cmd_d_and_4
-- Purpose: Binds a hotkey to show clipboard content.
-- Usage: require this module and call M.bindHotkey() to enable Alt+D.
-- Last updated: 2025-12-09

local M = {}

--- Binds Alt+D to show the native macOS clipboard.
function M.bindHotkey()
    hs.hotkey.bind({"alt"}, "d", function()
        -- Open Spotlight with Command+Space
        hs.eventtap.keyStroke({"cmd"}, "space")
        -- Wait 0.5 seconds for Spotlight to open
        hs.timer.doAfter(0.5, function()
            -- Then press Command+4 to open Clipboard
            hs.eventtap.keyStroke({"cmd"}, "4")
            print("[cmd_d_and_4] Opened Spotlight and Clipboard")
        end)
    end)
end

return M
