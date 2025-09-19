-- luacheck: globals hs
-- luacheck: ignore caffeinateStatus
-- Purpose: Prevents display sleep while FileZilla is running by toggling caffeinate.
-- Usage: require this module and call M.start() to enable automatic caffeinate for FileZilla.
-- Author: [Your Name]
-- Last updated: 2025-09-19

local M = {}

local caffeinateStatus = false
local watcher = nil

--- Handles FileZilla launch/termination events to toggle caffeinate.
-- luacheck: ignore app
local function appEvent(appName, eventType, _)
    if appName ~= "FileZilla" then
        return
    end
    if eventType == hs.application.watcher.launched then
        hs.caffeinate.set("displayIdle", true)
        caffeinateStatus = true
        hs.alert.closeAll()
        hs.alert.show("☕ Caffeinate ON")
        print("☕ FileZilla launched → Caffeinate ON")
    elseif eventType == hs.application.watcher.terminated then
        hs.caffeinate.set("displayIdle", false)
        caffeinateStatus = false
        hs.alert.closeAll()
        hs.alert.show("💤 Caffeinate OFF")
        print("☕ FileZilla closed → Caffeinate OFF")
    end
end

--- Starts the FileZilla watcher and sets caffeinate if FileZilla is already running.
function M.start()
    watcher = hs.application.watcher.new(appEvent)
    watcher:start()
    -- If FileZilla is already running at startup, enable caffeinate
    hs.timer.doAfter(1, function()
        local app = hs.application.find("FileZilla")
        if app and app:isRunning() then
            hs.caffeinate.set("displayIdle", true)
            caffeinateStatus = true
            hs.alert.closeAll()
            hs.alert.show("☕ Caffeinate ON (startup)")
            print("☕ FileZilla already running → Caffeinate ON")
        end
    end)
    print("📦 FileZilla watcher started")
end

--- Stops the FileZilla watcher.
function M.stop()
    if watcher then
        watcher:stop()
        watcher = nil
    end
end

return M
