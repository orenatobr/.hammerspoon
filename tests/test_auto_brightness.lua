-- Unit tests for auto_brightness.lua
local busted = require('busted')
local auto_brightness = require('../modules/auto_brightness')

describe("auto_brightness", function()
    it("should export a table", function()
        assert.is_table(auto_brightness)
    end)
    -- Add more unit tests for functions in auto_brightness here
end)
