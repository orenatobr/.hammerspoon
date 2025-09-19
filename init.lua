-- ~/.hammerspoon/init.lua
-- Main entry point for Hammerspoon Productivity Toolkit
-- Loads and starts all automation modules, binds hotkeys, and shows startup alerts.
-- Author: [Your Name]
-- Last updated: 2025-09-19

-- Load modules
local autoBrightness      = require("modules.auto_brightness")
local windowCycle         = require("modules.window_cycle")
local launchPadShortcut   = require("modules.launchpad_hotkey")
local filezillaCaffeinate = require("modules.filezilla_caffeinate")
local keepalive           = require("modules.idle_keepalive")
local autoLock            = require("modules.auto_lock")
local teamsFocus          = require("modules.teams_focus_restore")
local refreshPage         = require("modules.refresh_hotkey")
local awsTabMonitor       = require("modules.aws_tab_monitor")
local safariManager       = require("modules.safari_window_manager")
local vscodeManager       = require("modules.vscode_window_manager")
local tabNavigation       = require("modules.tab_navigation")
local appNavigation       = require("modules.app_navigation")
local autoFullscreen      = require("modules.auto_fullscreen")

-- Start automations
autoBrightness.start()
filezillaCaffeinate.start()
keepalive.start({
    app_names = {"Microsoft Teams", "Zoom", "Slack"},
    bundle_ids = {"com.microsoft.teams2"}
})
autoLock.start()
teamsFocus.start()
awsTabMonitor.start()
safariManager.start()
vscodeManager.start()
autoFullscreen.start({
    native_fullscreen = false,
    internal_hint = "Built%-in",
    exclude_apps = {"Terminal", "iTerm2"},
    maximize_only_apps = {"Code", "Safari", "FileZilla", "Microsoft Teams", "zoom.us"},
    screens_settle_seconds = 2.0,
    quarantine_seconds = 12.0
})

-- Bind hotkeys
windowCycle.bindHotkey()
launchPadShortcut.bindHotkey()
refreshPage.bindHotkey()
tabNavigation.bindHotkey()
appNavigation.bindHotkey()

-- Initialization
print("✅ Hammerspoon Productivity Toolkit initialized.")
hs.alert.show("🎉 All automations active")
-- ~/.hammerspoon/init.lua
-- Main entry point for Hammerspoon Productivity Toolkit
-- Loads and starts all automation modules, binds hotkeys, and shows startup alerts.
-- Author: [Your Name]
-- Last updated: 2025-09-19

-- Load modules
local autoBrightness      = require("modules.auto_brightness")
local windowCycle         = require("modules.window_cycle")
local launchPadShortcut   = require("modules.launchpad_hotkey")
local filezillaCaffeinate = require("modules.filezilla_caffeinate")
local keepalive           = require("modules.idle_keepalive")
local autoLock            = require("modules.auto_lock")
local teamsFocus          = require("modules.teams_focus_restore")
local refreshPage         = require("modules.refresh_hotkey")
local awsTabMonitor       = require("modules.aws_tab_monitor")
local safariManager       = require("modules.safari_window_manager")
local vscodeManager       = require("modules.vscode_window_manager")
local tabNavigation       = require("modules.tab_navigation")
local appNavigation       = require("modules.app_navigation")
local autoFullscreen      = require("modules.auto_fullscreen")

-- Start automations
autoBrightness.start()
filezillaCaffeinate.start()
keepalive.start({
    app_names = {"Microsoft Teams", "Zoom", "Slack"},
    bundle_ids = {"com.microsoft.teams2"}
})
autoLock.start()
teamsFocus.start()
awsTabMonitor.start()
safariManager.start()
vscodeManager.start()
autoFullscreen.start({
    native_fullscreen = false,
    internal_hint = "Built%-in",
    exclude_apps = {"Terminal", "iTerm2"},
    maximize_only_apps = {"Code", "Safari", "FileZilla", "Microsoft Teams", "zoom.us"},
    screens_settle_seconds = 2.0,
    quarantine_seconds = 12.0
})

-- Bind hotkeys
windowCycle.bindHotkey()
launchPadShortcut.bindHotkey()
refreshPage.bindHotkey()
tabNavigation.bindHotkey()
appNavigation.bindHotkey()

-- Initialization
print("✅ Hammerspoon Productivity Toolkit initialized.")
hs.alert.show("🎉 All automations active")
