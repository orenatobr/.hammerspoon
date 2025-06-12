-- Carrega módulos locais
local autoBrightness = require("modules.auto_brightness")
local windowCycle = require("modules.window_cycle")
local filezillaCaffeinate = require("modules.filezilla_caffeinate")
local teamsMouse = require("modules.teams_mouse")

-- Agendamentos
autoBrightness.start()
filezillaCaffeinate.start()
teamsMouse.start()

-- Atalhos
windowCycle.bindHotkey()

-- Inicialização
print("✅ Hammerspoon Productivity Toolkit initialized.")
hs.alert.show("🎉 All automations active")
