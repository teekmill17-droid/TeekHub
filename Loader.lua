-- Tempo Hub used to live here, as TeekHub.
--
-- This file is deliberately not the loader. It is a bootstrap, kept so that
-- every loadstring already pasted into somebody's executor keeps working and
-- keeps updating, forever, without them having to change anything.
--
-- The repository was NOT renamed on purpose: GitHub serves raw content at a
-- renamed repo's old path with a 200 and no redirect, but frozen at the moment
-- of the rename. That would have pinned every existing member to one build
-- with no error to tell them. Leaving this repo in place and forwarding from
-- it has none of that failure mode.
--
-- Nothing here needs maintaining. The real loader is in TempoHub.
local url = "https://raw.githubusercontent.com/teekmill17-droid/TempoHub/main/Loader.lua"
local ok, body = pcall(function() return game:HttpGet(url) end)
if not ok or not body then
    ok, body = pcall(function() return request({ Url = url }).Body end)
end
if not ok or not body then
    return warn("[Tempo] could not reach the loader. Check your internet, then retry.")
end
local fn, err = loadstring(body)
if not fn then
    return warn("[Tempo] loader failed to compile: " .. tostring(err))
end
return fn()
