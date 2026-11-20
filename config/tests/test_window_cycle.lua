-- luacheck: globals hs busted describe it assert print
-- luacheck: max_line_length 250
_G.hs = _G.hs or {}
hs.hotkey = hs.hotkey or {
    bind = function(mods, key, fn)
        _G._last_hotkey = {mods = mods, key = key, fn = fn}
    end
}
hs.application = hs.application or {}
hs.application.frontmostApplication = function()
    return _G._mock_app
end
hs.fnutils = hs.fnutils or {
    filter = function(tbl, fn)
        local out = {}
        for _, v in ipairs(tbl) do
            if fn(v) then table.insert(out, v) end
        end
        return out
    end
}

local _ = require('busted')
local window_cycle = require('../modules/window_cycle')

describe("window_cycle", function()
    it("should export a table", function()
        assert.is_table(window_cycle)
    end)

    it("should bind Alt+C hotkey", function()
        _G._last_hotkey = nil
        window_cycle.bindHotkey()
        assert.is_not_nil(_G._last_hotkey)
        assert.same(_G._last_hotkey.mods, {"alt"})
        assert.equal(_G._last_hotkey.key, "C")
    end)

    it("should cycle to next window if multiple windows", function()
        local raised, focused = false, false
        local win1 = {isStandard = function() return true end, isVisible = function() return true end, id = function() return 1 end, raise = function(self) raised = true; return self end, focus = function(self) focused = true; return self end}
        local win2 = {isStandard = function() return true end, isVisible = function() return true end, id = function() return 2 end, raise = function(self) raised = true; return self end, focus = function(self) focused = true; return self end}
        _G._mock_app = {
            allWindows = function() return {win1, win2} end,
            focusedWindow = function() return win1 end
        }
        print = function(_) end
        window_cycle.bindHotkey()
        _G._last_hotkey.fn()
        assert.is_true(raised)
        assert.is_true(focused)
    end)

    it("should cycle to first window if last is focused", function()
        local raised, focused = false, false
        local win1 = {isStandard = function() return true end, isVisible = function() return true end, id = function() return 1 end, raise = function(self) raised = true; return self end, focus = function(self) focused = true; return self end}
        local win2 = {isStandard = function() return true end, isVisible = function() return true end, id = function() return 2 end, raise = function(self) raised = true; return self end, focus = function(self) focused = true; return self end}
        _G._mock_app = {
            allWindows = function() return {win1, win2} end,
            focusedWindow = function() return win2 end
        }
        print = function(_) end
        window_cycle.bindHotkey()
        _G._last_hotkey.fn()
        assert.is_true(raised)
        assert.is_true(focused)
    end)
end)
