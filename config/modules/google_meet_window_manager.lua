-- luacheck: globals hs
-- luacheck: max line length 120
-- ~/.hammerspoon/modules/google_meet_window_manager.lua
-- Module: google_meet_window_manager
-- Purpose: Enforces a single window for the Google Meet Chrome App (PWA), closing duplicates
--          whenever a new meeting window is created or an old one is focused. Ignores transient
--          windows Meet/Chrome spawn on their own (e.g. the screen-share indicator bar or the
--          share picker), which are not real duplicate meeting windows.
-- Usage: require this module and call M.start() to enable automatic single-window enforcement.
-- Author: [Your Name]
-- Last updated: 2026-07-14

local M = {}

M.config = {
    app_names = {"Meet", "Google Meet"}, -- possible names the Chrome App PWA can register as
    bundle_ids = {}, -- optional, e.g. a specific "com.google.Chrome.app.<id>" once known
    debounce_seconds = 0.3,
    min_width = 400, -- minimum width to be considered a real meeting window
    min_height = 300 -- minimum height to be considered a real meeting window
}

local windowFilter = nil

--- Returns true if the given app matches a configured target name or bundle id.
local function appMatchesTarget(app)
    if not app then
        return false
    end
    local name = app:name() or ""
    local bundle = app:bundleID() or ""
    for _, targetName in ipairs(M.config.app_names) do
        if name == targetName then
            return true
        end
    end
    for _, targetBundle in ipairs(M.config.bundle_ids) do
        if bundle ~= "" and bundle == targetBundle then
            return true
        end
    end
    return false
end

--- Returns true if w is large enough to be a real Meet call window, as opposed to a
--- transient window Meet/Chrome spawns for its own UI (screen-share indicator bar,
--- share picker, etc.), which must never be closed nor treated as a duplicate.
local function isMeetingWindow(w)
    if not w or not w:isStandard() then
        return false
    end
    local ok, size = pcall(function()
        return w:size()
    end)
    if not ok or not size then
        return true
    end
    return size.w >= M.config.min_width and size.h >= M.config.min_height
end

--- Closes every other real meeting window belonging to win's app, then focuses win.
local function keepOnly(win)
    if not win or not win:isStandard() then
        return
    end
    local app = win:application()
    if not appMatchesTarget(app) then
        return
    end
    if not isMeetingWindow(win) then
        -- win is a transient window (e.g. screen-share bar/picker); leave everything alone.
        return
    end

    local standardWindows = {}
    for _, w in ipairs(app:allWindows()) do
        if isMeetingWindow(w) then
            table.insert(standardWindows, w)
        end
    end
    if #standardWindows <= 1 then
        return
    end

    local keptId = win:id()
    for _, w in ipairs(standardWindows) do
        if w:id() ~= keptId then
            print("🪟 [GoogleMeet] Closing duplicate window: " .. tostring(w:title()))
            w:close()
        end
    end
    win:focus()
end

--- Collapses any pre-existing duplicate windows (e.g. after a Hammerspoon config reload).
local function sweepExistingWindows()
    for _, app in ipairs(hs.application.runningApplications()) do
        if appMatchesTarget(app) then
            local standardWindows = {}
            for _, w in ipairs(app:allWindows()) do
                if isMeetingWindow(w) then
                    table.insert(standardWindows, w)
                end
            end
            if #standardWindows > 1 then
                local keep = (app.mainWindow and app:mainWindow()) or standardWindows[1]
                if not keep or not isMeetingWindow(keep) then
                    keep = standardWindows[1]
                end
                keepOnly(keep)
            end
        end
    end
end

--- Starts watching Google Meet windows and enforcing a single-window policy.
function M.start(opts)
    opts = opts or {}
    if opts.app_names then
        M.config.app_names = opts.app_names
    end
    if opts.bundle_ids then
        M.config.bundle_ids = opts.bundle_ids
    end
    if opts.debounce_seconds then
        M.config.debounce_seconds = opts.debounce_seconds
    end

    windowFilter = hs.window.filter.new(false)
    for _, name in ipairs(M.config.app_names) do
        windowFilter:setAppFilter(name, {allowRoles = "*"})
    end

    -- luacheck: ignore appName event
    windowFilter:subscribe({hs.window.filter.windowCreated, hs.window.filter.windowFocused},
        function(win, appName, event)
            hs.timer.doAfter(M.config.debounce_seconds, function()
                keepOnly(win)
            end)
        end)

    sweepExistingWindows()

    print("👀 [GoogleMeet] Watching for duplicate windows")
end

--- Stops watching Google Meet windows.
function M.stop()
    if windowFilter then
        windowFilter:unsubscribeAll()
        windowFilter = nil
    end
end

-- For testing
M._test_appMatchesTarget = appMatchesTarget
M._test_isMeetingWindow = isMeetingWindow
M._test_keepOnly = keepOnly
M._test_sweepExistingWindows = sweepExistingWindows

return M
