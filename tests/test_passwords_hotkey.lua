-- luacheck: globals hs busted describe it assert before_each
-- luacheck: ignore busted
_G.hs = _G.hs or {}
hs.hotkey = hs.hotkey or {}
hs.application = hs.application or {}

local busted = require('busted')
local passwords_hotkey = require('../modules/passwords_hotkey')

local function mockNav()
    local noop = function() end
    hs.timer = { doEvery = function() return { stop = noop } end }
    hs.eventtap = { new = function() return { start = noop, stop = noop } end, event = { types = {} } }
    hs.keycodes = { map = {} }
    hs.canvas = { windowLevels = {}, new = function()
        return setmetatable({ level = noop, delete = noop, hide = noop }, { __newindex = noop })
    end }
end

describe("passwords_hotkey", function()
    before_each(mockNav)

    it("binds Alt+P and the Ctrl+Alt+P Secure Input fallback", function()
        local bound = {}
        hs.hotkey.bind = function(m, k) bound[#bound + 1] = { m, k } end
        passwords_hotkey.bindHotkey()
        assert.are.same({ { {"alt"}, "P" }, { {"ctrl", "alt"}, "P" } }, bound)
    end)

    it("clicks the center of the menu bar item and restores the mouse", function()
        local clicked, restored
        local item = { attributeValue = function() return { x = 100, y = -10, w = 40, h = 20 } end }
        hs.eventtap.leftClick = function(p) clicked = p end
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
        hs.timer = { doAfter = function() end, doEvery = function() return { stop = function() end } end }
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
        hs.timer = { doAfter = function(_, fn) timers[#timers + 1] = fn; return {} end,
            doEvery = function() return { stop = function() end } end }
        hs.eventtap.leftClick = function() clicks = clicks + 1 end
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

    it("steps the row index clamped to the list bounds", function()
        assert.are.equal(1, passwords_hotkey.step(0, 1, 5))
        assert.are.equal(3, passwords_hotkey.step(2, 1, 5))
        assert.are.equal(5, passwords_hotkey.step(5, 1, 5))
        assert.are.equal(1, passwords_hotkey.step(1, -1, 5))
    end)

    describe("arrow navigation", function()
        local ph, tick, started, stopped, state

        before_each(function()
            package.loaded["../modules/passwords_hotkey"] = nil
            ph = require('../modules/passwords_hotkey')
            started, stopped, state = 0, 0, { windows = {} }
            local frame = function() return { x = 0, y = 0, w = 10, h = 10 } end
            local item = { attributeValue = frame }
            local bar = { attributeValue = function() return { item } end }
            local win = { attributeValue = function(_, k)
                if k == "AXFrame" then return { x = 0, y = 0, w = 100, h = 100 } end
                return {}
            end }
            hs.application.get = function() return {} end
            hs.axuielement = { applicationElement = function()
                return { attributeValue = function(_, k)
                    if k == "AXWindows" then return state.windows end
                    return bar
                end }
            end }
            hs.eventtap = {
                new = function() return { start = function() started = started + 1 end,
                                          stop = function() stopped = stopped + 1 end } end,
                leftClick = function() end, event = { types = {} } }
            hs.mouse = { absolutePosition = function() return { x = 0, y = 0 } end }
            hs.timer = { doEvery = function(_, fn) tick = fn; return { stop = function() end } end }
            state.win = win
        end)

        it("ignores keys when navigation is not active", function()
            assert.is_false(ph.onKey("down", false))
        end)

        it("keeps the keys free until the popover window shows up", function()
            ph.open()
            tick()
            assert.are.equal(0, started)
            assert.is_false(ph.onKey("return", false))
            state.windows = { state.win }
            tick()
            assert.are.equal(1, started)
        end)

        it("passes keys through when the popover has no rows and stays active", function()
            ph.open()
            state.windows = { state.win }
            tick()
            assert.is_false(ph.onKey("down", false))
            assert.is_false(ph.onKey("return", false))
            assert.is_false(ph.onKey("left", false))
            tick()
            assert.are.equal(0, stopped)
        end)

        it("never consumes keys with modifiers", function()
            ph.open()
            state.windows = { state.win }
            tick()
            assert.is_false(ph.onKey("down", true))
        end)

        it("stops once the popover window is gone", function()
            ph.open()
            state.windows = { state.win }
            tick()
            state.windows = {}
            tick()
            assert.are.equal(1, stopped)
        end)
    end)
end)
