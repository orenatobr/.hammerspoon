-- ~/.hammerspoon/modules/teams_focus_restore.lua
-- Module: teams_focus_restore
-- Purpose: Restores focus to the last useful Teams window when Teams is activated.
-- Usage: require this module and call M.start() to enable Teams window focus restore.
-- Author: [Your Name]
-- Last updated: 2025-09-19

local M = {}
local appWatcher = nil
local windowFilter = nil
local lastUsefulWindow = nil
local appName = "Microsoft Teams" -- adjust if needed

--- Tracks the last focused useful window from Teams.
local function createWindowFilter()
    windowFilter = hs.window.filter.new(appName)
    windowFilter:subscribe(hs.window.filter.windowFocused, function(win)
        local ok, title = pcall(function() return win:title() end)
        if ok and win:isStandard() and title and title ~= "" then
            lastUsefulWindow = win
            print("💾 [Teams] Saved useful window: " .. title)
        end
    end)
end

--- Attempts to restore focus to the last Teams window.
local function handleAppActivated()
    local win = lastUsefulWindow
    if win and win:isStandard() and win:application():name() == appName then
        hs.timer.doAfter(0.3, function()
            local frontmost = hs.window.frontmostWindow()
            if win:id() ~= frontmost:id() and win:isVisible() then
                local ok, title = pcall(function() return win:title() end)
                if ok then
                    print("🔁 [Teams] Refocusing useful window: " .. title)
                    win:raise()
                    win:focus()
                end
            end
        end)
    end
end

--- Handles Teams activation only.
local function appEventHandler(app, eventType, appObj)
    if app == appName and eventType == hs.application.watcher.activated then
        if not windowFilter then
            createWindowFilter()
        end
        handleAppActivated()
    end
end

--- Starts the Teams focus restore watcher.
function M.start()
    appWatcher = hs.application.watcher.new(appEventHandler)
    appWatcher:start()
    print("👀 Watching Microsoft Teams (restore last focused window)")
end

--- Stops the Teams focus restore watcher.
function M.stop()
    if appWatcher then
        appWatcher:stop()
        appWatcher = nil
    end
    if windowFilter then
        windowFilter:unsubscribeAll()
        windowFilter = nil
    end
end

return M
