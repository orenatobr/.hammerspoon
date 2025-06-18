local M = {}

local appWatcher = nil
local windowFilters = {}
local lastUsefulWindows = {}

-- Salva a última janela útil de qualquer app
local function createWindowFilter(appName)
    local wf = hs.window.filter.new(appName)
    wf:subscribe(hs.window.filter.windowFocused, function(win)
        local title = win:title()
        if win:isStandard() and title and title ~= "" then
            lastUsefulWindows[appName] = win
            print("💾 [" .. appName .. "] Saved useful window: " .. title)
        end
    end)
    windowFilters[appName] = wf
end

-- Aplica lógica de restauração quando o app é ativado
local function handleAppActivated(appName)
    local lastWindow = lastUsefulWindows[appName]
    if lastWindow and lastWindow:isStandard() then
        hs.timer.doAfter(0.3, function()
            print("🔁 [" .. appName .. "] Refocusing useful window: " .. lastWindow:title())
            lastWindow:focus()
        end)
    end
end

-- Watcher para todos os apps
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
    print("👀 Global app watcher active (restore last focused windows)")
end

return M
