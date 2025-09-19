
-- luacheck: globals hs busted describe it assert
-- luacheck: ignore busted
_G.hs = _G.hs or {}
hs.window = hs.window or {}
hs.application = hs.application or {}
hs.hotkey = hs.hotkey or {}
hs.timer = hs.timer or {}

-- Unit tests for tab_navigation.lua
local busted = require('busted')
local tab_navigation = require('../modules/tab_navigation')

describe("tab_navigation", function()
    it("should export a table", function()
        assert.is_table(tab_navigation)
    end)
    -- Add more unit tests for functions in tab_navigation here
end)
