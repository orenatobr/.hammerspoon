--------------------------------------------------------------------------------
-- 🔋 AUTO-AJUSTE DE BRILHO COM BASE NA FONTE DE ENERGIA (AC/BATERIA)
--------------------------------------------------------------------------------

local lastPowerSource = hs.battery.powerSource()

function checkPowerSource()
    local source = hs.battery.powerSource()
    if source ~= lastPowerSource then
        hs.alert.show("Fonte de energia: " .. source)

        -- Ajuste de brilho conforme fonte de energia
        if source == "AC Power" then
            hs.brightness.set(100)
        elseif source == "Battery Power" then
            hs.brightness.set(50)
        end

        lastPowerSource = source
    end
end

-- Verifica a fonte de energia a cada 5 segundos
hs.timer.doEvery(5, checkPowerSource)

--------------------------------------------------------------------------------
-- 🪟 ALTERNÂNCIA ENTRE JANELAS DO MESMO APLICATIVO COM ALT + A
--------------------------------------------------------------------------------

hs.hotkey.bind({"alt"}, "A", function()
    local app = hs.application.frontmostApplication()
    local windows = hs.fnutils.filter(app:allWindows(), function(win)
        return win:isStandard() and win:isVisible()
    end)

    if #windows < 2 then return end

    -- Ordenação determinística pelas IDs das janelas
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

    -- Foco na próxima janela
    local nextWin = windows[nextIndex]
    if nextWin then
        nextWin:raise()
        nextWin:focus()
    end
end)

--------------------------------------------------------------------------------
-- ☕ CAFFEINATE ATIVO QUANDO FILEZILLA ESTIVER EM EXECUÇÃO
--------------------------------------------------------------------------------

local caffeinateStatus = false

-- Verifica se o FileZilla está rodando (pelo nome do processo)
function isAppRunning()
    local handle = io.popen("pgrep -lf filezilla")
    local result = handle:read("*a")
    handle:close()
    return result:match("FileZilla%.app") ~= nil
end

-- Alterna o estado do caffeinate
function toggleCaffeinate(state)
    if state and not caffeinateStatus then
        hs.caffeinate.set("displayIdle", true)
        caffeinateStatus = true
        hs.alert.show("☕ Caffeinate ON")
        print("☕ Caffeinate ativado")
    elseif not state and caffeinateStatus then
        hs.caffeinate.set("displayIdle", false)
        caffeinateStatus = false
        hs.alert.show("💤 Caffeinate OFF")
        print("💤 Caffeinate desligado")
    end
end

-- Checa o FileZilla a cada 5 segundos
hs.timer.doEvery(5, function()
    local running = isAppRunning()
    print("🔍 FileZilla rodando? ", running)
    toggleCaffeinate(running)
end)

-- Inicialização com o estado atual do FileZilla
toggleCaffeinate(isAppRunning())

--------------------------------------------------------------------------------
-- 🖱️ SIMULADOR DE ATIVIDADE PARA MICROSOFT TEAMS (MOUSE MOVE A CADA 60s)
--------------------------------------------------------------------------------

local appName = "Microsoft Teams"
local interval = 60  -- segundos

-- Verifica se o Teams está rodando
function isTeamsRunning()
    local handle = io.popen("pgrep -f \"" .. appName .. "\"")
    local result = handle:read("*a")
    handle:close()
    result = string.gsub(result, "%s+", "")
    return result ~= ""
end

-- Verifica se um ponto está dentro de qualquer tela visível
function isPointVisible(point)
    for _, screen in ipairs(hs.screen.allScreens()) do
        local frame = screen:frame()
        if point.x >= frame.x and point.x <= frame.x + frame.w and
           point.y >= frame.y and point.y <= frame.y + frame.h then
            return true
        end
    end
    return false
end

-- Move o mouse aleatoriamente em ±10px, respeitando a área visível
function moveMouseSafely()
    local point = hs.mouse.absolutePosition()
    local dx = (math.random(0, 1) == 0 and -10 or 10)
    local dy = (math.random(0, 1) == 0 and -10 or 10)

    local newPoint = {x = point.x + dx, y = point.y + dy}

    if isPointVisible(newPoint) then
        hs.mouse.absolutePosition(newPoint)
        print("🖱️ Mouse moved to:", newPoint.x, newPoint.y)
    else
        print("⚠️ Ignored move outside visible screen:", newPoint.x, newPoint.y)
    end
end

-- A cada 60 segundos, se o Teams estiver rodando, move o mouse
hs.timer.doEvery(interval, function()
    if isTeamsRunning() then
        moveMouseSafely()
    else
        print("🛑 Teams not running, no mouse movement")
    end
end)

-- Aviso visual ao carregar o script
hs.alert.show("👀 Teams activity monitor started (updated API)")