-- luacheck: globals hs
-- luacheck: ignore hs unused
-- luacheck: ignore unused
_G.hs = _G.hs or {}
hs.alert = hs.alert or {
    show = function() end,
    closeAll = function() end
}
hs.application = hs.application or {}
hs.application.watcher = hs.application.watcher or {
    launched = 1,
    terminated = 2,
    new = function()
        return {
            start = function() end,
            stop = function() end
        }
    end
}
hs.application.find = hs.application.find or function()
    return {
        isRunning = function() return true end
    }
end
hs.application.runningApplications = hs.application.runningApplications or function()
    return {}
end
hs.caffeinate = hs.caffeinate or {
    set = function() end
}
hs.timer = hs.timer or {
    doAfter = function(_, fn) -- luacheck: ignore fn
        if fn then
            fn()
        end
    end
}
hs.timer.doEvery = hs.timer.doEvery or function(_, fn) -- luacheck: ignore fn
    return {
        stop = function() end
    }
end
hs.window = hs.window or {}
hs.window.filter = hs.window.filter or {
    new = function()
        return {
            setAppFilter = function(self)
                return self
            end,
            subscribe = function() end,
            unsubscribeAll = function() end
        }
    end,
    windowCreated = "windowCreated"
}
hs.fnutils = hs.fnutils or {}
hs.fnutils.each = function(tbl, fn) -- luacheck: ignore fn
    for k, v in pairs(tbl) do
        if fn then
            fn(v, k)
        end
    end
end
hs.fnutils.find = function(tbl, fn) -- luacheck: ignore fn
    for k, v in pairs(tbl) do
        if fn and fn(v, k) then
            return v
        end
    end
end
hs.fnutils.filter = function(tbl, fn) -- luacheck: ignore fn
    local out = {};
    for k, v in pairs(tbl) do
        if fn and fn(v, k) then
            table.insert(out, v)
        end
    end
    return out
end
-- Remove any previous hs.fnutils.map definition with 'fn' and ensure only the suppressed '_' version remains:
hs.fnutils.map = function(tbl, _) -- luacheck: ignore _
    local out = {}
    for k, v in pairs(tbl) do
        if _ then
            table.insert(out, _(v, k))
        end
    end
    return out
end
hs.fnutils.copy = function(tbl)
    local out = {}
    for k, v in pairs(tbl) do
        out[k] = v
    end
    return out
end
hs.inspect = hs.inspect or function(val)
    if type(val) == "table" then
        local out = "{ "
        for k, v in pairs(val) do
            out = out .. tostring(k) .. " = " .. tostring(v) .. ", "
        end
        return out .. "}"
    else
        return tostring(val)
    end
end
hs.hotkey = hs.hotkey or {
    bind = function() end
}
hs.caffeinate.watcher = hs.caffeinate.watcher or {
    new = function()
        return {
            start = function() end,
            stop = function() end
        }
    end
}
hs.screen = hs.screen or {}
hs.screen.watcher = hs.screen.watcher or {
    new = function()
        return {
            start = function() end,
            stop = function() end
        }
    end
}
hs.screen.allScreens = hs.screen.allScreens or function()
    return {{
        name = function()
            return "Built-in Retina Display"
        end
    }}
end
hs.battery = hs.battery or {
    amperage = function()
        return 0
    end,
    percentage = function()
        return 100
    end,
    isCharging = function()
        return true
    end,
    powerSource = function()
        return "AC Power"
    end
}
hs.battery.watcher = hs.battery.watcher or {
    new = function()
        return {
            start = function() end,
            stop = function() end
        }
    end
}
