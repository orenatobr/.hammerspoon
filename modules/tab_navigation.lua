-- luacheck: globals hs
-- luacheck: max line length 120
-- ~/.hammerspoon/modules/tab_navigation.lua
-- Module: tab_navigation
-- Purpose: Binds a hotkey to show a chooser for open Safari tabs and switch to the selected tab.
-- Usage: require this module and call M.bindHotkey() to enable Alt+S for Safari tab navigation.
-- Author: [Your Name]
-- Last updated: 2025-09-19

local M = {}

--- Binds Alt+S to show a chooser for open Safari tabs and switch to the selected tab.
function M.bindHotkey()
    hs.hotkey.bind({"alt"}, "s", function()
        -- AppleScript to get open tabs in Safari
        local script = [[
            set output to ""
            tell application "Safari"
                set windowTabs to tabs of front window
                repeat with t in windowTabs
                    set output to output & name of t & "|||URL:" & URL of t & linefeed
                end repeat
            end tell
            return output
        ]]
        local success, result = hs.osascript.applescript(script)
        if not success then
            hs.alert("Failed to retrieve Safari tabs.")
            return
        end
        local choices = {}
        for line in string.gmatch(result, "[^\n]+") do
            local title, url = line:match("^(.-)%|%|%|URL:(.+)$")
            if title and url then
                table.insert(choices, {
                    text = title,
                    subText = url,
                    url = url
                })
            end
        end
    -- luacheck: ignore choice
    local chooser = hs.chooser.new(function(_)
            if choice then
                local openTabScript = string.format([[
                    tell application "Safari"
                        set theURL to "%s"
                        set windowTabs to tabs of front window
                        repeat with t in windowTabs
                            if URL of t is theURL then
                                set current tab of front window to t
                                exit repeat
                            end if
                        end repeat
                        activate
                    end tell
                ]], choice.url)
                hs.osascript.applescript(openTabScript)
            end
        end)
        chooser:choices(choices)
        chooser:rows(10)
        chooser:width(60)
        chooser:show()
    end)
end

return M
