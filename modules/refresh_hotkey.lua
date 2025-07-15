local M = {}

function M.bindHotkey()
    -- Bind Alt + R to clear browser cache and reload the page
    hs.hotkey.bind({"alt"}, "R", function()
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
