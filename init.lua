-- Load local modules
local autoBrightness = require("modules.auto_brightness")
local windowCycle = require("modules.window_cycle")
local launchPadShortcut = require("modules.launchpad_hotkey")
local filezillaCaffeinate = require("modules.filezilla_caffeinate")
local teamsMouse = require("modules.teams_mouse")
local autoLock = require("modules.auto_lock")
local teamsFocus = require("modules.teams_focus_restore")
local refreshPage = require("modules.refresh_hotkey")
local awsTabMonitor = require("modules.aws_tab_monitor")
local safariManager = require("modules.safari_window_manager")
local vscodeManager = require("modules.vscode_window_manager")

-- Start scheduled automations
autoBrightness.start()
filezillaCaffeinate.start()
teamsMouse.start()
autoLock.start()
teamsFocus.start()
awsTabMonitor.start()
safariManager.start()
vscodeManager.start()

-- Bind hotkeys
windowCycle.bindHotkey()
launchPadShortcut.bindHotkey()
refreshPage.bindHotkey()

-- Initialization
print("✅ Hammerspoon Productivity Toolkit initialized.")
hs.alert.show("🎉 All automations active")
