local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local VIM = game:GetService("VirtualInputManager")
local JBConfig = {
	ESP_Enabled = false,
	ESP_ShowBoxes = true,
	ESP_ShowNames = true,
	ESP_ShowHealth = true,
	ESP_ShowDistance = true,
	ESP_ShowTracers = false,
	ESP_TeamColors = true,
	ESP_MaxDistance = 1200,
	Aimbot_Enabled = false,
	Aimbot_UseRMB = true,
	Aimbot_FOV = 120,
	Aimbot_Smoothness = 0.25,
	Aimbot_TargetPart = "Head",
	Aimbot_WallCheck = true,
	Aimbot_Prediction = true,
	Aimbot_ShowFOV = true,
	FlyEnabled = false,
	FlySpeed = 80,
	NoClipEnabled = false,
	SpeedEnabled = false,
	SpeedValue = 32,
	JumpEnabled = false,
	JumpValue = 80,
	Fullbright_Enabled = false,
	InfNitro_Enabled = false,
	AutoReward_Enabled = false,
	AntiAFK_Enabled = false,
	AutoBank_Enabled = false,
	AutoJewelry_Enabled = false,
	AutoPickpocket_Enabled = false,
	SmoothTP_Speed = 200,
}
local SPOTS = {
	{name = "Bank", pos = CFrame.new(32, 18, 822)},
	{name = "Jewelry Store", pos = CFrame.new(142, 18, 1365)},
	{name = "Museum", pos = CFrame.new(1065, 135, 1235)},
	{name = "Casino", pos = CFrame.new(1735, 18, 720)},
	{name = "Tomb", pos = CFrame.new(792, 18, -309)},
	{name = "Power Plant", pos = CFrame.new(710, 37, 2355)},
	{name = "Mansion", pos = CFrame.new(-1350, 18, 370)},
	{name = "Oil Rig", pos = CFrame.new(2060, 55, -800)},
	{name = "Cargo Ship", pos = CFrame.new(1550, 18, 2400)},
	{name = "Rising Garage", pos = CFrame.new(340, 18, 1610)},
	{name = "Crater Garage", pos = CFrame.new(-390, 18, 1720)},
	{name = "Gun Shop 1", pos = CFrame.new(414, 18, 1526)},
	{name = "Gun Shop 2", pos = CFrame.new(-282, 18, 1685)},
	{name = "Criminal Base", pos = CFrame.new(-222, 18, 1590)},
	{name = "Volcano Base", pos = CFrame.new(1720, 52, -1580)},
	{name = "Prison Yard", pos = CFrame.new(-1310, 18, -1760)},
	{name = "Police HQ", pos = CFrame.new(-1180, 18, -1580)},
	{name = "Airport", pos = CFrame.new(-1430, 40, 2485)},
	{name = "Military Base", pos = CFrame.new(730, 18, -440)},
	{name = "Town", pos = CFrame.new(735, 18, 540)},
	{name = "Gas Station", pos = CFrame.new(156, 18, 882)},
	{name = "Donut Shop", pos = CFrame.new(-310, 18, 1660)},
	{name = "1M Dealership", pos = CFrame.new(-905, 18, -395)},
}
local BANK_WAYPOINTS = {
	CFrame.new(32, 18, 822),
	CFrame.new(28, 18, 782),
	CFrame.new(18, 0, 770),
	CFrame.new(18, -8, 760),
	CFrame.new(18, -8, 740),
}
local JEWELRY_WAYPOINTS = {
	CFrame.new(142, 18, 1365),
	CFrame.new(130, 18, 1355),
	CFrame.new(130, 22, 1340),
	CFrame.new(130, 30, 1340),
	CFrame.new(130, 40, 1340),
	CFrame.new(130, 50, 1340),
}
local CRIMINAL_BASE = CFrame.new(-222, 18, 1590)
local TEAM_COLORS = {
	Cop = Color3.fromRGB(80, 140, 255),
	Criminal = Color3.fromRGB(255, 80, 60),
	Prisoner = Color3.fromRGB(255, 165, 40),
	Unknown = Color3.fromRGB(200, 200, 200),
}
local function getMyRoot()
	local char = LP.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end
local function getMyHum()
	local char = LP.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end
local function getPlayerTeam(player)
	if not player.Team then return "Unknown" end
	local tn = player.Team.Name:lower()
	if tn:find("police") or tn:find("cop") or tn:find("guard") then return "Cop" end
	if tn:find("criminal") then return "Criminal" end
	if tn:find("prisoner") then return "Prisoner" end
	return "Unknown"
end
local function worldToScreen(pos)
	local sp, on = Camera:WorldToViewportPoint(pos)
	return Vector2.new(sp.X, sp.Y), on
end
local function distanceTo(worldPos)
	local root = getMyRoot()
	if not root then return math.huge end
	return (root.Position - worldPos).Magnitude
end
local function isVisible(origin, target)
	local direction = target - origin
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {LP.Character}
	params.FilterType = Enum.RaycastFilterType.Exclude
	local result = Workspace:Raycast(origin, direction, params)
	if result then return (result.Position - target).Magnitude < 3 end
	return true
end
local function predictPosition(targetPart, fromPosition)
	local distance = (targetPart.Position - fromPosition).Magnitude
	local root = targetPart.Parent and targetPart.Parent:FindFirstChild("HumanoidRootPart")
	if not root then return targetPart.Position end
	local velocity = root.AssemblyLinearVelocity
	if velocity.Magnitude < 2 then return targetPart.Position end
	local travelTime = distance / 1000
	return targetPart.Position + (velocity * travelTime)
end
local function setNoclipChar(enabled)
	pcall(function()
		local char = LP.Character; if not char then return end
		for _, part in char:GetDescendants() do
			if part:IsA("BasePart") then part.CanCollide = not enabled end
		end
	end)
end
local function smoothTeleport(targetCF)
	local root = getMyRoot()
	if not root then return end
	local startPos = root.Position
	local endPos = typeof(targetCF) == "CFrame" and targetCF.Position or targetCF
	local dist = (endPos - startPos).Magnitude
	if dist < 5 then root.CFrame = typeof(targetCF) == "CFrame" and targetCF or CFrame.new(targetCF); return end
	local speed = JBConfig.SmoothTP_Speed
	local stepSize = speed * 0.03
	local steps = math.ceil(dist / stepSize)
	steps = math.min(steps, 500)
	for i = 1, steps do
		root = getMyRoot()
		if not root or not root.Parent then return end
		local alpha = i / steps
		local newPos = startPos:Lerp(endPos, alpha)
		root.CFrame = CFrame.new(newPos)
		setNoclipChar(true)
		pcall(function()
			root.Velocity = Vector3.zero
			root.AssemblyLinearVelocity = Vector3.zero
		end)
		task.wait(0.03)
	end
	root = getMyRoot()
	if root then root.CFrame = typeof(targetCF) == "CFrame" and targetCF or CFrame.new(targetCF) end
