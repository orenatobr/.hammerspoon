-- luacheck: globals hs
-- luacheck: max line length 120
-- modules/reset_vscode.lua
-- Module: reset_vscode
-- Purpose: Reloads the VS Code window and resets the three main panel sizes to
--          20% of the window dimensions using macOS Accessibility (AXSplitter drag):
--            • Left sidebar  (file explorer)   → 20 % of window width
--            • Right sidebar (Copilot / aux)   → 20 % of window width
--            • Bottom panel  (terminal)        → 20 % of window height
-- Hotkey: Option + V

local M = {}

-- ──────────────────────────────────────────────────────────────────────────────
-- Config
-- ──────────────────────────────────────────────────────────────────────────────

local HOTKEY_MODS        = {"alt"}
local HOTKEY_KEY         = "v"
local RELOAD_WAIT_SECS   = 4.5   -- seconds to wait after Developer: Reload Window
local TARGET_RATIO       = 0.20  -- 20 % of the relevant window dimension
local SPLITTER_STEP_SECS = 0.35  -- gap between consecutive splitter drags

-- ──────────────────────────────────────────────────────────────────────────────
-- Accessibility helpers
-- ──────────────────────────────────────────────────────────────────────────────

--- Recursively collect all AX elements with the given role.
-- Stops descent at maxDepth to avoid hanging on deep Electron trees.
-- @param element hs.axuielement  root element
-- @param role    string          AXRole to match (e.g. "AXSplitter")
-- @param maxDepth number         max recursion depth (default 8)
-- @param _depth  number          internal counter (default 0)
-- @return table  flat list of matching elements
local function findByRole(element, role, maxDepth, _depth)
    maxDepth = maxDepth or 15
    _depth   = _depth   or 0
    if _depth > maxDepth or not element then return {} end

    local results = {}

    local okRole, elemRole = pcall(function()
        return element:attributeValue("AXRole")
    end)
    if okRole and elemRole == role then
        table.insert(results, element)
    end

    local okChildren, children = pcall(function()
        return element:attributeValue("AXChildren")
    end)
    if okChildren and children then
        for _, child in ipairs(children) do
            local sub = findByRole(child, role, maxDepth, _depth + 1)
            for _, r in ipairs(sub) do
                table.insert(results, r)
            end
        end
    end

    return results
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Mouse drag helpers
-- ──────────────────────────────────────────────────────────────────────────────

--- Multi-step synchronous drag for Electron/Chromium sash handles.
-- Uses hs.timer.usleep between steps so VS Code's web event loop processes each
-- mousemove before the next one arrives — a single-jump drag is ignored by Electron.
-- @param fromX number
-- @param fromY number
-- @param toX   number
-- @param toY   number
-- @param label string  log label
local DRAG_STEPS       = 20    -- intermediate mousemove events
local DRAG_STEP_US     = 12000 -- 12 ms between steps (µs)
local DRAG_SETTLE_US   = 60000 -- 60 ms hold after mousedown before first move

local function dragSash(fromX, fromY, toX, toY, label)
    print(string.format("🖱  drag %s: (%.0f,%.0f)→(%.0f,%.0f)", label or "?", fromX, fromY, toX, toY))
    local from = {x = fromX, y = fromY}
    local to   = {x = toX,   y = toY}
    hs.mouse.absolutePosition(from)
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, from):post()
    hs.timer.usleep(DRAG_SETTLE_US)
    for i = 1, DRAG_STEPS do
        local t = i / DRAG_STEPS
        local p = {x = fromX + (toX - fromX) * t, y = fromY + (toY - fromY) * t}
        hs.mouse.absolutePosition(p)
        hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDragged, p):post()
        hs.timer.usleep(DRAG_STEP_US)
    end
    hs.mouse.absolutePosition(to)
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, to):post()
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Panel resize logic
-- ──────────────────────────────────────────────────────────────────────────────

