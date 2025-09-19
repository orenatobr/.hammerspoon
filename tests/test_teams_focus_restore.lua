-- Unit tests for teams_focus_restore.lua
local busted = require('busted')
local teams_focus_restore = require('../modules/teams_focus_restore')

describe("teams_focus_restore", function()
    it("should export a table", function()
        assert.is_table(teams_focus_restore)
    end)
    -- Add more unit tests for functions in teams_focus_restore here
end)
