local M = {}

local appWatcher = nil
local windowFilters = {}
local lastUsefulWindows = {}

-- Creates a window filter to track the last useful window of a given app
local function createWindowFilter(appName)
    local wf = hs.window.filter.new(appName)
    wf:subscribe(hs.window.filter.windowFocused, function(win)
        local ok, title = pcall(function()
            return win:title()
        end)
        if ok and win:isStandard() and title and title ~= "" then
            lastUsefulWindows[appName] = win
            print("💾 [" .. appName .. "] Saved useful window: " .. title)
        end
    end)
    windowFilters[appName] = wf
end

-- Attempts to restore focus to the last useful window of an app
local function handleAppActivated(appName)
    local win = lastUsefulWindows[appName]
    if win and win:isStandard() and win:application():name() == appName then
        hs.timer.doAfter(0.3, function()
            -- Avoid refocusing if already focused or invalid
            local frontmost = hs.window.frontmostWindow()
            if win:id() ~= frontmost:id() and win:isVisible() then
                local ok, title = pcall(function()
                    return win:title()
                end)
                if ok then
                    print("🔁 [" .. appName .. "] Refocusing useful window: " .. title)
                    win:focus()
                end
            end
        end)
    end
end

-- Handles application activation events
local function appEventHandler(appName, eventType, appObj)
    if eventType == hs.application.watcher.activated then
        if not windowFilters[appName] then
            createWindowFilter(appName)
        end
        handleAppActivated(appName)
    end
end

function M.start()
    appWatcher = hs.application.watcher.new(appEventHandler)
    appWatcher:start()
    print("👀 Global app watcher active (restores last focused windows)")
end

return M
