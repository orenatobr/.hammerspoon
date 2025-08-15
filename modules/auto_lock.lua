local M = {}

-- ===== Bluetooth via Shortcuts (prefer background: OSA -> CLI -> URL) =====
local function urlEncode(s)
    return (s:gsub("([^%w%-_%.~ ])", function(c)
        return string.format("%%%02X", string.byte(c))
    end):gsub(" ", "%%20"))
end

-- Run via Shortcuts Events (background, no UI)
local function runShortcutOSA(name)
    local ok, _, err = hs.osascript.applescript(string.format([[
    tell application "Shortcuts Events"
      run shortcut "%s"
    end tell
  ]], name))
    return ok, err
end

-- Run via CLI (background, no UI)
local function runShortcutCLI(name)
    local cmd = string.format('/usr/bin/shortcuts run %q --show-errors 2>&1', name)
    local out, ok, _, rc = hs.execute(cmd, true)
    return ok and rc == 0, out or "", rc
end

-- Run via URL scheme (may open UI; we hide and restore focus)
local function runShortcutURL(name, restoreApp)
    local ok = hs.urlevent.openURL("shortcuts://run-shortcut?name=" .. urlEncode(name))
    if ok then
        hs.timer.doAfter(0.25, function()
            local sh = hs.application.get("Shortcuts")
            if sh then
                sh:hide()
            end
            if restoreApp then
                restoreApp:activate(true)
            end
        end)
    end
    return ok
end

local function bt(turnOn)
    local target = turnOn and "Bluetooth On" or "Bluetooth Off"
    local prevApp = hs.application.frontmostApplication()

    -- 1) Try Shortcuts Events (background)
    local okOSA, errOSA = runShortcutOSA(target)
    if okOSA then
        return true
    end

    -- 2) Try CLI (background)
    local okCLI, outCLI, rcCLI = runShortcutCLI(target)
    if okCLI then
        return true
    end

    -- 3) Try URL scheme (hide app and restore focus)
    local okURL = runShortcutURL(target, prevApp)
    if okURL then
        return true
    end

    print(string.format("❌ Bluetooth shortcut failed: OSA err=%s | CLI rc=%s out=%s", tostring(errOSA or "nil"),
        tostring(rcCLI or "nil"), outCLI or ""))
    return false
end

-- ===== Lid detection =====
local timer = nil
local lastBuiltInPresent = nil

local CLOSE_DELAY = 0.3
local OPEN_DELAY = 0.5
local POLL_INTERVAL = 2

local function isBuiltInDisplayPresent()
    for _, screen in ipairs(hs.screen.allScreens()) do
        local nm = (screen:name() or ""):lower()
        if nm:match("built%-in") or nm:find("liquid retina") or nm:find("color lcd") then
            return true
        end
    end
    return false
end

local function onLidClosed()
    hs.timer.doAfter(CLOSE_DELAY, function()
        bt(false) -- Turn Bluetooth OFF
        hs.caffeinate.lockScreen()
        print("🔒 Lid closed — Bluetooth OFF + screen locked.")
    end)
end

local function onLidOpened()
    hs.timer.doAfter(OPEN_DELAY, function()
        bt(true) -- Turn Bluetooth ON
        print("🔓 Lid opened — Bluetooth ON.")
    end)
end

local function checkLidState()
    local builtInPresent = isBuiltInDisplayPresent()

    if lastBuiltInPresent == nil then
        lastBuiltInPresent = builtInPresent
        return
    end

    -- Transition from open -> closed
    if lastBuiltInPresent and not builtInPresent then
        onLidClosed()
    end

    -- Transition from closed -> open
    if (not lastBuiltInPresent) and builtInPresent then
        onLidOpened()
    end

    lastBuiltInPresent = builtInPresent
end

function M.bindHotkey()
    -- Optional for manual testing:
    -- hs.hotkey.bind({"ctrl","alt","cmd"}, "9", function() onLidClosed() end)
    -- hs.hotkey.bind({"ctrl","alt","cmd"}, "0", function() onLidOpened() end)
end

function M.start()
    if not timer then
        lastBuiltInPresent = isBuiltInDisplayPresent()
        timer = hs.timer.doEvery(POLL_INTERVAL, checkLidState)
        print(string.format("✅ Lid monitoring started (polling every %ss).", POLL_INTERVAL))
    end
end

function M.stop()
    if timer then
        timer:stop()
        timer = nil
        print("🛑 Lid monitoring stopped.")
    end
end

return M
