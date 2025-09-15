-- ~/.hammerspoon/modules/idle_keepalive.lua
-- Keep "Available" in selected apps by breaking system idle with a tiny mouse jiggle + (safe) click.
-- Focus is never changed. For left-click, we pick an empty Desktop pixel to avoid UI actions.
local M = {}

-- ===== Config =====
local CHECK_EVERY = 30 -- seconds between checks
local IDLE_THRESHOLD = 30 -- seconds of inactivity required to trigger
local JIGGLE_OFFSET = 1 -- pixels to nudge the pointer
local JIGGLE_BACKOFF = 0.08 -- seconds between out-and-back

-- Click settings
local DO_MOUSE_CLICK = true -- also click to satisfy click counters
local CLICK_BUTTON = "left" -- "left" | "middle" | "right"
local CLICK_DELAY = 0.0 -- optional hs.eventtap click delay
local RESTORE_POINTER = true -- move pointer back after a desktop click

-- Safe-desktop search
local SAFE_MARGIN = 48 -- inset from screen edges for candidate points
local SAFE_GRID_STEP = 160 -- grid spacing for candidate points when scanning
-- Note: larger SAFE_MARGIN avoids menu bar/dock hot corners; grid tries many points.

-- Target apps (names and/or bundle IDs). Match is OR between lists.
M.config = {
    app_names = {"Microsoft Teams", "Zoom", "Slack"},
    bundle_ids = {"com.microsoft.teams2", "com.microsoft.teams"} -- new+classic Teams
}

-- ===== Internals =====
local _appWatcher = nil
local _checkTimer = nil
local _cafWatcher = nil
local _busy = false

-- ===== Helpers =====
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

local function tinyJiggle()
    local p = hs.mouse.absolutePosition()
    -- 1px move and back — doesn’t change focus
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

-- ----- Safe Desktop click support -----
local function pointInFrame(pt, fr)
    return pt.x >= fr.x and pt.x <= fr.x + fr.w and pt.y >= fr.y and pt.y <= fr.y + fr.h
end

local function pointCoveredByAnyWindow(pt, windows)
    for _, w in ipairs(windows) do
        local f = w:frame()
        if f and pointInFrame(pt, f) then
            return true
        end
    end
    return false
end

-- Try to find a pixel on the primary screen that is not covered by any visible window
local function findSafeDesktopPoint()
    local scr = hs.screen.primaryScreen()
    if not scr then
        return nil
    end
    local sf = scr:frame()

    -- Get list of visible, standard windows in current Space (no hidden/minimized)
    local wf = hs.window.filter.new():setCurrentSpace(true):setDefaultFilter{
        visible = true,
        currentSpace = true,
        allowScreens = {scr:id()},
        allowTitles = hs.window.filter.ignoreAlways, -- we don't filter by title; just faster
        allowRoles = {"AXStandardWindow"}
    }

    local windows = wf:getWindows()

    -- Candidate points: corners/edges inset + a coarse grid scan
    local candidates = {}

    local function add(x, y)
        table.insert(candidates, {
            x = math.floor(x),
            y = math.floor(y)
        })
    end

    local m = SAFE_MARGIN
    -- corners (inset)
    add(sf.x + m, sf.y + m)
    add(sf.x + sf.w - m, sf.y + m)
    add(sf.x + m, sf.y + sf.h - m)
    add(sf.x + sf.w - m, sf.y + sf.h - m)
    -- edges midpoints (inset)
    add(sf.x + sf.w / 2, sf.y + m)
    add(sf.x + sf.w / 2, sf.y + sf.h - m)
    add(sf.x + m, sf.y + sf.h / 2)
    add(sf.x + sf.w - m, sf.y + sf.h / 2)
    -- center-ish points
    add(sf.x + sf.w * 0.25, sf.y + sf.h * 0.25)
    add(sf.x + sf.w * 0.75, sf.y + sf.h * 0.25)
    add(sf.x + sf.w * 0.25, sf.y + sf.h * 0.75)
    add(sf.x + sf.w * 0.75, sf.y + sf.h * 0.75)

    -- grid scan
    local step = SAFE_GRID_STEP
    for y = sf.y + m, sf.y + sf.h - m, step do
        for x = sf.x + m, sf.x + sf.w - m, step do
            add(x, y)
        end
    end

    -- pick first candidate that is not covered by any window
    for _, pt in ipairs(candidates) do
        if not pointCoveredByAnyWindow(pt, windows) then
            return pt
        end
    end

    return nil -- none found (e.g., full-screen app)
end

local function safeClickLeft()
    -- Try to click only on the Desktop; if we can't find a safe pixel, skip left-click.
    local original = hs.mouse.absolutePosition()
    local safePt = findSafeDesktopPoint()
    if not safePt then
        -- Fallback: avoid risky left-click; choose middle click instead to still count
        if hs.eventtap.middleClick then
            hs.eventtap.middleClick(original, CLICK_DELAY)
        else
            hs.eventtap.otherClick(original, 2)
        end
        return
    end
    hs.mouse.absolutePosition(safePt)
    hs.eventtap.leftClick(safePt, CLICK_DELAY)
    if RESTORE_POINTER then
        hs.mouse.absolutePosition(original)
    end
end

local function safeClickAtPointer()
    if not DO_MOUSE_CLICK then
        return
    end
    local p = hs.mouse.absolutePosition()
    if CLICK_BUTTON == "left" then
        safeClickLeft()
    elseif CLICK_BUTTON == "right" then
        hs.eventtap.rightClick(p, CLICK_DELAY)
    else
        -- middle (default)
        if hs.eventtap.middleClick then
            hs.eventtap.middleClick(p, CLICK_DELAY)
        else
            hs.eventtap.otherClick(p, 2)
        end
    end
end

-- ===== Timer core =====
local function startTimer()
    if _checkTimer then
        return
    end
    _checkTimer = hs.timer.new(CHECK_EVERY, function()
        if not targetsRunningNow() then
            _checkTimer:stop();
            _checkTimer = nil
            print("🛑 Idle keep-alive timer stopped (no target apps).")
            return
        end

        -- We pause/resume using the caffeinate watcher below; no need to read caffeinate props here.

        local idle = hs.host.idleTime()
        if idle >= IDLE_THRESHOLD and not _busy then
            _busy = true
            tinyJiggle()
            hs.timer.doAfter(JIGGLE_BACKOFF, function()
                safeClickAtPointer()
                _busy = false
                print(string.format("🖱️ Keep-alive: jiggle + %s click%s", CLICK_BUTTON, (CLICK_BUTTON == "left" and
                    (findSafeDesktopPoint() and " (desktop)" or " (fallback)")) or ""))
            end)
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

local function handleCaffeinateEvent(e)
    if e == hs.caffeinate.watcher.systemWillSleep or e == hs.caffeinate.watcher.screensDidSleep or e ==
        hs.caffeinate.watcher.screensDidLock then
        stopTimer()
    elseif e == hs.caffeinate.watcher.systemDidWake or e == hs.caffeinate.watcher.screensDidWake or e ==
        hs.caffeinate.watcher.screensDidUnlock or e == hs.caffeinate.watcher.sessionDidBecomeActive then
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
    _busy = false
    print("🛑 idle_keepalive stopped.")
end

return M
