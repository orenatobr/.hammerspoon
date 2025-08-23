-- ~/.hammerspoon/modules/auto_fullscreen.lua
local M = {}

M.config = {
    native_fullscreen = false, -- false = maximize (Spectacle style), true = macOS native fullscreen (Spaces)
    internal_hint = "Built%-in", -- hint to detect internal screen name
    exclude_apps = {"Terminal", "iTerm2"} -- apps to ignore
}

-- ========================
-- Helpers
-- ========================
local function internalScreen(config)
    return hs.screen.find(config.internal_hint) or hs.screen.primaryScreen()
end

local function isOnInternalScreen(win, config)
    if not win then
        return false
    end
    local scr = win:screen()
    if not scr then
        return false
    end
    return scr == internalScreen(config)
end

local function isExcluded(win, config)
    local app = win:application()
    if not app then
        return false
    end
    local name = app:name()
    for _, excluded in ipairs(config.exclude_apps or {}) do
        if name == excluded then
            return true
        end
    end
    return false
end

local function centerWindow(win)
    local screenFrame = win:screen():frame()
    local frame = win:frame()
    frame.x = screenFrame.x + (screenFrame.w - frame.w) / 2
    frame.y = screenFrame.y -- keep it top aligned
    win:setFrame(frame)
end

local function fillWindow(win, config)
    if not win or not win:isStandard() or isExcluded(win, config) then
        return
    end

    if config.native_fullscreen then
        if not win:isFullScreen() then
            win:setFullScreen(true)
        end
    else
        win:maximize()
        centerWindow(win) -- re-center horizontally after maximize
    end
end

local function safelyFill(win, config)
    hs.timer.doAfter(0.2, function()
        if win and win:isStandard() and isOnInternalScreen(win, config) and not isExcluded(win, config) then
            fillWindow(win, config)
        end
    end)
end

-- ========================
-- State
-- ========================
M._wf = nil
M._running = false

local function ensureFilter()
    if M._wf then
        return M._wf
    end
    M._wf = hs.window.filter.new()
    return M._wf
end

-- ========================
-- API
-- ========================
function M.start(opts)
    if M._running then
        print("[auto_fullscreen] already running")
        return
    end

    -- merge config with user options
    M.config = hs.fnutils.copy(M.config)
    if type(opts) == "table" then
        for k, v in pairs(opts) do
            M.config[k] = v
        end
    end

    local wf = ensureFilter()

    wf:subscribe(hs.window.filter.windowCreated, function(win)
        safelyFill(win, M.config)
    end)
    wf:subscribe(hs.window.filter.windowMoved, function(win)
        if isOnInternalScreen(win, M.config) then
            fillWindow(win, M.config)
        end
    end)
    wf:subscribe(hs.window.filter.windowFocused, function(win)
        if isOnInternalScreen(win, M.config) then
            fillWindow(win, M.config)
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
    M._running = false
    hs.alert.show("🛑 Auto-fullscreen disabled")
    print("[auto_fullscreen] stopped")
end

return M
