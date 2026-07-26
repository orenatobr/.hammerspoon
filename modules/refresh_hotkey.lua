-- luacheck: globals hs
-- luacheck: max line length 120
-- ~/.hammerspoon/modules/refresh_hotkey.lua
-- Module: refresh_hotkey
-- Purpose: Binds a hotkey to clear browser storage (localStorage, sessionStorage,
--          cookies, IndexedDB, Cache Storage), clear the browser cache, and reload
--          the page (Alt+R). Storage clearing only runs when Safari or Chrome is
--          the frontmost app (requires "Allow JavaScript from Apple Events" enabled
--          in each browser's Develop/View > Developer menu); other apps keep the
--          previous cache+reload-only behavior.
-- Usage: require this module and call M.bindHotkey() to enable Alt+R.
-- Author: [Your Name]
-- Last updated: 2026-07-26

local M = {}

-- Clears localStorage, sessionStorage, cookies, IndexedDB and Cache Storage for
-- the current page. Kept as a single line (no newlines) so it can be embedded
-- safely inside an AppleScript double-quoted string.
--
-- Cookie deletion tries every host/domain (bare + leading-dot, current host and
-- registrable parent domain) and path (root + current pathname) combination,
-- since a cookie only expires when the new one's domain/path match the
-- original's exactly (a bare `path=/` re-set is a no-op for a cookie that was
-- set with e.g. `domain=.example.com`).
--
-- This can only ever touch storage/cookies readable from page JS. Cookies
-- flagged HttpOnly (typically the actual session cookie on sites that follow
-- security best practices, e.g. Instagram's `sessionid`) are invisible to
-- `document.cookie` by design and cannot be cleared this way — so this hotkey
-- will NOT force a logout on such sites. See README for details.
local CLEAR_STORAGE_JS = "(function(){"
    .. "try{localStorage.clear();}catch(e){}"
    .. "try{sessionStorage.clear();}catch(e){}"
    .. "try{"
    .. "var exp=new Date(0).toUTCString();"
    .. "var eraseCookie=function(n){"
    .. "var h=location.hostname,parts=h.split('.'),doms=[h,'.'+h];"
    .. "if(parts.length>2){var pd=parts.slice(-2).join('.');doms.push(pd,'.'+pd);}"
    .. "var paths=['/',location.pathname];"
    .. "doms.forEach(function(dm){paths.forEach(function(pp){"
    .. "document.cookie=n+'=;expires='+exp+';path='+pp+';domain='+dm;"
    .. "});});"
    .. "document.cookie=n+'=;expires='+exp+';path=/';"
    .. "};"
    .. "document.cookie.split(';').forEach(function(c){eraseCookie(c.split('=')[0].replace(/^ +/,''));});"
    .. "}catch(e){}"
    .. "try{if(window.indexedDB&&indexedDB.databases){indexedDB.databases().then(function(dbs){"
    .. "dbs.forEach(function(db){indexedDB.deleteDatabase(db.name);});"
    .. "});}}catch(e){}"
    .. "try{if(window.caches){caches.keys().then(function(names){"
    .. "names.forEach(function(n){caches.delete(n);});"
    .. "});}}catch(e){}"
    .. "})();"

--- Builds the AppleScript source that runs CLEAR_STORAGE_JS in the current tab
--- of the given browser's front window.
--- @param appName string "Safari" or "Google Chrome"
--- @return string|nil AppleScript source, or nil if the app isn't supported
local function buildClearStorageScript(appName)
    if appName == "Safari" then
        return string.format(
            'tell application "Safari" to do JavaScript "%s" in current tab of front window',
            CLEAR_STORAGE_JS
        )
    elseif appName == "Google Chrome" then
        return string.format(
            'tell application "Google Chrome" to tell active tab of front window to execute javascript "%s"',
            CLEAR_STORAGE_JS
        )
    end
    return nil
end

--- Clears browser storage (localStorage/sessionStorage/cookies/IndexedDB/Cache
--- Storage) for the current tab, if the frontmost app is Safari or Chrome.
--- Silently skips otherwise, and only logs (never throws) on AppleScript failure.
local function clearStorageForFrontApp()
    local app = hs.application.frontmostApplication()
    local appName = app and app:name() or nil
    local script = appName and buildClearStorageScript(appName)
    if not script then
        return
    end

    local ok, _, err = hs.osascript.applescript(script)
    if ok then
        print("🗑️ Storage cleared (" .. appName .. ").")
    else
        print("⚠️ Failed to clear storage on " .. appName .. ": " .. tostring(err))
    end
end

--- Binds Alt+R to clear browser storage + cache and reload the page.
function M.bindHotkey()
    -- luacheck: ignore _
    hs.hotkey.bind({"alt"}, "R", function(_)
        clearStorageForFrontApp()

        -- Simulate Option + Command + E (Empty Cache)
        hs.eventtap.keyStroke({"alt", "cmd"}, "E")
        print("🧹 Cache cleared.")
        -- Wait 1 second before reloading the page
        hs.timer.doAfter(1, function()
            -- Simulate Command + R (Reload Page)
            hs.eventtap.keyStroke({"cmd"}, "R")
            print("🔄 Page reloaded.")
        end)
    end)
end

return M
