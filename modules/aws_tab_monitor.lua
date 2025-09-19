-- luacheck: ignore appWatcher clickWatcher
-- luacheck: ignore hs
-- Last updated: 2025-09-19

local M = {}

local lastAWSUrl = nil
local accountMap = {
    ["376714490571"] = "🔵 fsm-preprod",
    ["074882943170"] = "🟡 fsm-int",
    ["075373948405"] = "🟣 fsm-tooling",
    ["885460024040"] = "🧪 fsm-e2e",
    ["816634016139"] = "🔴 fsm-prod"
}

--- Gets the current Safari tab URL and maps the AWS account if present.
-- luacheck: ignore script
local function fetchAWSAccountData()
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
        return nil, nil
    end
    if not url:find("console.aws.amazon.com") then
        return url, nil
    end
    local accountId = string.match(url, "https://(%d+)[%-%.]")
    if not accountId then
        return url, "Unknown"
    end
    return url, accountMap[accountId] or "Unknown"
end

--- Checks the current AWS account and shows a notification if changed.
local function checkAWSAccount()
    local url, label = fetchAWSAccountData()
    if not url then
        return
    end
    if label then
        -- URL is from AWS, only notify if different from the last seen AWS URL
        if url ~= lastAWSUrl then
            hs.alert.closeAll()
            hs.alert.show("🧭 AWS Account: " .. label)
            print("🧭 AWS Account: " .. label)
            lastAWSUrl = url
        end
    else
        -- Non-AWS URL: reset last seen AWS URL to allow future re-notification
        lastAWSUrl = nil
    end
end

function M.start()
    print("🧪 AWS Account Monitor started")
    -- Example: poll every 10 seconds
    if not M._timer then
        M._timer = hs.timer.doEvery(10, checkAWSAccount)
    end
end

function M.stop()
    if M._timer then
        M._timer:stop()
        M._timer = nil
    end
    print("🛑 AWS Account Monitor stopped")
end

-- Stops the watchers
function M.stop()
    if appWatcher then
        appWatcher:stop()
        appWatcher = nil
    end
    if clickWatcher then
        clickWatcher:stop()
        clickWatcher = nil
    end
    print("🛑 AWS Account Monitor stopped")
end

return M
