-- luacheck: globals hs
-- luacheck: max line length 120
-- modules/ide_apps.lua
-- Module: ide_apps
-- Purpose: Single source of truth for the VS Code compatible editors the
--          IDE modules can drive (VS Code and Antigravity IDE). Both share
--          the same command palette, default shortcuts and Electron UI.

local M = {}

M.BUNDLE_IDS = {"com.microsoft.VSCode", "com.google.antigravity-ide"}
M.APP_NAMES = {"Code", "Visual Studio Code", "Antigravity IDE"}

--- True when the app is one of the supported editors.
-- @param app hs.application|nil
-- @return boolean
function M.isIDE(app)
    if not app then return false end
    local id = app:bundleID()
    for _, b in ipairs(M.BUNDLE_IDS) do
        if id == b then return true end
    end
    return false
end

--- Find a running supported editor, preferring the frontmost one.
-- @return hs.application|nil
function M.find()
    local front = hs.application.frontmostApplication()
    if M.isIDE(front) then return front end
    for _, b in ipairs(M.BUNDLE_IDS) do
        local apps = hs.application.applicationsForBundleID(b)
        if apps and apps[1] then return apps[1] end
    end
    return nil
end

return M