end
local function teleportTo(cf)
	smoothTeleport(cf)
end
local function collectReward()
	pcall(function()
		for _, v in ReplicatedStorage:GetDescendants() do
			if v.Name == "RewardSpinnerCollectReward" and v:IsA("RemoteEvent") then
				v:FireServer("RobberyBonusReward")
			end
		end
	end)
end
local function findNearestCop()
	local closest, closestDist = nil, math.huge
	for _, player in Players:GetPlayers() do
		if player == LP then continue end
		local team = getPlayerTeam(player)
		if team ~= "Cop" then continue end
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then continue end
		local d = distanceTo(root.Position)
		if d < closestDist then closestDist = d; closest = player end
	end
	return closest
end
local autoRobActive = false
local function autoBank()
	if autoRobActive then return end
	autoRobActive = true
	task.spawn(function()
		while JBConfig.AutoBank_Enabled and autoRobActive do
			pcall(function()
				for _, wp in BANK_WAYPOINTS do
					if not JBConfig.AutoBank_Enabled then break end
					smoothTeleport(wp)
					task.wait(1)
				end
				if JBConfig.AutoBank_Enabled then
					task.wait(15)
					smoothTeleport(CRIMINAL_BASE)
					task.wait(3)
					collectReward()
					task.wait(5)
				end
			end)
			if JBConfig.AutoBank_Enabled then
				task.wait(120)
			end
		end
		autoRobActive = false
	end)
end
local function stopAutoRob()
	autoRobActive = false
	JBConfig.AutoBank_Enabled = false
	JBConfig.AutoJewelry_Enabled = false
end
local function autoJewelry()
	if autoRobActive then return end
	autoRobActive = true
	task.spawn(function()
		while JBConfig.AutoJewelry_Enabled and autoRobActive do
			pcall(function()
				for _, wp in JEWELRY_WAYPOINTS do
					if not JBConfig.AutoJewelry_Enabled then break end
					smoothTeleport(wp)
					task.wait(2)
				end
				if JBConfig.AutoJewelry_Enabled then
					task.wait(10)
					smoothTeleport(CRIMINAL_BASE)
					task.wait(3)
					collectReward()
					task.wait(5)
				end
			end)
			if JBConfig.AutoJewelry_Enabled then
				task.wait(120)
			end
		end
		autoRobActive = false
	end)
end
local pickpocketActive = false
local function autoPickpocket()
	if pickpocketActive then return end
	pickpocketActive = true
	task.spawn(function()
		while JBConfig.AutoPickpocket_Enabled and pickpocketActive do
			pcall(function()
				local cop = findNearestCop()
				if not cop then task.wait(2); return end
				local char = cop.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if not root then task.wait(1); return end
				local behindCF = root.CFrame * CFrame.new(0, 0, 3)
				smoothTeleport(behindCF)
				task.wait(0.3)
				pcall(function()
					VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
				end)
				task.wait(1.5)
				pcall(function()
					VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
				end)
				task.wait(1)
			end)
		end
		pickpocketActive = false
	end)
end
local function stopPickpocket()
	pickpocketActive = false
	JBConfig.AutoPickpocket_Enabled = false
end
local DrawingSupported = pcall(function() local t = Drawing.new("Line"); t:Remove() end)
local ESPCache = {}
local function createESP()
	if not DrawingSupported then return nil end
	local ok, d = pcall(function()
		local box = Drawing.new("Square"); box.Thickness = 1; box.Filled = false; box.Visible = false
		local name = Drawing.new("Text"); name.Center = true; name.Outline = true; name.Size = 13; name.Visible = false
		local health = Drawing.new("Text"); health.Center = true; health.Outline = true; health.Size = 12; health.Visible = false
		local dist = Drawing.new("Text"); dist.Center = true; dist.Outline = true; dist.Size = 11; dist.Color = Color3.fromRGB(180, 180, 180); dist.Visible = false
		local tracer = Drawing.new("Line"); tracer.Thickness = 1; tracer.Visible = false
		return {Box = box, Name = name, Health = health, Dist = dist, Tracer = tracer}
	end)
	return ok and d or nil
end
local function hideESP(d)
	if not d then return end
	pcall(function() d.Box.Visible = false; d.Name.Visible = false; d.Health.Visible = false; d.Dist.Visible = false; d.Tracer.Visible = false end)
end
local function updateESP()
	if not DrawingSupported then return end
	for _, player in Players:GetPlayers() do
		if player == LP then continue end
		if not ESPCache[player] then ESPCache[player] = createESP() end
		local d = ESPCache[player]
		if not d then continue end
		if not JBConfig.ESP_Enabled then hideESP(d); continue end
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local head = char and char:FindFirstChild("Head")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not root or not head or not hum or hum.Health <= 0 then hideESP(d); continue end
		local playerDist = distanceTo(root.Position)
		if playerDist > JBConfig.ESP_MaxDistance then hideESP(d); continue end
		local tp, to = worldToScreen(head.Position + Vector3.new(0, 1.5, 0))
		local bp, bo = worldToScreen(root.Position - Vector3.new(0, 3, 0))
		if not to and not bo then hideESP(d); continue end
		local team = getPlayerTeam(player)
		local col = JBConfig.ESP_TeamColors and TEAM_COLORS[team] or Color3.fromRGB(255, 255, 255)
		local h = math.abs(bp.Y - tp.Y); local w = h * 0.55
		if JBConfig.ESP_ShowBoxes then
			d.Box.Size = Vector2.new(w, h); d.Box.Position = Vector2.new(tp.X - w/2, tp.Y); d.Box.Color = col; d.Box.Visible = true
		else d.Box.Visible = false end
		if JBConfig.ESP_ShowNames then
			local tag = JBConfig.ESP_TeamColors and ("[" .. team:sub(1, 1) .. "] ") or ""
			d.Name.Text = tag .. player.DisplayName; d.Name.Position = Vector2.new(tp.X, tp.Y - 16); d.Name.Color = col; d.Name.Visible = true
		else d.Name.Visible = false end
		if JBConfig.ESP_ShowHealth then
			local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
			d.Health.Text = string.format("HP %d%%", pct * 100)
			d.Health.Color = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), pct)
			d.Health.Position = Vector2.new(tp.X, bp.Y + 2); d.Health.Visible = true
		else d.Health.Visible = false end
		if JBConfig.ESP_ShowDistance then
			d.Dist.Text = "[" .. math.floor(playerDist) .. "]"; d.Dist.Position = Vector2.new(tp.X, bp.Y + 16); d.Dist.Visible = true
		else d.Dist.Visible = false end
		if JBConfig.ESP_ShowTracers then
			d.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
			d.Tracer.To = bp; d.Tracer.Color = col; d.Tracer.Visible = true
		else d.Tracer.Visible = false end
	end
