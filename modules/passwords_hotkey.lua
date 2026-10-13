-- luacheck: globals hs
-- luacheck: max line length 120
-- ~/.hammerspoon/modules/passwords_hotkey.lua
-- Module: passwords_hotkey
-- Purpose: Binds Alt+P (and Ctrl+Alt+P as Secure Input fallback) to open the Passwords popover
-- and lets Up/Down/Return/Escape drive it while it is open.
-- Usage: require this module and call M.bindHotkey().

local M = {}

local BUNDLE_ID = "com.apple.Passwords.MenuBarExtra"
local EXTRA_PATH = "/System/Applications/Passwords.app/Contents/Library/LoginItems/PasswordsMenuBarExtra.app"

local COPY_DELAY = 0.3
local DETAIL_DELAY = 0.1
local DETAIL_POLLS = 15
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

--- Real-clicks the center of an AX element and puts the mouse back where it was.
-- @return boolean False when the element has no frame (e.g. the popover is closing).
local function clickElement(el)
    local f = el:attributeValue("AXFrame")
    if not f then return false end
    local mouse = hs.mouse.absolutePosition()
    hs.eventtap.leftClick({ x = f.x + f.w / 2, y = f.y + f.h / 2 })
    hs.mouse.absolutePosition(mouse)
    return true
end

-- Arrow-key navigation: the popover never becomes the key window, so it ignores keys sent to it.
-- While it is open we own Up/Down/Return/Escape, draw a highlight on the current row and click it.
local nav = nil

local function findOutline(el)
    for _, c in ipairs(el:attributeValue("AXChildren") or {}) do
        if c:attributeValue("AXRole") == "AXOutline" then return c end
        local o = findOutline(c)
        if o then return o end
    end
end

--- Returns the popover window, or nil when it is closed.
local function popoverWindow()
    local app = hs.application.get(BUNDLE_ID)
    return app and (hs.axuielement.applicationElement(app):attributeValue("AXWindows") or {})[1]
end

