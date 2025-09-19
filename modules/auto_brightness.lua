-- luacheck: globals hs
-- luacheck: max line length 120

-- ~/.hammerspoon/modules/auto_brightness.lua
-- Module: auto_brightness
-- Purpose: Automatically adjust screen brightness based on power source (AC/battery).
-- Usage: require this module and call M.start() to enable auto brightness adjustment.
-- Author: [Your Name]
-- Last updated: 2025-09-19

-- Mock hs for test/CI environments
if hs == nil then
    hs = {}
    hs.battery = {
        powerSource = function() return _G._mock_power_source or "AC Power" end,
        watcher = {
            new = function(callback)
                _G._battery_callback = callback
                return {
                    start = function() _G._battery_watcher_started = true end,
                    stop = function() _G._battery_watcher_stopped = true end
                }
            end
        }
    }
    hs.alert = { show = function(msg) _G._last_alert = msg end }
    hs.brightness = { set = function(val) _G._brightness_set = val end }
end

local M = {}

M.lastPowerSource = hs.battery.powerSource()


--- Handles power source change events and adjusts brightness accordingly.
-- luacheck: ignore source
local function handlePowerEvent()
    local source = hs.battery.powerSource()
    if source ~= M.lastPowerSource then
        hs.alert.show("🔌 Power: " .. source)
        hs.brightness.set(source == "AC Power" and 100 or 50)
        M.lastPowerSource = source
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
