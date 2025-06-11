---------------------------------------------------------------------
--  H A M M E R S P O O N   P R O D U C T I V I T Y   T O O L K I T
--  Author : Renato F. Pereira
--  Updated: 2025-06-11
--
--  Features
--  1. Auto-adjust display brightness when the power source changes
--  2. Alt + A cycles through visible windows of the frontmost app
--  3. Keeps the display awake while FileZilla is running
--  4. “Keep-alive” mouse wiggle every 60 s while Microsoft Teams is open
---------------------------------------------------------------------
---------------------------------------------------------------------
-- ▸ Helpers
---------------------------------------------------------------------
local function safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        print("❌ Error:", err)
    end
end

-- Generic process checker via pgrep
local function isProcessRunning(name)
    local output, _, _, rc = hs.execute("/usr/bin/pgrep -lf '" .. name .. "'", true)
    return rc == 0 and output and output ~= ""
end

---------------------------------------------------------------------
-- ▸ 1. Auto-brightness by power source (every 5s)
---------------------------------------------------------------------
local lastPowerSource = hs.battery.powerSource() or "Unknown"

local function checkPowerSource()
    safe(function()
        local source = hs.battery.powerSource() or "Unknown"
        if source ~= lastPowerSource then
            hs.alert.show("⏻ Power source changed: " .. source)
            hs.brightness.set(source == "AC Power" and 100 or 50)
            lastPowerSource = source
        end
        print("🔋 Power check → " .. source)
    end)
end

hs.timer.doEvery(5, checkPowerSource)
checkPowerSource()

---------------------------------------------------------------------
-- ▸ 2. Alt + A — cycle through visible windows of frontmost app
---------------------------------------------------------------------
hs.hotkey.bind({"alt"}, "A", function()
    local app = hs.application.frontmostApplication()
    local windows = hs.fnutils.filter(app:allWindows(), function(w)
        return w:isStandard() and w:isVisible()
    end)

    if #windows < 2 then
        return
    end

    table.sort(windows, function(a, b)
        return a:id() < b:id()
    end)

    local focusedID = app:focusedWindow():id()
    local nextIndex = 1

    for i, w in ipairs(windows) do
        if w:id() == focusedID then
            nextIndex = (i % #windows) + 1
            break
        end
    end

    windows[nextIndex]:raise():focus()
end)

---------------------------------------------------------------------
-- ▸ 3. Keep display awake while FileZilla is running (every 5s)
---------------------------------------------------------------------
local caffeinateActive = false

local function syncCaffeinate()
    safe(function()
        local running = isProcessRunning("FileZilla")
        print("🕵️ FileZilla running? " .. tostring(running))

        if running and not caffeinateActive then
            hs.caffeinate.set("displayIdle", true)
            caffeinateActive = true
            hs.alert.show("☕ Caffeinate ON")
        elseif not running and caffeinateActive then
            hs.caffeinate.set("displayIdle", false)
            caffeinateActive = false
            hs.alert.show("💤 Caffeinate OFF")
        end
    end)
end

hs.timer.doEvery(5, syncCaffeinate)
syncCaffeinate()

---------------------------------------------------------------------
-- ▸ 4. Mouse keep-alive while Microsoft Teams is running (every 60s)
---------------------------------------------------------------------
local delta = 10 -- ±pixel movement per axis

local function wiggleMouse()
    safe(function()
        if not isProcessRunning("Microsoft Teams") then
            print("🛑 Teams not running — skipping mouse wiggle.")
            return
        end

        local point = hs.mouse.absolutePosition()
        local screen = hs.mouse.getCurrentScreen()
        if not point or not screen then
            print("⚠️ Cannot determine mouse position or screen.")
            return
        end

        local frame = screen:frame()
        local dx = math.random(-delta, delta)
        local dy = math.random(-delta, delta)

        local newX = math.max(math.min(point.x + dx, frame.x + frame.w - 1), frame.x)
        local newY = math.max(math.min(point.y + dy, frame.y + frame.h - 1), frame.y)

        hs.mouse.absolutePosition({
            x = newX,
            y = newY
        })

        print(string.format("🖱️ Wiggle to (%.0f, %.0f) [±%dpx]", newX, newY, delta))
    end)
end

hs.timer.doEvery(60, wiggleMouse)
wiggleMouse()

---------------------------------------------------------------------
-- ▸ Ready!
---------------------------------------------------------------------
print("✅ Hammerspoon Productivity Toolkit initialized.")
hs.alert.show("🎉 All automations active")
