-- luacheck: globals hs
-- luacheck: max line length 120
-- ~/.hammerspoon/modules/passwords_hotkey.lua
-- Module: passwords_hotkey
-- Purpose: Binds Alt+P (and Ctrl+Alt+P as Secure Input fallback) to open the Passwords popover.
-- Usage: require this module and call M.bindHotkey().

local M = {}

local BUNDLE_ID = "com.apple.Passwords.MenuBarExtra"
local EXTRA_PATH = "/System/Applications/Passwords.app/Contents/Library/LoginItems/PasswordsMenuBarExtra.app"

local RETRIES = 10
local RETRY_DELAY = 0.3

-- Held at module level so the timer is not garbage-collected and presses can be ignored while it runs.
local pending = nil

--- Returns the Passwords menu bar item, or nil when the extra or its AX tree is not ready.
local function findItem()
    local app = hs.application.get(BUNDLE_ID)
    local bar = app and hs.axuielement.applicationElement(app):attributeValue("AXExtrasMenuBar")
    return bar and (bar:attributeValue("AXChildren") or {})[1]
end

local function attempt(tries)
    local item = findItem()
    if item then
        local f = item:attributeValue("AXFrame")
        local mouse = hs.mouse.absolutePosition()
        hs.eventtap.leftClick({ x = f.x + f.w / 2, y = f.y + f.h / 2 })
        hs.mouse.absolutePosition(mouse)
        return true
    end
    if tries > 0 then
        pending = hs.timer.doAfter(RETRY_DELAY, function()
            pending = nil
            attempt(tries - 1)
        end)
    else
        hs.alert.show("⚠️ Senhas: menu bar item not found")
    end
    return false
end

--- Clicks the Passwords menu bar item, which toggles the quick-access popover.
-- A real click is needed: AXPress on this status item does not open the popover.
-- If the extra is not running it is launched once and the click is retried for about 3s.
-- Presses while a retry is pending are ignored, since each click would toggle the popover.
-- @return boolean True when the click was sent immediately.
function M.open()
    if pending then
        return false
    end
    if not hs.application.get(BUNDLE_ID) then
        hs.task.new("/usr/bin/open", nil, { "-g", EXTRA_PATH }):start()
    end
    return attempt(RETRIES)
end

--- Binds Alt+P to open the Passwords quick-access popover.
-- Ctrl+Alt+P is a fallback: while a terminal has Secure Keyboard Entry on (e.g. at a sudo/ssh
-- password prompt) macOS drops Option-only hotkeys, but hotkeys with Ctrl or Cmd still arrive.
function M.bindHotkey()
    local function open() M.open() end
    hs.hotkey.bind({"alt"}, "P", open)
    hs.hotkey.bind({"ctrl", "alt"}, "P", open)
end

return M