--- Resize VS Code panels by locating thin AXGroup sash handles.
-- VS Code (Electron/Chromium) does not use AXSplitter; all elements are AXGroup.
-- Sash handles are identified as very thin AXGroups (≤ MAX_SASH_THICK px in one axis,
-- ≥ MIN_SASH_LENGTH px in the other). Each one is dragged with dragSash().
--
-- Selection strategy:
--   left sidebar  → rightmost vertical sash in the left half of the window
--   right sidebar → leftmost  vertical sash in the right half of the window
--   bottom panel  → topmost horizontal sash in the lower 60 % of the window
--
-- @param win hs.window  the VS Code window to operate on
local MAX_SASH_THICK  = 12   -- px: max thickness that qualifies as a sash
local MIN_SASH_LENGTH = 0.15 -- fraction of smallest window dimension

local function resizePanels(win)
    local frame = win:frame()
    local wx, wy, ww, wh = frame.x, frame.y, frame.w, frame.h
    local targetLeftX   = wx + ww * TARGET_RATIO
    local targetRightX  = wx + ww * (1.0 - TARGET_RATIO)
    local targetBottomY = wy + wh * (1.0 - TARGET_RATIO)
    local minLen = math.min(ww, wh) * MIN_SASH_LENGTH

    print(string.format("📐 Janela: %.0fx%.0f em (%.0f,%.0f) | L=%.0f R=%.0f B=%.0f",
        ww, wh, wx, wy, targetLeftX, targetRightX, targetBottomY))

    local axWin = hs.axuielement.windowElement(win)
    if not axWin then
        hs.alert.show("VS Code: acessibilidade indisponível")
        return
    end

    -- Collect all AXGroups and filter for thin sash candidates
    local allGroups = findByRole(axWin, "AXGroup", 25)
    print(string.format("ℹ️  AXGroups totais: %d — filtrando sashes (thick≤%d, len≥%.0f)…",
        #allGroups, MAX_SASH_THICK, minLen))

    local vertSashes  = {}
    local horizSashes = {}
    for _, group in ipairs(allGroups) do
        local ok, f = pcall(function() return group:attributeValue("AXFrame") end)
        if ok and f then
            local isVert  = f.w <= MAX_SASH_THICK and f.h >= minLen
            local isHoriz = f.h <= MAX_SASH_THICK and f.w >= minLen
            if isVert then
                table.insert(vertSashes,  {frame = f, midX = f.x + f.w/2, midY = f.y + f.h/2})
                print(string.format("  ↔️ vert  sash: %.0fx%.0f @ %.0f,%.0f", f.w, f.h, f.x, f.y))
            elseif isHoriz then
                table.insert(horizSashes, {frame = f, midX = f.x + f.w/2, midY = f.y + f.h/2})
                print(string.format("  ↕️ horiz sash: %.0fx%.0f @ %.0f,%.0f", f.w, f.h, f.x, f.y))
            end
        end
    end
    print(string.format("🔍 Sashes encontrados: %d vertical(is), %d horizontal(is)",
        #vertSashes, #horizSashes))

    if #vertSashes == 0 and #horizSashes == 0 then
        hs.alert.show("VS Code: sash não encontrado — abra todos os painéis e tente novamente")
        return
    end

    -- Pick the best candidate for each panel divider
    -- RIGHT_EDGE_MARGIN: ignore sashes within this many px of the right window edge
    -- (they belong to the activity bar border, not the Copilot sidebar)
    local RIGHT_EDGE_MARGIN = 80
    local leftSash, rightSash, bottomSash
    local midWin       = wx + ww / 2
    local rightZoneMax = wx + ww - RIGHT_EDGE_MARGIN
    for _, s in ipairs(vertSashes) do
        if s.midX < midWin then
            if not leftSash  or s.midX > leftSash.midX  then leftSash  = s end
        elseif s.midX <= rightZoneMax then
            if not rightSash or s.midX < rightSash.midX then rightSash = s end
        end
    end
    for _, s in ipairs(horizSashes) do
        if s.midY > wy + wh * 0.4 then
            if not bottomSash or s.midY < bottomSash.midY then bottomSash = s end
        end
    end

    if leftSash   then print(string.format("✅ leftSash:   midX=%.0f → target=%.0f", leftSash.midX,   targetLeftX))  end
    if rightSash  then print(string.format("✅ rightSash:  midX=%.0f → target=%.0f", rightSash.midX,  targetRightX)) end
    if bottomSash then print(string.format("✅ bottomSash: midY=%.0f → target=%.0f", bottomSash.midY, targetBottomY)) end

    -- Schedule drags sequentially
    local delay = 0.0
    local function schedule(sash, toX, toY, label)
        if not sash then return end
        delay = delay + SPLITTER_STEP_SECS
        local s = sash
        hs.timer.doAfter(delay, function()
            dragSash(s.midX, s.midY, toX, toY, label)
        end)
    end

    schedule(leftSash,   targetLeftX,              leftSash   and leftSash.midY   or 0, "sidebar esquerda")
    schedule(rightSash,  targetRightX,             rightSash  and rightSash.midY  or 0, "sidebar direita")
    schedule(bottomSash, bottomSash and bottomSash.midX or 0, targetBottomY,             "painel inferior")

    hs.timer.doAfter(delay + 2.0, function()
        hs.alert.show("VS Code: painéis resetados para 20%")
    end)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Panel visibility (ensure sidebars and terminal are open before resizing)
-- ──────────────────────────────────────────────────────────────────────────────

--- Ensure the primary sidebar (Explorer), secondary sidebar, and terminal panel
-- are visible so their sash handles appear in the accessibility tree.
-- Uses non-toggle commands so panels are always left open:
--   Cmd+Shift+E                  → always shows the Explorer sidebar (safe)
--   Ctrl+50 (backtick keycode)   → shows / focuses the integrated terminal (safe)
--   Command palette: Focus Auxiliary Bar → shows Copilot sidebar without toggling
-- @param callback function  called after all panels are shown
local function ensurePanelsVisible(callback)
    -- Show primary sidebar (Explorer)
    hs.eventtap.keyStroke({"cmd", "shift"}, "e")
    hs.timer.doAfter(0.5, function()
        -- Show integrated terminal (keycode 50 = backtick físico, independe de layout de teclado)
        hs.eventtap.keyStroke({"ctrl"}, 50)
        hs.timer.doAfter(0.5, function()
            -- Show secondary sidebar (Copilot) via dedicated keybinding.
            -- Cmd+Shift+Alt+A → workbench.action.focusAuxiliaryBar (never closes it).
            hs.eventtap.keyStroke({"cmd", "shift", "alt"}, "a")
            hs.timer.doAfter(0.4, function()
                -- Return focus to the editor area so AX tree is stable
                hs.eventtap.keyStroke({"cmd"}, "1")
                hs.timer.doAfter(0.5, callback)
            end)
        end)
    end)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Main action
-- ──────────────────────────────────────────────────────────────────────────────

--- Reload VS Code and reset panel layout to TARGET_RATIO for all three panels.
local function resetVSCode()
    local app = hs.application.find("Code")
    if not app then
        app = hs.application.find("Visual Studio Code")
    end
    if not app then
        hs.alert.show("VS Code não encontrado")
        return
    end

    app:activate()
    hs.timer.doAfter(0.3, function()
        -- Trigger reload via dedicated keybinding (Cmd+Shift+Alt+R → workbench.action.reloadWindow)
        -- Avoids opening the command palette visually.
        hs.eventtap.keyStroke({"cmd", "shift", "alt"}, "r")
        hs.alert.show("Recarregando VS Code…")

        -- Wait for VS Code to finish reloading before interacting
        hs.timer.doAfter(RELOAD_WAIT_SECS, function()
            local codeApp = hs.application.find("Code")
            if not codeApp then
                codeApp = hs.application.find("Visual Studio Code")
            end
            if not codeApp then return end

            codeApp:activate()
            hs.timer.doAfter(0.5, function()
                -- Resolve the frontmost (or first available) window
                local win = codeApp:focusedWindow()
                if not win then
                    local wins = codeApp:allWindows()
                    if wins and #wins > 0 then win = wins[1] end
                end
                if not win then
                    hs.alert.show("VS Code: nenhuma janela encontrada")
                    return
                end

                -- Open every panel before measuring splitter positions
                ensurePanelsVisible(function()
                    resizePanels(win)
                end)
            end)
        end)
    end)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Public API
-- ──────────────────────────────────────────────────────────────────────────────

--- Bind Option + V to the VS Code reset action.
function M.bindHotkey()
    hs.hotkey.bind(HOTKEY_MODS, HOTKEY_KEY, resetVSCode)
end

return M
