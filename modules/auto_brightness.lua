local M = {}

local lastPowerSource = hs.battery.powerSource()

function M.checkPowerSource()
    local source = hs.battery.powerSource()
    if source ~= lastPowerSource then
        hs.alert.show("🔌 Power: " .. source)
        hs.brightness.set(source == "AC Power" and 100 or 50)
        lastPowerSource = source
    end
    print("🔋 Power check → " .. source)
end

return M
