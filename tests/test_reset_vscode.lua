-- luacheck: globals hs busted describe it assert before_each
-- luacheck: ignore busted

-- Unit tests for modules/reset_vscode.lua
-- These tests verify the public interface and internal guards without
-- triggering real accessibility or keyboard events.

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

hs.mouse = hs.mouse or {
    absolutePosition = function() end
}

hs.eventtap = hs.eventtap or {
    keyStroke  = function() end,
    keyStrokes = function() end,
    event = {
        types = {
            leftMouseDown    = 1,
            leftMouseDragged = 6,
            leftMouseUp      = 2,
        },
        newMouseEvent = function()
            return {post = function() end}
        end
    }
}

hs.application = hs.application or {
    find = function() return nil end
}

hs.axuielement = hs.axuielement or {
    windowElement = function() return nil end
}

-- ──────────────────────────────────────────────────────────────────────────────
-- Load the module under test
-- ──────────────────────────────────────────────────────────────────────────────

local reset_vscode = require('../modules/reset_vscode')

-- ──────────────────────────────────────────────────────────────────────────────
-- Tests
-- ──────────────────────────────────────────────────────────────────────────────

local busted = require('busted')

describe("reset_vscode", function()

    it("should export a table", function()
        assert.is_table(reset_vscode)
    end)

    it("should expose a bindHotkey function", function()
        assert.is_function(reset_vscode.bindHotkey)
    end)

    describe("bindHotkey", function()
        it("should call hs.hotkey.bind without error", function()
            local called = false
            hs.hotkey.bind = function(mods, key, _fn)
                called = true
                assert.same({"alt"}, mods)
                assert.equals("v", key)
            end
            reset_vscode.bindHotkey()
            assert.is_true(called)
        end)
    end)

    describe("resetVSCode (via hotkey callback)", function()
        it("should show an alert when VS Code is not running", function()
            local alertMsg = nil
            hs.alert.show = function(msg) alertMsg = msg end
            hs.application.find = function() return nil end

            -- Capture the hotkey callback and invoke it directly
            local capturedFn = nil
            hs.hotkey.bind = function(_mods, _key, fn) capturedFn = fn end
            reset_vscode.bindHotkey()

            assert.is_function(capturedFn)
            capturedFn()
            assert.is_not_nil(alertMsg)
            assert.truthy(alertMsg:find("não encontrado") or alertMsg:find("VS Code"))
        end)

        it("should activate the app when VS Code is found", function()
            local activated = false
            local fakeApp = {
                activate   = function() activated = true end,
                focusedWindow = function() return nil end,
                allWindows    = function() return {} end,
            }
            hs.application.find = function() return fakeApp end

            local capturedFn = nil
            hs.hotkey.bind = function(_mods, _key, fn) capturedFn = fn end
            reset_vscode.bindHotkey()

            capturedFn()
            assert.is_true(activated)
        end)
    end)

end)
