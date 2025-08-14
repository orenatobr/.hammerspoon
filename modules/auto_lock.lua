local M = {}

-- ===== Bluetooth via Shortcuts (URL -> CLI -> AppleScript) =====
local function urlEncode(s)
    return (s:gsub("([^%w%-_%.~ ])", function(c)
        return string.format("%%%02X", string.byte(c))
    end):gsub(" ", "%%20"))
end

local function runShortcutURL(name)
    local ok = hs.urlevent.openURL("shortcuts://run-shortcut?name=" .. urlEncode(name))
    hs.timer.doAfter(0.2, function()
    end)
    return ok
end

local function runShortcutCLI(name)
    local cmd = string.format('/usr/bin/shortcuts run %q --show-errors 2>&1', name)
    local out, ok, _, rc = hs.execute(cmd, true)
    return ok and rc == 0, out, rc
end

local function runShortcutOSA(name)
    local osa = string.format([[osascript -e 'tell application "Shortcuts Events" to run shortcut %q']], name)
    local out, ok, _, rc = hs.execute(osa, true)
    return ok and rc == 0, out, rc
end

local function bt(on)
    local target = on and "Bluetooth On" or "Bluetooth Off"
    if runShortcutURL(target) then
        return true
    end
    local ok1, out1, rc1 = runShortcutCLI(target)
    if ok1 then
        return true
    end
    local ok2, out2, rc2 = runShortcutOSA(target)
    if ok2 then
        return true
    end
    print(string.format("❌ BT Shortcut falhou: CLI rc=%s out=%s | OSA rc=%s out=%s", tostring(rc1), out1 or "",
        tostring(rc2), out2 or ""))
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
        bt(false) -- Bluetooth OFF
        hs.caffeinate.lockScreen()
        print("🔒 Lid closed — BT OFF + screen locked.")
    end)
end

local function onLidOpened()
    hs.timer.doAfter(OPEN_DELAY, function()
        bt(true) -- Bluetooth ON
        print("🔓 Lid opened — BT ON.")
    end)
end

local function checkLidState()
    local builtInPresent = isBuiltInDisplayPresent()

    if lastBuiltInPresent == nil then
        lastBuiltInPresent = builtInPresent
        return
    end

    -- Transição aberto -> fechado
    if lastBuiltInPresent and not builtInPresent then
        onLidClosed()
    end

    -- Transição fechado -> aberto
    if (not lastBuiltInPresent) and builtInPresent then
        onLidOpened()
    end

    lastBuiltInPresent = builtInPresent
end

function M.bindHotkey()
    -- opcional para testes manuais:
    -- hs.hotkey.bind({"ctrl","alt","cmd"}, "9", function() onLidClosed() end)
    -- hs.hotkey.bind({"ctrl","alt","cmd"}, "0", function() onLidOpened() end)
end

function M.start()
    if not timer then
        lastBuiltInPresent = isBuiltInDisplayPresent()
        timer = hs.timer.doEvery(POLL_INTERVAL, checkLidState)
        print(string.format("✅ Lid monitoring started (polling: %ss).", POLL_INTERVAL))
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
