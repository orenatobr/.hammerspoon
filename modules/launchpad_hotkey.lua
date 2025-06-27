local M = {}

function M.bindHotkey()
    hs.hotkey.bind({"alt"}, "A", function()
        hs.execute("open -a Launchpad")
        print("🚀 Launchpad opened.")
    end)
end

return M
