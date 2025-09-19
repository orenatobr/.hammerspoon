-- Unit tests for window_cycle.lua
local busted = require('busted')
local window_cycle = require('../modules/window_cycle')

describe("window_cycle", function()
    it("should export a table", function()
        assert.is_table(window_cycle)
    end)
    -- Add more unit tests for functions in window_cycle here
end)
