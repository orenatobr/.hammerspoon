-- Unit tests for idle_keepalive.lua
local busted = require('busted')
local idle_keepalive = require('../modules/idle_keepalive')

describe("idle_keepalive", function()
    it("should export a table", function()
        assert.is_table(idle_keepalive)
    end)
    -- Add more unit tests for functions in idle_keepalive here
end)
