-- ~/.hammerspoon/modules/idle_keepalive.lua
-- Keep "Available" in selected apps by breaking system idle with a tiny jiggle + desktop click.
local M = {}

-- ===== Config =====
local CHECK_EVERY = 30 -- seconds between checks
local IDLE_THRESHOLD = 30 -- seconds of inactivity required to trigger
local JIGGLE_OFFSET = 1 -- pixels to nudge the pointer
local FINDER_WAIT = 0.15 -- seconds to wait after focusing Finder before clicking

-- Target apps (names and/or bundle IDs). Match is OR between lists.
M.config = {
    app_names = {"Microsoft Teams", "Zoom", "Slack"},
    bundle_ids = {"com.microsoft.teams2"} -- add more if you need
}

-- ===== Internals =====
local _appWatcher = nil
local _checkTimer = nil
local _cafWatcher = nil
local _busy = false
local _debouncers = {}

-- ===== Helpers =====
local function debounce(key, delay, fn)
    local t = _debouncers[key]
    if t then
        t:stop()
    end
    _debouncers[key] = hs.timer.doAfter(delay, function()
        _debouncers[key] = nil
        fn()
    end)
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

local function targetsRunningNow()
    for _, app in ipairs(hs.application.runningApplications()) do
        if appIsTarget(app) then
            return true
        end
    end
    return false
end

local function startTimer()
    if _checkTimer then
        return
    end
    _checkTimer = hs.timer.new(CHECK_EVERY, function()
        -- Only act if targets currently running
        if not targetsRunningNow() then
            -- stop if no longer needed
            _checkTimer:stop();
            _checkTimer = nil
            print("🛑 Idle keep-alive timer stopped (no target apps).")
            return
        end
        -- Skip if screens are locked/asleep
        if hs.caffeinate.get("screensLocked") or hs.caffeinate.get("displayIdle") then
            return
        end
        local idle = hs.host.idleTime()
        if idle >= IDLE_THRESHOLD then
            -- perform keep-alive
            if not _busy then
                _busy = true
                local p = hs.mouse.absolutePosition()
                -- tiny jiggle
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
                -- safe desktop click via Finder, then restore previous app
                local prev = hs.application.frontmostApplication()
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
                hs.application.launchOrFocus("Finder")
                hs.timer.doAfter(FINDER_WAIT, function()
                    hs.mouse.absolutePosition(center)
                    hs.eventtap.leftClick(center)
                    if prev and prev:bundleID() ~= "com.apple.finder" then
                        prev:activate(true)
                    end
                    _busy = false
                    print("🖱️ Keep-alive: jiggle + desktop click")
                end)
            end
        end
    end)
    _checkTimer:start()
    print(string.format("⏱️ Idle keep-alive timer started (every %ss, threshold %ss).", CHECK_EVERY, IDLE_THRESHOLD))
end

local function stopTimer()
    if _checkTimer then
        _checkTimer:stop();
        _checkTimer = nil
    end
end

-- ===== Watchers =====
local function handleAppEvent(appName, event, app)
    -- We only care about launched/terminated; recalc on each event
    if event == hs.application.watcher.launched or event == hs.application.watcher.terminated then
        if targetsRunningNow() then
            startTimer()
        else
            stopTimer()
            print("🛑 Idle keep-alive paused (no target apps).")
        end
    end
end

local function handleCaffeinateEvent(e)
    if e == hs.caffeinate.watcher.systemWillSleep or e == hs.caffeinate.watcher.screensDidSleep or e ==
        hs.caffeinate.watcher.screensDidLock then
        stopTimer()
    elseif e == hs.caffeinate.watcher.systemDidWake or e == hs.caffeinate.watcher.screensDidWake or e ==
        hs.caffeinate.watcher.screensDidUnlock or e == hs.caffeinate.watcher.sessionDidBecomeActive then
        -- resume only if we currently need it
        if targetsRunningNow() then
            startTimer()
        end
    end
end

-- ===== Public API =====
function M.start(opts)
    if type(opts) == "table" then
        M.config.app_names = opts.app_names or M.config.app_names
        M.config.bundle_ids = opts.bundle_ids or M.config.bundle_ids
    end

    -- Start timer only if needed right now
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
    for _, t in pairs(_debouncers) do
        if t then
            t:stop()
        end
    end
    _debouncers = {}
    _busy = false
    print("🛑 idle_keepalive stopped.")
end

return M
