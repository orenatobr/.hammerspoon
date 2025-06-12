local M = {}

local watcher = nil
local mouseTimer = nil

local function moveMouse()
    local point = hs.mouse.absolutePosition()
    local wiggle = 10
    local newX = math.floor(point.x + (math.random(0, 1) == 0 and -wiggle or wiggle))
    local newY = math.floor(point.y + (math.random(0, 1) == 0 and -wiggle or wiggle))
    local newPoint = {
        x = newX,
        y = newY
    }

    hs.mouse.absolutePosition(newPoint)
    print(string.format("🖱️ Mouse moved to: x=%d, y=%d", newX, newY))
end

local function startMouseKeepAlive()
    if not mouseTimer then
        mouseTimer = hs.timer.new(60, moveMouse)
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
