-- luacheck: globals describe it assert
-- Ensure package.path includes the modules directory for correct resolution
local project_root = debug.getinfo(1, "S").source:match("^@(.*/).*") or "./"
package.path = project_root .. "modules/?.lua;" .. package.path

local modules = {
    "app_navigation",
    "auto_brightness",
    "auto_fullscreen",
    "auto_lock",
    "aws_tab_monitor",
    "filezilla_caffeinate",
    "idle_keepalive",
    "launchpad_hotkey",
    "refresh_hotkey",
    "safari_window_manager",
    "tab_navigation",
    "teams_focus_restore",
    "vscode_window_manager",
    "window_cycle"
}
for _, name in ipairs(modules) do
    require("modules." .. name)
end

describe("all modules required", function()
    it("should require all modules for coverage", function()
        assert.is_true(true)
    end)
end)
