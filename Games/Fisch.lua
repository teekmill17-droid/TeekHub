local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local VIM = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local StarterGui = game:GetService("StarterGui")
local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local pg = LP.PlayerGui
local NO_HOOKING = typeof(hookfunction) ~= "function"
local FConfig = {
	AutoFish_Enabled = false,
	AutoShake_Enabled = true,
	CenterShake = true,
	AutoSell_Enabled = false,
	AutoSell_Interval = 60,
	InstantReel = false,
	LegitReel = true,
	PerfectReel = false,
	ReelDelay_Min = 2,
	ReelDelay_Max = 5,
	InstantBob = false,
	InfiniteOxygen = false,
	NoFishModels = false,
	DisableInventory = false,
	PersistentMap = false,
	SpamTool = false,
	ZoneFish = false,
	NoAmbient = false,
	FlyEnabled = false,
	FlySpeed = 60,
	NoClip = false,
	AntiAFK = true,
	InfiniteJump = false,
	DayOnly = false,
	WeatherClear = false,
	FishEMP = false,
	FishCount = 0,
}
local reelFinished = RS:FindFirstChild("events") and RS.events:FindFirstChild("reelfinished")
local sellEverything = RS:FindFirstChild("events") and RS.events:FindFirstChild("selleverything")
local CurrentTool = nil
local ZoneFishOrigin = nil
local FakeTank = Instance.new("Glue"); FakeTank.Name = "DivingTank"; FakeTank:SetAttribute("Tier", 9e9)
local DayOnlyConn = nil
local FlyConn = nil
local NoClipConn = nil
local function findRod()
	local char = LP.Character
	if not char then return nil end
	for _, t in char:GetChildren() do
		if t:IsA("Tool") and (t.Name:find("Rod") or t.Name:find("rod")) then return t end
	end
	return nil
end
local function getRodState()
	local rod = findRod()
	if not rod then return nil, nil end
	return rod, rod:FindFirstChild("values")
end
local function getMyRoot()
	local char = LP.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end
local function teleportTo(cf)
	local root = getMyRoot()
	if root then root.CFrame = typeof(cf) == "CFrame" and cf or CFrame.new(cf) end
end
-- CAST
local castCooldown = 0
local function autoCast()
	if not FConfig.AutoFish_Enabled then return end
	if tick() - castCooldown < 2 then return end
	local rod, vals = getRodState()
	if not rod or not vals then return end
	if vals.state.Value ~= 3 or vals.casted.Value == true then return end
	castCooldown = tick()
	pcall(function()
		local anims = RS:FindFirstChild("resources") and RS.resources:FindFirstChild("animations")
		if anims and LP.Character:FindFirstChild("Humanoid") then
			local throw = LP.Character.Humanoid:LoadAnimation(anims.fishing.throw)
			throw.Priority = Enum.AnimationPriority.Action3
			throw:Play()
		end
	end)
	VIM:SendMouseButtonEvent(400, 400, 0, true, game, 0)
	task.delay(0.8, function()
		VIM:SendMouseButtonEvent(400, 400, 0, false, game, 0)
	end)
end
-- SHAKE (Sasware method)
local function handleShakeButton(button)
	button.Selectable = true
	GuiService.AutoSelectGuiEnabled = false
	GuiService.GuiNavigationEnabled = true
	if button and button:IsDescendantOf(game) then
		GuiService.SelectedObject = button
		task.wait()
		VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
		VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
		task.wait()
	end
	GuiService.AutoSelectGuiEnabled = true
	GuiService.GuiNavigationEnabled = false
	GuiService.SelectedObject = nil
end
local function mountShakeUI(shakeUI)
	local safezone = shakeUI:FindFirstChild("safezone")
	if not safezone then return end
	if FConfig.CenterShake then
		local connect = safezone:FindFirstChild("connect")
		if connect then connect.Enabled = false end
		safezone.Size = UDim2.fromOffset(0, 0)
		safezone.Position = UDim2.fromScale(0.5, 0.5)
		safezone.AnchorPoint = Vector2.new(0.5, 0.5)
	end
	if FConfig.AutoShake_Enabled then
		local shakeConn
		shakeConn = safezone.ChildAdded:Connect(function(child)
			if child:IsA("ImageButton") then
				local active = true
				task.spawn(function()
					repeat RunService.RenderStepped:Wait(); pcall(function() handleShakeButton(child) end)
					until not active
				end)
				task.spawn(function()
					repeat RunService.RenderStepped:Wait()
					until not child or not child:IsDescendantOf(safezone)
					active = false
				end)
			end
		end)
		task.spawn(function()
			repeat task.wait() until not safezone:IsDescendantOf(pg)
			shakeConn:Disconnect()
		end)
	end
