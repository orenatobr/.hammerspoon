
-- luacheck: globals hs busted describe it assert
-- luacheck: ignore busted
local busted = require('busted')

describe("auto_lock", function()
    local auto_lock
    local currentScreens
    local watcherCallback
    local lidWatcherCallback
    local keepaliveCalls
    local executeCalls
    local caffeinateSetCalls
    local ioregState
    local pendingTimers

    local function commandExecuted(command)
        for _, call in ipairs(executeCalls) do
            if call.command == command then
                return true
            end
        end
        return false
    end

    local function runPendingTimers()
        local timers = pendingTimers
        pendingTimers = {}
        for _, timer in ipairs(timers) do
            if not timer.stopped and timer.fn then
                timer.fn()
            end
        end
    end

    local function internalScreen(name)
        return {
            name = function()
                return name or "Built-in Retina Display"
            end
        }
    end

    local function externalScreen(name)
        return {
            name = function()
                return name or "DELL U2720Q"
            end
        }
    end

    before_each(function()
        package.loaded['../modules/auto_lock'] = nil
        package.loaded['modules.auto_lock'] = nil
        package.loaded['modules.idle_keepalive'] = {
            setLidClosed = function(isClosed)
                table.insert(keepaliveCalls, isClosed)
            end
        }

        keepaliveCalls = {}
        executeCalls = {}
        caffeinateSetCalls = {}
        watcherCallback = nil
        lidWatcherCallback = nil
        ioregState = "No"
        pendingTimers = {}
        currentScreens = {internalScreen(), externalScreen()}

        _G.hs = {
            caffeinate = {
                set = function(kind, enabled, global)
                    table.insert(caffeinateSetCalls, {kind = kind, enabled = enabled, global = global})
                end
            },
            execute = function(command, withUserEnv)
                table.insert(executeCalls, {command = command, withUserEnv = withUserEnv})
                if command == '/usr/sbin/ioreg -r -k AppleClamshellState -d 4' then
                    return string.format('    | |   "AppleClamshellState" = %s', ioregState), true, "exit", 0
                end
                return "", true, "exit", 0
            end,
            timer = {
                doAfter = function(_, fn)
                    local timer = {
                        fn = fn,
                        stopped = false,
                        stop = function(self)
                            self.stopped = true
                        end
                    }
                    table.insert(pendingTimers, timer)
                    return timer
                end,
                doEvery = function(_, fn)
                    lidWatcherCallback = fn
                    return {
                        stop = function() end
                    }
                end
            },
            screen = {
                allScreens = function()
                    return currentScreens
                end,
                watcher = {
                    new = function(cb)
                        watcherCallback = cb
                        return {
                            start = function() end,
                            stop = function() end
                        }
                    end
                }
            }
        }

        auto_lock = require('../modules/auto_lock')
    end)

    after_each(function()
        if auto_lock and auto_lock.stop then
            auto_lock.stop()
        end
    end)

    it("should export a table", function()
        assert.is_table(auto_lock)
    end)

    it("should keep keepalive running in lid-closed mode and sleep displays when lid closes", function()
        auto_lock.start()
        ioregState = "Yes"
        currentScreens = {externalScreen()}

        lidWatcherCallback()
        runPendingTimers()
        runPendingTimers()

        assert.is_true(keepaliveCalls[1])
        assert.is_true(commandExecuted('/usr/bin/pmset displaysleepnow'))
        assert.are.same({kind = 'displayIdle', enabled = false, global = true}, caffeinateSetCalls[1])
    end)

    it("should restore keepalive open mode when lid opens", function()
        auto_lock.start()
        ioregState = "Yes"
        currentScreens = {externalScreen()}
        lidWatcherCallback()
        runPendingTimers()
        runPendingTimers()

        ioregState = "No"
        currentScreens = {internalScreen(), externalScreen()}
        lidWatcherCallback()
        runPendingTimers()

        assert.is_false(keepaliveCalls[2])
    end)

    it("should cancel a pending lid-close action when the lid reopens quickly", function()
        auto_lock.start()
        ioregState = "Yes"
        currentScreens = {externalScreen()}
        lidWatcherCallback()

        ioregState = "No"
        currentScreens = {internalScreen(), externalScreen()}
        lidWatcherCallback()
        runPendingTimers()
        runPendingTimers()

        assert.is_nil(keepaliveCalls[1])
        assert.is_false(commandExecuted('/usr/bin/pmset displaysleepnow'))
    end)
end)
