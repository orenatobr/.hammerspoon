-- Unit tests for auto_fullscreen.lua
local busted = require('busted')
local auto_fullscreen = require('../modules/auto_fullscreen')

describe("auto_fullscreen", function()
    it("should export a table", function()
        assert.is_table(auto_fullscreen)
    end)
    -- Add more unit tests for functions in auto_fullscreen here
end)
