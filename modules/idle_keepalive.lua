
-- luacheck: globals hs
local M = {}

-- ===== Configuration =====
local CHECK_INTERVAL = 5      -- Check idle time every 5 seconds
local IDLE_THRESHOLD = 30     -- Trigger mouse movement after 30 seconds of idle
local MOUSE_MOVE_RANGE = 50   -- Random movement within 50 pixels from current position

-- Target apps (names and/or bundle IDs)
M.config = {
    app_names = {"Microsoft Teams", "Zoom", "Slack"},
    bundle_ids = {"com.microsoft.teams2", "com.microsoft.teams"} -- new+classic Teams
}

-- ===== Internal State =====
local _idleTimer = nil
local _appWatcher = nil
local _cafWatcher = nil
local _screenLocked = false

-- ===== Helper Functions =====

--- Returns true if the given app matches any target name or bundle ID
local function appIsTarget(app)
    if not app then return false end

    local name = app:name() or ""
    local bundle = app:bundleID() or ""

    for _, targetName in ipairs(M.config.app_names) do
        if name == targetName then return true end
    end
    for _, targetBundle in ipairs(M.config.bundle_ids) do
        if bundle == targetBundle then return true end
    end
    return false
end

--- Returns true if any target app is currently running
local function targetsRunningNow()
    for _, app in ipairs(hs.application.runningApplications()) do
        if appIsTarget(app) then
            return true
        end
    end
    return false
end

--- Gets safe display boundaries for mouse movement
local function getSafeDisplayBounds()
    local screens = hs.screen.allScreens()
    if #screens == 0 then return nil end

    -- Use the main screen or first available screen
    local screen = hs.screen.mainScreen() or screens[1]
    local frame = screen:frame()

    -- Add some padding to avoid edges
    local padding = 50
    return {
        x = frame.x + padding,
        y = frame.y + padding,
        w = frame.w - (padding * 2),
        h = frame.h - (padding * 2)
    }
end

--- Moves mouse to a random position within safe display bounds
local function moveMouseRandomly()
    local bounds = getSafeDisplayBounds()
    if not bounds then return end

    local currentPos = hs.mouse.absolutePosition()

    -- Generate random position within MOUSE_MOVE_RANGE from current position
    local deltaX = math.random(-MOUSE_MOVE_RANGE, MOUSE_MOVE_RANGE)
    local deltaY = math.random(-MOUSE_MOVE_RANGE, MOUSE_MOVE_RANGE)

    local newX = math.max(bounds.x, math.min(bounds.x + bounds.w, currentPos.x + deltaX))
    local newY = math.max(bounds.y, math.min(bounds.y + bounds.h, currentPos.y + deltaY))

    -- Move mouse to new position
    hs.mouse.absolutePosition({x = newX, y = newY})

    print(string.format("🖱️ Mouse moved randomly: (%d,%d) -> (%d,%d)",
                       math.floor(currentPos.x), math.floor(currentPos.y),
                       math.floor(newX), math.floor(newY)))
end

--- Main idle check function
local function checkIdleTime()
    if not targetsRunningNow() then
        return -- No target apps running, skip check
    end

    local idleTime = hs.host.idleTime()

    if idleTime >= IDLE_THRESHOLD then
        -- User has been idle for more than threshold, move mouse
        moveMouseRandomly()

        -- Prevent display sleep when screen is locked
        if _screenLocked then
            hs.caffeinate.set('displayIdle', true, true)
            print("🔒 Screen locked - preventing display sleep")
        end

        print(string.format("⏰ Idle for %ds (threshold: %ds) - keeping active",
                           math.floor(idleTime), IDLE_THRESHOLD))
    end
end

--- Starts the idle check timer
local function startIdleTimer()
    if _idleTimer then return end

    _idleTimer = hs.timer.new(CHECK_INTERVAL, checkIdleTime)
    _idleTimer:start()
    print(string.format("⏱️ Idle keep-alive started (check every %ds, threshold %ds)",
                       CHECK_INTERVAL, IDLE_THRESHOLD))
end

--- Stops the idle check timer
local function stopIdleTimer()
    if _idleTimer then
        _idleTimer:stop()
        _idleTimer = nil
        hs.caffeinate.set('displayIdle', false, true) -- Re-enable display sleep
        print("⏹️ Idle keep-alive stopped")
    end
end

--- Handles app launch/terminate events
local function handleAppEvent(_appName, eventType, _appObject)
    if eventType == hs.application.watcher.launched or
       eventType == hs.application.watcher.terminated then

        if targetsRunningNow() then
            startIdleTimer()
        else
            stopIdleTimer()
        end
    end
end

--- Handles system sleep/wake/lock events
local function handleCaffeinateEvent(eventType)
    if eventType == hs.caffeinate.watcher.screensDidLock then
        _screenLocked = true
        print("🔒 Screen locked - idle keep-alive continues")

    elseif eventType == hs.caffeinate.watcher.screensDidUnlock then
        _screenLocked = false
        hs.caffeinate.set('displayIdle', false, true) -- Re-enable normal display sleep
        print("🔓 Screen unlocked")

    elseif eventType == hs.caffeinate.watcher.systemWillSleep then
        stopIdleTimer()
        print("� System going to sleep - idle keep-alive paused")

    elseif eventType == hs.caffeinate.watcher.systemDidWake then
        if targetsRunningNow() then
            startIdleTimer()
            print("🌅 System woke up - idle keep-alive resumed")
        end
    end
end

-- ===== Public API =====

--- Starts the idle keep-alive module
function M.start(opts)
    opts = opts or {}

    -- Override config if provided
    if opts.app_names then
        M.config.app_names = opts.app_names
    end
    if opts.bundle_ids then
        M.config.bundle_ids = opts.bundle_ids
    end

    -- Start watchers
    if not _appWatcher then
        _appWatcher = hs.application.watcher.new(handleAppEvent)
        _appWatcher:start()
    end

    if not _cafWatcher then
        _cafWatcher = hs.caffeinate.watcher.new(handleCaffeinateEvent)
        _cafWatcher:start()
    end

    -- Start timer if target apps are already running
    if targetsRunningNow() then
        startIdleTimer()
    end

    print(string.format("✅ idle_keepalive started - monitoring %d apps",
                       #M.config.app_names + #M.config.bundle_ids))
end

--- Stops the idle keep-alive module
function M.stop()
    -- Stop timer
    stopIdleTimer()

    -- Stop watchers
    if _appWatcher then
        _appWatcher:stop()
        _appWatcher = nil
    end

    if _cafWatcher then
        _cafWatcher:stop()
        _cafWatcher = nil
    end

    -- Reset state
    _screenLocked = false

    print("🛑 idle_keepalive stopped")
end

-- For testing
M._test_appIsTarget = appIsTarget
M._test_targetsRunningNow = targetsRunningNow

return M
