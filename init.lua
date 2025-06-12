-- Carrega módulos locais
local autoBrightness = require("modules.auto_brightness")
local windowCycle = require("modules.window_cycle")
-- local filezillaCaffeinate = require("modules.filezilla_caffeinate")
-- local teamsMouse = require("modules.teams_mouse")

-- Agendamentos
hs.timer.doEvery(5, autoBrightness.checkPowerSource)
-- hs.timer.doEvery(5, filezillaCaffeinate.syncCaffeinate)
-- hs.timer.doEvery(60, teamsMouse.moveMouse)

-- Atalhos
windowCycle.bindHotkey()

-- Inicialização
print("✅ Hammerspoon Productivity Toolkit initialized.")
hs.alert.show("🎉 All automations active")