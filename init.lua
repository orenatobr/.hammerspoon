-- Load local modules
local autoBrightness = require("modules.auto_brightness")
local windowCycle = require("modules.window_cycle")
local filezillaCaffeinate = require("modules.filezilla_caffeinate")
local teamsMouse = require("modules.teams_mouse")
local autoLock = require("modules.auto_lock")

-- Start scheduled automations
autoBrightness.start()
filezillaCaffeinate.start()
teamsMouse.start()
autoLock.start()

-- Bind hotkeys
windowCycle.bindHotkey()

-- Initialization
print("✅ Hammerspoon Productivity Toolkit initialized.")
hs.alert.show("🎉 All automations active")
