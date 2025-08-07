local M = {}

function M.bindHotkey()
    hs.hotkey.bind({"alt"}, "z", function()
        local apps = hs.application.runningApplications()
        local choices = {}

        for _, app in ipairs(apps) do
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
