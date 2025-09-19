-- Mock Hammerspoon global for CI
_G.hs = _G.hs or {}
hs.window = hs.window or {}
hs.application = hs.application or {}
hs.hotkey = hs.hotkey or {}
hs.timer = hs.timer or {}

-- Unit tests for app_navigation.lua
local busted = require('busted')
local app_navigation = require('../modules/app_navigation')

describe("app_navigation", function()
    it("should export a table", function()
        assert.is_table(app_navigation)
    end)
    -- Add more unit tests for functions in app_navigation here
end)
