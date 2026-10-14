-- luacheck: globals hs busted describe it assert before_each
-- luacheck: ignore busted
_G.hs = _G.hs or {}
hs.hotkey = hs.hotkey or {}
hs.window = hs.window or {}
hs.spaces = hs.spaces or {}
hs.mouse = hs.mouse or {}
hs.timer = hs.timer or {}
hs.eventtap = hs.eventtap or {}
hs.alert = hs.alert or {}
hs.eventtap.event = hs.eventtap.event or {}

local busted = require('busted')
local move_window_space = require('../modules/move_window_space')

describe("move_window_space", function()
    local binds, log, win, alerts

    local function press(key)
        move_window_space.bindHotkey()
        binds[key].fn()
    end

    local function bindsFor(mods)
        local out = {}
        local orig = hs.hotkey.bind
        hs.hotkey.bind = function(m, key, fn)
            if table.concat(m, "+") == mods then out[key] = fn end
        end
        move_window_space.bindHotkey()
        hs.hotkey.bind = orig
        return out
    end

    before_each(function()
        binds, log, alerts = {}, {}, {}
        win = {
            screen = function() return "scr" end,
            title = function() return "w" end,
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
        hs.alert.show = function(msg) table.insert(alerts, msg) end
        hs.eventtap.checkKeyboardModifiers = function() return {} end
        hs.eventtap.keyStroke = function(mods, key) table.insert(log, {mods = mods, key = key}) end
    end)

    it("binds alt+arrows and the ctrl+alt fallback", function()
        assert.is_function(bindsFor("alt").right)
        assert.is_function(bindsFor("alt").left)
        assert.is_function(bindsFor("ctrl+alt").right)
        assert.is_function(bindsFor("ctrl+alt").left)
    end)

    it("moves the window from the ctrl+alt fallback too", function()
        bindsFor("ctrl+alt").right()
        assert.equals("right", log[4].key)
    end)

    it("alerts when the window stays on the same Space", function()
        press("right")
        assert.equals(1, #alerts)
    end)

    it("does not alert when the window changed Space", function()
        local calls = 0
        hs.spaces.windowSpaces = function()
            calls = calls + 1
            return {calls == 1 and 20 or 30}
        end
        press("right")
        assert.equals(0, #alerts)
    end)

    it("moves anyway when Option never reads as released", function()
        hs.eventtap.checkKeyboardModifiers = function() return {alt = true} end
        press("right")
        assert.equals("down", log[2])
    end)

    it("waits for Ctrl to be released too", function()
        local held = 2
        hs.eventtap.checkKeyboardModifiers = function()
            held = held - 1
            return held > 0 and {ctrl = true} or {}
        end
        press("right")
        assert.equals("down", log[2])
    end)

    it("holds the title bar and sends ctrl+fn+right", function()
        press("right")
        assert.same({"mouse", "down", "drag", {mods = {"ctrl", "fn"}, key = "right"}, "up", "mouse"}, log)
    end)

    it("sends ctrl+fn+left for alt+left", function()
        press("left")
        assert.equals("left", log[4].key)
    end)

    it("waits for Option to be released before grabbing the window", function()
        local held = 2
        hs.eventtap.checkKeyboardModifiers = function()
            held = held - 1
            return held > 0 and {alt = true} or {}
        end
        press("right")
        assert.equals("down", log[2])
        assert.equals("right", log[4].key)
    end)

    it("does nothing but alert at the edge", function()
        hs.spaces.windowSpaces = function() return {30} end
        press("right")
        assert.same({}, log)
        assert.equals(1, #alerts)
    end)

    it("does nothing for fullscreen windows", function()
        win.isFullScreen = function() return true end
        press("right")
        assert.same({}, log)
        assert.equals(1, #alerts)
    end)

    it("does nothing without a focused window", function()
        hs.window.focusedWindow = function() return nil end
        press("right")
        assert.same({}, log)
    end)
end)
