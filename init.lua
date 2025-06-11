--------------------------------------------------------------------------------
-- 🔋 AUTO-AJUSTE DE BRILHO COM BASE NA FONTE DE ENERGIA (AC/BATERIA)
--------------------------------------------------------------------------------
-- Salva o estado atual da fonte de energia
local lastPowerSource = hs.battery.powerSource()

-- Função chamada periodicamente para checar se a fonte mudou (AC/Bateria)
function checkPowerSource()
    local ok, err = pcall(function()
        local source = hs.battery.powerSource()
        if source ~= lastPowerSource then
            hs.alert.show("Fonte de energia: " .. source)

            -- Ajuste o brilho dependendo da fonte
            if source == "AC Power" then
                hs.brightness.set(100)
            elseif source == "Battery Power" then
                hs.brightness.set(50)
            end

            lastPowerSource = source
        end
        print("🔋 Power check at", os.date("%H:%M:%S"), "-", source)
    end)
    if not ok then
        print("❌ Power check failed:", err)
    end
end

-- Executa a checagem a cada 5 segundos
hs.timer.doEvery(5, checkPowerSource)

--------------------------------------------------------------------------------
-- 🪟 ALTERNÂNCIA ENTRE JANELAS DO MESMO APLICATIVO COM ALT + A
--------------------------------------------------------------------------------

-- Atalho Alt+A para alternar entre janelas visíveis do app em foco
hs.hotkey.bind({"alt"}, "A", function()
    local app = hs.application.frontmostApplication()
    local windows = hs.fnutils.filter(app:allWindows(), function(win)
        return win:isStandard() and win:isVisible()
    end)

    if #windows < 2 then
        return
    end

    -- Ordena para garantir alternância determinística
    table.sort(windows, function(a, b)
        return a:id() < b:id()
    end)

    local focused = app:focusedWindow()
    local focusedID = focused and focused:id()
    local nextIndex = 1

    for i, win in ipairs(windows) do
        if win:id() == focusedID then
            nextIndex = (i % #windows) + 1
            break
        end
    end

    local nextWin = windows[nextIndex]
    if nextWin then
        nextWin:raise()
        nextWin:focus()
    end
end)

--------------------------------------------------------------------------------
-- ☕ CAFFEINATE ATIVO QUANDO FILEZILLA ESTIVER EM EXECUÇÃO
--------------------------------------------------------------------------------

-- Estado atual do caffeinate (se está impedindo ocioso)
local caffeinateStatus = false

-- Verifica se o FileZilla está rodando com base no nome do processo
function isAppRunning()
    local handle = io.popen("pgrep -lf filezilla")
    local result = handle:read("*a")
    handle:close()
    return result:match("FileZilla%.app") ~= nil
end

-- Ativa ou desativa o caffeinate conforme estado do FileZilla
function toggleCaffeinate(state)
    if state and not caffeinateStatus then
        hs.caffeinate.set("displayIdle", true)
        caffeinateStatus = true
        hs.alert.show("☕ Caffeinate ON")
        print("☕ Caffeinate ativado", os.date("%H:%M:%S"))
    elseif not state and caffeinateStatus then
        hs.caffeinate.set("displayIdle", false)
        caffeinateStatus = false
        hs.alert.show("💤 Caffeinate OFF")
        print("💤 Caffeinate desligado", os.date("%H:%M:%S"))
    end
end

-- Checa periodicamente o estado do FileZilla e atualiza o caffeinate
hs.timer.doEvery(5, function()
    local ok, err = pcall(function()
        local running = isAppRunning()
        print("🔍 FileZilla rodando?", running, os.date("%H:%M:%S"))
        toggleCaffeinate(running)
    end)
    if not ok then
        print("❌ FileZilla timer error:", err)
    end
end)

-- Inicializa o estado ao carregar o script
toggleCaffeinate(isAppRunning())

--------------------------------------------------------------------------------
-- 🖱️ SIMULADOR DE ATIVIDADE PARA MICROSOFT TEAMS (MOUSE MOVE A CADA 60s)
--------------------------------------------------------------------------------

local appName = "Microsoft Teams"
local interval = 60 -- segundos

-- Verifica se o Microsoft Teams está em execução
function isTeamsRunning()
    local handle = io.popen("pgrep -f \"" .. appName .. "\"")
    local result = handle:read("*a")
    handle:close()
    result = string.gsub(result, "%s+", "")
    return result ~= ""
end

-- Verifica se um ponto está dentro da área de qualquer tela conectada
function isPointVisible(point)
    for _, screen in ipairs(hs.screen.allScreens()) do
        local frame = screen:frame()
        if point.x >= frame.x and point.x <= frame.x + frame.w and point.y >= frame.y and point.y <= frame.y + frame.h then
            return true
        end
    end
    return false
end

-- Move o mouse em uma direção aleatória (±10px) respeitando área visível
function moveMouseSafely()
    local point = hs.mouse.absolutePosition()
    local dx = (math.random(0, 1) == 0 and -10 or 10)
    local dy = (math.random(0, 1) == 0 and -10 or 10)
    local newPoint = {
        x = point.x + dx,
        y = point.y + dy
    }

    if isPointVisible(newPoint) then
        hs.mouse.absolutePosition(newPoint)
        print("🖱️ Mouse moved to:", newPoint.x, newPoint.y, os.date("%H:%M:%S"))
    else
        print("⚠️ Ignored move outside visible screen:", newPoint.x, newPoint.y, os.date("%H:%M:%S"))
    end
end

-- A cada 60 segundos, se o Teams estiver rodando, move o mouse
hs.timer.doEvery(interval, function()
    local ok, err = pcall(function()
        if isTeamsRunning() then
            moveMouseSafely()
        else
            print("🛑 Teams not running, no mouse movement", os.date("%H:%M:%S"))
        end
    end)
    if not ok then
        print("❌ Teams timer error:", err)
    end
end)

-- Alerta visual ao carregar o script
hs.alert.show("👀 Teams activity monitor started (updated API)")
