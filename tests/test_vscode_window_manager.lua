
-- luacheck: globals busted describe it assert
-- luacheck: ignore busted
local busted = require('busted')
local vscode_window_manager = require('../modules/vscode_window_manager')

describe("vscode_window_manager", function()
    it("should export a table", function()
        assert.is_table(vscode_window_manager)
    end)
    -- Add more unit tests for functions in vscode_window_manager here
end)
