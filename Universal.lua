local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local TweenService     = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Config = {
	ESP_Enabled      = false,
	ESP_ShowBoxes    = true,
	ESP_ShowNames    = true,
	ESP_ShowHealth   = true,
	ESP_ShowDistance  = true,
	ESP_ShowTracers  = false,
	ESP_TeamCheck    = false,
	ESP_MaxDistance   = 1000,
	ESP_BoxColor     = Color3.fromRGB(255, 50, 50),
	ESP_NameColor    = Color3.fromRGB(255, 255, 255),
	ESP_HealthHigh   = Color3.fromRGB(0, 255, 0),
	ESP_HealthLow    = Color3.fromRGB(255, 0, 0),
	Aimbot_Enabled     = false,
	Aimbot_UseRMB      = true,
	Aimbot_FOV          = 120,
	Aimbot_Smoothness   = 0.25,
	Aimbot_TargetPart   = "Head",
	Aimbot_TeamCheck    = false,
	Aimbot_WallCheck    = true,
	Aimbot_ShowFOV      = true,
	Aimbot_Prediction   = true,
	SpeedEnabled  = false,
	SpeedValue    = 26,
	JumpEnabled   = false,
	JumpValue     = 70,
	FlyEnabled    = false,
	FlySpeed      = 60,
	NoClipEnabled = false,
	Fullbright_Enabled  = false,
	Crosshair_Enabled   = false,
	Crosshair_Size      = 12,
	Crosshair_Thickness = 1.5,
	Crosshair_Color     = Color3.fromRGB(0, 255, 0),
	Crosshair_Gap       = 4,
	FOV_Enabled         = false,
	FOV_Value           = 100,
	AntiAFK_Enabled     = false,
}
local Utility = {}
function Utility.shouldSkipPlayer(player, useTeamCheck)
	if player == LocalPlayer then return true end
	if not useTeamCheck then return false end
	local myTeam    = LocalPlayer.Team
	local theirTeam = player.Team
	if myTeam == nil or theirTeam == nil then return false end
	if myTeam.Name == "" or theirTeam.Name == "" then return false end
	return myTeam == theirTeam
end
function Utility.getCharacterParts(player)
	local char = player.Character
	if not char then return nil, nil, nil end
	local root = char:FindFirstChild("HumanoidRootPart")
	local hum  = char:FindFirstChildOfClass("Humanoid")
	return char, root, hum
end
function Utility.worldToScreen(pos)
	local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
	return Vector2.new(screenPos.X, screenPos.Y), onScreen
end
function Utility.distanceTo(worldPos)
	local _, root = Utility.getCharacterParts(LocalPlayer)
	if not root then return math.huge end
	return (root.Position - worldPos).Magnitude
end
function Utility.isVisible(origin, target)
	local direction = target - origin
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { LocalPlayer.Character }
	params.FilterType = Enum.RaycastFilterType.Exclude
	local result = Workspace:Raycast(origin, direction, params)
	if result then
		return (result.Position - target).Magnitude < 3
	end
	return true
end
function Utility.lerpCFrame(a, b, alpha)
	return a:Lerp(b, alpha)
end
function Utility.predictPosition(targetPart, fromPosition)
	local distance = (targetPart.Position - fromPosition).Magnitude
	local root = targetPart.Parent and targetPart.Parent:FindFirstChild("HumanoidRootPart")
	if not root then return targetPart.Position end
	local velocity = root.AssemblyLinearVelocity
	if velocity.Magnitude < 2 then
		return targetPart.Position
	end
	local bulletSpeed = 1000
	local travelTime = distance / bulletSpeed
	local predicted = targetPart.Position + (velocity * travelTime)
	return predicted
end
local ESPCache = {}
local DrawingSupported = pcall(function()
	local t = Drawing.new("Line"); t:Remove()
end)
local function createESP()
	if not DrawingSupported then return nil end
	local ok, drawing = pcall(function()
		local box = Drawing.new("Square")
		box.Thickness = 1; box.Filled = false
		box.Color = Config.ESP_BoxColor; box.Visible = false
		local name = Drawing.new("Text")
		name.Center = true; name.Outline = true
		name.Size = 14; name.Color = Config.ESP_NameColor; name.Visible = false
		local health = Drawing.new("Text")
		health.Center = true; health.Outline = true
		health.Size = 13; health.Visible = false
		local dist = Drawing.new("Text")
		dist.Center = true; dist.Outline = true
		dist.Size = 12; dist.Color = Color3.fromRGB(200, 200, 200); dist.Visible = false
		local tracer = Drawing.new("Line")
		tracer.Thickness = 1; tracer.Color = Config.ESP_BoxColor; tracer.Visible = false
		return { Box = box, Name = name, Health = health, Distance = dist, Tracer = tracer }
	end)
	return ok and drawing or nil
end
local function destroyESP(drawing)
	if not drawing then return end
	for _, obj in drawing do
		pcall(function() obj:Remove() end)
	end
end
local function hideESP(drawing)
	if not drawing then return end
	for _, obj in drawing do
		pcall(function() obj.Visible = false end)
	end
end
local FOVCircle
if DrawingSupported then
	pcall(function()
		FOVCircle = Drawing.new("Circle")
		FOVCircle.Thickness    = 1
		FOVCircle.NumSides     = 64
		FOVCircle.Filled       = false
		FOVCircle.Transparency = 0.6
		FOVCircle.Color        = Color3.fromRGB(255, 255, 255)
		FOVCircle.Visible      = false
	end)
end
local CrosshairLines = {}
if DrawingSupported then
	pcall(function()
		for i = 1, 4 do
			local line = Drawing.new("Line")
			line.Thickness = Config.Crosshair_Thickness
			line.Color     = Config.Crosshair_Color
			line.Visible   = false
			CrosshairLines[i] = line
		end
	end)
end
local function updateCrosshair()
	if not DrawingSupported or #CrosshairLines < 4 then return end
	if not Config.Crosshair_Enabled then
		for _, line in CrosshairLines do
			line.Visible = false
		end
		return
	end
	local center = Camera.ViewportSize / 2
	local size = Config.Crosshair_Size
	local gap  = Config.Crosshair_Gap
	CrosshairLines[1].From    = Vector2.new(center.X, center.Y - gap)
	CrosshairLines[1].To      = Vector2.new(center.X, center.Y - gap - size)
	CrosshairLines[1].Color   = Config.Crosshair_Color
	CrosshairLines[1].Visible = true
	CrosshairLines[2].From    = Vector2.new(center.X, center.Y + gap)
	CrosshairLines[2].To      = Vector2.new(center.X, center.Y + gap + size)
	CrosshairLines[2].Color   = Config.Crosshair_Color
	CrosshairLines[2].Visible = true
	CrosshairLines[3].From    = Vector2.new(center.X - gap, center.Y)
	CrosshairLines[3].To      = Vector2.new(center.X - gap - size, center.Y)
	CrosshairLines[3].Color   = Config.Crosshair_Color
	CrosshairLines[3].Visible = true
	CrosshairLines[4].From    = Vector2.new(center.X + gap, center.Y)
	CrosshairLines[4].To      = Vector2.new(center.X + gap + size, center.Y)
	CrosshairLines[4].Color   = Config.Crosshair_Color
	CrosshairLines[4].Visible = true
