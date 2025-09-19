-- luacheck: globals hs
-- luacheck: max line length 120
-- ~/.hammerspoon/modules/safari_window_manager.lua
-- Module: safari_window_manager
-- Purpose: Moves new Safari windows to the secondary screen and resizes them.
-- Usage: require this module and call M.start() to enable automatic Safari window management.
-- Author: [Your Name]
-- Last updated: 2025-09-19

local M = {}

local safariWindowFilter = nil

--- Moves a Safari window to the secondary screen and resizes it to half width.
local function moveSafariWindow(win)
    if not win or not win:isStandard() then return end
    if win:application():name() ~= "Safari" then return end
    local allScreens = hs.screen.allScreens()
    if #allScreens < 2 then return end
    local primary = hs.screen.primaryScreen()
    local targetScreen = nil
    for _, screen in ipairs(allScreens) do
        if screen:id() ~= primary:id() then
            targetScreen = screen
            break
        end
    end
    if not targetScreen then return end
    -- Delay to ensure window is ready
    hs.timer.doAfter(0.3, function()
        if not win:isVisible() then return end
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

--- Starts the Safari window manager (moves new windows to secondary screen).
function M.start()
    safariWindowFilter = hs.window.filter.new(false):setAppFilter("Safari", {
        allowRoles = "*"
    })
    safariWindowFilter:subscribe({hs.window.filter.windowCreated}, function(win, _, _)
        hs.timer.doAfter(0.2, function()
            moveSafariWindow(win)
        end)
    end)
end

--- Stops the Safari window manager.
function M.stop()
    if safariWindowFilter then
        safariWindowFilter:unsubscribeAll()
        safariWindowFilter = nil
    end
end

return M

-- ...existing code...
