-- luacheck: globals hs
-- luacheck: max line length 120
-- ~/.hammerspoon/modules/move_window_space.lua
-- Module: move_window_space
-- Purpose: Sends the focused window to the next/previous Space (desktop) on its screen and follows it.
-- Usage: require this module and call M.bindHotkey() to enable Alt+Right / Alt+Left.
-- Last updated: 2026-10-14

local M = {}

local GRAB_DELAY = 0.15 -- seconds between mouse-down, drag and the Space shortcut
local RELEASE_DELAY = 1.0 -- seconds to let the Space animation finish before releasing the title bar

--- Returns the window's index among its screen's Spaces, and that list.
local function spaceIndex(win)
    local spaces = hs.spaces.spacesForScreen(win:screen())
    local current = (hs.spaces.windowSpaces(win) or {})[1]
    if not spaces or not current then return nil end
    for i, id in ipairs(spaces) do
        if id == current then return i, spaces end
    end
    return nil
end

--- Point on the title bar, just right of the traffic lights, safe to press and drag.
local function titleBarPoint(win)
    local z = win:zoomButtonRect()
    if z then return {x = z.x + z.w + 40, y = z.y + z.h / 2} end
    local f = win:frame()
    return {x = f.x + f.w / 2, y = f.y + 10}
end

--- Moves the focused window `step` Spaces away (+1 right, -1 left) and follows it.
-- hs.spaces.moveWindowToSpace/gotoSpace are silently ignored on recent macOS, so the window
-- is held by its title bar while the "Move right/left a space" shortcut (Ctrl+Arrow, needs
-- the fn flag) carries it along.
local function moveFocusedWindow(step)
    local win = hs.window.focusedWindow()
    if not win or win:isFullScreen() then return end
    local i, spaces = spaceIndex(win)
    if not i or not spaces[i + step] then return end

    local types = hs.eventtap.event.types
    local origin = hs.mouse.absolutePosition()
    local p = titleBarPoint(win)
    local dragged = {x = p.x + 4, y = p.y}
    local key = step > 0 and "right" or "left"

    hs.mouse.absolutePosition(p)
    hs.eventtap.event.newMouseEvent(types.leftMouseDown, p):post()
    hs.timer.doAfter(GRAB_DELAY, function()
        hs.eventtap.event.newMouseEvent(types.leftMouseDragged, dragged):post()
        hs.timer.doAfter(GRAB_DELAY, function()
            hs.eventtap.keyStroke({"ctrl", "fn"}, key, 0)
            hs.timer.doAfter(RELEASE_DELAY, function()
                hs.eventtap.event.newMouseEvent(types.leftMouseUp, dragged):post()
                hs.mouse.absolutePosition(origin)
            end)
        end)
    end)
end

--- Binds Alt+Right / Alt+Left to send the focused window to the adjacent Space.
function M.bindHotkey()
    hs.hotkey.bind({"alt"}, "right", function() moveFocusedWindow(1) end)
    hs.hotkey.bind({"alt"}, "left", function() moveFocusedWindow(-1) end)
end

return M
