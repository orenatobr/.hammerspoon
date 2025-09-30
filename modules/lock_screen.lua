-- luacheck: globals hs
-- luacheck: max line length 120

-- ~/.hammerspoon/modules/lock_screen.lua
-- Module: lock_screen
-- Purpose: Lock the screen using a hotkey (Option+Q).
-- Usage: require this module and call M.bindHotkey() to enable Option+Q lock screen.
-- Author: [Your Name]
-- Last updated: 2025-09-30

local M = {}

--- Binds Option+Q to lock the screen immediately.
function M.bindHotkey()
    hs.hotkey.bind({"alt"}, "q", function()
        hs.caffeinate.lockScreen()
    end)
end

return M
