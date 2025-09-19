-- Unit tests for auto_lock.lua
local busted = require('busted')
local auto_lock = require('../modules/auto_lock')

describe("auto_lock", function()
    it("should export a table", function()
        assert.is_table(auto_lock)
    end)
    -- Add more unit tests for functions in auto_lock here
end)
