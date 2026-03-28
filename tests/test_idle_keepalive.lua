
-- luacheck: globals hs busted describe it assert
-- luacheck: ignore busted
_G.hs = _G.hs or {}
hs.timer = hs.timer or {}
hs.caffeinate = hs.caffeinate or {}
hs.application = hs.application or {}
hs.alert = hs.alert or {}
hs.application.runningApplications = function() return {} end
hs.alert.show = function() end
hs.alert.closeAll = function() end
hs.host = hs.host or {}
hs.host.idleTime = function() return 0 end
hs.mouse = hs.mouse or {}
hs.mouse.absolutePosition = function(pos)
    if pos then
        return pos
    end
    return {x = 0, y = 0}
end
hs.eventtap = hs.eventtap or {}
hs.eventtap.event = hs.eventtap.event or {}
hs.eventtap.event.newScrollEvent = function()
    return {
        post = function() end
    }
end
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
hs.caffeinate.set = function() end
hs.timer.new = function(_, _)
    return {
        start = function() end,
        stop = function() end
    }
end

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

    it("should keep system awake but allow display sleep when lid is closed", function()
        local setCalls = {}
        local function hasSetCall(kind, enabled)
            for _, call in ipairs(setCalls) do
                if call.kind == kind and call.enabled == enabled and call.global == true then
                    return true
                end
            end
            return false
        end

        hs.caffeinate.set = function(kind, enabled, global)
            table.insert(setCalls, {kind = kind, enabled = enabled, global = global})
        end
        hs.application.runningApplications = function()
            return {{
                name = function() return "Code" end,
                bundleID = function() return "com.microsoft.VSCode" end
            }}
        end

        idle_keepalive.setLidClosed(true, "test")
        idle_keepalive._test_simulateActivity()

        assert.is_true(idle_keepalive.isLidClosed())
        assert.is_true(hasSetCall('systemIdle', true))
        assert.is_true(hasSetCall('displayIdle', false))

        idle_keepalive.setLidClosed(false, "test")
        idle_keepalive.stop()
    end)
end)