end
local function updateESP()
	if not DrawingSupported then return end
	for _, player in Players:GetPlayers() do
		if player == LocalPlayer then continue end
		if not ESPCache[player] then
			ESPCache[player] = createESP()
		end
		local drawing = ESPCache[player]
		if not drawing then continue end
		local char, root, hum = Utility.getCharacterParts(player)
		if not Config.ESP_Enabled
			or not root or not hum
			or hum.Health <= 0
			or Utility.shouldSkipPlayer(player, Config.ESP_TeamCheck)
		then
			hideESP(drawing); continue
		end
		local dist = Utility.distanceTo(root.Position)
		if dist > Config.ESP_MaxDistance then
			hideESP(drawing); continue
		end
		local head = char:FindFirstChild("Head")
		if not head then hideESP(drawing); continue end
		local topPos, topOn    = Utility.worldToScreen(head.Position + Vector3.new(0, 1.5, 0))
		local bottomPos, botOn = Utility.worldToScreen(root.Position - Vector3.new(0, 3, 0))
		if not topOn and not botOn then
			hideESP(drawing); continue
		end
		local boxHeight = math.abs(bottomPos.Y - topPos.Y)
		local boxWidth  = boxHeight * 0.55
		if Config.ESP_ShowBoxes then
			drawing.Box.Size     = Vector2.new(boxWidth, boxHeight)
			drawing.Box.Position = Vector2.new(topPos.X - boxWidth / 2, topPos.Y)
			drawing.Box.Color    = Config.ESP_BoxColor
			drawing.Box.Visible  = true
		else
			drawing.Box.Visible = false
		end
		if Config.ESP_ShowNames then
			drawing.Name.Text     = player.DisplayName
			drawing.Name.Position = Vector2.new(topPos.X, topPos.Y - 16)
			drawing.Name.Visible  = true
		else
			drawing.Name.Visible = false
		end
		if Config.ESP_ShowHealth then
			local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
			drawing.Health.Text     = string.format("HP %d%%", pct * 100)
			drawing.Health.Color    = Config.ESP_HealthLow:Lerp(Config.ESP_HealthHigh, pct)
			drawing.Health.Position = Vector2.new(topPos.X, bottomPos.Y + 2)
			drawing.Health.Visible  = true
		else
			drawing.Health.Visible = false
		end
		if Config.ESP_ShowDistance then
			drawing.Distance.Text     = string.format("[%d studs]", dist)
			drawing.Distance.Position = Vector2.new(topPos.X, bottomPos.Y + 16)
			drawing.Distance.Visible  = true
		else
			drawing.Distance.Visible = false
		end
		if Config.ESP_ShowTracers then
			local viewSize = Camera.ViewportSize
			drawing.Tracer.From    = Vector2.new(viewSize.X / 2, viewSize.Y)
			drawing.Tracer.To      = bottomPos
			drawing.Tracer.Color   = Config.ESP_BoxColor
			drawing.Tracer.Visible = true
		else
			drawing.Tracer.Visible = false
		end
	end
end
local AimbotTarget = nil
local function getClosestPlayerToFOV()
	local closest = nil
	local closestDist = Config.Aimbot_FOV
	local center = Camera.ViewportSize / 2
	for _, player in Players:GetPlayers() do
		if Utility.shouldSkipPlayer(player, Config.Aimbot_TeamCheck) then continue end
		local char, root, hum = Utility.getCharacterParts(player)
		if not char or not root or not hum or hum.Health <= 0 then continue end
		local targetPart = char:FindFirstChild(Config.Aimbot_TargetPart) or root
		local aimPos
		if Config.Aimbot_Prediction then
			aimPos = Utility.predictPosition(targetPart, Camera.CFrame.Position)
		else
			aimPos = targetPart.Position
		end
		local screenPos, onScreen = Utility.worldToScreen(aimPos)
		if not onScreen then continue end
		if Config.Aimbot_WallCheck then
			if not Utility.isVisible(Camera.CFrame.Position, targetPart.Position) then continue end
		end
		local distFromCenter = (screenPos - center).Magnitude
		if distFromCenter < closestDist then
			closestDist = distFromCenter
			closest = player
		end
	end
	return closest
end
local function updateAimbot()
	if FOVCircle then
		if Config.Aimbot_ShowFOV and Config.Aimbot_Enabled then
			FOVCircle.Position = Camera.ViewportSize / 2
			FOVCircle.Radius   = Config.Aimbot_FOV
			FOVCircle.Visible  = true
		else
			FOVCircle.Visible = false
		end
	end
	if not Config.Aimbot_Enabled then return end
	local aimHeld = false
	if Config.Aimbot_UseRMB then
		aimHeld = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
	end
	if not aimHeld then
		AimbotTarget = nil; return
	end
	if AimbotTarget then
		local char, root, hum = Utility.getCharacterParts(AimbotTarget)
		if not root or not hum or hum.Health <= 0 then
			AimbotTarget = nil
		end
		if AimbotTarget and Config.Aimbot_WallCheck and root then
			local targetPart = char:FindFirstChild(Config.Aimbot_TargetPart) or root
			if not Utility.isVisible(Camera.CFrame.Position, targetPart.Position) then
				AimbotTarget = nil
			end
		end
	end
	if not AimbotTarget then AimbotTarget = getClosestPlayerToFOV() end
	if not AimbotTarget then return end
	local char = AimbotTarget.Character
	if not char then return end
	local targetPart = char:FindFirstChild(Config.Aimbot_TargetPart)
		or char:FindFirstChild("HumanoidRootPart")
	if not targetPart then return end
	local aimPos
	if Config.Aimbot_Prediction then
		aimPos = Utility.predictPosition(targetPart, Camera.CFrame.Position)
	else
		aimPos = targetPart.Position
	end
	local goalCF = CFrame.lookAt(Camera.CFrame.Position, aimPos)
	Camera.CFrame = Utility.lerpCFrame(Camera.CFrame, goalCF, 1 - Config.Aimbot_Smoothness)
end
local originalLighting = {}
local function enableFullbright()
	pcall(function()
		local lighting = game:GetService("Lighting")
		originalLighting.Ambient       = lighting.Ambient
		originalLighting.Brightness    = lighting.Brightness
		originalLighting.FogEnd        = lighting.FogEnd
		originalLighting.GlobalShadows = lighting.GlobalShadows
		lighting.Ambient       = Color3.fromRGB(255, 255, 255)
		lighting.Brightness    = 2
		lighting.FogEnd        = 1e6
		lighting.GlobalShadows = false
		for _, effect in lighting:GetChildren() do
			if effect:IsA("Atmosphere") or effect:IsA("BloomEffect")
				or effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") then
				effect.Enabled = false
			end
		end
	end)
