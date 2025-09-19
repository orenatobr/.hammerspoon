-- ~/.hammerspoon/modules/idle_keepalive.lua
-- Module: idle_keepalive
-- Purpose: Prevent selected apps from showing as "Away" by simulating user activity (mouse jiggle) after a period of inactivity.
-- No mouse clicks are performed; only a subtle pointer movement is used.
-- Usage: require this module and call M.start() to begin. Optionally pass a table to override target apps.
-- Author: [Your Name]
-- Last updated: 2025-09-19
local M = {}

-- ===== Config =====
-- ===== Configuration =====
local CHECK_EVERY = 30         -- Interval (seconds) between idle checks
local IDLE_THRESHOLD = 30      -- Idle time (seconds) required to trigger jiggle
local JIGGLE_OFFSET = 1        -- Pixels to nudge the pointer
local JIGGLE_BACKOFF = 0.08    -- Delay (seconds) between out-and-back movement

-- Mouse click functionality removed; only jiggle remains

-- Menubar click region and click-related constants removed

-- Target apps (names and/or bundle IDs). Match is OR between lists.
M.config = {
    app_names = {"Microsoft Teams", "Zoom", "Slack"},
    bundle_ids = {"com.microsoft.teams2", "com.microsoft.teams"} -- new+classic Teams
}

-- ===== Internals =====
local _appWatcher = nil      -- Application watcher for target apps
local _checkTimer = nil      -- Timer for periodic idle checks
local _cafWatcher = nil      -- Caffeinate watcher for sleep/wake events
local _busy = false          -- Prevents overlapping jiggle actions

--- Checks if the given app matches any target name or bundle ID.
local function appIsTarget(app)
    if not app then return false end
    local name = app:name() or ""
    local bundle = app:bundleID() or ""
    for _, n in ipairs(M.config.app_names or {}) do
        if name == n then return true end
    end
    for _, b in ipairs(M.config.bundle_ids or {}) do
        if bundle == b then return true end
    end
    return false
end

--- Returns true if any target app is currently running.
local function targetsRunningNow()
    for _, app in ipairs(hs.application.runningApplications()) do
        if appIsTarget(app) then return true end
    end
    return false
end

--- Moves the mouse pointer by a small offset and returns it to its original position.
local function tinyJiggle()
    local p = hs.mouse.absolutePosition()
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.mouseMoved, {
        x = p.x + JIGGLE_OFFSET,
        y = p.y + JIGGLE_OFFSET
    }):post()
    hs.timer.doAfter(JIGGLE_BACKOFF, function()
        hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.mouseMoved, {
            x = p.x,
            y = p.y
        }):post()
    end)
end

-- Geometry and click helpers removed (no longer used)

-- Mouse click functions removed (no longer used)

--- Starts the periodic idle check timer.
local function startTimer()
    if _checkTimer then return end
    _checkTimer = hs.timer.new(CHECK_EVERY, function()
        if not targetsRunningNow() then
            _checkTimer:stop()
            _checkTimer = nil
            print("🛑 Idle keep-alive timer stopped (no target apps).")
            return
        end

        local idle = hs.host.idleTime()
        if idle >= IDLE_THRESHOLD and not _busy then
            _busy = true
            tinyJiggle()
            hs.timer.doAfter(JIGGLE_BACKOFF, function()
                _busy = false
                print("🖱️ Keep-alive: jiggle only (no click)")
            end)
        end
    end)
    _checkTimer:start()
    print(string.format("⏱️ Idle keep-alive timer started (every %ss, threshold %ss).", CHECK_EVERY, IDLE_THRESHOLD))
end

--- Stops the idle check timer.
local function stopTimer()
    if _checkTimer then
        _checkTimer:stop()
        _checkTimer = nil
    end
end

-- ===== Watchers =====
--- Handles app launch/terminate events to start/stop the timer as needed.
local function handleAppEvent(_, event, _)
    if event == hs.application.watcher.launched or event == hs.application.watcher.terminated then
        if targetsRunningNow() then
            startTimer()
        else
            stopTimer()
            print("🛑 Idle keep-alive paused (no target apps).")
        end
    end
end

--- Handles system sleep/wake/lock events to pause/resume the timer.
local function handleCaffeinateEvent(e)
    if e == hs.caffeinate.watcher.systemWillSleep or e == hs.caffeinate.watcher.screensDidSleep or e == hs.caffeinate.watcher.screensDidLock then
        stopTimer()
    elseif e == hs.caffeinate.watcher.systemDidWake or e == hs.caffeinate.watcher.screensDidWake or e == hs.caffeinate.watcher.screensDidUnlock or e == hs.caffeinate.watcher.sessionDidBecomeActive then
        if targetsRunningNow() then
            startTimer()
        end
    end
end

-- ===== Public API =====
--- Public API: Start the idle keepalive module.
-- Optionally override target app names/bundle IDs via opts table.
function M.start(opts)
    if type(opts) == "table" then
        M.config.app_names = opts.app_names or M.config.app_names
        M.config.bundle_ids = opts.bundle_ids or M.config.bundle_ids
    end

    if targetsRunningNow() then
        startTimer()
    end

    if not _appWatcher then
        _appWatcher = hs.application.watcher.new(handleAppEvent)
        _appWatcher:start()
    end
    if not _cafWatcher then
        _cafWatcher = hs.caffeinate.watcher.new(handleCaffeinateEvent)
        _cafWatcher:start()
    end

    print(string.format("✅ idle_keepalive started. Watching %d names / %d bundle IDs.", #(M.config.app_names or {}), #(M.config.bundle_ids or {})))
end

-- Public API: Stop the idle keepalive module and clean up watchers/timers.
function M.stop()
    if _appWatcher then
        _appWatcher:stop()
        _appWatcher = nil
    end
    if _cafWatcher then
        _cafWatcher:stop()
        _cafWatcher = nil
    end
    stopTimer()
    _busy = false
    print("🛑 idle_keepalive stopped.")
end

-- Return module table
return M
