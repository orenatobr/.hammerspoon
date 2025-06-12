local M = {}
local caffeinateStatus = false

local function isAppRunning(appName)
    local app = hs.application.get(appName)
    return app and app:isRunning()
end

function M.start()
    hs.timer.doEvery(5, function()
        local running = isAppRunning("FileZilla")
        if running and not caffeinateStatus then
            hs.caffeinate.set("displayIdle", true)
            caffeinateStatus = true
            hs.alert.show("Caffeinate ON")
            print("Caffeinate ativado")
        elseif not running and caffeinateStatus then
            hs.caffeinate.set("displayIdle", false)
            caffeinateStatus = false
            hs.alert.show("Caffeinate OFF")
            print("Caffeinate desligado")
        end
        print("FileZilla running?", tostring(running))
    end)
end

return M