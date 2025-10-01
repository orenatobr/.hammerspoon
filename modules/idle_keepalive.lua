
-- luacheck: globals hs
local M = {}

-- ===== Configuration =====
local ACTIVITY_INTERVAL = 15  -- Simulate activity every 15 seconds (aggressive)
local MOUSE_JIGGLE_PIXELS = 1  -- Tiny mouse movement (almost unnoticeable)
local MAX_IDLE_TIME = 20       -- Never let system be idle more than 20 seconds

-- Target apps (names and/or bundle IDs)
M.config = {
    app_names = {"Microsoft Teams", "Zoom", "Slack"},
    bundle_ids = {"com.microsoft.teams2", "com.microsoft.teams"} -- new+classic Teams
}

-- ===== Internal State =====
local _activityTimer = nil
local _appWatcher = nil
local _cafWatcher = nil

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

--- Performs tiny mouse jiggle (almost invisible)
local function performMouseJiggle()
    local currentPos = hs.mouse.absolutePosition()

    -- Move mouse by 1 pixel
    hs.mouse.absolutePosition({
        x = currentPos.x + MOUSE_JIGGLE_PIXELS,
        y = currentPos.y
    })

    -- Move it back after a brief delay
    hs.timer.doAfter(0.05, function()
        hs.mouse.absolutePosition(currentPos)
    end)
end

--- Simulates keyboard activity using safer method
local function performKeyboardActivity()
    -- Use scroll wheel event instead of problematic key events
    -- This registers as user activity without affecting anything
    local scrollEvent = hs.eventtap.event.newScrollEvent({0, 0}, {}, "pixel")
    if scrollEvent then
        scrollEvent:post()
    end
end

--- Main activity simulation function
local function simulateActivity()
    if not targetsRunningNow() then
        return -- No target apps running
    end

    local idleTime = hs.host.idleTime()

    -- Always prevent system/display sleep
    hs.caffeinate.set('displayIdle', true, true)
    hs.caffeinate.set('systemIdle', true, true)

    -- If idle time is approaching the threshold, simulate activity
    if idleTime >= MAX_IDLE_TIME then
        -- Alternate between mouse and keyboard activity
        if math.random() > 0.5 then
            performMouseJiggle()
            print(string.format("🖱️ Mouse jiggle (idle: %ds)", math.floor(idleTime)))
        else
            performKeyboardActivity()
            print(string.format("🛞 Scroll activity (idle: %ds)", math.floor(idleTime)))
        end
    end
end

--- Starts the activity simulation timer
local function startActivityTimer()
    if _activityTimer then return end

    _activityTimer = hs.timer.new(ACTIVITY_INTERVAL, simulateActivity)
    _activityTimer:start()

    -- Immediate sleep prevention
    hs.caffeinate.set('displayIdle', true, true)
    hs.caffeinate.set('systemIdle', true, true)

    print(string.format("⏱️ Aggressive keep-alive started (activity every %ds, max idle %ds)",
                       ACTIVITY_INTERVAL, MAX_IDLE_TIME))
end

--- Stops the activity simulation timer
local function stopActivityTimer()
    if _activityTimer then
        _activityTimer:stop()
        _activityTimer = nil

        -- Re-enable normal sleep behavior
        hs.caffeinate.set('displayIdle', false, true)
        hs.caffeinate.set('systemIdle', false, true)

        print("⏹️ Aggressive keep-alive stopped")
    end
end

--- Handles app launch/terminate events
local function handleAppEvent(_appName, eventType, _appObject)
    if eventType == hs.application.watcher.launched or
       eventType == hs.application.watcher.terminated then

        if targetsRunningNow() then
            startActivityTimer()
        else
            stopActivityTimer()
        end
    end
end

--- Handles system sleep/wake/lock events
local function handleCaffeinateEvent(eventType)
    if eventType == hs.caffeinate.watcher.screensDidLock then
        print("🔒 Screen locked - aggressive keep-alive continues")

    elseif eventType == hs.caffeinate.watcher.screensDidUnlock then
        print("🔓 Screen unlocked - aggressive keep-alive continues")

    elseif eventType == hs.caffeinate.watcher.systemWillSleep then
        -- Aggressively prevent sleep when target apps are running
        if targetsRunningNow() then
            print("🚫 BLOCKING system sleep - keeping apps available")
            -- Force activity to prevent sleep
            simulateActivity()
        else
            stopActivityTimer()
            print("💤 Allowing system sleep - no target apps running")
        end

    elseif eventType == hs.caffeinate.watcher.systemDidWake then
        if targetsRunningNow() then
            startActivityTimer()
            print("🌅 System woke up - aggressive keep-alive resumed")
        end
    end
end

-- ===== Public API =====

--- Starts the aggressive keep-alive module
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

    -- Start aggressive activity simulation if target apps are already running
    if targetsRunningNow() then
        startActivityTimer()
    end

    print(string.format("✅ AGGRESSIVE idle_keepalive started - forcing %d apps to stay available",
                       #M.config.app_names + #M.config.bundle_ids))
end

--- Stops the aggressive keep-alive module
function M.stop()
    -- Stop activity timer
    stopActivityTimer()

    -- Stop watchers
    if _appWatcher then
        _appWatcher:stop()
        _appWatcher = nil
    end

    if _cafWatcher then
        _cafWatcher:stop()
        _cafWatcher = nil
    end

    print("🛑 AGGRESSIVE idle_keepalive stopped")
end

-- For testing
M._test_appIsTarget = appIsTarget
M._test_targetsRunningNow = targetsRunningNow

return M
