-- luacheck: globals hs
-- luacheck: max line length 120
-- ~/.hammerspoon/modules/refresh_hotkey.lua
-- Module: refresh_hotkey
-- Purpose: Binds a hotkey to clear browser cache and reload the page (Alt+R).
-- Usage: require this module and call M.bindHotkey() to enable Alt+R for cache clear and reload.
-- Author: [Your Name]
-- Last updated: 2025-09-19

local M = {}

--- Binds Alt+R to clear browser cache and reload the page.
function M.bindHotkey()
    -- luacheck: ignore _
    hs.hotkey.bind({"alt"}, "R", function(_)
        -- Simulate Option + Command + E (Empty Cache)
        hs.eventtap.keyStroke({"alt", "cmd"}, "E")
        print("🧹 Cache cleared.")
        -- Wait 1 second before reloading the page
        hs.timer.doAfter(1, function()
            -- Simulate Command + R (Reload Page)
            hs.eventtap.keyStroke({"cmd"}, "R")
            print("🔄 Page reloaded.")
        end)
    end)
end

return M
