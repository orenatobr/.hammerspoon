-- luacheck: globals hs
-- luacheck: max line length 120
-- ~/.hammerspoon/modules/vscode_window_manager.lua
-- Module: vscode_window_manager
-- Purpose: Moves new VSCode windows to the secondary screen and resizes them.
-- Usage: require this module and call M.start() to enable automatic VSCode window management.
-- Author: [Your Name]
-- Last updated: 2025-09-19

local M = {}

local vscodeWindowFilter = nil

--- Moves a VSCode window to the secondary screen and resizes it to half width (right side).
local function moveVSCodeWindow(win)
    if not win or not win:isStandard() then return end
    if win:application():name() ~= "Code" then return end
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
    hs.timer.doAfter(0.3, function()
        if not win:isVisible() then return end
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

--- Starts the VSCode window manager (moves new/focused windows to secondary screen).
function M.start()
    vscodeWindowFilter = hs.window.filter.new(false):setAppFilter("Code", {
        allowRoles = "*"
    })
    -- luacheck: ignore appName event
    vscodeWindowFilter:subscribe({hs.window.filter.windowCreated, hs.window.filter.windowFocused},
        function(win, appName, event)
            hs.timer.doAfter(0.2, function()
                moveVSCodeWindow(win)
            end)
        end)
end

--- Stops the VSCode window manager.
function M.stop()
    if vscodeWindowFilter then
        vscodeWindowFilter:unsubscribeAll()
        vscodeWindowFilter = nil
    end
end

return M

-- ...existing code...
