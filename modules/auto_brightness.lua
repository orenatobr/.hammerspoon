
-- ~/.hammerspoon/modules/auto_brightness.lua
-- Module: auto_brightness
-- Purpose: Automatically adjust screen brightness based on power source (AC/battery).
-- Usage: require this module and call M.start() to enable auto brightness adjustment.
-- Author: [Your Name]
-- Last updated: 2025-09-19

local M = {}

local lastPowerSource = hs.battery.powerSource()

--- Handles power source change events and adjusts brightness accordingly.
local function handlePowerEvent()
    local source = hs.battery.powerSource()
    if source ~= lastPowerSource then
        hs.alert.show("🔌 Power: " .. source)
        hs.brightness.set(source == "AC Power" and 100 or 50)
        lastPowerSource = source
    end
    print("🔋 Power check → " .. source)
end

--- Battery watcher instance (created once)
M.watcher = hs.battery.watcher.new(handlePowerEvent)

--- Starts the battery watcher for auto brightness.
function M.start()
    M.watcher:start()
    print("⚡ Power watcher started")
end

--- Stops the battery watcher.
function M.stop()
    M.watcher:stop()
    print("🛑 Power watcher stopped")
end

return M
