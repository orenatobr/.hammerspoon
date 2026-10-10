-- luacheck: globals hs busted describe it assert
-- luacheck: ignore busted
_G.hs = _G.hs or {}
hs.hotkey = hs.hotkey or {}

local busted = require('busted')
local passwords_hotkey = require('../modules/passwords_hotkey')

describe("passwords_hotkey", function()
    it("binds Alt+P", function()
        local mods, key
        hs.hotkey.bind = function(m, k) mods, key = m, k end
        passwords_hotkey.bindHotkey()
        assert.are.same({"alt"}, mods)
        assert.are.equal("P", key)
    end)

    it("clicks the center of the menu bar item and restores the mouse", function()
        local clicked, restored
        local item = { attributeValue = function() return { x = 100, y = -10, w = 40, h = 20 } end }
        hs.eventtap = { leftClick = function(p) clicked = p end }
        hs.mouse = { absolutePosition = function(p) if p then restored = p else return { x = 1, y = 2 } end end }
        local bar = { attributeValue = function() return { item } end }
        hs.application.get = function() return {} end
        hs.axuielement = { applicationElement = function() return { attributeValue = function() return bar end } end }
        assert.is_true(passwords_hotkey.open())
        assert.are.same({ x = 120, y = 0 }, clicked)
        assert.are.same({ x = 1, y = 2 }, restored)
    end)
end)
