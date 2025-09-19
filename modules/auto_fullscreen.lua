-- luacheck: ignore hs
-- luacheck: max line length 250

local M = {}

-- ======================================
-- Config (defaults)
-- ======================================
M.config = {
    -- Behavior
    native_fullscreen = false, -- when maximizing a window, use native macOS fullscreen
    internal_hint = "Built%-in", -- regex hint to detect internal screen name (fallback: primary)

    -- App filters
    exclude_apps = {"Terminal", "iTerm2"}, -- never touch these
    maximize_only_apps = {}, -- *only* these apps get maximize/fullscreen; everything else centers by default
    maximize_only_bundle_ids = {}, -- same rule but by bundle id

    -- Stability / UX
    screens_settle_seconds = 2.0, -- pause after screens change
    quarantine_seconds = 12.0 -- skip auto actions on wins moved by a screens change
}

-- ======================================
-- Helpers
-- ======================================
--- Returns the internal screen object based on config hint (fallback: primary screen).
local function internalScreen(config)
    return hs.screen.find(config.internal_hint) or hs.screen.primaryScreen()
end

--- Returns a unique identifier for a screen.
local function screenUUID(scr)
    if not scr then
        return nil
    end
    -- Dot to check, colon to call
    return (scr.getUUID and scr:getUUID()) or (scr:name() .. ":" .. tostring(scr:id()))
end

--- Returns true if the window is on the internal screen.
local function isOnInternalScreen(win, config)
    if not win then
        return false
    end
    local scr = win:screen()
    if not scr then
        return false
    end
    return screenUUID(scr) == screenUUID(internalScreen(config))
end

--- Returns true if the window's app is excluded from auto actions.
local function isExcluded(win, config)
    local app = win and win:application()
    if not app then
        return false
    end
    local name = app:name() or ""
    for _, excluded in ipairs(config.exclude_apps or {}) do
        if name == excluded then
            return true
        end
    end
    return false
end

--- Returns true if val matches any value in list.
local function anyEquals(val, list)
    for _, v in ipairs(list or {}) do
        if val == v then
            return true
        end
    end
    return false
end

--- Returns true if the window should be maximized based on config.
local function shouldMaximize(win, config)
    if not win then
        return false
    end
    local app = win:application()
    local appName = app and app:name() or ""
    if anyEquals(appName, config.maximize_only_apps or {}) then
        return true
    end
    local bundleID = app and app:bundleID() or ""
    if anyEquals(bundleID, config.maximize_only_bundle_ids or {}) then
        return true
    end
    return false
end

-- Only act on windows that actually have standard controls (close/min/zoom)
-- This filters out Dock popovers, sheets without zoom, HUDs, etc.
--- Returns true if the window is standard and resizable.
local function isActionable(win)
    if not win then
        return false
    end
    if not (win.isStandard and win:isStandard()) then
        return false
    end
    if (win.isResizable and not win:isResizable()) then
        return false
    end
    return true
end

--- Centers the window on its screen.
local function centerWindow(win)
    if not win then
        return
    end
    local scr = win:screen()
    if not scr then
        return
    end
    local scrFrame = scr:frame()
    local f = win:frame()
    -- center both axes by default
    f.x = scrFrame.x + (scrFrame.w - f.w) / 2
    f.y = scrFrame.y + (scrFrame.h - f.h) / 2
    win:setFrame(f)
end

--- Returns true if a and b are nearly equal (within eps).
local function nearlyEqual(a, b, eps)
    eps = eps or 2
    return math.abs(a - b) <= eps
end

--- Returns true if two window frames are nearly equal.
local function framesRoughlyEqual(a, b)
    return nearlyEqual(a.x, b.x) and nearlyEqual(a.y, b.y) and nearlyEqual(a.w, b.w) and nearlyEqual(a.h, b.h)
end

