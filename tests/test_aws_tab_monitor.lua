-- Unit tests for aws_tab_monitor.lua
local busted = require('busted')
local aws_tab_monitor = require('../modules/aws_tab_monitor')

describe("aws_tab_monitor", function()
    it("should export a table", function()
        assert.is_table(aws_tab_monitor)
    end)
    -- Add more unit tests for functions in aws_tab_monitor here
end)
