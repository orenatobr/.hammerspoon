local M = {}

local vscodeWindowFilter = nil

local function moveVSCodeWindow(win)
    if not win or not win:isStandard() then
        return
    end
    if win:application():name() ~= "Code" then
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

    hs.timer.doAfter(0.3, function()
        if not win:isVisible() then
            return
        end
        win:moveToScreen(targetScreen)

        hs.timer.doAfter(0.2, function()
            local f = targetScreen:frame()
            win:setFrame({
                x = f.x + f.w / 2,
                y = f.y,
                w = f.w / 2,
                h = f.h
            })
        end)
    end)
end

function M.start()
    vscodeWindowFilter = hs.window.filter.new(false):setAppFilter("Code", {
        allowRoles = "*"
    })

    vscodeWindowFilter:subscribe({hs.window.filter.windowCreated, hs.window.filter.windowFocused},
        function(win, appName, event)
            hs.timer.doAfter(0.2, function()
                moveVSCodeWindow(win)
            end)
        end)

    print("💻 VSCode window watcher started")
end

function M.stop()
    if vscodeWindowFilter then
        vscodeWindowFilter:unsubscribeAll()
        vscodeWindowFilter = nil
        print("🛑 VSCode window watcher stopped")
    end
end

return M
