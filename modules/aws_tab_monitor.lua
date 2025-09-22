-- luacheck: globals hs
local M = {}
local pollTimer = nil
local lastTabUrl = nil
local accountMap = {
    ["376714490571"] = "🔵 fsm-preprod",
    ["074882943170"] = "🟡 fsm-int",
    ["075373948405"] = "🟣 fsm-tooling",
    ["885460024040"] = "🧪 fsm-e2e",
    ["816634016139"] = "🔴 fsm-prod"
}

local function getCurrentAWSTab()
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
        return nil, nil
    end
    local accountId = string.match(url, "https://(%d+)[%-%.]")
    return accountId, url
end

local function showAWSAccount()
    local accountId, url = getCurrentAWSTab()
    if not accountId or not url then return end
    if url ~= lastTabUrl then
        local label = accountMap[accountId] or "Unknown"
        hs.alert.closeAll()
        hs.alert.show("🧭 AWS Account: " .. label)
        print("🧭 AWS Account: " .. label)
        lastTabUrl = url
    end
end

function M.start()
    print("🧪 AWS Account Monitor started")
    if not pollTimer then
        pollTimer = hs.timer.doEvery(0.5, function()
            local safari = hs.application.find("Safari")
            if safari and safari:isFrontmost() then
                showAWSAccount()
            else
                lastTabUrl = nil
            end
        end)
    end
end

function M.stop()
    if pollTimer then
        pollTimer:stop()
        pollTimer = nil
    end
    lastTabUrl = nil
    print("🛑 AWS Account Monitor stopped")
end

return M
