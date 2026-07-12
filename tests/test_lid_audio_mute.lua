
-- luacheck: globals hs busted describe it assert before_each after_each
-- luacheck: ignore busted
local busted = require('busted')

describe("lid_audio_mute", function()
    local lid_audio_mute
    local currentScreens
    local lidWatcherCallback
    local muteCalls
    local pendingTimers

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
        package.loaded['../modules/lid_audio_mute'] = nil
        package.loaded['modules.lid_audio_mute'] = nil

        muteCalls = {}
        lidWatcherCallback = nil
        pendingTimers = {}
        currentScreens = {internalScreen(), externalScreen()}

        _G.hs = {
            caffeinate = {},
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
                    new = function()
                        return {
                            start = function() end,
                            stop = function() end
                        }
                    end
                }
            },
            audiodevice = {
                defaultOutputDevice = function()
                    return {
                        setOutputMuted = function(_, muted)
                            table.insert(muteCalls, muted)
                        end
                    }
                end
            }
        }

        lid_audio_mute = require('../modules/lid_audio_mute')
    end)

    after_each(function()
        if lid_audio_mute and lid_audio_mute.stop then
            lid_audio_mute.stop()
        end
    end)

    it("should export a table", function()
        assert.is_table(lid_audio_mute)
    end)

    it("should mute audio when the lid closes", function()
        lid_audio_mute.start()
        currentScreens = {externalScreen()}

        lidWatcherCallback()
        runPendingTimers()

        assert.are.same({true}, muteCalls)
    end)

    it("should unmute audio when the lid reopens", function()
        lid_audio_mute.start()
        currentScreens = {externalScreen()}
        lidWatcherCallback()
        runPendingTimers()

        currentScreens = {internalScreen(), externalScreen()}
        lidWatcherCallback()
        runPendingTimers()

        assert.are.same({true, false}, muteCalls)
    end)

    it("should cancel a pending mute action when the lid reopens quickly", function()
        lid_audio_mute.start()
        currentScreens = {externalScreen()}
        lidWatcherCallback()

        currentScreens = {internalScreen(), externalScreen()}
        lidWatcherCallback()
        runPendingTimers()
        runPendingTimers()

        assert.are.same({}, muteCalls)
    end)

    it("should tear down watchers and timers on stop", function()
        lid_audio_mute.start()
        lid_audio_mute.stop()

        currentScreens = {externalScreen()}
        lidWatcherCallback()
        runPendingTimers()

        assert.are.same({}, muteCalls)
    end)
end)
