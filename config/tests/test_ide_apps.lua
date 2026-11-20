-- luacheck: globals hs busted describe it assert before_each
-- luacheck: ignore busted

_G.hs = _G.hs or {}

local function fakeApp(bundle, name)
    return {
        bundleID = function() return bundle end,
        name = function() return name end
    }
end

local running, front
hs.application = hs.application or {}
hs.application.applicationsForBundleID = function(id) return running[id] or {} end
hs.application.frontmostApplication = function() return front end

local ide_apps = require('../modules/ide_apps')

describe("ide_apps", function()
    before_each(function()
        running, front = {}, nil
    end)

    it("recognises VS Code and Antigravity IDE by bundle id", function()
        assert.is_true(ide_apps.isIDE(fakeApp("com.microsoft.VSCode", "Code")))
        assert.is_true(ide_apps.isIDE(fakeApp("com.google.antigravity-ide", "Antigravity IDE")))
        assert.is_false(ide_apps.isIDE(fakeApp("com.apple.Safari", "Safari")))
        assert.is_false(ide_apps.isIDE(nil))
    end)

    it("find returns nil when no IDE runs", function()
        assert.is_nil(ide_apps.find())
    end)

    it("find returns the running Antigravity IDE", function()
        local agy = fakeApp("com.google.antigravity-ide", "Antigravity IDE")
        running["com.google.antigravity-ide"] = {agy}
        assert.are.equal(agy, ide_apps.find())
    end)

    it("find prefers the frontmost IDE when several run", function()
        local code = fakeApp("com.microsoft.VSCode", "Code")
        local agy = fakeApp("com.google.antigravity-ide", "Antigravity IDE")
        running["com.microsoft.VSCode"] = {code}
        running["com.google.antigravity-ide"] = {agy}
        front = agy
        assert.are.equal(agy, ide_apps.find())
        front = code
        assert.are.equal(code, ide_apps.find())
    end)
end)
