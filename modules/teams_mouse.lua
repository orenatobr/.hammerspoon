local M = {}

local watcher = nil
local mouseTimer = nil

-- Simula um pequeno movimento real com eventos do sistema
local function jiggleMouse()
    local point = hs.mouse.absolutePosition()
    local offset = 1

    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.mouseMoved, {
        x = point.x + offset,
        y = point.y + offset
    }):post()

    hs.timer.doAfter(0.1, function()
        hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.mouseMoved, {
            x = point.x,
            y = point.y
        }):post()
    end)

    print("🖱️ Simulated mouse movement (Teams keep-alive)")
end

local function startMouseKeepAlive()
    if not mouseTimer then
        mouseTimer = hs.timer.new(60, jiggleMouse)
        mouseTimer:start()
        print("✅ Mouse keep-alive timer iniciado.")
    end
end

local function stopMouseKeepAlive()
    if mouseTimer then
        mouseTimer:stop()
        mouseTimer = nil
        print("🛑 Mouse keep-alive timer parado.")
    end
end

local function appWatcher(appName, eventType)
    if appName == "Microsoft Teams" then
        if eventType == hs.application.watcher.launched then
            print("🚀 Microsoft Teams iniciado.")
            startMouseKeepAlive()
        elseif eventType == hs.application.watcher.terminated then
            print("❌ Microsoft Teams encerrado.")
            stopMouseKeepAlive()
        end
    end
end

function M.start()
    -- Verifica se o Teams já estava aberto ao iniciar
    local app = hs.application.find("Microsoft Teams")
    if app and app:isRunning() then
        print("🔎 Microsoft Teams já estava rodando.")
        startMouseKeepAlive()
    end

    watcher = hs.application.watcher.new(appWatcher)
    watcher:start()
    print("👀 Watching for Microsoft Teams...")
end

return M
