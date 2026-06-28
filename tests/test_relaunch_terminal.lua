-- luacheck: globals hs busted describe it assert before_each
-- luacheck: ignore busted

-- Unit tests for modules/relaunch_terminal.lua
-- Verifies the public interface and the VS Code command-palette flow without
-- triggering real keyboard events or application focus changes.

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
    keyStroke  = function() end,
    keyStrokes = function() end,
}

hs.application = hs.application or {
    find = function() return nil end
}

-- ──────────────────────────────────────────────────────────────────────────────
-- Tests
-- ──────────────────────────────────────────────────────────────────────────────

describe("relaunch_terminal", function()
    local capturedFn
    local alertShown
    local activated
    local keyStrokeCalls
    local keyStrokesCalls

    before_each(function()
        capturedFn      = nil
        alertShown      = nil
        activated       = false
        keyStrokeCalls  = {}
        keyStrokesCalls = {}

        _G.hs.hotkey.bind = function(_, _, fn) capturedFn = fn end
        _G.hs.alert.show  = function(msg) alertShown = msg end
        _G.hs.timer.doAfter = function(_, fn) if fn then fn() end end
        _G.hs.eventtap.keyStroke  = function(mods, key)
            table.insert(keyStrokeCalls, {mods = mods, key = key})
        end
        _G.hs.eventtap.keyStrokes = function(text)
            table.insert(keyStrokesCalls, text)
        end
        _G.hs.application.find = function() return nil end

        package.loaded["modules.relaunch_terminal"] = nil
    end)

    it("returns a module table", function()
        local m = require("modules.relaunch_terminal")
        assert.is_table(m)
    end)

    it("exposes bindHotkey as a function", function()
        local m = require("modules.relaunch_terminal")
        assert.is_function(m.bindHotkey)
    end)

    it("shows alert when VS Code is not running", function()
        local m = require("modules.relaunch_terminal")
        m.bindHotkey()
        assert.is_function(capturedFn)
        capturedFn()
        assert.is_not_nil(alertShown)
        assert.truthy(alertShown:find("VS Code"))
    end)

    it("does not send keystrokes when VS Code is not running", function()
        local m = require("modules.relaunch_terminal")
        m.bindHotkey()
        capturedFn()
        assert.equals(0, #keyStrokeCalls)
        assert.equals(0, #keyStrokesCalls)
    end)

    it("activates VS Code when found", function()
        _G.hs.application.find = function() return {activate = function() activated = true end} end
        local m = require("modules.relaunch_terminal")
        m.bindHotkey()
        capturedFn()
        assert.is_true(activated)
    end)

    it("opens the command palette with Cmd+Shift+P when VS Code is found", function()
        _G.hs.application.find = function() return {activate = function() end} end
        local m = require("modules.relaunch_terminal")
        m.bindHotkey()
        capturedFn()
        local found = false
        for _, call in ipairs(keyStrokeCalls) do
            if call.key == "p" then
                local hasCmd, hasShift = false, false
                for _, mod in ipairs(call.mods) do
                    if mod == "cmd"   then hasCmd   = true end
                    if mod == "shift" then hasShift = true end
                end
                if hasCmd and hasShift then found = true end
            end
        end
        assert.is_true(found)
    end)

    it("types 'relaunch active terminal' into the command palette", function()
        _G.hs.application.find = function() return {activate = function() end} end
        local m = require("modules.relaunch_terminal")
        m.bindHotkey()
        capturedFn()
        local found = false
        for _, text in ipairs(keyStrokesCalls) do
            if text:find("relaunch active terminal") then found = true end
        end
        assert.is_true(found)
    end)

    it("sends Return to confirm the command", function()
        _G.hs.application.find = function() return {activate = function() end} end
        local m = require("modules.relaunch_terminal")
        m.bindHotkey()
        capturedFn()
        local found = false
        for _, call in ipairs(keyStrokeCalls) do
            if call.key == "return" then found = true end
        end
        assert.is_true(found)
    end)
end)