--- Maximizes or centers the window based on config and window state.
local function fillWindow(win, config)
    if not win or isExcluded(win, config) then
        return
    end
    if not isActionable(win) then
        return
    end

    local doMax = shouldMaximize(win, config)

    if doMax then
        if config.native_fullscreen and win:isStandard() then
            if not win:isFullScreen() then
                win:setFullScreen(true)
            end
            return
        end
        local before = win:frame()
        win:maximize()
        local after = win:frame()
        -- If maximize was a no-op (non-resizable, tiled, etc.), just center
        if framesRoughlyEqual(before, after) then
            win:setFrame(before)
            centerWindow(win)
        else
            -- After maximizing, re-center horizontally a hair in case of menu bar/tiles
            local f = win:frame()
            local s = win:screen():frame()
            f.x = s.x + (s.w - f.w) / 2
            win:setFrame(f)
        end
    else
        centerWindow(win)
    end
end

-- ======================================
-- State
-- ======================================
M._wf = nil
M._running = false

M._screensChanging = false
M._screensChangeTimer = nil
M._lastScreenChangeAt = 0

M._winLastScreen = {} -- [win:id()] = screenUUID
M._quarantine = {} -- [win:id()] = epochSecondsExpiry

--- Returns the current epoch time in seconds.
local function now()
    return hs.timer.secondsSinceEpoch()
end

--- Returns true if the window is in quarantine (skip auto actions).
local function inQuarantine(win)
    local id = win and win:id()
    if not id then
        return false
    end
    local exp = M._quarantine[id]
    if not exp then
        return false
    end
    if now() < exp then
        return true
    end
    M._quarantine[id] = nil
    return false
end

--- Marks a window as quarantined for a given number of seconds.
local function markQuarantine(win, seconds)
    local id = win and win:id()
    if not id then
        return
    end
    M._quarantine[id] = now() + (seconds or M.config.quarantine_seconds)
end

--- Remembers the screen UUID for a window.
local function rememberScreen(win)
    local id = win and win:id()
    if not id then
        return
    end
    local scr = win:screen()
    if not scr then
        return
    end
    M._winLastScreen[id] = screenUUID(scr)
end

--- Returns the last remembered screen UUID for a window.
local function lastScreenUUID(win)
    local id = win and win:id()
    if not id then
        return nil
    end
    return M._winLastScreen[id]
end

--- Ensures the window filter is created and returns it.
local function ensureFilter()
    if M._wf then
        return M._wf
    end
    M._wf = hs.window.filter.new()
    return M._wf
end

--- Safely fills (maximizes/centers) a window after a short delay, if not quarantined or during screen change.
local function safelyFill(win, config)
    hs.timer.doAfter(0.2, function()
        if not win then
            return
        end
        if M._screensChanging then
            return
        end
        if inQuarantine(win) then
            return
        end
        if isOnInternalScreen(win, config) and not isExcluded(win, config) then
            fillWindow(win, config)
        end
    end)
end

-- NEW: one-shot sweep to fix windows that landed on the internal screen during changes
--- Sweeps all visible windows on the internal screen and fills them if needed.
local function sweepInternalWindows()
    if M._screensChanging then
        return
    end
    -- only visible windows to avoid messing with other Spaces
    for _, win in ipairs(hs.window.visibleWindows()) do
        if win and not inQuarantine(win) and isOnInternalScreen(win, M.config) and not isExcluded(win, M.config) and
            isActionable(win) then
            fillWindow(win, M.config)
        end
    end
end

-- ======================================
-- Watchers
-- ======================================
--- Handles screen change events, sets quarantine, and sweeps windows after settling.
local function handleScreensChanged()
    M._screensChanging = true
    M._lastScreenChangeAt = now()
    if M._screensChangeTimer then
        M._screensChangeTimer:stop()
    end
    M._screensChangeTimer = hs.timer.doAfter(M.config.screens_settle_seconds, function()
        M._screensChanging = false
        -- cleanup stale quarantines
        for id, exp in pairs(M._quarantine) do
            if now() > exp + 30 then
                M._quarantine[id] = nil
            end
        end
        print("[auto_fullscreen] screens settled")

        -- After settling, wait for quarantine to end and then sweep once
        hs.timer.doAfter(M.config.quarantine_seconds + 0.2, function()
            sweepInternalWindows()
        end)
    end)
    print("[auto_fullscreen] screens changing...")
