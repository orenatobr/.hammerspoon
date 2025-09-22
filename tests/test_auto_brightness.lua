
-- luacheck: globals hs busted describe it assert
-- luacheck: ignore busted
_G.hs = _G.hs or {}
hs.window = hs.window or {}
hs.application = hs.application or {}
hs.screen = hs.screen or {}
hs.brightness = hs.brightness or {}
hs.timer = hs.timer or {}
hs.battery = hs.battery or {}
hs.battery.currentCapacity = hs.battery.currentCapacity or function() return 100 end
hs.battery.isCharging = hs.battery.isCharging or function() return true end
hs.battery.powerSource = hs.battery.powerSource or function() return "AC Power" end
hs.battery.watcher = {
    new = function(callback)
        _G._battery_callback = callback
        return {
            start = function() _G._battery_watcher_started = true end,
            stop = function() _G._battery_watcher_stopped = true end
        }
    end
}

local busted = require('busted')
local before_each = require('busted').before_each

local function reload_auto_brightness()
    package.loaded['../modules/auto_brightness'] = nil
    return require('../modules/auto_brightness')
end

describe("auto_brightness", function()
    it("should export a table", function()
        local auto_brightness = reload_auto_brightness()
        assert.is_table(auto_brightness)
    end)

    before_each(function()
        _G._battery_watcher_started = false
        _G._battery_watcher_stopped = false
        _G._last_alert = nil
        _G._brightness_set = nil
        hs.alert = { show = function(msg) _G._last_alert = msg end }
        hs.brightness = { set = function(val) _G._brightness_set = val end }
    end)

    it("should start the watcher and set started flag", function()
        local auto_brightness = reload_auto_brightness()
        auto_brightness.start()
        assert.is_true(_G._battery_watcher_started)
    end)

    it("should stop the watcher and set stopped flag", function()
        local auto_brightness = reload_auto_brightness()
        auto_brightness.stop()
        assert.is_true(_G._battery_watcher_stopped)
    end)

    it("should handle power source change to battery", function()
        hs.alert = { show = function(msg) _G._last_alert = msg end }
        hs.brightness = { set = function(val) _G._brightness_set = val end }
        hs.battery = hs.battery or {}
        hs.battery.powerSource = function() return "Battery Power" end
        local auto_brightness = reload_auto_brightness()
        auto_brightness.lastPowerSource = "AC Power"
        -- Confirm state before handler
        assert.equals("AC Power", auto_brightness.lastPowerSource)
        assert.equals("Battery Power", hs.battery.powerSource())
        auto_brightness._test_handlePowerEvent()
        assert.equals("🔌 Power: Battery Power", _G._last_alert)
        assert.equals(50, _G._brightness_set)
    end)

    it("should handle power source change to AC Power", function()
        hs.alert = { show = function(msg) _G._last_alert = msg end }
        hs.brightness = { set = function(val) _G._brightness_set = val end }
        hs.battery = hs.battery or {}
        hs.battery.powerSource = function() return "AC Power" end
        local auto_brightness = reload_auto_brightness()
        auto_brightness.lastPowerSource = "Battery Power"
        auto_brightness._test_handlePowerEvent()
        assert.equals("🔌 Power: AC Power", _G._last_alert)
        assert.equals(100, _G._brightness_set)
    end)

    it("should not alert or set brightness if power source unchanged", function()
        hs.alert = { show = function(msg) _G._last_alert = msg end }
        hs.brightness = { set = function(val) _G._brightness_set = val end }
        hs.battery = hs.battery or {}
        hs.battery.powerSource = function() return "AC Power" end
        local auto_brightness = reload_auto_brightness()
        auto_brightness.lastPowerSource = "AC Power"
        _G._last_alert = nil
        _G._brightness_set = nil
        auto_brightness._test_handlePowerEvent()
        assert.is_nil(_G._last_alert)
        assert.is_nil(_G._brightness_set)
    end)
end)
