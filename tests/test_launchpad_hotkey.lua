-- Unit tests for launchpad_hotkey.lua
local busted = require('busted')
local launchpad_hotkey = require('../modules/launchpad_hotkey')

describe("launchpad_hotkey", function()
    it("should export a table", function()
        assert.is_table(launchpad_hotkey)
    end)
    -- Add more unit tests for functions in launchpad_hotkey here
end)
