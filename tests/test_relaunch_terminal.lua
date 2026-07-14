-- luacheck: globals hs busted describe it assert before_each
-- luacheck: ignore busted

-- Unit tests for modules/relaunch_terminal.lua
-- These tests verify the public interface and internal guards without
-- triggering real keyboard events.

_G.hs = _G.hs or {}

-- ──────────────────────────────────────────────────────────────────────────────
-- Minimal hs stubs required by the module
-- ──────────────────────────────────────────────────────────────────────────────

hs.hotkey = hs.hotkey or {
    bind = function() end
}

hs.alert = hs.alert or {
    show = function() end
}

hs.timer = hs.timer or {
    doAfter = function(_, fn) if fn then fn() end end
}

hs.eventtap = hs.eventtap or {
    keyStroke = function() end,
    keyStrokes = function() end
}

hs.application = hs.application or {
    find = function() return nil end
}

-- ──────────────────────────────────────────────────────────────────────────────
-- Load the module under test
-- ──────────────────────────────────────────────────────────────────────────────

local relaunch_terminal = require('../modules/relaunch_terminal')

-- ──────────────────────────────────────────────────────────────────────────────
-- Tests
-- ──────────────────────────────────────────────────────────────────────────────

local busted = require('busted')

describe("relaunch_terminal", function()

    it("should export a table", function()
        assert.is_table(relaunch_terminal)
    end)

    it("should expose a bindHotkey function", function()
        assert.is_function(relaunch_terminal.bindHotkey)
    end)

    describe("bindHotkey", function()
        it("should call hs.hotkey.bind without error", function()
            local called = false
            hs.hotkey.bind = function(mods, key, _fn)
                called = true
                assert.same({"alt"}, mods)
                assert.equals("f", key)
            end
            relaunch_terminal.bindHotkey()
            assert.is_true(called)
        end)
    end)

    describe("relaunchTerminal (via hotkey callback)", function()
        it("should show an alert when VS Code is not running", function()
            local alertMsg = nil
            hs.alert.show = function(msg) alertMsg = msg end
            hs.application.find = function() return nil end

            -- Capture the hotkey callback and invoke it directly
            local capturedFn = nil
            hs.hotkey.bind = function(_mods, _key, fn) capturedFn = fn end
            relaunch_terminal.bindHotkey()

            assert.is_function(capturedFn)
            capturedFn()
            assert.is_not_nil(alertMsg)
            assert.truthy(alertMsg:find("não encontrado") or alertMsg:find("VS Code"))
        end)

        it("should activate VS Code and run the relaunch command via the Command Palette when found", function()
            local activated = false
            local fakeApp = {
                activate = function() activated = true end,
            }
            hs.application.find = function() return fakeApp end

            local strokes = {}
            hs.eventtap.keyStroke = function(mods, key)
                table.insert(strokes, {mods = mods, key = key})
            end
            local typedText = nil
            hs.eventtap.keyStrokes = function(text)
                typedText = text
            end

            local capturedFn = nil
            hs.hotkey.bind = function(_mods, _key, fn) capturedFn = fn end
            relaunch_terminal.bindHotkey()

            capturedFn()
            assert.is_true(activated)
            assert.same({"cmd", "shift"}, strokes[1].mods)
            assert.equals("p", strokes[1].key)
            assert.equals("Relaunch Active Terminal", typedText)
            assert.same({}, strokes[2].mods)
            assert.equals("return", strokes[2].key)
        end)
    end)

end)
