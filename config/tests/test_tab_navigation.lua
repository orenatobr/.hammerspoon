
-- luacheck: globals hs busted describe it assert
-- luacheck: ignore busted
_G.hs = _G.hs or {}
hs.window = hs.window or {}
hs.application = hs.application or {}
hs.hotkey = hs.hotkey or {}
hs.timer = hs.timer or {}

-- Unit tests for tab_navigation.lua
local busted = require('busted')
local tab_navigation = require('../modules/tab_navigation')

describe("tab_navigation", function()
    it("should export a table", function()
        assert.is_table(tab_navigation)
    end)

    it("escapes quotes and backslashes in the URL before building AppleScript", function()
        local scripts, onChoice = {}, nil
        hs.alert = function() end
        hs.hotkey.bind = function(_, _, fn) fn() end
        hs.osascript = { applescript = function(src)
            table.insert(scripts, src)
            return true, 'T|||URL:x" & (do shell script "id") & "\\'
        end }
        hs.chooser = { new = function(cb)
            onChoice = cb
            return { choices = function() end, rows = function() end, width = function() end, show = function() end }
        end }
        tab_navigation.bindHotkey()
        onChoice({ url = 'x" & (do shell script "id") & "\\' })
        assert.is_truthy(scripts[2]:find('set theURL to "x\\" & (do shell script \\"id\\") & \\"\\\\"', 1, true))
    end)
end)