end
local FOVCircle
if DrawingSupported then
	pcall(function()
		FOVCircle = Drawing.new("Circle"); FOVCircle.Thickness = 1; FOVCircle.NumSides = 64
		FOVCircle.Filled = false; FOVCircle.Transparency = 0.6; FOVCircle.Color = Color3.fromRGB(255, 255, 255); FOVCircle.Visible = false
	end)
end
local AimbotTarget = nil
local function getClosestPlayerToFOV()
	local closest, closestDist = nil, JBConfig.Aimbot_FOV
	local center = Camera.ViewportSize / 2
	for _, player in Players:GetPlayers() do
		if player == LP then continue end
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not char or not root or not hum or hum.Health <= 0 then continue end
		local targetPart = char:FindFirstChild(JBConfig.Aimbot_TargetPart) or root
		local aimPos = JBConfig.Aimbot_Prediction and predictPosition(targetPart, Camera.CFrame.Position) or targetPart.Position
		local screenPos, onScreen = worldToScreen(aimPos)
		if not onScreen then continue end
		if JBConfig.Aimbot_WallCheck and not isVisible(Camera.CFrame.Position, targetPart.Position) then continue end
		local distFromCenter = (screenPos - center).Magnitude
		if distFromCenter < closestDist then closestDist = distFromCenter; closest = player end
	end
	return closest
end
local function updateAimbot()
	if FOVCircle then
		if JBConfig.Aimbot_ShowFOV and JBConfig.Aimbot_Enabled then
			FOVCircle.Position = Camera.ViewportSize / 2; FOVCircle.Radius = JBConfig.Aimbot_FOV; FOVCircle.Visible = true
		else FOVCircle.Visible = false end
	end
	if not JBConfig.Aimbot_Enabled then return end
	local aimHeld = JBConfig.Aimbot_UseRMB and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or false
	if not aimHeld then AimbotTarget = nil; return end
	if AimbotTarget then
		local char = AimbotTarget.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not root or not hum or hum.Health <= 0 then AimbotTarget = nil end
		if AimbotTarget and JBConfig.Aimbot_WallCheck and root then
			local tPart = char:FindFirstChild(JBConfig.Aimbot_TargetPart) or root
			if not isVisible(Camera.CFrame.Position, tPart.Position) then AimbotTarget = nil end
		end
	end
	if not AimbotTarget then AimbotTarget = getClosestPlayerToFOV() end
	if not AimbotTarget then return end
	local char = AimbotTarget.Character
	if not char then return end
	local targetPart = char:FindFirstChild(JBConfig.Aimbot_TargetPart) or char:FindFirstChild("HumanoidRootPart")
	if not targetPart then return end
	local aimPos = JBConfig.Aimbot_Prediction and predictPosition(targetPart, Camera.CFrame.Position) or targetPart.Position
	local goalCF = CFrame.lookAt(Camera.CFrame.Position, aimPos)
	Camera.CFrame = Camera.CFrame:Lerp(goalCF, 1 - JBConfig.Aimbot_Smoothness)
end
local Flying, FlyConnection = false, nil
local function startFly()
	local root = getMyRoot(); local hum = getMyHum()
	if not root or not hum then return end
	Flying = true
	pcall(function() hum.PlatformStand = true end)
	FlyConnection = RunService.RenderStepped:Connect(function(dt)
		if not Flying then return end
		local r = getMyRoot(); local h = getMyHum()
		if not r or not h then return end
		pcall(function()
			local dir = Vector3.zero
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end
			if dir.Magnitude > 0 then dir = dir.Unit end
			r.CFrame = r.CFrame + (dir * JBConfig.FlySpeed * dt)
			r.Velocity = Vector3.zero; r.AssemblyLinearVelocity = Vector3.zero
			h.PlatformStand = true
		end)
	end)
end
local function stopFly()
	Flying = false
	if FlyConnection then FlyConnection:Disconnect(); FlyConnection = nil end
	pcall(function() local h = getMyHum(); if h then h.PlatformStand = false end end)
end
local NoClipConnection = nil
local function startNoClip()
	NoClipConnection = RunService.Stepped:Connect(function()
		if not JBConfig.NoClipEnabled then return end
		setNoclipChar(true)
	end)
end
local function stopNoClip()
	if NoClipConnection then NoClipConnection:Disconnect(); NoClipConnection = nil end
end
local function applyCharacterMods()
	pcall(function()
		local hum = getMyHum(); if not hum then return end
		if JBConfig.SpeedEnabled then hum.WalkSpeed = JBConfig.SpeedValue end
		if JBConfig.JumpEnabled then hum.JumpPower = JBConfig.JumpValue end
	end)
end
local originalLighting = {}
local function enableFullbright()
	pcall(function()
		local lighting = game:GetService("Lighting")
		originalLighting.Ambient = lighting.Ambient
		originalLighting.Brightness = lighting.Brightness
		originalLighting.FogEnd = lighting.FogEnd
		originalLighting.GlobalShadows = lighting.GlobalShadows
		lighting.Ambient = Color3.fromRGB(255, 255, 255); lighting.Brightness = 2
		lighting.FogEnd = 1e6; lighting.GlobalShadows = false
		for _, effect in lighting:GetChildren() do
			if effect:IsA("Atmosphere") or effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") then
				effect.Enabled = false
			end
		end
	end)
end
local function disableFullbright()
	pcall(function()
		local lighting = game:GetService("Lighting")
		for key, value in originalLighting do lighting[key] = value end
		for _, effect in lighting:GetChildren() do
			if effect:IsA("Atmosphere") or effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") then
				effect.Enabled = true
			end
		end
	end)