end
pg.ChildAdded:Connect(function(child)
	if child.Name == "shakeui" and child:IsA("ScreenGui") then
		pcall(function() mountShakeUI(child) end)
	end
end)
-- BITE
local biteHandled = false
local function handleBite()
	if not FConfig.AutoFish_Enabled then return end
	local _, vals = getRodState()
	if not vals then return end
	if vals.state.Value == 6 and not biteHandled then
		biteHandled = true
		for i = 1, 5 do
			VIM:SendMouseButtonEvent(400, 400, 0, true, game, 0)
			VIM:SendMouseButtonEvent(400, 400, 0, false, game, 0)
		end
		local rod = findRod()
		if rod then task.spawn(function() pcall(function() rod:Activate() end) end) end
	end
	if vals.state.Value == 5 or vals.state.Value == 3 then biteHandled = false end
end
-- REEL
local reelHandled = false
local function handleReel()
	if not FConfig.AutoFish_Enabled then return end
	if reelHandled then return end
	if not reelFinished then return end
	local _, vals = getRodState()
	if not vals then return end
	local state = vals.state.Value
	if state == 7 or state == 8 then
		local reelUI = pg:FindFirstChild("reel")
		if not reelUI then return end
		local bar = reelUI:FindFirstChild("bar")
		if not bar then return end
		if FConfig.InstantReel then
			local reelScript = bar:FindFirstChild("reel")
			if reelScript and reelScript.Enabled == true then
				reelHandled = true
				local delay = math.random(FConfig.ReelDelay_Min * 10, FConfig.ReelDelay_Max * 10) / 10
				task.delay(delay, function()
					local progress = math.random(82, 98)
					local perfect = FConfig.PerfectReel or (math.random() > 0.4)
					pcall(function() reelFinished:FireServer(progress, perfect) end)
					FConfig.FishCount += 1
					reelHandled = false
				end)
			end
		elseif FConfig.LegitReel then
			reelHandled = true
			task.spawn(function()
				local playerBar = bar:FindFirstChild("playerbar")
				local fishBar = bar:FindFirstChild("fish")
				if playerBar and fishBar then
					while bar and reelUI:IsDescendantOf(pg) do
						RunService.RenderStepped:Wait()
						pcall(function()
							local target = playerBar.Position:Lerp(fishBar.Position, 0.7)
							playerBar.Position = UDim2.fromScale(math.clamp(target.X.Scale, 0.15, 0.85), target.Y.Scale)
						end)
					end
					FConfig.FishCount += 1
				end
				reelHandled = false
			end)
		end
	end
	if state == 3 or state == 5 then reelHandled = false end
end
-- INSTANT BOB
local function instantBob()
	if not FConfig.InstantBob then return end
	local rod = findRod()
	if not rod then return end
	pcall(function()
		local bobber = rod:FindFirstChild("bobber")
		if bobber then
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Include
			params.FilterDescendantsInstances = {Workspace.Terrain}
			local result = Workspace:Raycast(bobber.Position, -Vector3.yAxis * 100, params)
			if result and result.Instance:IsA("Terrain") then
				bobber:PivotTo(CFrame.new(result.Position))
			end
		end
	end)
end
-- AUTO SELL
local sellCooldown = 0
local function autoSell()
	if not FConfig.AutoSell_Enabled or not sellEverything then return end
	if tick() - sellCooldown < FConfig.AutoSell_Interval then return end
	sellCooldown = tick()
	pcall(function() sellEverything:InvokeServer() end)
end
-- INFINITE OXYGEN
local function updateOxygen()
	if FConfig.InfiniteOxygen then
		if FakeTank.Parent ~= LP.Character then FakeTank.Parent = LP.Character end
	else
		if FakeTank.Parent ~= nil then FakeTank.Parent = nil end
	end
end
-- NO FISH MODELS
Workspace:WaitForChild("active").ChildAdded:Connect(function(child)
	if FConfig.NoFishModels and child:IsA("Model") then
		pcall(function()
			local fish = child:WaitForChild("Fish", 1)
			if fish then task.wait(); child:Destroy() end
		end)
	end
end)
-- PERSISTENT MAP
local function togglePersistentMap(v)
	if v then
		for _, d in Workspace:GetDescendants() do
			if d:IsA("Model") and d.ModelStreamingMode ~= Enum.ModelStreamingMode.Persistent then
				CollectionService:AddTag(d, "ForcePersistent")
				d:SetAttribute("OldStreamingMode", d.ModelStreamingMode.Name)
				d.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
			end
		end
	else
		for _, m in CollectionService:GetTagged("ForcePersistent") do
			pcall(function()
				local old = m:GetAttribute("OldStreamingMode")
				m.ModelStreamingMode = old and Enum.ModelStreamingMode[old] or Enum.ModelStreamingMode.Default
				CollectionService:RemoveTag(m, "ForcePersistent")
				m:SetAttribute("OldStreamingMode", nil)
			end)
		end
	end
end
-- DISABLE INVENTORY
local function toggleInventory(v)
	pcall(function()
		local inv = LP.PlayerGui:FindFirstChild("hud") and LP.PlayerGui.hud:FindFirstChild("safezone") and LP.PlayerGui.hud.safezone:FindFirstChild("backpack")
		if inv then inv.Visible = not v; StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, v) end
	end)
end
-- NO AMBIENT
local function updateAmbient()
	pcall(function()
		local loc = Lighting:FindFirstChild("location")
		if loc then loc.Enabled = not FConfig.NoAmbient end
	end)
