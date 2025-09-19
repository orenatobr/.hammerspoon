
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
hs.battery.watcher = hs.battery.watcher or {
    new = function() return { start = function() end, stop = function() end } end
}

-- Unit tests for auto_brightness.lua
local busted = require('busted')
local auto_brightness = require('../modules/auto_brightness')

describe("auto_brightness", function()
    it("should export a table", function()
        assert.is_table(auto_brightness)
    end)
    -- Add more unit tests for functions in auto_brightness here
end)
