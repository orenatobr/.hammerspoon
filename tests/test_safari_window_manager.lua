-- Unit tests for safari_window_manager.lua
local busted = require('busted')
local safari_window_manager = require('../modules/safari_window_manager')

describe("safari_window_manager", function()
    it("should export a table", function()
        assert.is_table(safari_window_manager)
    end)
    -- Add more unit tests for functions in safari_window_manager here
end)
