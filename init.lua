---------------------------------------------------------------------
--  H A M M E R S P O O N   P R O D U C T I V I T Y   T O O L K I T
--  Author : Renato F. Pereira
--  Updated: 2025-06-11
--
--  Features:
--   1. Auto-adjust display brightness when power source changes
--   2. Alt + A to cycle through visible windows of frontmost app
--   3. Keep display awake while FileZilla is running
--   4. Mouse keep-alive while Microsoft Teams is running
---------------------------------------------------------------------
---------------------------------------------------------------------
-- ▸ Helpers
---------------------------------------------------------------------
-- Safe wrapper with logging
local function safe(fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then
        print("❌ ERROR in function:", debug.getinfo(fn).name or "anonymous", "\nDetails:", result)
    end
    return ok and result
end

---------------------------------------------------------------------
-- ▸ 1. Auto-brightness by power source (every 5s)
---------------------------------------------------------------------
local lastPowerSource = hs.battery.powerSource()

local function checkPowerSource()
    safe(function()
        local source = hs.battery.powerSource()
        if source ~= lastPowerSource then
            hs.alert.show("⏻ Power source: " .. source)
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
    safe(function()
        local app = hs.application.frontmostApplication()
        local windows = hs.fnutils.filter(app:allWindows(), function(w)
            return w:isStandard() and w:isVisible()
        end)

        if #windows < 2 then
            print("ℹ️ Only one window — no cycling needed.")
            return
        end

        table.sort(windows, function(a, b)
            return a:id() < b:id()
        end)

        local focusedID = app:focusedWindow() and app:focusedWindow():id()
        local nextIndex = 1

        for i, w in ipairs(windows) do
            if w:id() == focusedID then
                nextIndex = (i % #windows) + 1
                break
            end
        end

        windows[nextIndex]:raise():focus()
        print("🪟 Window switched.")
    end)
end)

---------------------------------------------------------------------
-- ▸ Ready!
---------------------------------------------------------------------
print("✅ Hammerspoon Productivity Toolkit initialized.")
hs.alert.show("🎉 All automations active")
