-- luacheck: globals hs
local M = {}
local ok, keepalive = pcall(require, "modules.idle_keepalive")
-- ===== Config =====
local OPEN_DELAY = 0.05 -- minimal delay to avoid holding screen wake-up
local CLOSE_DELAY = 0.4 -- wait after lid close before sleeping displays
-- Polling is only a fallback; screen/caffeinate watchers catch most transitions.
-- 0.25s (#4/s) was spawning ioreg shell processes at very high rate.
local LID_POLL_INTERVAL = 10.0
local DISPLAY_SLEEP_RETRIES = 4
local DISPLAY_SLEEP_RETRY_INTERVAL = 1.0
local INTERNAL_HINTS = {"built%-in", "liquid retina", "color lcd"}

-- ===== Internal =====
local lastInternalPresent = nil
local detectedLidClosed = nil
local appliedLidClosed = nil
M._screenWatcher = nil
M._lidWatcher = nil
M._cafWatcher = nil
M._closeDebouncer = nil
M._openDebouncer = nil
M._displaySleepTimers = {}

-- ===== Helpers =====
local function internalDisplayPresent()
    for _, s in ipairs(hs.screen.allScreens()) do
        local nm = (s:name() or ""):lower()
        for _, pat in ipairs(INTERNAL_HINTS) do

            if nm:match(pat) then
                return true
            end
        end
    end
    return false
end

local function debounce(timerKey, delay, fn)
    if M[timerKey] then
        M[timerKey]:stop()
    end
    M[timerKey] = hs.timer.doAfter(delay, function()
        M[timerKey] = nil
        fn()
    end)
end

local function cancelTimer(timerKey)
    if M[timerKey] then
        M[timerKey]:stop()
        M[timerKey] = nil
    end
end

local function stopDisplaySleepReinforcement()
    for _, timer in ipairs(M._displaySleepTimers) do
        timer:stop()
    end
    M._displaySleepTimers = {}
end

local function isLidClosed()
    -- internalDisplayPresent() usa a API nativa do Hammerspoon e é equivalente
    -- ao ioreg, sem spawnar um processo filho a cada chamada.
    return not internalDisplayPresent()
end

local function setKeepaliveLidClosed(isClosed, reason)
    if ok and keepalive and keepalive.setLidClosed then
        keepalive.setLidClosed(isClosed, reason)
    end
end

local function forceDisplaySleep()
    if hs.caffeinate and hs.caffeinate.set then
        hs.caffeinate.set('displayIdle', false, true)
    end

    if hs.execute then
        hs.execute('/usr/bin/pmset displaysleepnow', true)
    end
end

local function reinforceDisplaySleep()
    stopDisplaySleepReinforcement()

    for attempt = 1, DISPLAY_SLEEP_RETRIES do
        local timer = hs.timer.doAfter(attempt * DISPLAY_SLEEP_RETRY_INTERVAL, function()
            if appliedLidClosed then
                forceDisplaySleep()
            end
        end)
        table.insert(M._displaySleepTimers, timer)
    end
end

-- ===== Actions =====
local function onLidClosed()
    cancelTimer("_openDebouncer")
    debounce("_closeDebouncer", CLOSE_DELAY, function()
        if appliedLidClosed then
            return
        end
        appliedLidClosed = true
        setKeepaliveLidClosed(true, "lid closed")
        forceDisplaySleep()
        reinforceDisplaySleep()
        print("🌙 Lid closed — displays slept")
    end)
end

local function onLidOpened()
    stopDisplaySleepReinforcement()
    cancelTimer("_closeDebouncer")
    debounce("_openDebouncer", OPEN_DELAY, function()
        if appliedLidClosed == false then
            return
        end
        appliedLidClosed = false
        setKeepaliveLidClosed(false, "lid opened")
        print("🔓 Lid opened")
    end)
end

local function syncLidState()
    local present = internalDisplayPresent()
    local lidClosed = isLidClosed()

    if lastInternalPresent == nil then
        lastInternalPresent = present
    end

    if detectedLidClosed == nil then
        detectedLidClosed = lidClosed
        appliedLidClosed = lidClosed
        return
    end

    if lidClosed == detectedLidClosed then
        lastInternalPresent = present
        return
    end

    detectedLidClosed = lidClosed

    if lidClosed then
        onLidClosed()
    else
        onLidOpened()
    end

    lastInternalPresent = present
end

local function handlePowerEvent(event)
    if event == hs.caffeinate.watcher.systemDidWake or
        event == hs.caffeinate.watcher.screensDidWake or
        event == hs.caffeinate.watcher.screensDidUnlock or
        event == hs.caffeinate.watcher.systemWillSleep or
        event == hs.caffeinate.watcher.screensDidSleep then
        syncLidState()
    end
end

-- ===== Public API =====
function M.start()
    if not M._screenWatcher then
        M._screenWatcher = hs.screen.watcher.new(syncLidState)
        M._screenWatcher:start()
        lastInternalPresent = internalDisplayPresent()
        detectedLidClosed = isLidClosed()
        appliedLidClosed = detectedLidClosed
        M._lidWatcher = hs.timer.doEvery(LID_POLL_INTERVAL, syncLidState)
        if hs.caffeinate and hs.caffeinate.watcher and hs.caffeinate.watcher.new then
            M._cafWatcher = hs.caffeinate.watcher.new(handlePowerEvent)
            M._cafWatcher:start()
        end
        print("✅ auto_lock started (display sleep on lid close)")
    end
end

function M.stop()
    if M._screenWatcher then
        M._screenWatcher:stop()
        M._screenWatcher = nil
    end
    cancelTimer("_closeDebouncer")
    cancelTimer("_openDebouncer")
    if M._lidWatcher then
        M._lidWatcher:stop()
        M._lidWatcher = nil
    end
    if M._cafWatcher then
        M._cafWatcher:stop()
        M._cafWatcher = nil
    end
    stopDisplaySleepReinforcement()
    detectedLidClosed = nil
    appliedLidClosed = nil
    print("🛑 auto_lock stopped")
end

return M
