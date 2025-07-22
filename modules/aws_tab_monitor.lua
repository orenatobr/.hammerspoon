local M = {}

local timer = nil
local lastAccount = nil
local appWatcher = nil

local accountMap = {
    ["376714490571"] = "🔵 fsm-preprod",
    ["074882943170"] = "🟡 fsm-int",
    ["075373948405"] = "🟣 fsm-tooling",
    ["885460024040"] = "🧪 fsm-e2e",
    ["816634016139"] = "🔴 fsm-prod"
}

local function fetchAWSAccountLabel()
    local script = [[
        tell application "Safari"
            if (count of windows) = 0 then return "NO_WINDOW"
            if (count of tabs of front window) = 0 then return "NO_TAB"
            set tabURL to URL of current tab of front window
            return tabURL
        end tell
    ]]

    local success, url = hs.osascript.applescript(script)
    if not success or not url or url == "NO_WINDOW" or url == "NO_TAB" then
        return nil
    end

    if not url:find("console.aws.amazon.com") then
        return nil
    end

    local accountId = string.match(url, "https://(%d+)[%-%.]")
    if not accountId then
        return nil
    end

    return accountMap[accountId] or "Unknown"
end

local function checkAWSAccount()
    local label = fetchAWSAccountLabel()
    if label and label ~= lastAccount then
        hs.alert.closeAll()
        hs.alert.show("🧭 AWS Account: " .. label)
        print("🧭 AWS Account: " .. label)
        lastAccount = label
    end
end

function M.start()
    appWatcher = hs.application.watcher.new(function(appName, eventType, app)
        if appName == "Safari" then
            if eventType == hs.application.watcher.activated then
                if not timer then
                    timer = hs.timer.doEvery(1, checkAWSAccount)
                    print("▶️ Started polling AWS account (Safari in focus)")
                end
            elseif eventType == hs.application.watcher.deactivated then
                if timer then
                    timer:stop()
                    timer = nil
                    print("⏹️ Stopped polling AWS account (Safari lost focus)")
                end
            end
        end
    end)
    appWatcher:start()
    print("🧪 AWS Account Monitor (hybrid watcher) started")
end

function M.stop()
    if timer then
        timer:stop()
        timer = nil
    end
    if appWatcher then
        appWatcher:stop()
        appWatcher = nil
    end
    print("🛑 AWS Account Monitor (hybrid watcher) stopped")
end

return M
