local M = {}

local safariWindowFilter = nil

local function moveSafariWindow(win)
    if not win or not win:isStandard() then
        return
    end
    if win:application():name() ~= "Safari" then
        return
    end

    local allScreens = hs.screen.allScreens()
    if #allScreens < 2 then
        return
    end

    local primary = hs.screen.primaryScreen()
    local targetScreen = nil

    for _, screen in ipairs(allScreens) do
        if screen:id() ~= primary:id() then
            targetScreen = screen
            break
        end
    end

    if not targetScreen then
        return
    end

    -- Delay para garantir que a janela está pronta
    hs.timer.doAfter(0.3, function()
        if not win:isVisible() then
            return
        end
        win:moveToScreen(targetScreen)

        hs.timer.doAfter(0.2, function()
            local f = targetScreen:frame()
            win:setFrame({
                x = f.x,
                y = f.y,
                w = f.w / 2,
                h = f.h
            })
        end)
    end)
end

function M.start()
    safariWindowFilter = hs.window.filter.new(false):setAppFilter("Safari", {
        allowRoles = "*"
    })

    safariWindowFilter:subscribe({hs.window.filter.windowCreated}, function(win, appName, event)
        hs.timer.doAfter(0.2, function()
            moveSafariWindow(win)
        end)
    end)

    print("🧭 Safari window filter watcher started")
end

function M.stop()
    if safariWindowFilter then
        safariWindowFilter:unsubscribeAll()
        safariWindowFilter = nil
        print("🛑 Safari window filter watcher stopped")
    end
end

return M