end
local function disableFullbright()
	pcall(function()
		local lighting = game:GetService("Lighting")
		for key, value in originalLighting do
			lighting[key] = value
		end
		for _, effect in lighting:GetChildren() do
			if effect:IsA("Atmosphere") or effect:IsA("BloomEffect")
				or effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") then
				effect.Enabled = true
			end
		end
	end)
end
local OriginalFOV = Camera.FieldOfView
local function updateFOV()
	if Config.FOV_Enabled then
		Camera.FieldOfView = Config.FOV_Value
	end
end
local function resetFOV()
	Camera.FieldOfView = OriginalFOV
end
local function applyCharacterMods()
	pcall(function()
		local _, _, hum = Utility.getCharacterParts(LocalPlayer)
		if not hum then return end
		if Config.SpeedEnabled then hum.WalkSpeed = Config.SpeedValue end
		if Config.JumpEnabled then hum.JumpPower = Config.JumpValue end
	end)
end
local Flying = false
local FlyConnection = nil
local function startFly()
	local _, root, hum = Utility.getCharacterParts(LocalPlayer)
	if not root or not hum then return end
	Flying = true
	pcall(function() hum.PlatformStand = true end)
	FlyConnection = RunService.RenderStepped:Connect(function(dt)
		if not Flying then return end
		local _, currentRoot, currentHum = Utility.getCharacterParts(LocalPlayer)
		if not currentRoot or not currentHum then return end
		pcall(function()
			local dir = Vector3.zero
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end
			if dir.Magnitude > 0 then dir = dir.Unit end
			currentRoot.CFrame = currentRoot.CFrame + (dir * Config.FlySpeed * dt)
			currentRoot.Velocity = Vector3.zero
			currentRoot.AssemblyLinearVelocity = Vector3.zero
			currentHum.PlatformStand = true
		end)
	end)
end
local function stopFly()
	Flying = false
	if FlyConnection then FlyConnection:Disconnect(); FlyConnection = nil end
	pcall(function()
		local _, _, hum = Utility.getCharacterParts(LocalPlayer)
		if hum then hum.PlatformStand = false end
	end)
end
local NoClipConnection = nil
local function startNoClip()
	NoClipConnection = RunService.Stepped:Connect(function()
		if not Config.NoClipEnabled then return end
		pcall(function()
			local char = LocalPlayer.Character
			if not char then return end
			for _, part in char:GetDescendants() do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end)
	end)
end
local function stopNoClip()
	if NoClipConnection then NoClipConnection:Disconnect(); NoClipConnection = nil end
end
local AntiAFKConnection = nil
local function enableAntiAFK()
	pcall(function()
		local idleConn = LocalPlayer.Idled
		if idleConn then
			AntiAFKConnection = LocalPlayer.Idled:Connect(function()
				pcall(function()
					local vim = game:GetService("VirtualInputManager")
					vim:SendMouseMoveEvent(1, 0, game)
					vim:SendMouseMoveEvent(-1, 0, game)
				end)
			end)
			print("[ScriptHub] Anti-AFK: Hooked Idled event")
		end
	end)
end
local function disableAntiAFK()
	if AntiAFKConnection then
		AntiAFKConnection:Disconnect()
		AntiAFKConnection = nil
	end
end
local StaminaEnabled = false
local function updateStamina()
	if not StaminaEnabled then return end
	pcall(function()
		local char = LocalPlayer.Character
		if not char then return end
		local staminaNames = {"Stamina", "Energy", "Sprint", "SprintStamina", "Hunger", "Thirst", "Endurance"}
		for _, name in staminaNames do
			local val = char:FindFirstChild(name, true)
			if val and (val:IsA("NumberValue") or val:IsA("IntValue")) then
				val.Value = 100
			end
			local pg = LocalPlayer:FindFirstChild("PlayerGui")
			if pg then
				local pgVal = pg:FindFirstChild(name, true)
				if pgVal and (pgVal:IsA("NumberValue") or pgVal:IsA("IntValue")) then
					pgVal.Value = 100
				end
			end
		end
		for attrName, attrValue in char:GetAttributes() do
			local lower = string.lower(attrName)
			if string.find(lower, "stamina") or string.find(lower, "energy")
				or string.find(lower, "sprint") or string.find(lower, "endurance") then
				if typeof(attrValue) == "number" then
					char:SetAttribute(attrName, 100)
				end
			end
		end
		for attrName, attrValue in LocalPlayer:GetAttributes() do
			local lower = string.lower(attrName)
			if string.find(lower, "stamina") or string.find(lower, "energy")
				or string.find(lower, "sprint") then
				if typeof(attrValue) == "number" then
					LocalPlayer:SetAttribute(attrName, 100)
				end
			end
		end
	end)