--- Collects the copyable fields of the item detail screen (username, password...) in screen order.
-- Clicking one of them copies its value.
local function findFields(el, found)
    for _, c in ipairs(el:attributeValue("AXChildren") or {}) do
        local copyable = hs.fnutils.contains(c:actionNames() or {}, "AXShowMenu")
        if copyable and c:attributeValue("AXRole") == "AXStaticText" then
            found[#found + 1] = c
        end
        findFields(c, found)
    end
    return found
end

--- Returns the navigable rows (list rows, or detail fields when there is no list; empty when there is
-- nothing, e.g. no search results) and the window frame, or nil when the popover is closed.
local function popoverRows()
    local win = popoverWindow()
    if not win then return nil end
    local outline = findOutline(win)
    return (outline and outline:attributeValue("AXRows")) or findFields(win, {}), win:attributeValue("AXFrame")
end

--- Moves an index by delta, clamped to 1..count (the first Down from no selection lands on row 1).
function M.step(idx, delta, count)
    return math.max(1, math.min(count, idx + delta))
end

--- True when the frame lies fully inside the popover window (rows scrolled out of view do not).
local function inside(f, win)
    return f and win and f.y >= win.y and f.y + f.h <= win.y + win.h
end

local function stopNav()
    if not nav then return end
    nav.tap:stop()
    nav.canvas:delete()
    nav.watch:stop()
    nav = nil
end

--- Returns the highlighted row when it exists and is visible, else nil.
local function currentRow()
    local rows, win = popoverRows()
    local row = rows and rows[nav.idx]
    if row and inside(row:attributeValue("AXFrame"), win) then return row end
end

--- Redraws the highlight on the current row, or hides it when that row is gone or scrolled away.
local function refresh()
    local rows = popoverRows()
    if not rows then return stopNav() end
    nav.idx = math.min(nav.idx, #rows)
    local row = currentRow()
    if row then
        nav.canvas:frame(row:attributeValue("AXFrame"))
        nav.canvas:show()
    else
        nav.canvas:hide()
    end
end

--- Moves the highlight by delta. Returns false (key passes through) when there is nothing to move over.
local function move(delta)
    local rows = popoverRows()
    if not rows or #rows == 0 then return false end
    nav.idx = M.step(nav.idx, delta, #rows)
    rows[nav.idx]:performAction("AXScrollToVisible")
    refresh()
    return true
end

--- Returns the first button of the popover (the "back" button on the item detail screen).
local function firstButton(el)
    for _, c in ipairs(el:attributeValue("AXChildren") or {}) do
        if c:attributeValue("AXRole") == "AXButton" then return c end
        local b = firstButton(c)
        if b then return b end
    end
end

--- Clicks the highlighted row: opens a list item, or copies a detail field.
local function enterRow()
    local row = currentRow()
    if not row then return false end
    return clickElement(row)
end

--- True on the item detail screen: no list, but copyable fields (an empty search has neither).
local function inDetail()
    local win = popoverWindow()
    return win ~= nil and findOutline(win) == nil and #findFields(win, {}) > 0
end

--- Goes back from the item detail screen. The list screen has an outline, the detail screen does not.
local function goBack()
    if not inDetail() then return false end
    local button = firstButton(popoverWindow())
    return button ~= nil and button:performAction("AXPress") ~= nil
end

--- Closes the popover by clicking its menu bar item again.
local function closePopover()
    local item = popoverWindow() and findItem()
    if not item then return false end
    clickElement(item)
    return true
end

--- Lets the copy click land, then closes the popover.
local function finishCopy()
    hs.timer.doAfter(COPY_DELAY, closePopover)
end

--- Waits for the detail screen to load, clicks its password field (the masked one, else the last) and closes.
local function copyPasswordWhenReady(tries)
    if inDetail() then
        local fields = findFields(popoverWindow(), {})
        local target = fields[#fields]
        for _, f in ipairs(fields) do
            if tostring(f:attributeValue("AXValue")):find("^•") then target = f end
        end
        if target and clickElement(target) then finishCopy() end
    elseif tries > 0 then
        hs.timer.doAfter(DETAIL_DELAY, function() copyPasswordWhenReady(tries - 1) end)
    end
end

-- Key handlers: return true to consume the key, false to let it through to the focused app.
local handlers = {
    down = function() return move(1) end,
    up = function() return move(-1) end,
    -- Right opens the highlighted item and Left goes back to the list; navigation stays on for both.
    right = function()
        if inDetail() or not enterRow() then return false end
        nav.idx = 0
        return true
    end,
    left = function()
        if not goBack() then return false end
        nav.idx = 0
        return true
    end,
    -- Return copies: on a list item it opens it and copies its password, on the detail screen it copies the
    -- highlighted field. Either way the popover closes afterwards.
    ["return"] = function()
        local detail = inDetail()
        if not enterRow() then return false end
        if detail then
            finishCopy()
        else
            copyPasswordWhenReady(DETAIL_POLLS)
        end
        stopNav()
        return true
    end,
    escape = function()
        if not closePopover() then return false end
        stopNav()
        return true
    end,
}

--- Handles a key press while navigating. Keys with modifiers are never touched.
-- @return boolean True when the key was consumed.
function M.onKey(name, hasModifiers)
    local handler = handlers[name]
    if not nav or hasModifiers or not handler then return false end
    local ok, consumed = pcall(handler)
    if not ok then
        stopNav()
        return false
    end
    return consumed
end

local function startNav()
    if nav then return end
    local canvas = hs.canvas.new({ x = 0, y = 0, w = 0, h = 0 })
    canvas:level(hs.canvas.windowLevels.overlay)
    canvas[1] = { type = "rectangle", action = "fill", roundedRectRadii = { xRadius = 8, yRadius = 8 },
                  fillColor = { red = 0.2, green = 0.5, blue = 1, alpha = 0.3 } }
    local tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
        local flags = event:getFlags()
        local hasModifiers = flags.cmd or flags.ctrl or flags.alt or flags.shift
        return M.onKey(hs.keycodes.map[event:getKeyCode()], hasModifiers and true or false)
    end)
    -- The popover opens asynchronously: keep the keys free until its window shows up, and give up
    -- after ~3s if it never does.
    local misses, seen = 0, false
    nav = { tap = tap, canvas = canvas, idx = 0,
            watch = hs.timer.doEvery(0.3, function()
                local open = popoverWindow() ~= nil
                -- macOS disables a tap whose callback runs too long; turn it back on.
                if open and not tap:isEnabled() then tap:start() end
                seen = seen or open
                misses = open and 0 or misses + 1
                if misses >= 10 or (seen and not open) then return stopNav() end
                if open and not pcall(refresh) then stopNav() end
            end) }
end

local function attempt(tries)
    local item = findItem()
    if item then
        local wasOpen = popoverRows() ~= nil
        if not clickElement(item) then return false end
        -- A click on an open popover closes it, so only start navigation when it was closed.
        if not wasOpen then startNav() end
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
