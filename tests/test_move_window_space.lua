-- luacheck: globals hs busted describe it assert before_each
-- luacheck: ignore busted
_G.hs = _G.hs or {}
hs.hotkey = hs.hotkey or {}
hs.window = hs.window or {}
hs.spaces = hs.spaces or {}
hs.alert = hs.alert or {}

local busted = require('busted')
local move_window_space = require('../modules/move_window_space')

describe("move_window_space", function()
    local binds, moved, went, alerts, win

    before_each(function()
        binds, moved, went, alerts = {}, nil, nil, {}
        win = {
            focus = function() end,
            screen = function() return "scr" end,
            id = function() return 1 end
        }
        hs.hotkey.bind = function(mods, key, fn) binds[key] = {mods = mods, fn = fn} end
        hs.alert.show = function(msg) table.insert(alerts, msg) end
        hs.window.focusedWindow = function() return win end
        hs.spaces.spacesForScreen = function() return {10, 20, 30} end
        hs.spaces.windowSpaces = function() return {20} end
        hs.spaces.moveWindowToSpace = function(_, id) moved = id return true end
        hs.spaces.gotoSpace = function(id) went = id return true end
    end)

    it("binds alt+right and alt+left", function()
        move_window_space.bindHotkey()
        assert.same({"alt"}, binds["right"].mods)
        assert.same({"alt"}, binds["left"].mods)
    end)

    it("moves the window to the next space and follows it", function()
        move_window_space.bindHotkey()
        binds["right"].fn()
        assert.equals(30, moved)
        assert.equals(30, went)
    end)

    it("moves the window to the previous space", function()
        move_window_space.bindHotkey()
        binds["left"].fn()
        assert.equals(10, moved)
    end)

    it("does nothing at the edge", function()
        hs.spaces.windowSpaces = function() return {30} end
        move_window_space.bindHotkey()
        binds["right"].fn()
        assert.is_nil(moved)
    end)

    it("does nothing without a focused window", function()
        hs.window.focusedWindow = function() return nil end
        move_window_space.bindHotkey()
        binds["right"].fn()
        assert.is_nil(moved)
    end)
end)
