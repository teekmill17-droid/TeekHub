local REPO = "https://raw.githubusercontent.com/teekmill17-droid/TeekHub/refs/heads/main/"
local SUPPORTED_GAMES = {
	[2753915549] = "Games/BloxFruits.lua",
	[13772394625] = "Games/BladeBall.lua",
	[16044264830] = "Games/BladeBall.lua",
	-- Add more: [placeId] = "Games/ScriptName.lua",
}
local KEY_ENABLED = true
local VALID_KEYS = {
	["TEEK-FREE-2026"] = true,
	["TEEK-VIP-HUB"] = true,
	["TEEK-BETA-KEY"] = true,
}
local function httpGet(url)
	local s, r = pcall(function() return game:HttpGet(url) end)
	if s then return r end
	s, r = pcall(function() return request({Url = url}).Body end)
	if s then return r end
	return nil
end
local function checkKey()
	if not KEY_ENABLED then return true end
	if getgenv and getgenv().__TeekHubKey then
		if VALID_KEYS[getgenv().__TeekHubKey] then return true end
	end
	local keyUrl = REPO .. "Key.lua"
	local keyScript = httpGet(keyUrl)
	if keyScript then
		local fn = loadstring(keyScript)
		if fn then
			local result = fn(VALID_KEYS)
			if result then
				if getgenv then getgenv().__TeekHubKey = result end
				return true
			end
		end
	end
	local input
	if request and syn then
		input = syn.request
	end
	warn("[TeekHub] Key required. Set key with: getgenv().__TeekHubKey = 'YOUR-KEY'")
	warn("[TeekHub] Then re-execute the loader.")
	return false
end
if not checkKey() then return end
local placeId = game.PlaceId
local scriptPath = SUPPORTED_GAMES[placeId]
local scriptUrl
if scriptPath then
	scriptUrl = REPO .. scriptPath
	print("[TeekHub] Detected supported game — loading " .. scriptPath)
else
	scriptUrl = REPO .. "Universal.lua"
	print("[TeekHub] Unknown game — loading Universal script")
end
local code = httpGet(scriptUrl)
if code then
	local fn, err = loadstring(code)
	if fn then
		fn()
	else
		warn("[TeekHub] Script compile error: " .. tostring(err))
	end
else
	warn("[TeekHub] Failed to fetch script from: " .. scriptUrl)
end
