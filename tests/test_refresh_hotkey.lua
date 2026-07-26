
-- luacheck: globals hs busted describe it assert before_each
-- luacheck: ignore busted
_G.hs = _G.hs or {}
hs.hotkey = hs.hotkey or {}
hs.application = hs.application or {}
hs.eventtap = hs.eventtap or {}
hs.timer = hs.timer or {}
hs.osascript = hs.osascript or {}

-- Unit tests for refresh_hotkey.lua
local busted = require('busted')
local refresh_hotkey = require('../modules/refresh_hotkey')

describe("refresh_hotkey", function()
    it("should export a table", function()
        assert.is_table(refresh_hotkey)
    end)

    it("should expose bindHotkey function", function()
        assert.is_function(refresh_hotkey.bindHotkey)
    end)

    describe("bindHotkey", function()
        local capturedFn
        local strokes
        local scriptRun
        local frontAppName

        before_each(function()
            capturedFn = nil
            strokes = {}
            scriptRun = nil
            frontAppName = "Safari"

            hs.hotkey.bind = function(_mods, _key, fn)
                capturedFn = fn
            end
            hs.eventtap.keyStroke = function(mods, key)
                table.insert(strokes, {mods = mods, key = key})
            end
            hs.timer.doAfter = function(_, fn)
                if fn then fn() end
            end
            hs.application.frontmostApplication = function()
                if not frontAppName then return nil end
                return {name = function() return frontAppName end}
            end
            hs.osascript.applescript = function(script)
                scriptRun = script
                return true, nil, nil
            end

            refresh_hotkey.bindHotkey()
        end)

        it("should bind Alt+R", function()
            local called = false
            hs.hotkey.bind = function(mods, key, _fn)
                called = true
                assert.same({"alt"}, mods)
                assert.equals("R", key)
            end
            refresh_hotkey.bindHotkey()
            assert.is_true(called)
        end)

        it("should clear storage via AppleScript when Safari is frontmost", function()
            capturedFn()
            assert.is_not_nil(scriptRun)
            assert.matches('tell application "Safari"', scriptRun, 1, true)
            assert.matches('do JavaScript', scriptRun, 1, true)
        end)

        it("should erase cookies across host/parent-domain and path variants", function()
            -- Regression test: a bare `path=/` re-set without `domain` is a
            -- no-op for cookies set with e.g. `domain=.example.com`, so the
            -- JS must retry across domain and path combinations.
            capturedFn()
            assert.matches("doms%.forEach", scriptRun)
            assert.matches("paths%.forEach", scriptRun)
            assert.matches("domain=", scriptRun, 1, true)
        end)

        it("should clear storage via AppleScript when Chrome is frontmost", function()
            frontAppName = "Google Chrome"
            capturedFn()
            assert.is_not_nil(scriptRun)
            assert.matches('tell application "Google Chrome"', scriptRun, 1, true)
            assert.matches('execute javascript', scriptRun, 1, true)
        end)

        it("should skip storage clearing for unsupported frontmost apps", function()
            frontAppName = "Code"
            capturedFn()
            assert.is_nil(scriptRun)
        end)

        it("should still clear cache and reload for unsupported frontmost apps", function()
            frontAppName = "Code"
            capturedFn()
            assert.same({"alt", "cmd"}, strokes[1].mods)
            assert.equals("E", strokes[1].key)
            assert.same({"cmd"}, strokes[2].mods)
            assert.equals("R", strokes[2].key)
        end)

        it("should not throw and should still reload when AppleScript fails", function()
            hs.osascript.applescript = function(script)
                scriptRun = script
                return false, nil, "not allowed"
            end
            assert.has_no.errors(function()
                capturedFn()
            end)
            assert.same({"alt", "cmd"}, strokes[1].mods)
            assert.same({"cmd"}, strokes[2].mods)
        end)
    end)
end)
