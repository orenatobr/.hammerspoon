-- luacheck: globals hs
local M = {}
local pipWatcher = nil
local PIP_CHECK_INTERVAL = 2 -- seconds

local function getInternalScreen()
    for _, scr in ipairs(hs.screen.allScreens()) do
        if scr:frame().x == 0 and scr:frame().y == 0 then
            return scr
        end
    end
    return hs.screen.primaryScreen()
end

local function findPIPWindow()
    for _, app in ipairs(hs.application.runningApplications()) do
        if app:name() == "PIPAgent" then
            local axApp = hs.axuielement.applicationElement(app)
            if axApp then
                local windows = axApp:attributeValue("AXWindows") or {}
                for _, axWin in ipairs(windows) do
                    local title = axWin:attributeValue("AXTitle") or ""
                    local subrole = axWin:attributeValue("AXSubrole") or ""
                    if subrole == "AXSystemFloatingWindow" and title == "PIP" then
                        return axWin
                    end
                end
            end
        end
    end
    return nil
end

function M.movePIPToBottomLeft()
    local axWin = findPIPWindow()
    if axWin then
        local screen = getInternalScreen()
        local frame = screen:frame()
        local pipW, pipH = 636, 358
        local newPos = {
            x = frame.x,
            y = frame.y + frame.h - pipH
        }
        axWin:setAttributeValue("AXPosition", newPos)
        axWin:setAttributeValue("AXSize", {
            w = pipW,
            h = pipH
        })
        print(string.format("[PIP-AX] Moved PIP window to bottom-left: x=%d, y=%d, w=%d, h=%d", newPos.x, newPos.y,
            pipW, pipH))
        return true
    end
    print("[PIP-AX] No PIP window to move.")
    return false
end

function M.startPIPWatcher()
    if pipWatcher then
        return
    end
    pipWatcher = hs.timer.doEvery(PIP_CHECK_INTERVAL, function()
        if not M.movePIPToBottomLeft() then
            print("[PIP-AX] (Watcher) No PIP window detected.")
        end
    end)
    print("[PIP-AX] PIP watcher started.")
end

function M.check()
    local axWin = findPIPWindow()
    local active = axWin ~= nil
    print("[PIP-AX] Safari PIP active:", active)
    if active then
        M.movePIPToBottomLeft()
    end
    return active
end

function M.scanAllAXWindows()
    print("[PIP-AX SCAN] Scanning all AX windows from all apps:")
    for _, app in ipairs(hs.application.runningApplications()) do
        local axApp = hs.axuielement.applicationElement(app)
        if axApp then
            local windows = axApp:attributeValue("AXWindows") or {}
            for _, axWin in ipairs(windows) do
                local appName = app:name() or "?"
                local title = axWin:attributeValue("AXTitle") or ""
                local role = axWin:attributeValue("AXRole") or ""
                local subrole = axWin:attributeValue("AXSubrole") or ""
                local pos = axWin:attributeValue("AXPosition") or {
                    x = 0,
                    y = 0
                }
                local size = axWin:attributeValue("AXSize") or {
                    w = 0,
                    h = 0
                }
                print(string.format("[PIP-AX SCAN] App='%s', title='%s', role=%s, subrole=%s, x=%d, y=%d, w=%d, h=%d",
                    appName, title, role, subrole, pos.x or 0, pos.y or 0, size.w or 0, size.h or 0))
            end
        end
    end
end

return M
