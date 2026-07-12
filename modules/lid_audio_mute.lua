-- luacheck: globals hs
local M = {}

-- ===== Config =====
local INTERNAL_HINTS = {"built%-in", "liquid retina", "color lcd"}
local CLOSE_DELAY = 0.4 -- wait before muting so quick lid bounces don't trigger
local OPEN_DELAY = 0.05 -- minimal delay before unmuting on lid open
local LID_POLL_INTERVAL = 10.0 -- fallback poll; screen/caffeinate watchers catch most transitions

-- ===== Internal =====
local lastInternalPresent = nil
local detectedLidClosed = nil
local appliedLidClosed = nil
M._screenWatcher = nil
M._lidWatcher = nil
M._cafWatcher = nil
M._closeDebouncer = nil
M._openDebouncer = nil

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

local function isLidClosed()
    return not internalDisplayPresent()
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

local function setOutputMuted(muted)
    if hs.audiodevice and hs.audiodevice.defaultOutputDevice then
        local device = hs.audiodevice.defaultOutputDevice()
        if device and device.setOutputMuted then
            device:setOutputMuted(muted)
        end
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
        setOutputMuted(true)
        print("🔇 Lid closed — audio muted")
    end)
end

local function onLidOpened()
    cancelTimer("_closeDebouncer")
    debounce("_openDebouncer", OPEN_DELAY, function()
        if appliedLidClosed == false then
            return
        end
        appliedLidClosed = false
        setOutputMuted(false)
        print("🔊 Lid opened — audio unmuted")
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
        print("✅ lid_audio_mute started (mute audio on lid close)")
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
    detectedLidClosed = nil
    appliedLidClosed = nil
    print("🛑 lid_audio_mute stopped")
end

-- For testing
M._test_isLidClosed = isLidClosed
M._test_syncLidState = syncLidState

return M
