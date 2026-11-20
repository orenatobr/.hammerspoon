-- luacheck: globals hs busted describe it assert
-- luacheck: ignore busted
_G.hs = _G.hs or {}
hs.application = hs.application or {}
hs.application.runningApplications = hs.application.runningApplications or function()
    return {}
end
hs.timer = hs.timer or {}
hs.timer.doAfter = hs.timer.doAfter or function(_, fn)
    if fn then
        fn()
    end
end
hs.window = hs.window or {}

local capturedHandler = nil
hs.window.filter = hs.window.filter or {
    windowCreated = "windowCreated",
    windowFocused = "windowFocused",
    new = function()
        return {
            setAppFilter = function(self)
                return self
            end,
            subscribe = function(_, _, fn)
                capturedHandler = fn
            end,
            unsubscribeAll = function()
            end
        }
    end
}

local busted = require('busted')
local googleMeetWindowManager = require('../modules/google_meet_window_manager')

local function makeWindow(id, size)
    local win = {closed = false, focused = false}
    win.id = function()
        return id
    end
    win.isStandard = function()
        return true
    end
    win.title = function()
        return "Meet window " .. tostring(id)
    end
    win.size = function()
        return size or {w = 800, h = 600}
    end
    win.close = function()
        win.closed = true
    end
    win.focus = function()
        win.focused = true
    end
    return win
end

local function makeApp(name, windows)
    local app = {}
    app.name = function()
        return name
    end
    app.bundleID = function()
        return ""
    end
    app.allWindows = function()
        return windows
    end
    app.mainWindow = function()
        return windows[1]
    end
    for _, w in ipairs(windows) do
        w.application = function()
            return app
        end
    end
    return app
end

describe("google_meet_window_manager", function()
    it("should export a table", function()
        assert.is_table(googleMeetWindowManager)
    end)

    it("closes duplicate Meet windows and focuses the triggering one", function()
        local win1 = makeWindow(1)
        local win2 = makeWindow(2)
        makeApp("Meet", {win1, win2})

        googleMeetWindowManager.start()
        capturedHandler(win2, "Meet", "windowCreated")
        googleMeetWindowManager.stop()

        assert.is_true(win1.closed)
        assert.is_false(win2.closed)
        assert.is_true(win2.focused)
    end)

    it("does not close the meet window when a transient share-bar window appears", function()
        local meetWin = makeWindow(1)
        local shareBar = makeWindow(2, {w = 300, h = 60})
        makeApp("Meet", {meetWin, shareBar})

        googleMeetWindowManager.start()
        capturedHandler(shareBar, "Meet", "windowCreated")
        googleMeetWindowManager.stop()

        assert.is_false(meetWin.closed)
        assert.is_false(shareBar.closed)
        assert.is_false(meetWin.focused)
        assert.is_false(shareBar.focused)
    end)

    it("does not touch windows belonging to other apps", function()
        local otherWin = makeWindow(99)
        makeApp("Slack", {otherWin})
        local meetWin1 = makeWindow(1)
        local meetWin2 = makeWindow(2)
        makeApp("Meet", {meetWin1, meetWin2})

        googleMeetWindowManager.start()
        capturedHandler(otherWin, "Slack", "windowCreated")
        googleMeetWindowManager.stop()

        assert.is_false(otherWin.closed)
    end)

    it("does nothing when only one window exists", function()
        local win1 = makeWindow(1)
        makeApp("Meet", {win1})

        googleMeetWindowManager.start()
        capturedHandler(win1, "Meet", "windowFocused")
        googleMeetWindowManager.stop()

        assert.is_false(win1.closed)
        assert.is_false(win1.focused)
    end)

    it("sweeps pre-existing duplicates on start", function()
        local win1 = makeWindow(1)
        local win2 = makeWindow(2)
        local app = makeApp("Meet", {win1, win2})
        hs.application.runningApplications = function()
            return {app}
        end

        googleMeetWindowManager.start()
        googleMeetWindowManager.stop()

        assert.is_true(win1.closed or win2.closed)
        hs.application.runningApplications = function()
            return {}
        end
    end)

    it("does not treat a lingering share-bar window as a duplicate on start", function()
        local meetWin = makeWindow(1)
        local shareBar = makeWindow(2, {w = 300, h = 60})
        local app = makeApp("Meet", {meetWin, shareBar})
        hs.application.runningApplications = function()
            return {app}
        end

        googleMeetWindowManager.start()
        googleMeetWindowManager.stop()

        assert.is_false(meetWin.closed)
        assert.is_false(shareBar.closed)
        hs.application.runningApplications = function()
            return {}
        end
    end)

    it("matches apps by name or bundle id", function()
        local win1 = makeWindow(1)
        local app = makeApp("Meet", {win1})
        assert.is_true(googleMeetWindowManager._test_appMatchesTarget(app))

        app.name = function()
            return "Something Else"
        end
        assert.is_false(googleMeetWindowManager._test_appMatchesTarget(app))
    end)

    it("isMeetingWindow distinguishes real meeting windows from transient ones", function()
        local meetWin = makeWindow(1)
        local shareBar = makeWindow(2, {w = 300, h = 60})
        local nonStandard = makeWindow(3)
        nonStandard.isStandard = function()
            return false
        end

        assert.is_true(googleMeetWindowManager._test_isMeetingWindow(meetWin))
        assert.is_false(googleMeetWindowManager._test_isMeetingWindow(shareBar))
        assert.is_false(googleMeetWindowManager._test_isMeetingWindow(nonStandard))
    end)

    it("M.stop() runs without error", function()
        googleMeetWindowManager.start()
        assert.has_no.errors(function()
            googleMeetWindowManager.stop()
        end)
    end)
end)
