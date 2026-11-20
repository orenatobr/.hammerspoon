-- luacheck: globals busted describe it assert
-- luacheck: ignore busted
require('tests.test_hs_mock')
local busted = require('busted')
local app_navigation = require('../modules/app_navigation')
local window_cycle = require('../modules/window_cycle')

describe("Integration: app_navigation and window_cycle", function()
    it("should both export tables", function()
        assert.is_table(app_navigation)
        assert.is_table(window_cycle)
    end)
    -- Add more integration tests for module interactions here
end)