end

--- Subscribes to screen and caffeinate watchers for screen change events.
local function subscribeWatchers()
    if not M._screenWatcher then
        M._screenWatcher = hs.screen.watcher.new(handleScreensChanged)
        M._screenWatcher:start()
    end
    if not M._cafWatcher then
    -- luacheck: ignore event
    M._cafWatcher = hs.caffeinate.watcher.new(function(_)
            if event == hs.caffeinate.watcher.screensDidSleep or event == hs.caffeinate.watcher.screensDidWake or event ==
                hs.caffeinate.watcher.systemWillSleep or event == hs.caffeinate.watcher.systemDidWake then
                handleScreensChanged()
            end
        end)
        M._cafWatcher:start()
    end
end

-- ======================================
-- API
-- ======================================
--- Starts the auto_fullscreen module with optional config overrides.
function M.start(opts)
    if M._running then
        print("[auto_fullscreen] already running")
        return
    end

    M.config = hs.fnutils.copy(M.config)
    if type(opts) == "table" then
        for k, v in pairs(opts) do
            M.config[k] = v
        end
    end

    subscribeWatchers()
    local wf = ensureFilter()

    wf:subscribe(hs.window.filter.windowCreated, function(win)
        rememberScreen(win)
        if M._screensChanging then
            return
        end
        if inQuarantine(win) then
            return
        end
        safelyFill(win, M.config)
    end)

    wf:subscribe(hs.window.filter.windowMoved, function(win)
        if not win then
            return
        end
        local prevUUID = lastScreenUUID(win)
        local currScr = win:screen()
        local currUUID = screenUUID(currScr)
        local internalUUID = screenUUID(internalScreen(M.config))

        if M._screensChanging and prevUUID and prevUUID ~= internalUUID and currUUID == internalUUID then
            markQuarantine(win, M.config.quarantine_seconds)
            print(string.format(
                "[auto_fullscreen] quarantined win %s for %.1fs (external→internal during screens change)",
                tostring(win:id()), M.config.quarantine_seconds))
        end

        rememberScreen(win)

        if M._screensChanging then
            return
        end
        if inQuarantine(win) then
            return
        end
        if isOnInternalScreen(win, M.config) then
            fillWindow(win, M.config)
        end
    end)

    wf:subscribe(hs.window.filter.windowFocused, function(win)
        if M._screensChanging then
            return
        end
        if inQuarantine(win) then
            return
        end
        if isOnInternalScreen(win, M.config) then
            fillWindow(win, M.config)
        end
    end)

    wf:subscribe(hs.window.filter.windowUnminimized, function(win)
        if not win then
            return
        end
        if not isOnInternalScreen(win, M.config) then
            M._quarantine[win:id()] = nil
        end
    end)

    M._running = true
    print("[auto_fullscreen] started with config:", hs.inspect(M.config))
end

--- Stops the auto_fullscreen module and unsubscribes all watchers.
function M.stop()
    if not M._running then
        return
    end
    if M._wf then
        M._wf:unsubscribeAll()
    end
    if M._screenWatcher then
        M._screenWatcher:stop();
        M._screenWatcher = nil
    end
    if M._cafWatcher then
        M._cafWatcher:stop();
        M._cafWatcher = nil
    end
    if M._screensChangeTimer then
        M._screensChangeTimer:stop();
        M._screensChangeTimer = nil
    end
    M._running = false
    hs.alert.show("🛑 Auto-fullscreen disabled")
    print("[auto_fullscreen] stopped")
end

return M
