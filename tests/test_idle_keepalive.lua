
-- luacheck: globals hs busted describe it assert
-- luacheck: ignore busted
_G.hs = _G.hs or {}
hs.timer = hs.timer or {}
hs.caffeinate = hs.caffeinate or {}
hs.application = hs.application or {}
hs.application.runningApplications = function() return {} end
hs.application.watcher = {
    launched = "launched",
    terminated = "terminated",
    new = function()
        return {
            start = function() end,
            stop = function() end
        }
    end
}
hs.caffeinate.watcher = {
    new = function()
        return {
            start = function() end,
            stop = function() end
        }
    end,
    systemWillSleep = "systemWillSleep",
    screensDidSleep = "screensDidSleep",
    screensDidLock = "screensDidLock",
    systemDidWake = "systemDidWake",
    screensDidWake = "screensDidWake",
    screensDidUnlock = "screensDidUnlock",
    sessionDidBecomeActive = "sessionDidBecomeActive"
}

-- Unit tests for idle_keepalive.lua
local busted = require('busted')
local idle_keepalive = require('../modules/idle_keepalive')

describe("idle_keepalive", function()
    it("should export a table", function()
        assert.is_table(idle_keepalive)
    end)

    it("should start and stop without error", function()
        assert.has_no.errors(function() idle_keepalive.start() end)
        assert.has_no.errors(function() idle_keepalive.stop() end)
    end)

    it("should override config via start opts", function()
        local opts = {
            app_names = {
                "TestApp"
            },
            bundle_ids = {
                "com.test.app"
            }
        }
        idle_keepalive.start(opts)
        assert.are.same({"TestApp"}, idle_keepalive.config.app_names)
        assert.are.same({"com.test.app"}, idle_keepalive.config.bundle_ids)
        idle_keepalive.stop()
    end)

    it("should match target app by name", function()
        idle_keepalive.config.app_names = {
            "Microsoft Teams",
            "Zoom",
            "Slack"
        }
        idle_keepalive.config.bundle_ids = {
            "com.microsoft.teams2",
            "com.microsoft.teams"
        }
        local app = {}
        app.name = function() return "Microsoft Teams" end
        app.bundleID = function() return "other" end
        assert.is_true(idle_keepalive._test_appIsTarget(app))
    end)

    it("should match target app by bundle ID", function()
        idle_keepalive.config.app_names = {
            "Microsoft Teams",
            "Zoom",
            "Slack"
        }
        idle_keepalive.config.bundle_ids = {
            "com.microsoft.teams2",
            "com.microsoft.teams"
        }
        local app = {}
        app.name = function() return "Other" end
        app.bundleID = function() return "com.microsoft.teams" end
        assert.is_true(idle_keepalive._test_appIsTarget(app))
    end)

    it("should not match non-target app", function()
        idle_keepalive.config.app_names = {
            "Microsoft Teams",
            "Zoom",
            "Slack"
        }
        idle_keepalive.config.bundle_ids = {
            "com.microsoft.teams2",
            "com.microsoft.teams"
        }
        local app = {}
        app.name = function() return "Other" end
        app.bundleID = function() return "other" end
        assert.is_false(idle_keepalive._test_appIsTarget(app))
    end)
end)
