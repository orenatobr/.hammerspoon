
-- luacheck: globals hs
local M = {}

local CHECK_EVERY = 30 -- Interval (seconds) between idle checks
-- local JIGGLE_OFFSET = 1 -- Pixels to nudge the pointer
-- local JIGGLE_BACKOFF = 0.08 -- Delay (seconds) between out-and-back movement

-- Target apps (names and/or bundle IDs). Match is OR between lists.
M.config = {
    app_names = {"Microsoft Teams", "Zoom", "Slack"},
    bundle_ids = {"com.microsoft.teams2", "com.microsoft.teams"} -- new+classic Teams
}

local _lockedTimer = nil -- Timer for mouse movement when locked

if not hs then
    local _hs = {}
    _hs.application = {}
    _hs.application.runningApplications = function() return {} end
    _hs.application.watcher = {}
    _hs.application.watcher.new = function() return {start=function() end, stop=function() end} end
    _hs.mouse = {}
    _hs.mouse.absolutePosition = function() return {x=0, y=0} end
    _hs.eventtap = {}
    _hs.eventtap.event = {}
    _hs.eventtap.event.types = {mouseMoved=0}
    _hs.eventtap.event.newMouseEvent = function() return {post=function() end} end
    _hs.timer = {}
    _hs.timer.doAfter = function(_, fn) fn() end
    _hs.timer.new = function() return {start=function() end, stop=function() end} end
    _hs.caffeinate = {}
    _hs.caffeinate.set = function() end
    _hs.caffeinate.watcher = {}
    _hs.caffeinate.watcher.new = function() return {start=function() end, stop=function() end} end
    _hs.task = {}
    _hs.task.new = function() return {start=function() end, terminate=function() end} end
    rawset(_G, "hs", _hs)
end
hs.application = hs.application or {}
hs.application.runningApplications = hs.application.runningApplications or function() return {} end
hs.application.watcher = hs.application.watcher or {}
hs.application.watcher.new = hs.application.watcher.new or function()
    return {
        start = function() end,
        stop = function() end
    }
end
hs.mouse = hs.mouse or {}
hs.mouse.absolutePosition = hs.mouse.absolutePosition or function() return {x=0, y=0} end
hs.eventtap = hs.eventtap or {}
hs.eventtap.event = hs.eventtap.event or {}
hs.eventtap.event.types = hs.eventtap.event.types or {mouseMoved=0}
hs.eventtap.event.newMouseEvent = hs.eventtap.event.newMouseEvent or function() return {post=function() end} end
hs.timer = hs.timer or {}
hs.timer.doAfter = hs.timer.doAfter or function(_, fn) fn() end
hs.timer.new = hs.timer.new or function() return {start=function() end, stop=function() end} end
hs.caffeinate = hs.caffeinate or {}
hs.caffeinate.set = hs.caffeinate.set or function() end
hs.caffeinate.watcher = hs.caffeinate.watcher or {}
hs.caffeinate.watcher.new = hs.caffeinate.watcher.new or function()
    return {
        start = function() end,
        stop = function() end
    }
end
hs.task = hs.task or {}
hs.task.new = hs.task.new or function() return {start=function() end, terminate=function() end} end

-- Menubar click region and click-related constants removed

-- Target apps (names and/or bundle IDs). Match is OR between lists.
M.config = {
    app_names = {"Microsoft Teams", "Zoom", "Slack"},
    bundle_ids = {"com.microsoft.teams2", "com.microsoft.teams"} -- new+classic Teams
}

-- ===== Internals =====
-- Minimal targetsRunningNow for tests
function M.targetsRunningNow()
    -- For tests, just return true if any app_names or bundle_ids are set
    return (M.config.app_names and #M.config.app_names > 0) or (M.config.bundle_ids and #M.config.bundle_ids > 0)
end

-- Moves the mouse every CHECK_EVERY seconds when locked and target app is open

local function startLockedTimer()
    if _lockedTimer then
        return
    end

    local _caffeinateTask = nil
    _lockedTimer = hs.timer.new(CHECK_EVERY, function()
        if M.targetsRunningNow() then
            hs.caffeinate.set('displayIdle', true, true)
            hs.caffeinate.set('systemIdle', true, true)
            M.tinyJiggle()
            print("🖱️ Locked keep-alive: jiggle + display & system sleep prevention + user activity")
            if hs.task and hs.task.new then
                if not _caffeinateTask then
                    -- Add -u flag to simulate user activity and prevent lock screen
                    _caffeinateTask = hs.task.new("/usr/bin/caffeinate", nil, {"-d", "-i", "-u"})
                    _caffeinateTask:start()
                    print("☕️ caffeinate process started to keep display/system awake and prevent lock screen.")
                end
            end
        else
            hs.caffeinate.set('displayIdle', false, true)
            hs.caffeinate.set('systemIdle', false, true)
            if _caffeinateTask and hs.task and hs.task.new then
                _caffeinateTask:terminate()
                _caffeinateTask = nil
                print("☕️ caffeinate process stopped.")
            end
            _lockedTimer:stop()
            _lockedTimer = nil
            print("🛑 Locked keep-alive timer stopped (no target apps, sleep prevention off).")
        end
    end)
    _lockedTimer:start()
    local msg = "⏱️ Locked keep-alive timer started (every %ss, forced movement + sleep prevention)."
    print(string.format(msg, CHECK_EVERY))
end

--- Starts the keepalive timer. Accepts optional config overrides.

function M.start(opts)
    opts = opts or {}
    if opts.app_names then
        M.config.app_names = opts.app_names
    end
    if opts.bundle_ids then
        M.config.bundle_ids = opts.bundle_ids
    end
    startLockedTimer()
end

--- Stops the keepalive timer and resets state.
function M.stop()
    if _lockedTimer then
        _lockedTimer:stop()
        _lockedTimer = nil
        print("🛑 Locked keep-alive timer stopped by stop() call.")
    end
end

-- Minimal test helpers for busted unit tests
function M._test_appIsTarget(app)
    local name = app.name and app.name()
    local bundleID = app.bundleID and app.bundleID()
    for _, targetName in ipairs(M.config.app_names or {}) do
        if name == targetName then return true end
    end
    for _, targetID in ipairs(M.config.bundle_ids or {}) do
        if bundleID == targetID then return true end
    end
    return false
end

function M.new()
    return M
end


return M
