-- luacheck: globals hs
-- luacheck: max line length 120
-- modules/relaunch_terminal.lua
-- Module: relaunch_terminal
-- Purpose: Relaunches the active integrated terminal in VS Code by
--          activating VS Code, opening the Command Palette, and running
--          its built-in "Relaunch Active Terminal" command
--          (workbench.action.terminal.relaunch). This command has no
--          default keybinding, so it's invoked via the palette instead
--          of a custom keybindings.json entry.
-- Hotkey: Option + F

local M = {}

-- ──────────────────────────────────────────────────────────────────────────────
-- Config
-- ──────────────────────────────────────────────────────────────────────────────

local HOTKEY_MODS = {"alt"}
local HOTKEY_KEY = "f"
local ACTIVATE_WAIT_SECS = 0.3 -- seconds to wait for VS Code to focus before opening the Command Palette
local PALETTE_WAIT_SECS = 0.2 -- seconds to wait for the Command Palette to open before typing

-- ──────────────────────────────────────────────────────────────────────────────
-- Main action
-- ──────────────────────────────────────────────────────────────────────────────

--- Activate VS Code and relaunch its active integrated terminal.
local function relaunchTerminal()
    local app = hs.application.find("Code")
    if not app then
        app = hs.application.find("Visual Studio Code")
    end
    if not app then
        hs.alert.show("VS Code não encontrado")
        return
    end

    app:activate()
    hs.timer.doAfter(ACTIVATE_WAIT_SECS, function()
        -- Open the Command Palette and run the built-in relaunch command
        hs.eventtap.keyStroke({"cmd", "shift"}, "p")
        hs.timer.doAfter(PALETTE_WAIT_SECS, function()
            hs.eventtap.keyStrokes("Relaunch Active Terminal")
            hs.eventtap.keyStroke({}, "return")
            hs.alert.show("🔁 Terminal relançado")
        end)
    end)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Public API
-- ──────────────────────────────────────────────────────────────────────────────

--- Bind Option + F to the VS Code terminal relaunch action.
function M.bindHotkey()
    hs.hotkey.bind(HOTKEY_MODS, HOTKEY_KEY, relaunchTerminal)
end

return M
