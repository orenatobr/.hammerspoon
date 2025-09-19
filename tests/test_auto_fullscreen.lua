-- Mock Hammerspoon global for CI
_G.hs = _G.hs or {}
hs.window = hs.window or {}
hs.application = hs.application or {}
hs.timer = hs.timer or {}

-- Unit tests for auto_fullscreen.lua
local busted = require('busted')
local auto_fullscreen = require('../modules/auto_fullscreen')

describe("auto_fullscreen", function()
    it("should export a table", function()
        assert.is_table(auto_fullscreen)
    end)
    -- Add more unit tests for functions in auto_fullscreen here
end)
