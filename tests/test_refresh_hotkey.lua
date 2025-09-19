-- Unit tests for refresh_hotkey.lua
local busted = require('busted')
local refresh_hotkey = require('../modules/refresh_hotkey')

describe("refresh_hotkey", function()
    it("should export a table", function()
        assert.is_table(refresh_hotkey)
    end)
    -- Add more unit tests for functions in refresh_hotkey here
end)
