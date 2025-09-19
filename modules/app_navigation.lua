
-- ~/.hammerspoon/modules/app_navigation.lua
-- Module: app_navigation
-- Purpose: Quickly switch between running applications using a chooser hotkey.
-- Usage: require this module and call M.bindHotkey() to enable Alt+Z app switcher.
-- Author: [Your Name]
-- Last updated: 2025-09-19

local M = {}

--- Binds Alt+Z to show a chooser for running apps and activate the selected one.
function M.bindHotkey()
    hs.hotkey.bind({"alt"}, "z", function()
        local choices = {}
        for _, app in ipairs(hs.application.runningApplications()) do
            -- Only show visible, non-background apps with a name
            if app:kind() == 1 and not app:isHidden() and app:name() then
                table.insert(choices, {
                    text = app:name(),
                    subText = app:bundleID(),
                    uuid = app:bundleID(),
                    image = hs.image.imageFromAppBundle(app:bundleID())
                })
            end
        end

        local chooser = hs.chooser.new(function(choice)
            if choice then
                local app = hs.application.get(choice.uuid)
                if app then
                    app:activate()
                end
            end
        end)
        chooser:choices(choices)
        chooser:rows(10)
        chooser:width(40)
        chooser:show()
    end)
end

return M
