-- Carrega módulos locais
local autoBrightness = require("modules.auto_brightness")
local windowCycle = require("modules.window_cycle")
local filezillaCaffeinate = require("modules.filezilla_caffeinate")
local teamsMouse = require("modules.teams_mouse")
local autoLock = require("modules.auto_lock")

-- Agendamentos
autoBrightness.start()
filezillaCaffeinate.start()
teamsMouse.start()
autoLock.start()

-- Atalhos
windowCycle.bindHotkey()

-- Inicialização
print("✅ Hammerspoon Productivity Toolkit initialized.")
hs.alert.show("🎉 All automations active")
