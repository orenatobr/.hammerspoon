-- Mock Hammerspoon global for CI
_G.hs = _G.hs or {}
hs.window = hs.window or {}
hs.application = hs.application or {}
hs.screen = hs.screen or {}
hs.brightness = hs.brightness or {}
hs.timer = hs.timer or {}

-- Unit tests for auto_brightness.lua
local busted = require('busted')
local auto_brightness = require('../modules/auto_brightness')

describe("auto_brightness", function()
    it("should export a table", function()
        assert.is_table(auto_brightness)
    end)
    -- Add more unit tests for functions in auto_brightness here
end)