end
-- WEATHER CLEAR
local function updateWeather()
	pcall(function()
		local weather = RS:FindFirstChild("world") and RS.world:FindFirstChild("weather")
		if weather and FConfig.WeatherClear then weather.Value = "Clear" end
	end)
end
-- DAY ONLY
local function toggleDayOnly(v)
	if v then
		if not DayOnlyConn then
			DayOnlyConn = RunService.Heartbeat:Connect(function() Lighting.TimeOfDay = "12:00:00" end)
		end
	else
		if DayOnlyConn then DayOnlyConn:Disconnect(); DayOnlyConn = nil end
	end
end
-- FLY (CFrame)
local function startFly()
	local _, _, hum = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"), nil, LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = true end
	FlyConn = RunService.RenderStepped:Connect(function(dt)
		if not FConfig.FlyEnabled then return end
		local root = getMyRoot()
		if not root then return end
		pcall(function()
			local dir = Vector3.zero
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end
			if dir.Magnitude > 0 then dir = dir.Unit end
			root.CFrame = root.CFrame + dir * FConfig.FlySpeed * dt
			root.Velocity = Vector3.zero
			root.AssemblyLinearVelocity = Vector3.zero
			LP.Character:FindFirstChildOfClass("Humanoid").PlatformStand = true
		end)
	end)
end
local function stopFly()
	if FlyConn then FlyConn:Disconnect(); FlyConn = nil end
	pcall(function() LP.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false end)
end
-- NOCLIP
local function startNoClip()
	NoClipConn = RunService.Stepped:Connect(function()
		if not FConfig.NoClip then return end
		pcall(function()
			for _, p in LP.Character:GetDescendants() do
				if p:IsA("BasePart") then p.CanCollide = false end
			end
		end)
	end)
end
local function stopNoClip()
	if NoClipConn then NoClipConn:Disconnect(); NoClipConn = nil end
end
-- ANTI AFK
LP.Idled:Connect(function()
	if FConfig.AntiAFK then
		pcall(function()
			VIM:SendMouseMoveEvent(1, 0, game)
			VIM:SendMouseMoveEvent(-1, 0, game)
		end)
	end
end)
-- INFINITE JUMP
UserInputService.JumpRequest:Connect(function()
	if FConfig.InfiniteJump then
		pcall(function() LP.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping") end)
	end
end)
-- SPAM TOOL
local function spamTool()
	if not FConfig.SpamTool then return end
	local rod = findRod()
	if rod then for i = 1, 10 do rod:Activate() end end
end
-- ZONE FISH
local FishingZones = {}
pcall(function()
	for _, z in Workspace:WaitForChild("zones"):WaitForChild("fishing"):GetChildren() do
		if not FishingZones[z.Name] then FishingZones[z.Name] = z end
	end
end)
local zoneNames = {}
for name in FishingZones do table.insert(zoneNames, name) end
table.sort(zoneNames)
local selectedZone = zoneNames[1] or ""
-- FISH EMP
local empCooldown = 0
local function fishEMP()
	if not FConfig.FishEMP then return end
	if tick() - empCooldown < 0.5 then return end
	empCooldown = tick()
	pcall(function()
		for _, player in Players:GetPlayers() do
			if player == LP then continue end
			local char = player.Character
			if char then
				for _, d in char:GetDescendants() do
					if d.Name == "reset" or d.Name == "breakbobber" then
						pcall(function() d:FireServer() end)
					end
				end
			end
		end
	end)
end
-- FPS BOOST
local function fpsBoost()
	pcall(function()
		local t = Workspace.Terrain
		t.WaterWaveSize = 0; t.WaterWaveSpeed = 0; t.WaterReflectance = 0; t.WaterTransparency = 0
		Lighting.GlobalShadows = false; Lighting.FogEnd = 9e9; Lighting.Brightness = 0
		settings().Rendering.QualityLevel = "Level01"
		for _, v in game:GetDescendants() do
			pcall(function()
				if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("MeshPart") then
					v.Material = Enum.Material.Plastic; v.Reflectance = 0
				elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Lifetime = NumberRange.new(0)
				elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then v.Enabled = false
				elseif v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then v.Enabled = false
				end
			end)
		end
	end)
end
-- HOOKS (if available)
if not NO_HOOKING then
	pcall(function()
		local oldnamecall
		oldnamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
			local method = getnamecallmethod()
			local args = {...}
			if method == "FireServer" then
				if self == reelFinished and FConfig.PerfectReel then
					args[1] = 100; args[2] = true
					return oldnamecall(self, unpack(args))
				end
			end
			return oldnamecall(self, ...)
		end))
	end)
end
-- CHARACTER TRACKING
local function onCharAdded(char)
	for _, child in char:GetChildren() do
		if child:IsA("Tool") then CurrentTool = child end
	end
	char.ChildAdded:Connect(function(child) if child:IsA("Tool") then CurrentTool = child end end)
	char.ChildRemoved:Connect(function(child) if child:IsA("Tool") then CurrentTool = nil end end)
