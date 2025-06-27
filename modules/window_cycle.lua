local M = {}

function M.bindHotkey()
    hs.hotkey.bind({"alt"}, "C", function()
        local app = hs.application.frontmostApplication()
        local windows = hs.fnutils.filter(app:allWindows(), function(w)
            return w:isStandard() and w:isVisible()
        end)

        if #windows < 2 then
            print("ℹ️ Only one window — no cycling needed.")
            return
        end

        table.sort(windows, function(a, b)
            return a:id() < b:id()
        end)

        local focusedID = app:focusedWindow() and app:focusedWindow():id()
        local nextIndex = 1

        for i, w in ipairs(windows) do
            if w:id() == focusedID then
                nextIndex = (i % #windows) + 1
                break
            end
        end

        windows[nextIndex]:raise():focus()
        print("🪟 Window switched.")
    end)
end

return M