end
local function buildUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name           = "ScriptHub"
	screenGui.ResetOnSpawn   = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local ok = pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
	if not ok then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
	local SIDEBAR_BG   = Color3.fromRGB(16, 16, 26)
	local TOPBAR_BG    = Color3.fromRGB(22, 22, 34)
	local CONTENT_BG   = Color3.fromRGB(26, 26, 40)
	local CARD_BG      = Color3.fromRGB(32, 32, 50)
	local ACCENT       = Color3.fromRGB(110, 90, 230)
	local ACCENT_HOVER = Color3.fromRGB(130, 110, 250)
	local GREEN        = Color3.fromRGB(50, 200, 90)
	local RED_DIM      = Color3.fromRGB(55, 55, 70)
	local TEXT_WHITE   = Color3.fromRGB(240, 240, 245)
	local TEXT_DIM     = Color3.fromRGB(130, 130, 155)
	local TAG_PURPLE   = Color3.fromRGB(110, 80, 220)
	local TAG_GREEN    = Color3.fromRGB(50, 180, 100)
	local TAG_ORANGE   = Color3.fromRGB(230, 140, 40)
	local DIVIDER      = Color3.fromRGB(45, 45, 65)
	local WINDOW_W     = 520
	local WINDOW_H     = 400
	local SIDEBAR_W    = 140
	local TOPBAR_H     = 40
	local NAV_BTN_H    = 34
	local main = Instance.new("Frame")
	main.Name             = "MainFrame"
	main.Size             = UDim2.new(0, 0, 0, 0)
	main.Position         = UDim2.new(0.5, 0, 0.5, 0)
	main.BackgroundColor3 = CONTENT_BG
	main.BorderSizePixel  = 0
	main.Active           = true
	main.ClipsDescendants = true
	main.Parent           = screenGui
	Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
	local TWEEN_FAST = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local TWEEN_MED = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local TWEEN_SMOOTH = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local function tween(obj, props, info)
		TweenService:Create(obj, info or TWEEN_FAST, props):Play()
	end
	tween(main, {
		Size = UDim2.new(0, WINDOW_W, 0, WINDOW_H),
		Position = UDim2.new(0.5, -WINDOW_W/2, 0.5, -WINDOW_H/2)
	}, TWEEN_MED)
	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color        = ACCENT
	mainStroke.Thickness    = 1
	mainStroke.Transparency = 0.7
	mainStroke.Parent       = main
	local topBar = Instance.new("Frame")
	topBar.Size             = UDim2.new(1, 0, 0, TOPBAR_H)
	topBar.BackgroundColor3 = TOPBAR_BG
	topBar.BorderSizePixel  = 0
	topBar.Parent           = main
	Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 12)
	local topBarFill = Instance.new("Frame")
	topBarFill.Size             = UDim2.new(1, 0, 0, 12)
	topBarFill.Position         = UDim2.new(0, 0, 1, -12)
	topBarFill.BackgroundColor3 = TOPBAR_BG
	topBarFill.BorderSizePixel  = 0
	topBarFill.Parent           = topBar
	local hubIcon = Instance.new("TextLabel")
	hubIcon.Size              = UDim2.new(0, 32, 0, 32)
	hubIcon.Position          = UDim2.new(0, 10, 0.5, -16)
	hubIcon.BackgroundColor3  = ACCENT
	hubIcon.Text              = "⚡"
	hubIcon.TextSize          = 16
	hubIcon.Font              = Enum.Font.GothamBold
	hubIcon.TextColor3        = TEXT_WHITE
	hubIcon.BorderSizePixel   = 0
	hubIcon.Parent            = topBar
	Instance.new("UICorner", hubIcon).CornerRadius = UDim.new(0, 8)
	local hubTitle = Instance.new("TextLabel")
	hubTitle.Size              = UDim2.new(0, 100, 0, 18)
	hubTitle.Position          = UDim2.new(0, 48, 0, 4)
	hubTitle.BackgroundTransparency = 1
	hubTitle.Text              = "TeekHub"
	hubTitle.TextColor3        = TEXT_WHITE
	hubTitle.TextSize          = 15
	hubTitle.Font              = Enum.Font.GothamBold
	hubTitle.TextXAlignment    = Enum.TextXAlignment.Left
	hubTitle.Parent            = topBar
	local devLabel = Instance.new("TextLabel")
	devLabel.Size              = UDim2.new(0, 100, 0, 14)
	devLabel.Position          = UDim2.new(0, 48, 0, 22)
	devLabel.BackgroundTransparency = 1
	devLabel.Text              = "Dev  @Teek"
	devLabel.TextColor3        = TEXT_DIM
	devLabel.TextSize          = 11
	devLabel.Font              = Enum.Font.Gotham
	devLabel.TextXAlignment    = Enum.TextXAlignment.Left
	devLabel.Parent            = topBar
	local tagContainer = Instance.new("Frame")
	tagContainer.Size              = UDim2.new(0, 250, 0, 22)
	tagContainer.Position          = UDim2.new(0, 155, 0.5, -11)
	tagContainer.BackgroundTransparency = 1
	tagContainer.Parent            = topBar
	local tagListLayout = Instance.new("UIListLayout")
	tagListLayout.FillDirection = Enum.FillDirection.Horizontal
	tagListLayout.Padding       = UDim.new(0, 6)
	tagListLayout.SortOrder     = Enum.SortOrder.LayoutOrder
	tagListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tagListLayout.Parent        = tagContainer
	local function makeTag(text, color, order)
		local tag = Instance.new("TextLabel")
		tag.Size              = UDim2.new(0, #text * 7 + 16, 0, 20)
		tag.BackgroundColor3  = color
		tag.Text              = text
		tag.TextColor3        = TEXT_WHITE
		tag.TextSize          = 10
		tag.Font              = Enum.Font.GothamBold
		tag.BorderSizePixel   = 0
		tag.LayoutOrder       = order
		tag.Parent            = tagContainer
		Instance.new("UICorner", tag).CornerRadius = UDim.new(0, 6)
	end
	makeTag("v4!", TAG_PURPLE, 1)
	makeTag("Universal", TAG_GREEN, 2)
	makeTag("Free!", TAG_ORANGE, 3)
	local function makeWindowBtn(text, posOffset, callback)
		local btn = Instance.new("TextButton")
		btn.Size             = UDim2.new(0, 28, 0, 28)
		btn.Position         = UDim2.new(1, posOffset, 0.5, -14)
		btn.BackgroundTransparency = 1
		btn.Text             = text
		btn.TextColor3       = TEXT_DIM
		btn.TextSize         = 16
		btn.Font             = Enum.Font.GothamBold
		btn.BorderSizePixel  = 0
		btn.AutoButtonColor  = false
		btn.Parent           = topBar
		btn.MouseButton1Click:Connect(callback)
		btn.MouseEnter:Connect(function() tween(btn, {TextColor3 = TEXT_WHITE}, TWEEN_FAST) end)
		btn.MouseLeave:Connect(function() tween(btn, {TextColor3 = TEXT_DIM}, TWEEN_FAST) end)
		return btn
	end
	local minimized = false
	makeWindowBtn("—", -60, function()
		if not minimized then
			minimized = true
			tween(main, {Size = UDim2.new(0, WINDOW_W, 0, TOPBAR_H)}, TWEEN_SMOOTH)
		else
			minimized = false
			tween(main, {Size = UDim2.new(0, WINDOW_W, 0, WINDOW_H)}, TWEEN_MED)
		end
	end)
	makeWindowBtn("✕", -30, function()
		tween(main, {
			Size = UDim2.new(0, 0, 0, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0)
		}, TWEEN_SMOOTH)
		task.delay(0.3, function() main.Visible = false end)
	end)
	local dragging, dragStart, startPos = false, nil, nil
	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = input.Position; startPos = main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
	local sidebar = Instance.new("Frame")
	sidebar.Size             = UDim2.new(0, SIDEBAR_W, 1, -TOPBAR_H)
	sidebar.Position         = UDim2.new(0, 0, 0, TOPBAR_H)
	sidebar.BackgroundColor3 = SIDEBAR_BG
	sidebar.BorderSizePixel  = 0
	sidebar.Parent           = main
	Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 12)
	local sidebarTopFill = Instance.new("Frame")
	sidebarTopFill.Size             = UDim2.new(1, 0, 0, 12)
	sidebarTopFill.BackgroundColor3 = SIDEBAR_BG
	sidebarTopFill.BorderSizePixel  = 0
	sidebarTopFill.Parent           = sidebar
	local sidebarRightFill = Instance.new("Frame")
	sidebarRightFill.Size             = UDim2.new(0, 12, 1, 0)
	sidebarRightFill.Position         = UDim2.new(1, -12, 0, 0)
	sidebarRightFill.BackgroundColor3 = SIDEBAR_BG
	sidebarRightFill.BorderSizePixel  = 0
	sidebarRightFill.Parent           = sidebar
	local sidebarDivider = Instance.new("Frame")
	sidebarDivider.Size             = UDim2.new(0, 1, 1, -20)
	sidebarDivider.Position         = UDim2.new(1, 0, 0, 10)
	sidebarDivider.BackgroundColor3 = DIVIDER
	sidebarDivider.BorderSizePixel  = 0
	sidebarDivider.Parent           = sidebar
	local navContainer = Instance.new("Frame")
	navContainer.Size              = UDim2.new(1, -12, 1, -60)
	navContainer.Position          = UDim2.new(0, 6, 0, 16)
	navContainer.BackgroundTransparency = 1
	navContainer.Parent            = sidebar
	local navLayout = Instance.new("UIListLayout")
	navLayout.Padding   = UDim.new(0, 3)
	navLayout.SortOrder = Enum.SortOrder.LayoutOrder
	navLayout.Parent    = navContainer
	local userInfo = Instance.new("Frame")
	userInfo.Size              = UDim2.new(1, -12, 0, 40)
	userInfo.Position          = UDim2.new(0, 6, 1, -46)
	userInfo.BackgroundColor3  = Color3.fromRGB(24, 24, 38)
	userInfo.BorderSizePixel   = 0
	userInfo.Parent            = sidebar
	Instance.new("UICorner", userInfo).CornerRadius = UDim.new(0, 8)
	local avatarCircle = Instance.new("TextLabel")
	avatarCircle.Size             = UDim2.new(0, 28, 0, 28)
	avatarCircle.Position         = UDim2.new(0, 6, 0.5, -14)
	avatarCircle.BackgroundColor3 = ACCENT
	avatarCircle.Text             = string.sub(LocalPlayer.DisplayName, 1, 1)
	avatarCircle.TextColor3       = TEXT_WHITE
	avatarCircle.TextSize         = 14
	avatarCircle.Font             = Enum.Font.GothamBold
	avatarCircle.BorderSizePixel  = 0
	avatarCircle.Parent           = userInfo
	Instance.new("UICorner", avatarCircle).CornerRadius = UDim.new(1, 0)
	local userName = Instance.new("TextLabel")
	userName.Size              = UDim2.new(1, -42, 0, 16)
	userName.Position          = UDim2.new(0, 38, 0, 4)
	userName.BackgroundTransparency = 1
	userName.Text              = LocalPlayer.DisplayName
	userName.TextColor3        = TEXT_WHITE
	userName.TextSize          = 11
	userName.Font              = Enum.Font.GothamMedium
	userName.TextXAlignment    = Enum.TextXAlignment.Left
	userName.TextTruncate      = Enum.TextTruncate.AtEnd
	userName.Parent            = userInfo
	local userHandle = Instance.new("TextLabel")
	userHandle.Size              = UDim2.new(1, -42, 0, 12)
	userHandle.Position          = UDim2.new(0, 38, 0, 20)
	userHandle.BackgroundTransparency = 1
	userHandle.Text              = "@" .. LocalPlayer.Name
	userHandle.TextColor3        = TEXT_DIM
	userHandle.TextSize          = 10
	userHandle.Font              = Enum.Font.Gotham
	userHandle.TextXAlignment    = Enum.TextXAlignment.Left
	userHandle.TextTruncate      = Enum.TextTruncate.AtEnd
	userHandle.Parent            = userInfo
	local contentArea = Instance.new("Frame")
	contentArea.Size              = UDim2.new(1, -(SIDEBAR_W + 16), 1, -(TOPBAR_H + 12))
	contentArea.Position          = UDim2.new(0, SIDEBAR_W + 8, 0, TOPBAR_H + 6)
	contentArea.BackgroundTransparency = 1
	contentArea.ClipsDescendants  = true
	contentArea.Parent            = main
	local pages = {}
	local navButtons = {}
	local activeTab = nil
	local tabDefs = {
		{ name = "ESP",      icon = "👁" },
		{ name = "Aimbot",   icon = "🎯" },
		{ name = "Movement", icon = "🏃" },
		{ name = "Visuals",  icon = "🎨" },
		{ name = "Players",  icon = "👥" },
		{ name = "Misc",     icon = "⚙" },
	}
	for _, def in tabDefs do
		local page = Instance.new("ScrollingFrame")
		page.Size                   = UDim2.new(1, 0, 1, 0)
		page.BackgroundTransparency = 1
		page.ScrollBarThickness     = 3
		page.ScrollBarImageColor3   = ACCENT
		page.BorderSizePixel        = 0
		page.Visible                = false
		page.CanvasSize             = UDim2.new(0, 0, 0, 0)
		page.AutomaticCanvasSize    = Enum.AutomaticSize.Y
		page.Parent                 = contentArea
		local pl = Instance.new("UIListLayout")
		pl.Padding   = UDim.new(0, 4)
		pl.SortOrder = Enum.SortOrder.LayoutOrder
		pl.Parent    = page
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 2)
		pad.Parent     = page
		pages[def.name] = page
	end
	local function switchTab(tabName)
		activeTab = tabName
		for name, page in pages do
			if name == tabName then
				page.Visible = true
				page.GroupTransparency = 1
				tween(page, {GroupTransparency = 0}, TWEEN_FAST)
			else
				page.Visible = false
			end
		end
		for name, btn in navButtons do
			if name == tabName then
				tween(btn, {BackgroundColor3 = ACCENT, BackgroundTransparency = 0, TextColor3 = TEXT_WHITE}, TWEEN_FAST)
			else
				tween(btn, {BackgroundTransparency = 1, TextColor3 = TEXT_DIM}, TWEEN_FAST)
			end
		end
	end
	for i, def in tabDefs do
		local btn = Instance.new("TextButton")
		btn.Size              = UDim2.new(1, 0, 0, NAV_BTN_H)
		btn.BackgroundTransparency = 1
		btn.BackgroundColor3  = ACCENT
		btn.Text              = "  " .. def.icon .. "  " .. def.name
		btn.TextColor3        = TEXT_DIM
		btn.TextSize          = 13
		btn.Font              = Enum.Font.GothamMedium
		btn.TextXAlignment    = Enum.TextXAlignment.Left
		btn.BorderSizePixel   = 0
		btn.LayoutOrder       = i
		btn.AutoButtonColor   = false
		btn.Parent            = navContainer
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		navButtons[def.name] = btn
		btn.MouseButton1Click:Connect(function() switchTab(def.name) end)
		btn.MouseEnter:Connect(function()
			if activeTab ~= def.name then
				tween(btn, {BackgroundColor3 = Color3.fromRGB(40, 40, 60), BackgroundTransparency = 0}, TWEEN_FAST)
			end
		end)
		btn.MouseLeave:Connect(function()
			if activeTab ~= def.name then
				tween(btn, {BackgroundTransparency = 1}, TWEEN_FAST)
			end
		end)
	end
	local function makeToggle(parent, label, default, callback, layoutOrder)
		local container = Instance.new("Frame")
		container.Size              = UDim2.new(1, 0, 0, 30)
		container.BackgroundColor3  = CARD_BG
		container.BorderSizePixel   = 0
		container.LayoutOrder       = layoutOrder or 0
		container.Parent            = parent
		Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)
		local lbl = Instance.new("TextLabel")
		lbl.Size              = UDim2.new(1, -60, 1, 0)
		lbl.Position          = UDim2.new(0, 12, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text              = label
		lbl.TextColor3        = TEXT_WHITE
		lbl.TextSize          = 12
		lbl.Font              = Enum.Font.GothamMedium
		lbl.TextXAlignment    = Enum.TextXAlignment.Left
		lbl.Parent            = container
		local toggle = Instance.new("TextButton")
		toggle.Size             = UDim2.new(0, 40, 0, 20)
		toggle.Position         = UDim2.new(1, -48, 0.5, -10)
		toggle.BackgroundColor3 = default and GREEN or RED_DIM
		toggle.Text             = default and "ON" or "OFF"
		toggle.TextColor3       = TEXT_WHITE
		toggle.TextSize         = 10
		toggle.Font             = Enum.Font.GothamBold
		toggle.BorderSizePixel  = 0
		toggle.Parent           = container
		Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 5)
		local state = default
		local function doToggle()
			state = not state
			toggle.Text = state and "ON" or "OFF"
			tween(toggle, {BackgroundColor3 = state and GREEN or RED_DIM}, TWEEN_FAST)
			tween(toggle, {Size = UDim2.new(0, 44, 0, 22)}, TweenInfo.new(0.08))
			task.delay(0.08, function()
				tween(toggle, {Size = UDim2.new(0, 40, 0, 20)}, TweenInfo.new(0.08))
			end)
			pcall(callback, state)
		end
		toggle.MouseButton1Click:Connect(doToggle)
		container.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then doToggle() end
		end)
		container.MouseEnter:Connect(function()
			tween(container, {BackgroundColor3 = Color3.fromRGB(42, 42, 62)}, TWEEN_FAST)
		end)
		container.MouseLeave:Connect(function()
			tween(container, {BackgroundColor3 = CARD_BG}, TWEEN_FAST)
		end)
		return container
	end
	local function makeLabel(parent, text, layoutOrder)
		local lbl = Instance.new("TextLabel")
		lbl.Size              = UDim2.new(1, 0, 0, 22)
		lbl.BackgroundTransparency = 1
		lbl.Text              = text
		lbl.TextColor3        = ACCENT
		lbl.TextSize          = 11
		lbl.Font              = Enum.Font.GothamBold
		lbl.TextXAlignment    = Enum.TextXAlignment.Left
		lbl.LayoutOrder       = layoutOrder or 0
		lbl.Parent            = parent
	end
	local function makeCycleButton(parent, label, values, default, callback, layoutOrder)
		local index = 1
		for i, v in values do
			if v == default then index = i; break end
		end
		local container = Instance.new("Frame")
		container.Size              = UDim2.new(1, 0, 0, 30)
		container.BackgroundColor3  = CARD_BG
		container.BorderSizePixel   = 0
		container.LayoutOrder       = layoutOrder or 0
		container.Parent            = parent
		Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)
		local lbl = Instance.new("TextLabel")
		lbl.Size              = UDim2.new(0.6, 0, 1, 0)
		lbl.Position          = UDim2.new(0, 12, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text              = label
		lbl.TextColor3        = TEXT_WHITE
		lbl.TextSize          = 12
		lbl.Font              = Enum.Font.GothamMedium
		lbl.TextXAlignment    = Enum.TextXAlignment.Left
		lbl.Parent            = container
		local valBtn = Instance.new("TextButton")
		valBtn.Size             = UDim2.new(0, 55, 0, 20)
		valBtn.Position         = UDim2.new(1, -63, 0.5, -10)
		valBtn.BackgroundColor3 = ACCENT
		valBtn.Text             = tostring(values[index])
		valBtn.TextColor3       = TEXT_WHITE
		valBtn.TextSize         = 11
		valBtn.Font             = Enum.Font.GothamBold
		valBtn.BorderSizePixel  = 0
		valBtn.Parent           = container
		Instance.new("UICorner", valBtn).CornerRadius = UDim.new(0, 5)
		valBtn.MouseButton1Click:Connect(function()
			index = index % #values + 1
			valBtn.Text = tostring(values[index])
			tween(valBtn, {Size = UDim2.new(0, 60, 0, 22)}, TweenInfo.new(0.06))
			task.delay(0.06, function()
				tween(valBtn, {Size = UDim2.new(0, 55, 0, 20)}, TweenInfo.new(0.06))
			end)
			pcall(callback, values[index])
		end)
		container.MouseEnter:Connect(function()
			tween(container, {BackgroundColor3 = Color3.fromRGB(42, 42, 62)}, TWEEN_FAST)
		end)
		container.MouseLeave:Connect(function()
			tween(container, {BackgroundColor3 = CARD_BG}, TWEEN_FAST)
		end)
		return container
	end
	local function makeDivider(parent, layoutOrder)
		local div = Instance.new("Frame")
		div.Size              = UDim2.new(1, 0, 0, 1)
		div.BackgroundColor3  = DIVIDER
		div.BorderSizePixel   = 0
		div.LayoutOrder       = layoutOrder or 0
		div.Parent            = parent
	end
	local esp = pages["ESP"]
	makeLabel(esp, "MAIN", 1)
	makeToggle(esp, "ESP Enabled", Config.ESP_Enabled, function(v)
		Config.ESP_Enabled = v
		if not v then for _, d in ESPCache do hideESP(d) end end
	end, 2)
	makeDivider(esp, 3)
	makeLabel(esp, "COMPONENTS", 4)
	makeToggle(esp, "Boxes", Config.ESP_ShowBoxes, function(v) Config.ESP_ShowBoxes = v end, 5)
	makeToggle(esp, "Names", Config.ESP_ShowNames, function(v) Config.ESP_ShowNames = v end, 6)
	makeToggle(esp, "Health Bars", Config.ESP_ShowHealth, function(v) Config.ESP_ShowHealth = v end, 7)
	makeToggle(esp, "Distance", Config.ESP_ShowDistance, function(v) Config.ESP_ShowDistance = v end, 8)
	makeToggle(esp, "Tracers", Config.ESP_ShowTracers, function(v) Config.ESP_ShowTracers = v end, 9)
	makeDivider(esp, 10)
	makeLabel(esp, "FILTERS", 11)
	makeToggle(esp, "Team Check", Config.ESP_TeamCheck, function(v) Config.ESP_TeamCheck = v end, 12)
	local aim = pages["Aimbot"]
	makeLabel(aim, "MAIN", 1)
	makeToggle(aim, "Aimbot (hold RMB)", Config.Aimbot_Enabled, function(v) Config.Aimbot_Enabled = v end, 2)
	makeToggle(aim, "Show FOV Circle", Config.Aimbot_ShowFOV, function(v) Config.Aimbot_ShowFOV = v end, 3)
	makeDivider(aim, 4)
	makeLabel(aim, "PREDICTION", 5)
	makeToggle(aim, "Aim Prediction", Config.Aimbot_Prediction, function(v) Config.Aimbot_Prediction = v end, 6)
	makeDivider(aim, 7)
	makeLabel(aim, "CHECKS", 8)
	makeToggle(aim, "Wall Check", Config.Aimbot_WallCheck, function(v) Config.Aimbot_WallCheck = v end, 9)
	makeToggle(aim, "Team Check", Config.Aimbot_TeamCheck, function(v) Config.Aimbot_TeamCheck = v end, 10)
	makeDivider(aim, 11)
	makeLabel(aim, "TARGET", 12)
	do
		local targetContainer = Instance.new("Frame")
		targetContainer.Size              = UDim2.new(1, 0, 0, 30)
		targetContainer.BackgroundColor3  = CARD_BG
		targetContainer.BorderSizePixel   = 0
		targetContainer.LayoutOrder       = 13
		targetContainer.Parent            = aim
		Instance.new("UICorner", targetContainer).CornerRadius = UDim.new(0, 6)
		local targetLbl = Instance.new("TextLabel")
		targetLbl.Size              = UDim2.new(0.5, 0, 1, 0)
		targetLbl.Position          = UDim2.new(0, 12, 0, 0)
		targetLbl.BackgroundTransparency = 1
		targetLbl.Text              = "Target Part"
		targetLbl.TextColor3        = TEXT_WHITE
		targetLbl.TextSize          = 12
		targetLbl.Font              = Enum.Font.GothamMedium
		targetLbl.TextXAlignment    = Enum.TextXAlignment.Left
		targetLbl.Parent            = targetContainer
		local targetVal = Instance.new("TextButton")
		targetVal.Size             = UDim2.new(0, 55, 0, 20)
		targetVal.Position         = UDim2.new(1, -63, 0.5, -10)
		targetVal.BackgroundColor3 = TAG_PURPLE
		targetVal.Text             = Config.Aimbot_TargetPart == "Head" and "Head" or "Torso"
		targetVal.TextColor3       = TEXT_WHITE
		targetVal.TextSize         = 10
		targetVal.Font             = Enum.Font.GothamBold
		targetVal.BorderSizePixel  = 0
		targetVal.Parent           = targetContainer
		Instance.new("UICorner", targetVal).CornerRadius = UDim.new(0, 5)
		targetVal.MouseButton1Click:Connect(function()
			if Config.Aimbot_TargetPart == "Head" then
				Config.Aimbot_TargetPart = "HumanoidRootPart"
				targetVal.Text = "Torso"
			else
				Config.Aimbot_TargetPart = "Head"
				targetVal.Text = "Head"
			end
		end)
	end
	makeDivider(aim, 14)
	makeLabel(aim, "TUNING", 15)
	makeCycleButton(aim, "FOV Radius", {60, 80, 100, 120, 150, 200, 300}, Config.Aimbot_FOV, function(v)
		Config.Aimbot_FOV = v
	end, 16)
	makeCycleButton(aim, "Smoothness", {0, 0.1, 0.25, 0.4, 0.6, 0.8}, Config.Aimbot_Smoothness, function(v)
		Config.Aimbot_Smoothness = v
	end, 17)
	local move = pages["Movement"]
	makeLabel(move, "SPEED", 1)
	makeToggle(move, "Speed Hack", Config.SpeedEnabled, function(v) Config.SpeedEnabled = v end, 2)
	makeCycleButton(move, "Walk Speed", {20, 26, 32, 40, 50, 75, 100}, Config.SpeedValue, function(v)
		Config.SpeedValue = v
	end, 3)
	makeDivider(move, 4)
	makeLabel(move, "JUMP", 5)
	makeToggle(move, "Jump Hack", Config.JumpEnabled, function(v) Config.JumpEnabled = v end, 6)
	makeCycleButton(move, "Jump Power", {50, 70, 100, 150, 200}, Config.JumpValue, function(v)
		Config.JumpValue = v
	end, 7)
	makeDivider(move, 8)
	makeLabel(move, "FLIGHT", 9)
	makeToggle(move, "Fly (CFrame)", Config.FlyEnabled, function(v)
		Config.FlyEnabled = v
		if v then startFly() else stopFly() end
	end, 10)
	makeCycleButton(move, "Fly Speed", {30, 60, 100, 150, 200, 300}, Config.FlySpeed, function(v)
		Config.FlySpeed = v
	end, 11)
	makeDivider(move, 12)
	makeLabel(move, "COLLISION", 13)
	makeToggle(move, "NoClip", Config.NoClipEnabled, function(v)
		Config.NoClipEnabled = v
		if v then startNoClip() else stopNoClip() end
	end, 14)
	local vis = pages["Visuals"]
	makeLabel(vis, "LIGHTING", 1)
	makeToggle(vis, "Fullbright", Config.Fullbright_Enabled, function(v)
		Config.Fullbright_Enabled = v
		if v then enableFullbright() else disableFullbright() end
	end, 2)
	makeDivider(vis, 3)
	makeLabel(vis, "CROSSHAIR", 4)
	makeToggle(vis, "Custom Crosshair", Config.Crosshair_Enabled, function(v)
		Config.Crosshair_Enabled = v
	end, 5)
	makeCycleButton(vis, "Size", {8, 12, 16, 20, 24}, Config.Crosshair_Size, function(v)
		Config.Crosshair_Size = v
	end, 6)
	makeCycleButton(vis, "Gap", {0, 2, 4, 6, 8}, Config.Crosshair_Gap, function(v)
		Config.Crosshair_Gap = v
	end, 7)
	makeDivider(vis, 8)
	makeLabel(vis, "FIELD OF VIEW", 9)
	makeToggle(vis, "FOV Changer", Config.FOV_Enabled, function(v)
		Config.FOV_Enabled = v
		if not v then resetFOV() end
	end, 10)
	makeCycleButton(vis, "FOV", {70, 80, 90, 100, 110, 120}, Config.FOV_Value, function(v)
		Config.FOV_Value = v
	end, 11)
	local playersPage = pages["Players"]
	local function buildPlayerList()
		for _, child in playersPage:GetChildren() do
			if child:IsA("Frame") and child.Name == "PlayerCard" then
				child:Destroy()
			end
		end
		local order = 0
		for _, player in Players:GetPlayers() do
			order += 1
			local isLocal = (player == LocalPlayer)
			local card = Instance.new("Frame")
			card.Name             = "PlayerCard"
			card.Size             = UDim2.new(1, 0, 0, 36)
			card.BackgroundColor3 = isLocal and Color3.fromRGB(35, 35, 55) or CARD_BG
			card.BorderSizePixel  = 0
			card.LayoutOrder      = order
			card.Parent           = playersPage
			Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
			local avatar = Instance.new("TextLabel")
			avatar.Size             = UDim2.new(0, 24, 0, 24)
			avatar.Position         = UDim2.new(0, 6, 0.5, -12)
			avatar.BackgroundColor3 = isLocal and ACCENT or TAG_PURPLE
			avatar.Text             = string.sub(player.DisplayName, 1, 1)
			avatar.TextColor3       = TEXT_WHITE
			avatar.TextSize         = 12
			avatar.Font             = Enum.Font.GothamBold
			avatar.BorderSizePixel  = 0
			avatar.Parent           = card
			Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size              = UDim2.new(1, -90, 1, 0)
			nameLabel.Position          = UDim2.new(0, 36, 0, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text              = player.DisplayName
			nameLabel.TextColor3        = isLocal and TEXT_DIM or TEXT_WHITE
			nameLabel.TextSize          = 12
			nameLabel.Font              = Enum.Font.GothamMedium
			nameLabel.TextXAlignment    = Enum.TextXAlignment.Left
			nameLabel.TextTruncate      = Enum.TextTruncate.AtEnd
			nameLabel.Parent            = card
			local distLabel = Instance.new("TextLabel")
			distLabel.Size              = UDim2.new(0, 50, 1, 0)
			distLabel.Position          = UDim2.new(1, -55, 0, 0)
			distLabel.BackgroundTransparency = 1
			distLabel.TextSize          = 10
			distLabel.Font              = Enum.Font.Gotham
			distLabel.TextXAlignment    = Enum.TextXAlignment.Right
			distLabel.Parent            = card
			if isLocal then
				distLabel.Text       = "YOU"
				distLabel.TextColor3 = ACCENT
			else
				local _, theirRoot = Utility.getCharacterParts(player)
				local dist = theirRoot and math.floor(Utility.distanceTo(theirRoot.Position)) or "?"
				distLabel.Text       = tostring(dist) .. "m"
				distLabel.TextColor3 = TEXT_DIM
			end
			if not isLocal then
				local tpBtn = Instance.new("TextButton")
				tpBtn.Size              = UDim2.new(1, 0, 1, 0)
				tpBtn.BackgroundTransparency = 1
				tpBtn.Text              = ""
				tpBtn.BorderSizePixel   = 0
				tpBtn.Parent            = card
				tpBtn.MouseButton1Click:Connect(function()
					pcall(function()
						local _, myRoot = Utility.getCharacterParts(LocalPlayer)
						local _, theirRoot = Utility.getCharacterParts(player)
						if myRoot and theirRoot then
							myRoot.CFrame = theirRoot.CFrame + Vector3.new(0, 5, 0)
						end
					end)
					card.BackgroundColor3 = GREEN
					tween(card, {BackgroundColor3 = CARD_BG}, TweenInfo.new(0.5))
				end)
			end
		end
	end
	buildPlayerList()
	Players.PlayerAdded:Connect(function() task.wait(1); buildPlayerList() end)
	Players.PlayerRemoving:Connect(function() task.wait(0.5); buildPlayerList() end)
	task.spawn(function()
		while task.wait(3) do pcall(buildPlayerList) end
	end)
	local misc = pages["Misc"]
	makeLabel(misc, "ANTI-KICK", 1)
	makeToggle(misc, "Anti-AFK", Config.AntiAFK_Enabled, function(v)
		Config.AntiAFK_Enabled = v
		if v then enableAntiAFK() else disableAntiAFK() end
	end, 2)
	makeDivider(misc, 3)
	makeLabel(misc, "STAMINA", 4)
	makeToggle(misc, "Infinite Stamina", false, function(v)
		StaminaEnabled = v
	end, 5)
	makeDivider(misc, 6)
	makeLabel(misc, "INFO", 7)
	local infoCard = Instance.new("Frame")
	infoCard.Size              = UDim2.new(1, 0, 0, 80)
	infoCard.BackgroundColor3  = CARD_BG
	infoCard.BorderSizePixel   = 0
	infoCard.LayoutOrder       = 8
	infoCard.Parent            = misc
	Instance.new("UICorner", infoCard).CornerRadius = UDim.new(0, 6)
	local infoText = Instance.new("TextLabel")
	infoText.Size              = UDim2.new(1, -16, 1, -8)
	infoText.Position          = UDim2.new(0, 8, 0, 4)
	infoText.BackgroundTransparency = 1
	infoText.Text              = "⌨  RightCtrl — Toggle UI\n🖱  Right Click — Aimbot lock\n⚡  Stamina — client-side only\n📦  v4 — TeekHub Universal"
	infoText.TextColor3        = TEXT_DIM
	infoText.TextSize          = 11
	infoText.Font              = Enum.Font.Gotham
	infoText.TextWrapped       = true
	infoText.TextXAlignment    = Enum.TextXAlignment.Left
	infoText.TextYAlignment    = Enum.TextYAlignment.Top
	infoText.Parent            = infoCard
	switchTab("ESP")
	return screenGui
end
Players.PlayerRemoving:Connect(function(player)
	if ESPCache[player] then
		destroyESP(ESPCache[player])
		ESPCache[player] = nil
	end
end)
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.5)
	applyCharacterMods()
	if Config.FlyEnabled then
		stopFly(); task.wait(0.2); startFly()
	end
end)
local gui = buildUI()
RunService.RenderStepped:Connect(function()
	pcall(updateESP)
	pcall(updateAimbot)
	pcall(applyCharacterMods)
	pcall(updateCrosshair)
	pcall(updateFOV)
	pcall(updateStamina)
end)
local WINDOW_W_CONST = 520
local WINDOW_H_CONST = 400
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.RightControl then
		local mf = gui.MainFrame
		if mf.Visible then
			TweenService:Create(mf, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Size = UDim2.new(0, 0, 0, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0)
			}):Play()
			task.delay(0.25, function() mf.Visible = false end)
		else
			mf.Visible = true
			mf.Size = UDim2.new(0, 0, 0, 0)
			mf.Position = UDim2.new(0.5, 0, 0.5, 0)
			TweenService:Create(mf, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, WINDOW_W_CONST, 0, WINDOW_H_CONST),
				Position = UDim2.new(0.5, -WINDOW_W_CONST/2, 0.5, -WINDOW_H_CONST/2)
			}):Play()
		end
	end
end)
print("[TeekHub] v4 Loaded — RightCtrl to toggle UI")
print("[TeekHub] Sidebar: ESP | Aimbot | Movement | Visuals | Players | Misc")
print("[TeekHub] New: Sidebar UI, Aim Prediction, Crosshair, FOV, Anti-AFK")
