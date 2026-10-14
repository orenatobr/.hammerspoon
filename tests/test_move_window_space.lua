-- luacheck: globals hs busted describe it assert before_each
-- luacheck: ignore busted
_G.hs = _G.hs or {}
hs.hotkey = hs.hotkey or {}
hs.window = hs.window or {}
hs.spaces = hs.spaces or {}
hs.mouse = hs.mouse or {}
hs.timer = hs.timer or {}
hs.eventtap = hs.eventtap or {}
hs.eventtap.event = hs.eventtap.event or {}

local busted = require('busted')
local move_window_space = require('../modules/move_window_space')

describe("move_window_space", function()
    local binds, log, win

    local function press(key)
        move_window_space.bindHotkey()
        binds[key].fn()
    end

    before_each(function()
        binds, log = {}, {}
        win = {
            screen = function() return "scr" end,
            isFullScreen = function() return false end,
            zoomButtonRect = function() return {x = 10, y = 20, w = 16, h = 16} end
        }
        hs.hotkey.bind = function(mods, key, fn) binds[key] = {mods = mods, fn = fn} end
        hs.window.focusedWindow = function() return win end
        hs.spaces.spacesForScreen = function() return {10, 20, 30} end
        hs.spaces.windowSpaces = function() return {20} end
        hs.mouse.absolutePosition = function(p) if p then table.insert(log, "mouse") end return {x = 0, y = 0} end
        hs.timer.doAfter = function(_, fn) fn() end
        hs.eventtap.event.types = {leftMouseDown = "down", leftMouseDragged = "drag", leftMouseUp = "up"}
        hs.eventtap.event.newMouseEvent = function(kind)
            return {post = function() table.insert(log, kind) end}
        end
        hs.eventtap.keyStroke = function(mods, key) table.insert(log, {mods = mods, key = key}) end
    end)

    it("binds alt+right and alt+left", function()
        move_window_space.bindHotkey()
        assert.same({"alt"}, binds["right"].mods)
        assert.same({"alt"}, binds["left"].mods)
    end)

    it("holds the title bar and sends ctrl+fn+right", function()
        press("right")
        assert.same({"mouse", "down", "drag", {mods = {"ctrl", "fn"}, key = "right"}, "up", "mouse"}, log)
    end)

    it("sends ctrl+fn+left for alt+left", function()
        press("left")
        assert.equals("left", log[4].key)
    end)

    it("does nothing at the edge", function()
        hs.spaces.windowSpaces = function() return {30} end
        press("right")
        assert.same({}, log)
    end)

    it("does nothing for fullscreen windows", function()
        win.isFullScreen = function() return true end
        press("right")
        assert.same({}, log)
    end)

    it("does nothing without a focused window", function()
        hs.window.focusedWindow = function() return nil end
        press("right")
        assert.same({}, log)
    end)
end)
