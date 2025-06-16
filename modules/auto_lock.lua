local M = {}

local timer = nil
local lastBuiltInPresent = true

local function isBuiltInDisplayPresent()
    for _, screen in ipairs(hs.screen.allScreens()) do
        if screen:name():lower():match("built%-in") then
            return true
        end
    end
    return false
end

local function checkLidState()
    local builtInPresent = isBuiltInDisplayPresent()

    if lastBuiltInPresent and not builtInPresent then
        hs.timer.doAfter(0.3, function()
            hs.caffeinate.lockScreen()
            print("🔒 Tampa fechada detectada — tela bloqueada.")
        end)
    end

    lastBuiltInPresent = builtInPresent
end

function M.bindHotkey()
    -- Placeholder se quiser atalhos no futuro
end

function M.start()
    if not timer then
        timer = hs.timer.doEvery(2, checkLidState)
        print("✅ Monitoramento de tampa iniciado (modo polling).")
    end
end

function M.stop()
    if timer then
        timer:stop()
        timer = nil
        print("🛑 Monitoramento de tampa desativado.")
    end
end

return M
