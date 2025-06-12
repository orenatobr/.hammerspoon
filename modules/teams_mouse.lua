local M = {}

local function isAppRunning(appName)
    local app = hs.application.get(appName)
    return app and app:isRunning()
end

function M.start()
    hs.timer.doEvery(60, function()
        if isAppRunning("Microsoft Teams") then
            local screen = hs.mouse.getCurrentScreen() or hs.screen.primaryScreen()
            local point = hs.mouse.absolutePosition()
            local wiggle = 10

            local newX = math.floor(math.max(screen:frame().x, math.min(screen:frame().x + screen:frame().w - 1, point.x +
                (math.random(0, 1) == 0 and -wiggle or wiggle))))
            local newY = math.floor(math.max(screen:frame().y, math.min(screen:frame().y + screen:frame().h - 1, point.y +
                (math.random(0, 1) == 0 and -wiggle or wiggle))))

            hs.mouse.absolutePosition({ x = newX, y = newY })
            print(string.format("🖱️ Mouse moved to: x=%d, y=%d", newX, newY))
        end
    end)
end

return M