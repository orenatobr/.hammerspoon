-- luacheck: globals hs busted describe it assert
-- luacheck: ignore busted
_G.hs = _G.hs or {}
hs.hotkey = hs.hotkey or {}
hs.application = hs.application or {}

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

    it("launches the menu bar extra via argv, not a shell string", function()
        local exe, args
        hs.alert = { show = function() end }
        hs.application.get = function() return nil end
        hs.timer = { doAfter = function() end }
        hs.task = { new = function(e, _, a) exe, args = e, a; return { start = function() end } end }
        passwords_hotkey.open()
        assert.are.equal("/usr/bin/open", exe)
        assert.are.equal("-g", args[1])
    end)

    it("launches once, ignores presses while pending, and clicks when the item appears", function()
        package.loaded["../modules/passwords_hotkey"] = nil
        local ph = require('../modules/passwords_hotkey')
        local launches, clicks, timers, ready = 0, 0, {}, false
        local item = { attributeValue = function() return { x = 0, y = 0, w = 10, h = 10 } end }
        local bar = { attributeValue = function() return { item } end }
        hs.application.get = function() return ready and {} or nil end
        hs.axuielement = { applicationElement = function() return { attributeValue = function() return bar end } end }
        hs.task = { new = function() launches = launches + 1; return { start = function() end } end }
        hs.timer = { doAfter = function(_, fn) timers[#timers + 1] = fn; return {} end }
        hs.eventtap = { leftClick = function() clicks = clicks + 1 end }
        hs.mouse = { absolutePosition = function() return { x = 0, y = 0 } end }

        assert.is_false(ph.open())
        assert.is_false(ph.open())
        assert.are.equal(1, launches)
        assert.are.equal(1, #timers)

        timers[1]()
        assert.are.equal(2, #timers)
        assert.are.equal(1, launches)

        ready = true
        timers[2]()
        assert.are.equal(1, clicks)
        assert.is_true(ph.open())
        assert.are.equal(2, clicks)
    end)
end)