end
if LP.Character then onCharAdded(LP.Character) end
LP.CharacterAdded:Connect(onCharAdded)
-- TELEPORT SPOTS
local SPOTS = {
	{name = "Moosewood", pos = Vector3.new(433, 147, 261)},
	{name = "Roslit Bay", pos = Vector3.new(-1501, 133, 416)},
	{name = "Snowcap Island", pos = Vector3.new(2589, 134, 2333)},
	{name = "Sunstone Island", pos = Vector3.new(-913, 137, -1129)},
	{name = "Mushgrove Swamp", pos = Vector3.new(2442, 130, -686)},
	{name = "Terrapin Island", pos = Vector3.new(152, 154, 2000)},
	{name = "Statue of Sovereignty", pos = Vector3.new(22, 159, -1039)},
	{name = "Enchant Room", pos = Vector3.new(1310, -805, -162)},
	{name = "Executive HQ", pos = Vector3.new(-36, -246, 205)},
	{name = "Enchant Relic", pos = Vector3.new(1309, -802, -83)},
}
pcall(function()
	local tpSpots = Workspace:FindFirstChild("world") and Workspace.world:FindFirstChild("spawns") and Workspace.world.spawns:FindFirstChild("TpSpots")
	if tpSpots then
		for _, loc in tpSpots:GetChildren() do
			local exists = false
			for _, s in SPOTS do if s.name == loc.Name then exists = true; break end end
			if not exists then table.insert(SPOTS, {name = loc.Name, pos = loc.Position + Vector3.new(0, 6, 0)}) end
		end
	end
end)
-- UI
local function buildUI()
	local sg = Instance.new("ScreenGui"); sg.Name = "TeekHubFisch"; sg.ResetOnSpawn = false; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	pcall(function() sg.Parent = game:GetService("CoreGui") end)
	if not sg.Parent then sg.Parent = LP:WaitForChild("PlayerGui") end
	local C = {
		bg1 = Color3.fromRGB(13,13,22), bg2 = Color3.fromRGB(18,18,30), bg3 = Color3.fromRGB(23,23,38),
		card = Color3.fromRGB(28,28,46), cardHover = Color3.fromRGB(35,35,56),
		accent = Color3.fromRGB(30,140,200), accentDim = Color3.fromRGB(20,100,160),
		green = Color3.fromRGB(45,200,95), red = Color3.fromRGB(220,55,65), redDim = Color3.fromRGB(50,40,55),
		text = Color3.fromRGB(235,235,242), textDim = Color3.fromRGB(120,120,150), textMuted = Color3.fromRGB(80,80,105),
		divider = Color3.fromRGB(40,40,60), warning = Color3.fromRGB(255,180,40),
	}
	local WW,WH,SW,TH = 520,430,135,42
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
	local icoT = Instance.new("TextLabel"); icoT.Size = UDim2.new(1,0,1,0); icoT.BackgroundTransparency = 1; icoT.Text = "🐟"; icoT.TextColor3 = C.text; icoT.TextSize = 14; icoT.Font = Enum.Font.GothamBold; icoT.Parent = ico
	local ttl = Instance.new("TextLabel"); ttl.Size = UDim2.new(0,100,0,16); ttl.Position = UDim2.new(0,44,0,5); ttl.BackgroundTransparency = 1; ttl.Text = "TeekHub"; ttl.TextColor3 = C.text; ttl.TextSize = 14; ttl.Font = Enum.Font.GothamBold; ttl.TextXAlignment = Enum.TextXAlignment.Left; ttl.Parent = top
	local subt = Instance.new("TextLabel"); subt.Size = UDim2.new(0,100,0,13); subt.Position = UDim2.new(0,44,0,22); subt.BackgroundTransparency = 1; subt.Text = "Fisch"; subt.TextColor3 = C.textDim; subt.TextSize = 11; subt.Font = Enum.Font.Gotham; subt.TextXAlignment = Enum.TextXAlignment.Left; subt.Parent = top
	local fishLbl = Instance.new("TextLabel"); fishLbl.Name = "fishLbl"; fishLbl.Size = UDim2.new(0,80,0,13); fishLbl.Position = UDim2.new(0,150,0,22); fishLbl.BackgroundTransparency = 1; fishLbl.Text = "0 caught"; fishLbl.TextColor3 = C.green; fishLbl.TextSize = 10; fishLbl.Font = Enum.Font.GothamMedium; fishLbl.TextXAlignment = Enum.TextXAlignment.Left; fishLbl.Parent = top
	local function mkWinBtn(txt,col,pos,cb) local b = Instance.new("TextButton"); b.Size = UDim2.new(0,24,0,24); b.Position = pos; b.BackgroundColor3 = col; b.BackgroundTransparency = 0.85; b.Text = txt; b.TextColor3 = C.textDim; b.TextSize = 12; b.Font = Enum.Font.GothamBold; b.BorderSizePixel = 0; b.AutoButtonColor = false; b.Parent = top; Instance.new("UICorner", b).CornerRadius = UDim.new(0,6); b.MouseEnter:Connect(function() tw(b,{BackgroundTransparency=0.3,TextColor3=C.text},TF) end); b.MouseLeave:Connect(function() tw(b,{BackgroundTransparency=0.85,TextColor3=C.textDim},TF) end); b.MouseButton1Click:Connect(cb) end
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
	Instance.new("Frame", sidebar).Size = UDim2.new(0,1,1,-24); Instance.new("Frame", sidebar).Position = UDim2.new(1,0,0,12)
	local dv = sidebar:GetChildren()[#sidebar:GetChildren()]; if dv then dv.BackgroundColor3 = C.divider; dv.BorderSizePixel = 0 end
	local navC = Instance.new("Frame"); navC.Size = UDim2.new(1,-14,1,-20); navC.Position = UDim2.new(0,7,0,14); navC.BackgroundTransparency = 1; navC.Parent = sidebar
	local nl = Instance.new("UIListLayout"); nl.Padding = UDim.new(0,2); nl.SortOrder = Enum.SortOrder.LayoutOrder; nl.Parent = navC
	local content = Instance.new("Frame"); content.Size = UDim2.new(1,-(SW+14),1,-(TH+10)); content.Position = UDim2.new(0,SW+7,0,TH+5); content.BackgroundTransparency = 1; content.ClipsDescendants = true; content.Parent = main
	local pages,navBtns,activeTab = {},{},nil
	local tabs = {{n="Auto Farm",i="🎣",d="Fishing"},{n="Items",i="📦",d="Sell & tools"},{n="Teleports",i="🗺",d="Fast travel"},{n="Visuals",i="🎨",d="World mods"},{n="Movement",i="🏃",d="Fly & clip"},{n="Misc",i="⚙",d="Utilities"}}
	for _,t in tabs do
		local p = Instance.new("ScrollingFrame"); p.Size = UDim2.new(1,0,1,0); p.BackgroundTransparency = 1; p.ScrollBarThickness = 2; p.ScrollBarImageColor3 = C.accent; p.BorderSizePixel = 0; p.Visible = false; p.CanvasSize = UDim2.new(0,0,0,0); p.AutomaticCanvasSize = Enum.AutomaticSize.Y; p.Parent = content
		Instance.new("UIListLayout", p).Padding = UDim.new(0,4); p:FindFirstChildOfClass("UIListLayout").SortOrder = Enum.SortOrder.LayoutOrder
		pages[t.n] = p
	end
	local function switchTab(name) activeTab=name;for n,p in pages do p.Visible=(n==name) end;for n,b in navBtns do if n==name then tw(b.f,{BackgroundColor3=C.accent,BackgroundTransparency=0},TF);tw(b.l,{TextColor3=C.text},TF) else tw(b.f,{BackgroundTransparency=1},TF);tw(b.l,{TextColor3=C.textDim},TF) end end end
	for i,t in tabs do
		local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1,0,0,36); btn.BackgroundTransparency = 1; btn.BackgroundColor3 = C.accent; btn.Text = ""; btn.BorderSizePixel = 0; btn.LayoutOrder = i; btn.AutoButtonColor = false; btn.Parent = navC
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0,7)
		local iL = Instance.new("TextLabel"); iL.Size = UDim2.new(0,18,0,18); iL.Position = UDim2.new(0,6,0.5,-9); iL.BackgroundTransparency = 1; iL.Text = t.i; iL.TextSize = 12; iL.Parent = btn
		local nL = Instance.new("TextLabel"); nL.Size = UDim2.new(1,-30,0,13); nL.Position = UDim2.new(0,28,0,4); nL.BackgroundTransparency = 1; nL.Text = t.n; nL.TextColor3 = C.textDim; nL.TextSize = 11; nL.Font = Enum.Font.GothamBold; nL.TextXAlignment = Enum.TextXAlignment.Left; nL.Parent = btn
		local dL = Instance.new("TextLabel"); dL.Size = UDim2.new(1,-30,0,10); dL.Position = UDim2.new(0,28,0,18); dL.BackgroundTransparency = 1; dL.Text = t.d; dL.TextColor3 = C.textMuted; dL.TextSize = 8; dL.Font = Enum.Font.Gotham; dL.TextXAlignment = Enum.TextXAlignment.Left; dL.Parent = btn
		navBtns[t.n] = {f=btn, l=nL}
		btn.MouseButton1Click:Connect(function() switchTab(t.n) end)
		btn.MouseEnter:Connect(function() if activeTab~=t.n then tw(btn,{BackgroundColor3=C.cardHover,BackgroundTransparency=0},TF) end end)
		btn.MouseLeave:Connect(function() if activeTab~=t.n then tw(btn,{BackgroundTransparency=1},TF) end end)
	end
	local function mkLabel(par,txt,ord) local l=Instance.new("TextLabel");l.Size=UDim2.new(1,0,0,18);l.BackgroundTransparency=1;l.Text="  "..txt;l.TextColor3=C.textMuted;l.TextSize=9;l.Font=Enum.Font.GothamBold;l.TextXAlignment=Enum.TextXAlignment.Left;l.LayoutOrder=ord or 0;l.Parent=par end
	local function mkToggle(par,txt,def,cb,ord)
		local row=Instance.new("Frame");row.Size=UDim2.new(1,0,0,32);row.BackgroundColor3=C.card;row.BorderSizePixel=0;row.LayoutOrder=ord or 0;row.Parent=par
		Instance.new("UICorner",row).CornerRadius=UDim.new(0,7)
		local l=Instance.new("TextLabel");l.Size=UDim2.new(1,-65,1,0);l.Position=UDim2.new(0,12,0,0);l.BackgroundTransparency=1;l.Text=txt;l.TextColor3=C.text;l.TextSize=11;l.Font=Enum.Font.GothamMedium;l.TextXAlignment=Enum.TextXAlignment.Left;l.Parent=row
		local pill=Instance.new("Frame");pill.Size=UDim2.new(0,36,0,18);pill.Position=UDim2.new(1,-44,0.5,-9);pill.BackgroundColor3=def and C.green or C.redDim;pill.BorderSizePixel=0;pill.Parent=row
		Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)
		local knob=Instance.new("Frame");knob.Size=UDim2.new(0,14,0,14);knob.Position=def and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7);knob.BackgroundColor3=C.text;knob.BorderSizePixel=0;knob.Parent=pill
		Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
		local state=def
		local ca=Instance.new("TextButton");ca.Size=UDim2.new(1,0,1,0);ca.BackgroundTransparency=1;ca.Text="";ca.Parent=row
		ca.MouseButton1Click:Connect(function() state=not state;tw(pill,{BackgroundColor3=state and C.green or C.redDim},TF);tw(knob,{Position=state and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)},TF);pcall(cb,state) end)
		row.MouseEnter:Connect(function() tw(row,{BackgroundColor3=C.cardHover},TF) end)
		row.MouseLeave:Connect(function() tw(row,{BackgroundColor3=C.card},TF) end)
	end
	local function mkCycle(par,txt,vals,def,cb,ord)
		local idx=1;for i,v in vals do if v==def then idx=i;break end end
		local row=Instance.new("Frame");row.Size=UDim2.new(1,0,0,32);row.BackgroundColor3=C.card;row.BorderSizePixel=0;row.LayoutOrder=ord or 0;row.Parent=par
		Instance.new("UICorner",row).CornerRadius=UDim.new(0,7)
		local l=Instance.new("TextLabel");l.Size=UDim2.new(0.55,0,1,0);l.Position=UDim2.new(0,12,0,0);l.BackgroundTransparency=1;l.Text=txt;l.TextColor3=C.text;l.TextSize=11;l.Font=Enum.Font.GothamMedium;l.TextXAlignment=Enum.TextXAlignment.Left;l.Parent=row
		local vb=Instance.new("TextButton");vb.Size=UDim2.new(0,55,0,20);vb.Position=UDim2.new(1,-63,0.5,-10);vb.BackgroundColor3=C.accentDim;vb.Text=tostring(vals[idx]);vb.TextColor3=C.text;vb.TextSize=10;vb.Font=Enum.Font.GothamBold;vb.BorderSizePixel=0;vb.AutoButtonColor=false;vb.Parent=row
		Instance.new("UICorner",vb).CornerRadius=UDim.new(0,5)
		vb.MouseButton1Click:Connect(function() idx=idx%#vals+1;vb.Text=tostring(vals[idx]);pcall(cb,vals[idx]) end)
		vb.MouseEnter:Connect(function() tw(vb,{BackgroundColor3=C.accent},TF) end);vb.MouseLeave:Connect(function() tw(vb,{BackgroundColor3=C.accentDim},TF) end)
		row.MouseEnter:Connect(function() tw(row,{BackgroundColor3=C.cardHover},TF) end);row.MouseLeave:Connect(function() tw(row,{BackgroundColor3=C.card},TF) end)
	end
	local function mkDivider(par,ord) local d=Instance.new("Frame");d.Size=UDim2.new(1,-20,0,1);d.Position=UDim2.new(0,10,0,0);d.BackgroundColor3=C.divider;d.BorderSizePixel=0;d.LayoutOrder=ord or 0;d.Parent=par end
	local function mkButton(par,txt,col,cb,ord)
		local b=Instance.new("TextButton");b.Size=UDim2.new(1,0,0,30);b.BackgroundColor3=col or C.accent;b.Text=txt;b.TextColor3=C.text;b.TextSize=11;b.Font=Enum.Font.GothamBold;b.BorderSizePixel=0;b.LayoutOrder=ord or 0;b.AutoButtonColor=false;b.Parent=par
		Instance.new("UICorner",b).CornerRadius=UDim.new(0,7)
		b.MouseButton1Click:Connect(function() pcall(cb);tw(b,{BackgroundColor3=C.green},TF);task.delay(0.4,function() tw(b,{BackgroundColor3=col or C.accent},TF) end) end)
		b.MouseEnter:Connect(function() tw(b,{BackgroundColor3=Color3.new(math.min((col or C.accent).R*1.2,1),math.min((col or C.accent).G*1.2,1),math.min((col or C.accent).B*1.2,1))},TF) end)
		b.MouseLeave:Connect(function() tw(b,{BackgroundColor3=col or C.accent},TF) end)
	end
	-- AUTO FARM TAB
	local af = pages["Auto Farm"]
	mkLabel(af,"CASTING",1)
	mkToggle(af,"Auto Fish",FConfig.AutoFish_Enabled,function(v) FConfig.AutoFish_Enabled=v end,2)
	mkToggle(af,"Instant Bob",FConfig.InstantBob,function(v) FConfig.InstantBob=v end,3)
	mkDivider(af,4)
	mkLabel(af,"SHAKE",5)
	mkToggle(af,"Auto Shake",FConfig.AutoShake_Enabled,function(v) FConfig.AutoShake_Enabled=v end,6)
	mkToggle(af,"Center Shake",FConfig.CenterShake,function(v) FConfig.CenterShake=v end,7)
	mkDivider(af,8)
	mkLabel(af,"REELING",9)
	mkToggle(af,"Legit Reel (safe)",FConfig.LegitReel,function(v) FConfig.LegitReel=v;if v then FConfig.InstantReel=false end end,10)
	mkToggle(af,"Instant Reel (risky)",FConfig.InstantReel,function(v) FConfig.InstantReel=v;if v then FConfig.LegitReel=false end end,11)
	mkToggle(af,"Perfect Reel (hook)",FConfig.PerfectReel,function(v) FConfig.PerfectReel=v end,12)
	mkCycle(af,"Reel Delay Min",{1,2,3,4,5},FConfig.ReelDelay_Min,function(v) FConfig.ReelDelay_Min=v end,13)
	mkCycle(af,"Reel Delay Max",{3,5,7,10},FConfig.ReelDelay_Max,function(v) FConfig.ReelDelay_Max=v end,14)
	-- ITEMS TAB
	local it = pages["Items"]
	mkLabel(it,"SELLING",1)
	mkToggle(it,"Auto Sell",FConfig.AutoSell_Enabled,function(v) FConfig.AutoSell_Enabled=v end,2)
	mkCycle(it,"Sell Interval (s)",{30,60,120,300},FConfig.AutoSell_Interval,function(v) FConfig.AutoSell_Interval=v end,3)
	mkButton(it,"Sell All Now",C.accent,function() pcall(function() if sellEverything then sellEverything:InvokeServer() end end) end,4)
	mkDivider(it,5)
	mkLabel(it,"TOOLS",6)
	mkToggle(it,"Spam Tool (crates)",FConfig.SpamTool,function(v) FConfig.SpamTool=v end,7)
	-- TELEPORTS TAB
	local tp = pages["Teleports"]
	mkLabel(tp,"FISHING SPOTS",1)
	for i,spot in SPOTS do
		mkButton(tp,"📍  "..spot.name,C.card,function() teleportTo(spot.pos) end,i+1)
	end
	mkDivider(tp,#SPOTS+2)
	mkLabel(tp,"ZONE FISH",#SPOTS+3)
	mkToggle(tp,"Zone Fish (underwater)",FConfig.ZoneFish,function(v)
		FConfig.ZoneFish=v
		if v then
			FConfig.InfiniteOxygen=true; updateOxygen()
			ZoneFishOrigin=LP.Character and LP.Character:GetPivot()
		else
			if ZoneFishOrigin then
				pcall(function() LP.Character.Humanoid:UnequipTools() end)
				teleportTo(ZoneFishOrigin.Position); ZoneFishOrigin=nil
			end
		end
	end,#SPOTS+4)
	-- VISUALS TAB
	local vis = pages["Visuals"]
	mkLabel(vis,"LIGHTING",1)
	mkToggle(vis,"No Ambient",FConfig.NoAmbient,function(v) FConfig.NoAmbient=v end,2)
	mkToggle(vis,"Day Only",FConfig.DayOnly,function(v) FConfig.DayOnly=v;toggleDayOnly(v) end,3)
	mkToggle(vis,"Weather Clear",FConfig.WeatherClear,function(v) FConfig.WeatherClear=v;updateWeather() end,4)
	mkDivider(vis,5)
	mkLabel(vis,"PERFORMANCE",6)
	mkToggle(vis,"No Fish Models (+FPS)",FConfig.NoFishModels,function(v) FConfig.NoFishModels=v end,7)
	mkToggle(vis,"Disable Inventory (+FPS)",FConfig.DisableInventory,function(v) FConfig.DisableInventory=v;toggleInventory(v) end,8)
	mkToggle(vis,"Persistent Map (-Ping)",FConfig.PersistentMap,function(v) FConfig.PersistentMap=v;togglePersistentMap(v) end,9)
	mkButton(vis,"FPS Boost",C.accent,fpsBoost,10)
	-- MOVEMENT TAB
	local mv = pages["Movement"]
	mkLabel(mv,"FLIGHT",1)
	mkToggle(mv,"Fly (CFrame)",FConfig.FlyEnabled,function(v) FConfig.FlyEnabled=v;if v then startFly() else stopFly() end end,2)
	mkCycle(mv,"Fly Speed",{30,60,100,150,200,300},FConfig.FlySpeed,function(v) FConfig.FlySpeed=v end,3)
	mkDivider(mv,4)
	mkLabel(mv,"COLLISION",5)
	mkToggle(mv,"NoClip",FConfig.NoClip,function(v) FConfig.NoClip=v;if v then startNoClip() else stopNoClip() end end,6)
	mkDivider(mv,7)
	mkLabel(mv,"JUMP",8)
	mkToggle(mv,"Infinite Jump",FConfig.InfiniteJump,function(v) FConfig.InfiniteJump=v end,9)
	-- MISC TAB
	local misc = pages["Misc"]
	mkLabel(misc,"SURVIVAL",1)
	mkToggle(misc,"Infinite Oxygen",FConfig.InfiniteOxygen,function(v) FConfig.InfiniteOxygen=v;updateOxygen() end,2)
	mkToggle(misc,"Anti-AFK",FConfig.AntiAFK,function(v) FConfig.AntiAFK=v end,3)
	mkDivider(misc,4)
	mkLabel(misc,"DISRUPTION",5)
	mkToggle(misc,"Fish EMP (break others)",FConfig.FishEMP,function(v) FConfig.FishEMP=v end,6)
	mkDivider(misc,7)
	mkLabel(misc,"SERVER",8)
	mkButton(misc,"Rejoin Server",C.card,function()
		pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, LP) end)
	end,9)
	mkButton(misc,"Server Hop",C.card,function()
		pcall(function()
			local data = game.HttpService:JSONDecode(game:HttpGetAsync("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
			for _,v in data.data do
				if v.id ~= game.JobId and v.maxPlayers > v.playing then
					game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, v.id, LP)
					break
				end
			end
		end)
	end,10)
	mkDivider(misc,11)
	mkLabel(misc,"INFO",12)
	local function mkInfo(par,k,v,ord)
		local r=Instance.new("Frame");r.Size=UDim2.new(1,0,0,26);r.BackgroundColor3=C.card;r.BorderSizePixel=0;r.LayoutOrder=ord;r.Parent=par
		Instance.new("UICorner",r).CornerRadius=UDim.new(0,6)
		local kl=Instance.new("TextLabel");kl.Size=UDim2.new(0.5,0,1,0);kl.Position=UDim2.new(0,12,0,0);kl.BackgroundTransparency=1;kl.Text=k;kl.TextColor3=C.textDim;kl.TextSize=10;kl.Font=Enum.Font.Gotham;kl.TextXAlignment=Enum.TextXAlignment.Left;kl.Parent=r
		local vl=Instance.new("TextLabel");vl.Size=UDim2.new(0.45,0,1,0);vl.Position=UDim2.new(0.5,0,0,0);vl.BackgroundTransparency=1;vl.Text=v;vl.TextColor3=C.text;vl.TextSize=10;vl.Font=Enum.Font.GothamMedium;vl.TextXAlignment=Enum.TextXAlignment.Right;vl.Parent=r
	end
	mkInfo(misc,"Toggle UI","RightCtrl",13)
	mkInfo(misc,"Hub","TeekHub v4",14)
	switchTab("Auto Farm")
	task.spawn(function() while task.wait(0.5) do pcall(function() fishLbl.Text = FConfig.FishCount.." caught" end) end end)
	return sg
end
local gui = buildUI()
RunService.Heartbeat:Connect(function()
	pcall(autoCast)
	pcall(handleBite)
	pcall(handleReel)
	pcall(instantBob)
	pcall(autoSell)
	pcall(spamTool)
	pcall(fishEMP)
	pcall(updateOxygen)
	pcall(updateAmbient)
	pcall(updateWeather)
	if FConfig.ZoneFish then
		pcall(function()
			for _,p in LP.Character:GetDescendants() do if p:IsA("BasePart") then p.CanTouch=false end end
			local zone = FishingZones[selectedZone]
			if zone then
				local origin = zone:GetPivot()
				teleportTo(origin.Position - Vector3.new(0,20,0))
				local rod = findRod()
				if rod then
					local bobber = rod:FindFirstChild("bobber")
					if bobber then
						local rope = bobber:FindFirstChildOfClass("RopeConstraint")
						if rope then rope.Length = 9e9 end
						bobber:PivotTo(origin)
					end
				end
			end
		end)
	end
end)
UserInputService.InputBegan:Connect(function(input,processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.RightControl then
		local mf = gui.MainFrame
		if mf.Visible then
			TweenService:Create(mf,TweenInfo.new(0.2,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Size=UDim2.new(0,0,0,0),Position=UDim2.new(0.5,0,0.5,0)}):Play()
			task.delay(0.25,function() mf.Visible=false end)
		else
			mf.Visible=true;mf.Size=UDim2.new(0,0,0,0);mf.Position=UDim2.new(0.5,0,0.5,0)
			TweenService:Create(mf,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,520,0,430),Position=UDim2.new(0.5,-260,0.5,-215)}):Play()
		end
	end
end)
print("[TeekHub] Fisch v2 loaded — full merge")
print("[TeekHub] Auto Farm | Items | Teleports | Visuals | Movement | Misc")
