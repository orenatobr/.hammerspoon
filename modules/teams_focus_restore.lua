local M = {}

local lastUsefulWindow = nil
local windowFilter = nil
local appName = "Microsoft Teams"

-- Tracks the last valid Teams window (ignores popups or empty titles)
local function setupWindowFilter()
    windowFilter = hs.window.filter.new(appName)
    windowFilter:subscribe(hs.window.filter.windowFocused, function(win)
        local ok, title = pcall(function()
            return win:title()
        end)
        if ok and win:isStandard() and title and title ~= "" then
            lastUsefulWindow = win
            print("💾 [Teams] Saved useful window: " .. title)
        end
    end)
end

-- Attempts to refocus the last known good Teams window
local function focusLastWindow()
    if not lastUsefulWindow then
        return
    end
    if not lastUsefulWindow:isStandard() or not lastUsefulWindow:isVisible() then
        return
    end

    hs.timer.doAfter(0.3, function()
        local front = hs.window.frontmostWindow()
        if front and front:id() == lastUsefulWindow:id() then
            return
        end

        local ok, title = pcall(function()
            return lastUsefulWindow:title()
        end)
        if ok then
            print("🔁 [Teams] Refocusing last known good window: " .. title)
            lastUsefulWindow:focus()
        end
    end)
end

-- Application watcher for Microsoft Teams only
local function onAppEvent(app, eventType, appObj)
    if app == appName and eventType == hs.application.watcher.activated then
        focusLastWindow()
    end
end

function M.start()
    setupWindowFilter()
    hs.application.watcher.new(onAppEvent):start()
    print("👀 Watching Microsoft Teams for window restoration.")
end

return M
