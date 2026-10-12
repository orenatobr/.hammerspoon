-- luacheck: globals hs
-- luacheck: max line length 120
-- ~/.hammerspoon/modules/passwords_hotkey.lua
-- Module: passwords_hotkey
-- Purpose: Binds Alt+P to open the Passwords quick-access popover (menu bar extra).
-- Usage: require this module and call M.bindHotkey().

local M = {}

local BUNDLE_ID = "com.apple.Passwords.MenuBarExtra"
local EXTRA_PATH = "/System/Applications/Passwords.app/Contents/Library/LoginItems/PasswordsMenuBarExtra.app"

--- Clicks the Passwords menu bar item, which toggles the quick-access popover.
-- A real click is needed: AXPress on this status item does not open the popover.
function M.open()
    local app = hs.application.get(BUNDLE_ID)
    if not app then
        hs.task.new("/usr/bin/open", nil, { "-g", EXTRA_PATH }):start()
        app = hs.application.get(BUNDLE_ID)
    end
    local bar = app and hs.axuielement.applicationElement(app):attributeValue("AXExtrasMenuBar")
    local item = bar and (bar:attributeValue("AXChildren") or {})[1]
    if not item then
        hs.alert.show("⚠️ Senhas: menu bar item not found")
        return false
    end
    local f = item:attributeValue("AXFrame")
    local mouse = hs.mouse.absolutePosition()
    hs.eventtap.leftClick({ x = f.x + f.w / 2, y = f.y + f.h / 2 })
    hs.mouse.absolutePosition(mouse)
    return true
end

--- Binds Alt+P to open the Passwords quick-access popover.
function M.bindHotkey()
    hs.hotkey.bind({"alt"}, "P", M.open)
end

return M