end
local AntiAFKConnection = nil
local function enableAntiAFK()
	pcall(function()
		AntiAFKConnection = LP.Idled:Connect(function()
			pcall(function() VIM:SendMouseMoveEvent(1, 0, game); VIM:SendMouseMoveEvent(-1, 0, game) end)
		end)
	end)
end
local function disableAntiAFK()
	if AntiAFKConnection then AntiAFKConnection:Disconnect(); AntiAFKConnection = nil end
end
local function updateNitro()
	if not JBConfig.InfNitro_Enabled then return end
	pcall(function()
		local char = LP.Character; if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		local seat = hum and hum.SeatPart
		if not seat then return end
		local vehicle = seat.Parent
		if vehicle then
			for _, v in vehicle:GetDescendants() do
				if (v.Name == "Nitro" or v.Name == "NitroAmount" or v.Name:lower():find("nitro")) and v:IsA("ValueBase") then
					if typeof(v.Value) == "number" then v.Value = 100 end
				end
			end
		end
	end)
end
local function buildUI()
	local sg = Instance.new("ScreenGui"); sg.Name = "TeekHubJB"; sg.ResetOnSpawn = false; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	pcall(function() sg.Parent = game:GetService("CoreGui") end)
	if not sg.Parent then sg.Parent = LP:WaitForChild("PlayerGui") end
	local C = {
		bg1 = Color3.fromRGB(13,13,22), bg2 = Color3.fromRGB(18,18,30), bg3 = Color3.fromRGB(23,23,38),
		card = Color3.fromRGB(28,28,46), cardHover = Color3.fromRGB(35,35,56),
		accent = Color3.fromRGB(220,140,40), accentDim = Color3.fromRGB(170,105,25),
		green = Color3.fromRGB(45,200,95), red = Color3.fromRGB(220,55,65), redDim = Color3.fromRGB(50,40,55),
		text = Color3.fromRGB(235,235,242), textDim = Color3.fromRGB(120,120,150), textMuted = Color3.fromRGB(80,80,105),
		divider = Color3.fromRGB(40,40,60), warning = Color3.fromRGB(255,180,40), safe = Color3.fromRGB(45,200,95),
	}
	local WW,WH,SW,TH = 500,420,135,42
	local TF = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local TM = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local TS = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local function tw(o,p,i) TweenService:Create(o, i or TF, p):Play() end
	local main = Instance.new("Frame"); main.Name = "MainFrame"; main.Size = UDim2.new(0,0,0,0); main.Position = UDim2.new(0.5,0,0.5,0)
	main.BackgroundColor3 = C.bg3; main.BorderSizePixel = 0; main.Active = true; main.ClipsDescendants = true; main.Parent = sg
	Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)
	local mst = Instance.new("UIStroke"); mst.Color = C.accent; mst.Thickness = 1; mst.Transparency = 0.6; mst.Parent = main
	tw(main, {Size = UDim2.new(0,WW,0,WH), Position = UDim2.new(0.5,-WW/2,0.5,-WH/2)}, TM)
	local top = Instance.new("Frame"); top.Size = UDim2.new(1,0,0,TH); top.BackgroundColor3 = C.bg2; top.BorderSizePixel = 0; top.Parent = main
	Instance.new("UICorner", top).CornerRadius = UDim.new(0,10)
	local topF = Instance.new("Frame"); topF.Size = UDim2.new(1,0,0,10); topF.Position = UDim2.new(0,0,1,-10); topF.BackgroundColor3 = C.bg2; topF.BorderSizePixel = 0; topF.Parent = top
	local ico = Instance.new("Frame"); ico.Size = UDim2.new(0,30,0,30); ico.Position = UDim2.new(0,8,0.5,-15); ico.BackgroundColor3 = C.accent; ico.BorderSizePixel = 0; ico.Parent = top
	Instance.new("UICorner", ico).CornerRadius = UDim.new(0,7)
	local icoT = Instance.new("TextLabel"); icoT.Size = UDim2.new(1,0,1,0); icoT.BackgroundTransparency = 1; icoT.Text = "🚔"; icoT.TextColor3 = C.text; icoT.TextSize = 14; icoT.Font = Enum.Font.GothamBold; icoT.Parent = ico
	local ttl = Instance.new("TextLabel"); ttl.Size = UDim2.new(0,100,0,16); ttl.Position = UDim2.new(0,44,0,5); ttl.BackgroundTransparency = 1; ttl.Text = "TeekHub"; ttl.TextColor3 = C.text; ttl.TextSize = 14; ttl.Font = Enum.Font.GothamBold; ttl.TextXAlignment = Enum.TextXAlignment.Left; ttl.Parent = top
	local subt = Instance.new("TextLabel"); subt.Size = UDim2.new(0,100,0,13); subt.Position = UDim2.new(0,44,0,22); subt.BackgroundTransparency = 1; subt.Text = "Jailbreak"; subt.TextColor3 = C.textDim; subt.TextSize = 11; subt.Font = Enum.Font.Gotham; subt.TextXAlignment = Enum.TextXAlignment.Left; subt.Parent = top
	local teamDot = Instance.new("Frame"); teamDot.Size = UDim2.new(0,8,0,8); teamDot.Position = UDim2.new(0,150,0,26); teamDot.BackgroundColor3 = C.safe; teamDot.BorderSizePixel = 0; teamDot.Parent = top
	Instance.new("UICorner", teamDot).CornerRadius = UDim.new(1,0)
	local teamLbl = Instance.new("TextLabel"); teamLbl.Size = UDim2.new(0,70,0,13); teamLbl.Position = UDim2.new(0,162,0,22); teamLbl.BackgroundTransparency = 1; teamLbl.Text = "Ready"; teamLbl.TextColor3 = C.safe; teamLbl.TextSize = 10; teamLbl.Font = Enum.Font.GothamMedium; teamLbl.TextXAlignment = Enum.TextXAlignment.Left; teamLbl.Parent = top
	local tagF = Instance.new("Frame"); tagF.Size = UDim2.new(0,130,0,20); tagF.Position = UDim2.new(0,240,0.5,-10); tagF.BackgroundTransparency = 1; tagF.Parent = top
	local tl = Instance.new("UIListLayout"); tl.FillDirection = Enum.FillDirection.Horizontal; tl.Padding = UDim.new(0,5); tl.VerticalAlignment = Enum.VerticalAlignment.Center; tl.Parent = tagF
	local function mkTag(txt,col,ord)
		local f = Instance.new("Frame"); f.Size = UDim2.new(0, #txt*6.5+14, 0, 18); f.BackgroundColor3 = col; f.BackgroundTransparency = 0.15; f.BorderSizePixel = 0; f.LayoutOrder = ord; f.Parent = tagF
		Instance.new("UICorner", f).CornerRadius = UDim.new(0,4)
		local l = Instance.new("TextLabel"); l.Size = UDim2.new(1,0,1,0); l.BackgroundTransparency = 1; l.Text = txt; l.TextColor3 = col; l.TextSize = 9; l.Font = Enum.Font.GothamBold; l.Parent = f
	end
	mkTag("v2", C.accent, 1); mkTag("FREE", C.green, 2)
	local function mkWinBtn(txt,col,pos,cb)
		local b = Instance.new("TextButton"); b.Size = UDim2.new(0,24,0,24); b.Position = pos; b.BackgroundColor3 = col; b.BackgroundTransparency = 0.85
		b.Text = txt; b.TextColor3 = C.textDim; b.TextSize = 12; b.Font = Enum.Font.GothamBold; b.BorderSizePixel = 0; b.AutoButtonColor = false; b.Parent = top
		Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
		b.MouseEnter:Connect(function() tw(b,{BackgroundTransparency=0.3,TextColor3=C.text},TF) end)
		b.MouseLeave:Connect(function() tw(b,{BackgroundTransparency=0.85,TextColor3=C.textDim},TF) end)
		b.MouseButton1Click:Connect(cb)
	end
	local minimized = false
	mkWinBtn("—",C.warning,UDim2.new(1,-60,0.5,-12),function() minimized = not minimized; if minimized then tw(main,{Size=UDim2.new(0,WW,0,TH)},TS) else tw(main,{Size=UDim2.new(0,WW,0,WH)},TM) end end)
	mkWinBtn("✕",C.red,UDim2.new(1,-32,0.5,-12),function() tw(main,{Size=UDim2.new(0,0,0,0),Position=UDim2.new(0.5,0,0.5,0)},TS); task.delay(0.3,function() main.Visible = false end) end)
	local dragging,dragStart,startPos = false,nil,nil
	top.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging=true;dragStart=input.Position;startPos=main.Position;input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end) end end)
	UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then local d=input.Position-dragStart;main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y) end end)
	local sidebar = Instance.new("Frame"); sidebar.Size = UDim2.new(0,SW,1,-TH); sidebar.Position = UDim2.new(0,0,0,TH); sidebar.BackgroundColor3 = C.bg1; sidebar.BorderSizePixel = 0; sidebar.Parent = main
	Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0,10)
	local sf1 = Instance.new("Frame"); sf1.Size = UDim2.new(1,0,0,10); sf1.BackgroundColor3 = C.bg1; sf1.BorderSizePixel = 0; sf1.Parent = sidebar
	local sf2 = Instance.new("Frame"); sf2.Size = UDim2.new(0,10,1,0); sf2.Position = UDim2.new(1,-10,0,0); sf2.BackgroundColor3 = C.bg1; sf2.BorderSizePixel = 0; sf2.Parent = sidebar
	local dv = Instance.new("Frame"); dv.Size = UDim2.new(0,1,1,-24); dv.Position = UDim2.new(1,0,0,12); dv.BackgroundColor3 = C.divider; dv.BorderSizePixel = 0; dv.Parent = sidebar
	local navC = Instance.new("Frame"); navC.Size = UDim2.new(1,-14,1,-20); navC.Position = UDim2.new(0,7,0,14); navC.BackgroundTransparency = 1; navC.Parent = sidebar
	local nl = Instance.new("UIListLayout"); nl.Padding = UDim.new(0,2); nl.SortOrder = Enum.SortOrder.LayoutOrder; nl.Parent = navC
	local content = Instance.new("Frame"); content.Size = UDim2.new(1,-(SW+14),1,-(TH+10)); content.Position = UDim2.new(0,SW+7,0,TH+5); content.BackgroundTransparency = 1; content.ClipsDescendants = true; content.Parent = main
	local pages,navBtns,activeTab = {},{},nil
	local tabsList = {
		{n="Auto Rob",i="💰",d="Farm money"},
		{n="Teleport",i="🗺",d="Fast travel"},
		{n="ESP",i="👁",d="Player overlays"},
		{n="Aimbot",i="🎯",d="Target lock"},
		{n="Movement",i="🏃",d="Fly & clip"},
		{n="Misc",i="⚙",d="Utilities"},
	}
	for _,t in tabsList do
		local p = Instance.new("ScrollingFrame"); p.Size = UDim2.new(1,0,1,0); p.BackgroundTransparency = 1; p.ScrollBarThickness = 2; p.ScrollBarImageColor3 = C.accent; p.BorderSizePixel = 0; p.Visible = false; p.CanvasSize = UDim2.new(0,0,0,0); p.AutomaticCanvasSize = Enum.AutomaticSize.Y; p.Parent = content
		local pl = Instance.new("UIListLayout"); pl.Padding = UDim.new(0,4); pl.SortOrder = Enum.SortOrder.LayoutOrder; pl.Parent = p
		pages[t.n] = p
	end
	local function switchTab(name)
		activeTab = name
		for n,p in pages do p.Visible = (n == name); if n == name then p.CanvasPosition = Vector2.new(0,0) end end
		for n,b in navBtns do
			if n == name then tw(b.f,{BackgroundColor3=C.accent,BackgroundTransparency=0},TF); tw(b.l,{TextColor3=C.text},TF); tw(b.s,{TextColor3=Color3.fromRGB(255,220,160)},TF)
			else tw(b.f,{BackgroundTransparency=1},TF); tw(b.l,{TextColor3=C.textDim},TF); tw(b.s,{TextColor3=C.textMuted},TF) end
		end
	end
	for i,t in tabsList do
		local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1,0,0,40); btn.BackgroundTransparency = 1; btn.BackgroundColor3 = C.accent; btn.Text = ""; btn.BorderSizePixel = 0; btn.LayoutOrder = i; btn.AutoButtonColor = false; btn.Parent = navC
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0,7)
		local iL = Instance.new("TextLabel"); iL.Size = UDim2.new(0,20,0,20); iL.Position = UDim2.new(0,8,0.5,-10); iL.BackgroundTransparency = 1; iL.Text = t.i; iL.TextSize = 13; iL.Parent = btn
		local nL = Instance.new("TextLabel"); nL.Size = UDim2.new(1,-34,0,14); nL.Position = UDim2.new(0,32,0,5); nL.BackgroundTransparency = 1; nL.Text = t.n; nL.TextColor3 = C.textDim; nL.TextSize = 12; nL.Font = Enum.Font.GothamBold; nL.TextXAlignment = Enum.TextXAlignment.Left; nL.Parent = btn
		local dL = Instance.new("TextLabel"); dL.Size = UDim2.new(1,-34,0,11); dL.Position = UDim2.new(0,32,0,20); dL.BackgroundTransparency = 1; dL.Text = t.d; dL.TextColor3 = C.textMuted; dL.TextSize = 9; dL.Font = Enum.Font.Gotham; dL.TextXAlignment = Enum.TextXAlignment.Left; dL.Parent = btn
		navBtns[t.n] = {f=btn, l=nL, s=dL}
		btn.MouseButton1Click:Connect(function() switchTab(t.n) end)
		btn.MouseEnter:Connect(function() if activeTab ~= t.n then tw(btn,{BackgroundColor3=C.cardHover,BackgroundTransparency=0},TF) end end)
		btn.MouseLeave:Connect(function() if activeTab ~= t.n then tw(btn,{BackgroundTransparency=1},TF) end end)
	end
	local function mkLabel(par,txt,ord)
		local l = Instance.new("TextLabel"); l.Size = UDim2.new(1,0,0,20); l.BackgroundTransparency = 1; l.Text = "  "..txt; l.TextColor3 = C.textMuted; l.TextSize = 9; l.Font = Enum.Font.GothamBold; l.TextXAlignment = Enum.TextXAlignment.Left; l.LayoutOrder = ord or 0; l.Parent = par
	end
	local function mkToggle(par,txt,def,cb,ord)
		local row = Instance.new("Frame"); row.Size = UDim2.new(1,0,0,34); row.BackgroundColor3 = C.card; row.BorderSizePixel = 0; row.LayoutOrder = ord or 0; row.Parent = par
		Instance.new("UICorner", row).CornerRadius = UDim.new(0,7)
		local l = Instance.new("TextLabel"); l.Size = UDim2.new(1,-65,1,0); l.Position = UDim2.new(0,14,0,0); l.BackgroundTransparency = 1; l.Text = txt; l.TextColor3 = C.text; l.TextSize = 12; l.Font = Enum.Font.GothamMedium; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = row
		local pill = Instance.new("Frame"); pill.Size = UDim2.new(0,38,0,20); pill.Position = UDim2.new(1,-48,0.5,-10); pill.BackgroundColor3 = def and C.green or C.redDim; pill.BorderSizePixel = 0; pill.Parent = row
		Instance.new("UICorner", pill).CornerRadius = UDim.new(1,0)
		local knob = Instance.new("Frame"); knob.Size = UDim2.new(0,16,0,16); knob.Position = def and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8); knob.BackgroundColor3 = C.text; knob.BorderSizePixel = 0; knob.Parent = pill
		Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
		local state = def
		local ca = Instance.new("TextButton"); ca.Size = UDim2.new(1,0,1,0); ca.BackgroundTransparency = 1; ca.Text = ""; ca.Parent = row
		ca.MouseButton1Click:Connect(function()
			state = not state
			tw(pill,{BackgroundColor3 = state and C.green or C.redDim},TF)
			tw(knob,{Position = state and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)},TF)
			pcall(cb, state)
		end)
		row.MouseEnter:Connect(function() tw(row,{BackgroundColor3=C.cardHover},TF) end)
		row.MouseLeave:Connect(function() tw(row,{BackgroundColor3=C.card},TF) end)
	end
	local function mkCycle(par,txt,vals,def,cb,ord)
		local idx = 1; for i,v in vals do if v == def then idx = i; break end end
		local row = Instance.new("Frame"); row.Size = UDim2.new(1,0,0,34); row.BackgroundColor3 = C.card; row.BorderSizePixel = 0; row.LayoutOrder = ord or 0; row.Parent = par
		Instance.new("UICorner", row).CornerRadius = UDim.new(0,7)
		local l = Instance.new("TextLabel"); l.Size = UDim2.new(0.55,0,1,0); l.Position = UDim2.new(0,14,0,0); l.BackgroundTransparency = 1; l.Text = txt; l.TextColor3 = C.text; l.TextSize = 12; l.Font = Enum.Font.GothamMedium; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = row
		local vb = Instance.new("TextButton"); vb.Size = UDim2.new(0,60,0,22); vb.Position = UDim2.new(1,-68,0.5,-11); vb.BackgroundColor3 = C.accentDim; vb.Text = tostring(vals[idx]); vb.TextColor3 = C.text; vb.TextSize = 11; vb.Font = Enum.Font.GothamBold; vb.BorderSizePixel = 0; vb.AutoButtonColor = false; vb.Parent = row
		Instance.new("UICorner", vb).CornerRadius = UDim.new(0,5)
		vb.MouseButton1Click:Connect(function() idx = idx % #vals + 1; vb.Text = tostring(vals[idx]); pcall(cb, vals[idx]) end)
		vb.MouseEnter:Connect(function() tw(vb,{BackgroundColor3=C.accent},TF) end); vb.MouseLeave:Connect(function() tw(vb,{BackgroundColor3=C.accentDim},TF) end)
		row.MouseEnter:Connect(function() tw(row,{BackgroundColor3=C.cardHover},TF) end); row.MouseLeave:Connect(function() tw(row,{BackgroundColor3=C.card},TF) end)
	end
	local function mkDivider(par,ord)
		local d = Instance.new("Frame"); d.Size = UDim2.new(1,-20,0,1); d.Position = UDim2.new(0,10,0,0); d.BackgroundColor3 = C.divider; d.BorderSizePixel = 0; d.LayoutOrder = ord or 0; d.Parent = par
	end
	local function mkButton(par,txt,col,cb,ord)
		local b = Instance.new("TextButton"); b.Size = UDim2.new(1,0,0,30); b.BackgroundColor3 = col or C.card; b.Text = txt; b.TextColor3 = C.text; b.TextSize = 11; b.Font = Enum.Font.GothamBold; b.BorderSizePixel = 0; b.LayoutOrder = ord or 0; b.AutoButtonColor = false; b.Parent = par
		Instance.new("UICorner", b).CornerRadius = UDim.new(0,7)
		b.MouseButton1Click:Connect(function() pcall(cb); tw(b,{BackgroundColor3=C.green},TF); task.delay(0.4,function() tw(b,{BackgroundColor3=col or C.card},TF) end) end)
		b.MouseEnter:Connect(function() tw(b,{BackgroundColor3=C.cardHover},TF) end)
		b.MouseLeave:Connect(function() tw(b,{BackgroundColor3=col or C.card},TF) end)
	end
	-- AUTO ROB TAB
	local ar = pages["Auto Rob"]
	mkLabel(ar,"ROBBERIES",1)
	mkToggle(ar,"Auto Bank",JBConfig.AutoBank_Enabled,function(v)
		JBConfig.AutoBank_Enabled = v
		if v then JBConfig.AutoJewelry_Enabled = false; autoBank()
		else stopAutoRob() end
	end,2)
	mkToggle(ar,"Auto Jewelry",JBConfig.AutoJewelry_Enabled,function(v)
		JBConfig.AutoJewelry_Enabled = v
		if v then JBConfig.AutoBank_Enabled = false; autoJewelry()
		else stopAutoRob() end
	end,3)
	mkDivider(ar,4); mkLabel(ar,"PICKPOCKET",5)
	mkToggle(ar,"Auto Pickpocket",JBConfig.AutoPickpocket_Enabled,function(v)
		JBConfig.AutoPickpocket_Enabled = v
		if v then autoPickpocket() else stopPickpocket() end
	end,6)
	mkDivider(ar,7); mkLabel(ar,"REWARDS",8)
	mkToggle(ar,"Auto Collect Reward",JBConfig.AutoReward_Enabled,function(v) JBConfig.AutoReward_Enabled = v end,9)
	mkButton(ar,"💰  Collect Reward Now",C.accent,function() collectReward() end,10)
	mkDivider(ar,11); mkLabel(ar,"SETTINGS",12)
	mkCycle(ar,"TP Speed",{100,150,200,300,500},JBConfig.SmoothTP_Speed,function(v) JBConfig.SmoothTP_Speed = v end,13)
	mkDivider(ar,14); mkLabel(ar,"QUICK TRAVEL",15)
	mkButton(ar,"🏦  Go to Bank",C.card,function() teleportTo(CFrame.new(32, 18, 822)) end,16)
	mkButton(ar,"💎  Go to Jewelry",C.card,function() teleportTo(CFrame.new(142, 18, 1365)) end,17)
	mkButton(ar,"🏴  Go to Criminal Base",C.card,function() teleportTo(CRIMINAL_BASE) end,18)
	-- TELEPORT TAB
	local tpPage = pages["Teleport"]
	mkLabel(tpPage,"ROBBERIES",1)
	local ord = 2
	for i,spot in SPOTS do
		if i <= 9 then
			mkButton(tpPage,"📍  "..spot.name,C.card,function() teleportTo(spot.pos) end,ord)
			ord += 1
		end
	end
	mkDivider(tpPage,ord); ord += 1
	mkLabel(tpPage,"LOCATIONS",ord); ord += 1
	for i,spot in SPOTS do
		if i > 9 then
			mkButton(tpPage,"📍  "..spot.name,C.card,function() teleportTo(spot.pos) end,ord)
			ord += 1
		end
	end
	-- ESP TAB
	local ep = pages["ESP"]
	mkLabel(ep,"PLAYER ESP",1)
	mkToggle(ep,"ESP Enabled",JBConfig.ESP_Enabled,function(v) JBConfig.ESP_Enabled = v; if not v then for _,d in ESPCache do hideESP(d) end end end,2)
	mkDivider(ep,3); mkLabel(ep,"COMPONENTS",4)
	mkToggle(ep,"Boxes",JBConfig.ESP_ShowBoxes,function(v) JBConfig.ESP_ShowBoxes = v end,5)
	mkToggle(ep,"Names",JBConfig.ESP_ShowNames,function(v) JBConfig.ESP_ShowNames = v end,6)
	mkToggle(ep,"Health",JBConfig.ESP_ShowHealth,function(v) JBConfig.ESP_ShowHealth = v end,7)
	mkToggle(ep,"Distance",JBConfig.ESP_ShowDistance,function(v) JBConfig.ESP_ShowDistance = v end,8)
	mkToggle(ep,"Tracers",JBConfig.ESP_ShowTracers,function(v) JBConfig.ESP_ShowTracers = v end,9)
	mkDivider(ep,10); mkLabel(ep,"COLORS",11)
	mkToggle(ep,"Team Colors",JBConfig.ESP_TeamColors,function(v) JBConfig.ESP_TeamColors = v end,12)
	local teamKey = Instance.new("Frame"); teamKey.Size = UDim2.new(1,0,0,50); teamKey.BackgroundColor3 = C.bg2; teamKey.BorderSizePixel = 0; teamKey.LayoutOrder = 13; teamKey.Parent = ep
	Instance.new("UICorner", teamKey).CornerRadius = UDim.new(0,7)
	local keyTxt = Instance.new("TextLabel"); keyTxt.Size = UDim2.new(1,-16,1,-8); keyTxt.Position = UDim2.new(0,8,0,4); keyTxt.BackgroundTransparency = 1
	keyTxt.Text = "🔵 Cop   🔴 Criminal   🟠 Prisoner"; keyTxt.TextColor3 = C.textDim; keyTxt.TextSize = 10; keyTxt.Font = Enum.Font.Gotham; keyTxt.TextWrapped = true; keyTxt.TextXAlignment = Enum.TextXAlignment.Left; keyTxt.Parent = teamKey
	-- AIMBOT TAB
	local ap = pages["Aimbot"]
	mkLabel(ap,"MAIN",1)
	mkToggle(ap,"Aimbot (hold RMB)",JBConfig.Aimbot_Enabled,function(v) JBConfig.Aimbot_Enabled = v end,2)
	mkToggle(ap,"Show FOV Circle",JBConfig.Aimbot_ShowFOV,function(v) JBConfig.Aimbot_ShowFOV = v end,3)
	mkDivider(ap,4); mkLabel(ap,"PREDICTION",5)
	mkToggle(ap,"Aim Prediction",JBConfig.Aimbot_Prediction,function(v) JBConfig.Aimbot_Prediction = v end,6)
	mkDivider(ap,7); mkLabel(ap,"CHECKS",8)
	mkToggle(ap,"Wall Check",JBConfig.Aimbot_WallCheck,function(v) JBConfig.Aimbot_WallCheck = v end,9)
	mkDivider(ap,10); mkLabel(ap,"TUNING",11)
	mkCycle(ap,"FOV Radius",{60,80,100,120,150,200,300},JBConfig.Aimbot_FOV,function(v) JBConfig.Aimbot_FOV = v end,12)
	mkCycle(ap,"Smoothness",{0,0.1,0.25,0.4,0.6,0.8},JBConfig.Aimbot_Smoothness,function(v) JBConfig.Aimbot_Smoothness = v end,13)
	-- MOVEMENT TAB
	local mp = pages["Movement"]
	mkLabel(mp,"SPEED",1)
	mkToggle(mp,"Speed Hack",JBConfig.SpeedEnabled,function(v) JBConfig.SpeedEnabled = v end,2)
	mkCycle(mp,"Walk Speed",{26,32,40,50,75,100},JBConfig.SpeedValue,function(v) JBConfig.SpeedValue = v end,3)
	mkDivider(mp,4); mkLabel(mp,"JUMP",5)
	mkToggle(mp,"Jump Hack",JBConfig.JumpEnabled,function(v) JBConfig.JumpEnabled = v end,6)
	mkCycle(mp,"Jump Power",{50,80,100,150,200},JBConfig.JumpValue,function(v) JBConfig.JumpValue = v end,7)
	mkDivider(mp,8); mkLabel(mp,"FLIGHT",9)
	mkToggle(mp,"Fly (CFrame)",JBConfig.FlyEnabled,function(v) JBConfig.FlyEnabled = v; if v then startFly() else stopFly() end end,10)
	mkCycle(mp,"Fly Speed",{40,60,80,120,200,300},JBConfig.FlySpeed,function(v) JBConfig.FlySpeed = v end,11)
	mkDivider(mp,12); mkLabel(mp,"COLLISION",13)
	mkToggle(mp,"NoClip",JBConfig.NoClipEnabled,function(v) JBConfig.NoClipEnabled = v; if v then startNoClip() else stopNoClip() end end,14)
	-- MISC TAB
	local misc = pages["Misc"]
	mkLabel(misc,"VISUALS",1)
	mkToggle(misc,"Fullbright",JBConfig.Fullbright_Enabled,function(v) JBConfig.Fullbright_Enabled = v; if v then enableFullbright() else disableFullbright() end end,2)
	mkDivider(misc,3); mkLabel(misc,"VEHICLE",4)
	mkToggle(misc,"Infinite Nitro",JBConfig.InfNitro_Enabled,function(v) JBConfig.InfNitro_Enabled = v end,5)
	mkButton(misc,"💥  Eject from Vehicle",C.card,function() pcall(function() local hum = getMyHum(); if hum then hum.Sit = false end end) end,6)
	mkDivider(misc,7); mkLabel(misc,"ANTI-KICK",8)
	mkToggle(misc,"Anti-AFK",JBConfig.AntiAFK_Enabled,function(v) JBConfig.AntiAFK_Enabled = v; if v then enableAntiAFK() else disableAntiAFK() end end,9)
	mkDivider(misc,10); mkLabel(misc,"CONTROLS",11)
	local function mkInfoRow(par,k,v,ord)
		local r = Instance.new("Frame"); r.Size = UDim2.new(1,0,0,28); r.BackgroundColor3 = C.card; r.BorderSizePixel = 0; r.LayoutOrder = ord; r.Parent = par
		Instance.new("UICorner", r).CornerRadius = UDim.new(0,6)
		local kl = Instance.new("TextLabel"); kl.Size = UDim2.new(0.5,0,1,0); kl.Position = UDim2.new(0,14,0,0); kl.BackgroundTransparency = 1; kl.Text = k; kl.TextColor3 = C.textDim; kl.TextSize = 11; kl.Font = Enum.Font.Gotham; kl.TextXAlignment = Enum.TextXAlignment.Left; kl.Parent = r
		local vl = Instance.new("TextLabel"); vl.Size = UDim2.new(0.45,0,1,0); vl.Position = UDim2.new(0.5,0,0,0); vl.BackgroundTransparency = 1; vl.Text = v; vl.TextColor3 = C.text; vl.TextSize = 11; vl.Font = Enum.Font.GothamMedium; vl.TextXAlignment = Enum.TextXAlignment.Right; vl.Parent = r
	end
	mkInfoRow(misc,"Toggle UI","RightCtrl",12)
	mkInfoRow(misc,"Aimbot","Hold RMB",13)
	mkInfoRow(misc,"Fly Controls","WASD + Space/Shift",14)
	mkInfoRow(misc,"Smooth TP","Anti-cheat safe",15)
	switchTab("Auto Rob")
	task.spawn(function()
		while task.wait(0.5) do
			pcall(function()
				local team = getPlayerTeam(LP)
				local col = TEAM_COLORS[team] or C.safe
				teamDot.BackgroundColor3 = col; teamLbl.Text = team; teamLbl.TextColor3 = col
			end)
		end
	end)
	return sg
end
local gui = buildUI()
RunService.RenderStepped:Connect(function()
	pcall(updateESP)
	pcall(updateAimbot)
	pcall(applyCharacterMods)
	pcall(updateNitro)
end)
Players.PlayerRemoving:Connect(function(p)
	if ESPCache[p] then
		pcall(function() for _,obj in ESPCache[p] do obj:Remove() end end)
		ESPCache[p] = nil
	end
end)
LP.CharacterAdded:Connect(function()
	task.wait(0.5)
	applyCharacterMods()
	if JBConfig.FlyEnabled then stopFly(); task.wait(0.2); startFly() end
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.RightControl then
		local mf = gui.MainFrame
		if mf.Visible then
			TweenService:Create(mf, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0,0,0,0), Position = UDim2.new(0.5,0,0.5,0)}):Play()
			task.delay(0.25, function() mf.Visible = false end)
		else
			mf.Visible = true; mf.Size = UDim2.new(0,0,0,0); mf.Position = UDim2.new(0.5,0,0.5,0)
			TweenService:Create(mf, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0,500,0,420), Position = UDim2.new(0.5,-250,0.5,-210)}):Play()
		end
	end
end)
print("[TeekHub] Jailbreak v2 loaded")
print("[TeekHub] Auto Rob | Teleport | ESP | Aimbot | Movement | Misc")
print("[TeekHub] Smooth TP enabled — anti-cheat safe movement")
