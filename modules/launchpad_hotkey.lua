-- luacheck: globals hs
-- luacheck: max line length 120
-- ~/.hammerspoon/modules/launchpad_hotkey.lua
-- Module: launchpad_hotkey
-- Purpose: Binds a hotkey to open Launchpad or Apps, using path or name fallback.
-- Usage: require this module and call M.bindHotkey() to enable Alt+A for Launchpad/Apps.
-- Author: [Your Name]
-- Last updated: 2025-09-19

local M = {}

--- Candidate apps to open (by path or name)
local CANDIDATES = {
    { path = "/System/Library/CoreServices/Apps.app", name = "Apps" },
    { path = "/System/Library/CoreServices/Launchpad.app", name = "Launchpad" },
    { path = nil, name = "Apps" },
    { path = nil, name = "Launchpad" }
}

--- Attempts to open an app by its filesystem path.
local function openByPath(appPath)
    if not appPath then return false end
    if not hs.fs.attributes(appPath) then return false end
    local ok = hs.execute(string.format('/usr/bin/open -a %q', appPath), true)
    return ok ~= nil
end

--- Attempts to open an app by its name.
local function openByName(appName)
    if not appName or appName == "" then return false end
    return hs.application.launchOrFocus(appName) or false
end

--- Tries all candidates to open Launchpad/Apps, falling back to F4 key.
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
    return false, nil, "fallback"
end

--- Binds Alt+A to open Launchpad/Apps using the above logic.
function M.bindHotkey()
    hs.hotkey.bind({"alt"}, "A", function()
        local ok, which, how = openAppsOrLaunchpad()
        if ok then
            print(string.format("[launchpad_hotkey] Opened %s via %s", which or "Apps", how))
        else
            hs.alert.show("⚠️ Couldn’t open Apps/Launchpad")
            print("[launchpad_hotkey] Failed to open Apps/Launchpad (tried paths, names, F4)")
        end
    end)
end

return M
