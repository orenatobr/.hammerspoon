-- ~/.hammerspoon/modules/idle_keepalive.lua
-- Keep-alive for selected apps:
-- - Every CHECK_EVERY seconds, if system idle >= IDLE_THRESHOLD, jiggle mouse and do a safe desktop click.
-- - Works only while at least one target app is running.
-- - No UI disruption: briefly activates Finder to click on the desktop, then restores previous app.
local M = {}

-- ===== Config =====
local CHECK_EVERY = 30 -- seconds between checks
local IDLE_THRESHOLD = 30 -- seconds of inactivity required to trigger
local JIGGLE_OFFSET = 1 -- pixels to nudge the pointer
local FINDER_WAIT = 0.15 -- seconds to wait after focusing Finder before clicking

-- Target apps (names and/or bundle IDs). Match is OR between lists.
M.config = {
    app_names = {"Microsoft Teams", "Zoom", "Slack"}, -- add/remove as you like
    bundle_ids = {"com.microsoft.teams2"} -- optional (add more if needed)
}

-- ===== Internals =====
local _appWatcher = nil
local _checkTimer = nil
local _cafWatcher = nil
local _activeCount = 0 -- how many target apps are running
local _busy = false

-- ===== Helpers =====
local function anyTargetAppRunning()
    -- Fast path: track via _activeCount maintained by the app watcher
    return _activeCount > 0
end

local function appIsTarget(app)
    if not app then
        return false
    end
    local name = app:name() or ""
    local bundle = app:bundleID() or ""
    for _, n in ipairs(M.config.app_names or {}) do
        if name == n then
            return true
        end
    end
    for _, b in ipairs(M.config.bundle_ids or {}) do
        if bundle == b then
            return true
        end
    end
    return false
end

local function scanRunningTargets()
    local count = 0
    for _, app in ipairs(hs.application.runningApplications()) do
        if appIsTarget(app) then
            count = count + 1
        end
    end
    return count
end

local function tinyJiggle()
    local p = hs.mouse.absolutePosition()
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.mouseMoved, {
        x = p.x + JIGGLE_OFFSET,
        y = p.y + JIGGLE_OFFSET
    }):post()
    hs.timer.doAfter(0.08, function()
        hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.mouseMoved, {
            x = p.x,
            y = p.y
        }):post()
    end)
end

local function safeDesktopClick(cb)
    -- Click the center of the primary screen's desktop in Finder, then restore focus
    local prev = hs.application.frontmostApplication()

    -- Move pointer to desktop center
    local scr = hs.screen.primaryScreen()
    local f = scr and scr:frame() or {
        x = 0,
        y = 0,
        w = 1280,
        h = 800
    }
    local center = {
        x = math.floor(f.x + f.w / 2),
        y = math.floor(f.y + f.h / 2)
    }

    -- Focus Finder (so the click targets the desktop and does nothing)
    hs.application.launchOrFocus("Finder")

    hs.timer.doAfter(FINDER_WAIT, function()
        -- move + click
        hs.mouse.absolutePosition(center)
        hs.eventtap.leftClick(center)

        -- restore previous frontmost app (if any)
        if prev and prev:bundleID() ~= "com.apple.finder" then
            prev:activate(true)
        end

        if cb then
            cb()
        end
    end)
end

local function performKeepAlive()
    if _busy then
        return
    end
    _busy = true

    tinyJiggle()
    safeDesktopClick(function()
        _busy = false
        print("🖱️ Keep-alive: jiggle + desktop click")
    end)
end

local function checkIdleAndMaybeKeepAlive()
    if not anyTargetAppRunning() then
        return
    end
    -- Skip if screens are sleeping/locked (avoid waking)
    if hs.caffeinate.get("screensLocked") or hs.caffeinate.get("displayIdle") then
        return
    end

    local idle = hs.host.idleTime()
    if idle >= IDLE_THRESHOLD then
        performKeepAlive()
    end
end

local function startTimer()
    if _checkTimer then
        return
    end
    _checkTimer = hs.timer.new(CHECK_EVERY, checkIdleAndMaybeKeepAlive)
    _checkTimer:start()
    print(string.format("⏱️ Idle keep-alive timer started (every %ss, threshold %ss).", CHECK_EVERY, IDLE_THRESHOLD))
end

local function stopTimer()
    if _checkTimer then
        _checkTimer:stop()
        _checkTimer = nil
        print("🛑 Idle keep-alive timer stopped.")
    end
end

-- ===== Watchers =====
local function handleAppEvent(appName, event, app)
    -- Maintain active count for target apps
    if not app then
        app = hs.application.get(appName)
    end
    local isTarget = app and appIsTarget(app)

    if event == hs.application.watcher.launched or event == hs.application.watcher.activated then
        if isTarget then
            _activeCount = _activeCount + 1
        end
    elseif event == hs.application.watcher.terminated then
        if isTarget and _activeCount > 0 then
            _activeCount = _activeCount - 1
        end
    end

    -- Start/stop timer based on count
    if anyTargetAppRunning() then
        startTimer()
    else
        stopTimer()
    end
end

local function handleCaffeinateEvent(e)
    -- Pause timer when sleeping; resume after wake
    if e == hs.caffeinate.watcher.systemWillSleep or e == hs.caffeinate.watcher.screensDidSleep or e ==
        hs.caffeinate.watcher.screensDidLock then
        stopTimer()
    elseif e == hs.caffeinate.watcher.systemDidWake or e == hs.caffeinate.watcher.screensDidWake or e ==
        hs.caffeinate.watcher.screensDidUnlock or e == hs.caffeinate.watcher.sessionDidBecomeActive then
        if anyTargetAppRunning() then
            startTimer()
        end
    end
end

-- ===== Public API =====
function M.start(opts)
    -- Allow runtime overrides
    if type(opts) == "table" then
        M.config.app_names = opts.app_names or M.config.app_names
        M.config.bundle_ids = opts.bundle_ids or M.config.bundle_ids
    end

    -- Seed active count and timer
    _activeCount = scanRunningTargets()
    if anyTargetAppRunning() then
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

    print(string.format("✅ idle_keepalive started. Watching %d names / %d bundle IDs.", #(M.config.app_names or {}),
        #(M.config.bundle_ids or {})))
end

function M.stop()
    if _appWatcher then
        _appWatcher:stop();
        _appWatcher = nil
    end
    if _cafWatcher then
        _cafWatcher:stop();
        _cafWatcher = nil
    end
    stopTimer()
    _busy = false
    print("🛑 idle_keepalive stopped.")
end

return M
