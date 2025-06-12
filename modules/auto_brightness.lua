local M = {}

local lastPowerSource = hs.battery.powerSource()

local function handlePowerEvent()
    local source = hs.battery.powerSource()
    if source ~= lastPowerSource then
        hs.alert.show("🔌 Power: " .. source)
        hs.brightness.set(source == "AC Power" and 100 or 50)
        lastPowerSource = source
    end
    print("🔋 Power check → " .. source)
end

M.watcher = hs.battery.watcher.new(handlePowerEvent)

function M.start()
    M.watcher:start()
    print("⚡ Power watcher started")
end

function M.stop()
    M.watcher:stop()
    print("🛑 Power watcher stopped")
end

return M
