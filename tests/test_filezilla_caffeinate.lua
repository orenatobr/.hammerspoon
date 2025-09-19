-- Unit tests for filezilla_caffeinate.lua
local busted = require('busted')
local filezilla_caffeinate = require('../modules/filezilla_caffeinate')

describe("filezilla_caffeinate", function()
    it("should export a table", function()
        assert.is_table(filezilla_caffeinate)
    end)
    -- Add more unit tests for functions in filezilla_caffeinate here
end)
