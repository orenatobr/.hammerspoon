-- ~/.hammerspoon/modules/app_launcher.lua
local M = {}

-- Try the new "Apps" and the classic "Launchpad", by path first (most reliable), then by name.
local CANDIDATES = {{
    path = "/System/Library/CoreServices/Apps.app",
    name = "Apps"
}, {
    path = "/System/Library/CoreServices/Launchpad.app",
    name = "Launchpad"
}, {
    path = nil,
    name = "Apps"
}, {
    path = nil,
    name = "Launchpad"
}}

local function openByPath(appPath)
    if not appPath then
        return false
    end
    if not hs.fs.attributes(appPath) then
        return false
    end
    local ok = hs.execute(string.format('/usr/bin/open -a %q', appPath), true)
    return ok ~= nil
end

local function openByName(appName)
    if not appName or appName == "" then
        return false
    end
    -- launchOrFocus returns true/false
    return hs.application.launchOrFocus(appName) or false
end

local function openAppsOrLaunchpad()
    for _, c in ipairs(CANDIDATES) do
        if c.path and openByPath(c.path) then
            return true, c.name, "path"
        end
        if (not c.path) and openByName(c.name) then
            return true, c.name, "name"
        end
    end
    -- Last-ditch fallback: try the F4 Launchpad key (some keyboards map it)
    hs.eventtap.keyStroke({}, "F4", 0)
    -- We can’t know for sure if user’s keyboard maps F4 to Launchpad; just return false here.
    return false, nil, "fallback"
end

function M.bindHotkey()
    hs.hotkey.bind({"alt"}, "A", function()
        local ok, which, how = openAppsOrLaunchpad()
        if ok then
            print(string.format("[app_launcher] Opened %s via %s", which or "Apps", how))
        else
            hs.alert.show("⚠️ Couldn’t open Apps/Launchpad")
            print("[app_launcher] Failed to open Apps/Launchpad (tried paths, names, F4)")
        end
    end)
end

return M
