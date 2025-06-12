-- modules/filezilla_watcher.lua
local M = {}

local caffeinateStatus = false
local watcher = nil

-- Callback reativo ao evento de lançamento/fechamento
local function appEvent(appName, eventType, app)
    if appName ~= "FileZilla" then
        return
    end

    if eventType == hs.application.watcher.launched then
        hs.caffeinate.set("displayIdle", true)
        caffeinateStatus = true
        hs.alert.closeAll()
        hs.alert.show("☕ Caffeinate ON")
        print("☕ FileZilla launched → Caffeinate ON")

    elseif eventType == hs.application.watcher.terminated then
        hs.caffeinate.set("displayIdle", false)
        caffeinateStatus = false
        hs.alert.closeAll()
        hs.alert.show("💤 Caffeinate OFF")
        print("☕ FileZilla closed → Caffeinate OFF")
    end
end

-- Inicia o watcher e faz checagem inicial
function M.start()
    watcher = hs.application.watcher.new(appEvent)
    watcher:start()

    -- Se já estiver rodando ao iniciar
    hs.timer.doAfter(1, function()
        local app = hs.application.find("FileZilla")
        if app and app:isRunning() then
            hs.caffeinate.set("displayIdle", true)
            caffeinateStatus = true
            hs.alert.closeAll()
            hs.alert.show("☕ Caffeinate ON (startup)")
            print("☕ FileZilla already running → Caffeinate ON")
        end
    end)

    print("📦 FileZilla watcher started")
end

function M.stop()
    if watcher then
        watcher:stop()
    end
end

return M
