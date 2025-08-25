-- ~/.hammerspoon/modules/auto_fullscreen.lua
local M = {}

M.config = {
    native_fullscreen = false, -- false = maximize (Spectacle style), true = macOS native fullscreen (Spaces)
    internal_hint = "Built%-in", -- hint to detect internal screen name
    exclude_apps = {"Terminal", "iTerm2"}, -- apps to ignore (never touch)
    screens_settle_seconds = 2.0, -- pause after screens change
    quarantine_seconds = 12.0, -- skip windows auto-fullscreen if moved by a screens change

    -- NEW: center-only rules (do not maximize; just center H+V)
    center_only_apps = {"System Settings", "System Preferences", "Archive Utility", "Installer"},
    center_only_bundle_ids = {"com.apple.systempreferences", -- macOS ≤ Monterey
    "com.apple.systemsettings", -- macOS Ventura+
    "com.apple.archiveutility", "com.apple.installer"},
    center_only_roles = {"AXDialog", "AXSystemDialog", "AXSheet"}, -- copy/move/extract sheets & dialogs
    center_only_title_patterns = {"Copy", "Moving", "Extract", "Compress", "Deleting", "Transfer", "Copying"}
}

-- ========================
-- Helpers
-- ========================
local function internalScreen(config)
    return hs.screen.find(config.internal_hint) or hs.screen.primaryScreen()
end

local function screenUUID(scr)
    if not scr then
        return nil
    end
    -- Use dot to *check* method existence, colon to *call* it
    return (scr.getUUID and scr:getUUID()) or (scr:name() .. ":" .. tostring(scr:id()))
end

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

local function anyEquals(val, list)
    for _, v in ipairs(list or {}) do
        if val == v then
            return true
        end
    end
    return false
end

local function titleMatches(win, patterns)
    local t = (win and win:title()) or ""
    for _, pat in ipairs(patterns or {}) do
        if t:find(pat) then
            return true
        end
    end
    return false
end

local function shouldCenterOnly(win, config)
    if not win then
        return true
    end

    -- Non-standard windows (sheets, panels, etc.) → center-only
    if not win:isStandard() then
        return true
    end

    -- Role/subrole rules (dialogs/sheets)
    local role = win:role() or ""
    local subrole = win:subrole() or ""
    if anyEquals(role, config.center_only_roles or {}) or anyEquals(subrole, config.center_only_roles or {}) then
        return true
    end

    -- App rules (name or bundle ID)
    local app = win:application()
    local appName = app and app:name() or ""
    if anyEquals(appName, config.center_only_apps or {}) then
        return true
    end
    local bundleID = app and app:bundleID() or ""
    if anyEquals(bundleID, config.center_only_bundle_ids or {}) then
        return true
    end

    -- Title patterns (copy/move/extract progress, etc.)
    if titleMatches(win, config.center_only_title_patterns or {}) then
        return true
    end

    -- If not resizable, don't try to maximize
    if win.isResizable and not win:isResizable() then
        return true
    end

    return false
end

local function centerWindow(win, opts)
    if not win then
        return
    end
    local scrFrame = win:screen():frame()
    local f = win:frame()
    f.x = scrFrame.x + (scrFrame.w - f.w) / 2
    if opts and opts.vertical then
        f.y = scrFrame.y + (scrFrame.h - f.h) / 2
    else
        f.y = scrFrame.y -- keep top-aligned unless vertical centering requested
    end
    win:setFrame(f)
end

local function nearlyEqual(a, b, eps)
    eps = eps or 2
    return math.abs(a - b) <= eps
end

local function framesRoughlyEqual(a, b)
    return nearlyEqual(a.x, b.x) and nearlyEqual(a.y, b.y) and nearlyEqual(a.w, b.w) and nearlyEqual(a.h, b.h)
end

local function fillWindow(win, config)
    if not win or isExcluded(win, config) then
        return
    end

    -- If native fullscreen requested, only apply to standard windows not in center-only set
    if config.native_fullscreen and win:isStandard() and not shouldCenterOnly(win, config) then
        if not win:isFullScreen() then
            win:setFullScreen(true)
        end
        return
    end

    -- Center-only branch: DO NOT maximize; just center both axes
    if shouldCenterOnly(win, config) then
        centerWindow(win, {
            vertical = true
        })
        return
    end

    -- Maximize for standard, allowed windows — then recenter horizontally
    local before = win:frame()
    win:maximize()
    local after = win:frame()

    -- If maximizing didn't change frame, revert and fully center
    if framesRoughlyEqual(before, after) then
        win:setFrame(before)
        centerWindow(win, {
            vertical = true
        })
    else
        centerWindow(win, {
            vertical = false
        })
    end
end

-- ========================
-- State
-- ========================
M._wf = nil
M._running = false

M._screensChanging = false
M._screensChangeTimer = nil
M._lastScreenChangeAt = 0

M._winLastScreen = {} -- [win:id()] = screenUUID
M._quarantine = {} -- [win:id()] = epochSecondsExpiry

local function now()
    return hs.timer.secondsSinceEpoch()
end

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

local function markQuarantine(win, seconds)
    local id = win and win:id()
    if not id then
        return
    end
    M._quarantine[id] = now() + (seconds or M.config.quarantine_seconds)
end

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

local function lastScreenUUID(win)
    local id = win and win:id()
    if not id then
        return nil
    end
    return M._winLastScreen[id]
end

local function ensureFilter()
    if M._wf then
        return M._wf
    end
    M._wf = hs.window.filter.new()
    return M._wf
end

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

-- ========================
-- Watchers
-- ========================
local function handleScreensChanged()
    M._screensChanging = true
    M._lastScreenChangeAt = now()
    if M._screensChangeTimer then
        M._screensChangeTimer:stop()
    end
    M._screensChangeTimer = hs.timer.doAfter(M.config.screens_settle_seconds, function()
        M._screensChanging = false
        for id, exp in pairs(M._quarantine) do
            if now() > exp + 30 then
                M._quarantine[id] = nil
            end
        end
        print("[auto_fullscreen] screens settled")
    end)
    print("[auto_fullscreen] screens changing...")
end

local function subscribeWatchers()
    if not M._screenWatcher then
        M._screenWatcher = hs.screen.watcher.new(handleScreensChanged)
        M._screenWatcher:start()
    end
    if not M._cafWatcher then
        M._cafWatcher = hs.caffeinate.watcher.new(function(event)
            if event == hs.caffeinate.watcher.screensDidSleep or event == hs.caffeinate.watcher.screensDidWake or event ==
                hs.caffeinate.watcher.systemWillSleep or event == hs.caffeinate.watcher.systemDidWake then
                handleScreensChanged()
            end
        end)
        M._cafWatcher:start()
    end
end

-- ========================
-- API
-- ========================
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
