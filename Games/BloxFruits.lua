local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local BFConfig = {
	AutoFarm_Enabled = false,
	AutoFarm_Range = 50,
	AutoQuest_Enabled = false,
	AutoRaid_Enabled = false,
	FruitSniper_Enabled = false,
	FruitSniper_Range = 2000,
	FruitESP_Enabled = false,
	ChestESP_Enabled = false,
	AutoBounty_Enabled = false,
	FastAttack_Enabled = false,
	BringMobs_Enabled = false,
	BringMobs_Range = 100,
	ServerHop_Enabled = false,
}
local Utility = {}
function Utility.getCharacterParts(player)
	local char = player.Character
	if not char then return nil, nil, nil end
	return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end
function Utility.worldToScreen(pos)
	local sp, on = Camera:WorldToViewportPoint(pos)
	return Vector2.new(sp.X, sp.Y), on
end
function Utility.teleportTo(cf)
	local _, root = Utility.getCharacterParts(LocalPlayer)
	if root then root.CFrame = cf end
end
local DrawingSupported = pcall(function() local t = Drawing.new("Line"); t:Remove() end)
local FruitESPCache = {}
local ChestESPCache = {}
local function createDot(color)
	if not DrawingSupported then return nil end
	local ok, circle = pcall(function()
		local c = Drawing.new("Circle")
		c.Radius = 6; c.Filled = true; c.Color = color
		c.Thickness = 1; c.Visible = false
		return c
	end)
	return ok and circle or nil
end
local function createLabel(color)
	if not DrawingSupported then return nil end
	local ok, lbl = pcall(function()
		local t = Drawing.new("Text")
		t.Center = true; t.Outline = true; t.Size = 13
		t.Color = color; t.Visible = false
		return t
	end)
	return ok and lbl or nil
end
local function updateFruitESP()
	if not BFConfig.FruitESP_Enabled or not DrawingSupported then
		for _, v in FruitESPCache do
			pcall(function() if v.dot then v.dot.Visible = false end end)
			pcall(function() if v.label then v.label.Visible = false end end)
		end
		return
	end
	local found = {}
	for _, obj in Workspace:GetDescendants() do
		pcall(function()
			if obj:IsA("Tool") or (obj:IsA("Model") and obj.Name:find("Fruit")) then
				local part = obj:IsA("Tool") and obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart")
				if part then
					found[obj] = part
					if not FruitESPCache[obj] then
						FruitESPCache[obj] = {
							dot = createDot(Color3.fromRGB(255, 200, 0)),
							label = createLabel(Color3.fromRGB(255, 200, 0))
						}
					end
					local cache = FruitESPCache[obj]
					local sp, on = Utility.worldToScreen(part.Position)
					if on and cache.dot then
						cache.dot.Position = sp; cache.dot.Visible = true
					elseif cache.dot then
						cache.dot.Visible = false
					end
					if on and cache.label then
						cache.label.Position = Vector2.new(sp.X, sp.Y - 16)
						cache.label.Text = obj.Name
						cache.label.Visible = true
					elseif cache.label then
						cache.label.Visible = false
					end
				end
			end
		end)
	end
	for obj, cache in FruitESPCache do
		if not found[obj] then
			pcall(function() if cache.dot then cache.dot:Remove() end end)
			pcall(function() if cache.label then cache.label:Remove() end end)
			FruitESPCache[obj] = nil
		end
	end
end
local function updateChestESP()
	if not BFConfig.ChestESP_Enabled or not DrawingSupported then
		for _, v in ChestESPCache do
			pcall(function() if v.dot then v.dot.Visible = false end end)
			pcall(function() if v.label then v.label.Visible = false end end)
		end
		return
	end
	for _, obj in Workspace:GetDescendants() do
		pcall(function()
			if obj.Name == "Chest" or obj.Name:find("Chest") then
				local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
				if part then
					if not ChestESPCache[obj] then
						ChestESPCache[obj] = {
							dot = createDot(Color3.fromRGB(0, 200, 255)),
							label = createLabel(Color3.fromRGB(0, 200, 255))
						}
					end
					local cache = ChestESPCache[obj]
					local sp, on = Utility.worldToScreen(part.Position)
					if on and cache.dot then
						cache.dot.Position = sp; cache.dot.Visible = true
					elseif cache.dot then
						cache.dot.Visible = false
					end
					if on and cache.label then
						cache.label.Position = Vector2.new(sp.X, sp.Y - 14)
						cache.label.Text = obj.Name
						cache.label.Visible = true
					elseif cache.label then
						cache.label.Visible = false
					end
				end
			end
		end)
	end
end
local function findNearestMob()
	local _, myRoot = Utility.getCharacterParts(LocalPlayer)
	if not myRoot then return nil, nil end
	local closest, closestDist = nil, BFConfig.AutoFarm_Range
	for _, mob in Workspace:GetDescendants() do
		pcall(function()
			if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChildOfClass("Humanoid") then
				local hum = mob:FindFirstChildOfClass("Humanoid")
				if hum.Health > 0 and mob ~= LocalPlayer.Character then
					local isNPC = not Players:GetPlayerFromCharacter(mob)
					if isNPC then
						local dist = (myRoot.Position - mob.HumanoidRootPart.Position).Magnitude
						if dist < closestDist then
							closest = mob; closestDist = dist
						end
					end
				end
			end
		end)
	end
	return closest, closestDist
end
local function autoFarm()
	if not BFConfig.AutoFarm_Enabled then return end
	pcall(function()
		local mob = findNearestMob()
		if mob and mob:FindFirstChild("HumanoidRootPart") then
			local _, myRoot = Utility.getCharacterParts(LocalPlayer)
			if myRoot then
				myRoot.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
			end
			pcall(function()
				local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
				if tool and tool:FindFirstChild("RemoteEvent") then
					tool.RemoteEvent:FireServer()
				end
			end)
		end
	end)
end
local function bringMobs()
	if not BFConfig.BringMobs_Enabled then return end
	pcall(function()
		local _, myRoot = Utility.getCharacterParts(LocalPlayer)
		if not myRoot then return end
		for _, mob in Workspace:GetDescendants() do
			pcall(function()
				if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChildOfClass("Humanoid") then
					local hum = mob:FindFirstChildOfClass("Humanoid")
					if hum.Health > 0 and not Players:GetPlayerFromCharacter(mob) then
						local dist = (myRoot.Position - mob.HumanoidRootPart.Position).Magnitude
						if dist < BFConfig.BringMobs_Range then
							mob.HumanoidRootPart.CFrame = myRoot.CFrame * CFrame.new(0, 0, -5)
						end
					end
				end
			end)
		end
	end)
end
local function fruitSniper()
	if not BFConfig.FruitSniper_Enabled then return end
	pcall(function()
		for _, obj in Workspace:GetDescendants() do
			pcall(function()
				if (obj:IsA("Tool") and obj.Name:find("Fruit")) or
					(obj:IsA("Model") and obj.Name:find("Fruit")) then
					local part = obj:IsA("Tool") and obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart")
					if part then
						local _, myRoot = Utility.getCharacterParts(LocalPlayer)
						if myRoot then
							local dist = (myRoot.Position - part.Position).Magnitude
							if dist < BFConfig.FruitSniper_Range then
								Utility.teleportTo(part.CFrame + Vector3.new(0, 3, 0))
							end
						end
					end
				end
			end)
		end
	end)
end
local function buildBFUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TeekHubBF"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
	if not screenGui.Parent then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
	local SIDEBAR_BG   = Color3.fromRGB(16, 16, 26)
	local TOPBAR_BG    = Color3.fromRGB(22, 22, 34)
	local CONTENT_BG   = Color3.fromRGB(26, 26, 40)
	local CARD_BG      = Color3.fromRGB(32, 32, 50)
	local ACCENT       = Color3.fromRGB(110, 90, 230)
	local GREEN        = Color3.fromRGB(50, 200, 90)
	local RED_DIM      = Color3.fromRGB(55, 55, 70)
	local TEXT_WHITE   = Color3.fromRGB(240, 240, 245)
	local TEXT_DIM     = Color3.fromRGB(130, 130, 155)
	local TAG_PURPLE   = Color3.fromRGB(110, 80, 220)
	local TAG_BLUE     = Color3.fromRGB(40, 140, 255)
	local DIVIDER      = Color3.fromRGB(45, 45, 65)
	local WINDOW_W, WINDOW_H = 520, 400
	local SIDEBAR_W, TOPBAR_H, NAV_BTN_H = 140, 40, 34
	local TWEEN_FAST = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local TWEEN_MED = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local function tween(obj, props, info)
		TweenService:Create(obj, info or TWEEN_FAST, props):Play()
	end
	local main = Instance.new("Frame")
	main.Name = "MainFrame"
	main.Size = UDim2.new(0, 0, 0, 0)
	main.Position = UDim2.new(0.5, 0, 0.5, 0)
	main.BackgroundColor3 = CONTENT_BG
	main.BorderSizePixel = 0
	main.Active = true
	main.ClipsDescendants = true
	main.Parent = screenGui
	Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color = ACCENT; mainStroke.Thickness = 1; mainStroke.Transparency = 0.7
	mainStroke.Parent = main
	tween(main, {
		Size = UDim2.new(0, WINDOW_W, 0, WINDOW_H),
		Position = UDim2.new(0.5, -WINDOW_W/2, 0.5, -WINDOW_H/2)
	}, TWEEN_MED)
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, TOPBAR_H)
	topBar.BackgroundColor3 = TOPBAR_BG
	topBar.BorderSizePixel = 0; topBar.Parent = main
	Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 12)
	local topFill = Instance.new("Frame")
	topFill.Size = UDim2.new(1, 0, 0, 12)
	topFill.Position = UDim2.new(0, 0, 1, -12)
	topFill.BackgroundColor3 = TOPBAR_BG; topFill.BorderSizePixel = 0; topFill.Parent = topBar
	local hubIcon = Instance.new("TextLabel")
	hubIcon.Size = UDim2.new(0, 32, 0, 32)
	hubIcon.Position = UDim2.new(0, 10, 0.5, -16)
	hubIcon.BackgroundColor3 = TAG_BLUE; hubIcon.Text = "🍎"
	hubIcon.TextSize = 16; hubIcon.Font = Enum.Font.GothamBold
	hubIcon.TextColor3 = TEXT_WHITE; hubIcon.BorderSizePixel = 0; hubIcon.Parent = topBar
	Instance.new("UICorner", hubIcon).CornerRadius = UDim.new(0, 8)
	local hubTitle = Instance.new("TextLabel")
	hubTitle.Size = UDim2.new(0, 150, 0, 18)
	hubTitle.Position = UDim2.new(0, 48, 0, 4)
	hubTitle.BackgroundTransparency = 1
	hubTitle.Text = "TeekHub — Blox Fruits"
	hubTitle.TextColor3 = TEXT_WHITE; hubTitle.TextSize = 14
	hubTitle.Font = Enum.Font.GothamBold; hubTitle.TextXAlignment = Enum.TextXAlignment.Left
	hubTitle.Parent = topBar
	local devLabel = Instance.new("TextLabel")
	devLabel.Size = UDim2.new(0, 100, 0, 14)
	devLabel.Position = UDim2.new(0, 48, 0, 22)
	devLabel.BackgroundTransparency = 1; devLabel.Text = "Dev  @Teek"
	devLabel.TextColor3 = TEXT_DIM; devLabel.TextSize = 11
	devLabel.Font = Enum.Font.Gotham; devLabel.TextXAlignment = Enum.TextXAlignment.Left
	devLabel.Parent = topBar
	local dragging, dragStart, startPos = false, nil, nil
	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = input.Position; startPos = main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	local sidebar = Instance.new("Frame")
	sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -TOPBAR_H)
	sidebar.Position = UDim2.new(0, 0, 0, TOPBAR_H)
	sidebar.BackgroundColor3 = SIDEBAR_BG; sidebar.BorderSizePixel = 0; sidebar.Parent = main
	Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 12)
	local sFill1 = Instance.new("Frame")
	sFill1.Size = UDim2.new(1, 0, 0, 12); sFill1.BackgroundColor3 = SIDEBAR_BG
	sFill1.BorderSizePixel = 0; sFill1.Parent = sidebar
	local sFill2 = Instance.new("Frame")
	sFill2.Size = UDim2.new(0, 12, 1, 0); sFill2.Position = UDim2.new(1, -12, 0, 0)
	sFill2.BackgroundColor3 = SIDEBAR_BG; sFill2.BorderSizePixel = 0; sFill2.Parent = sidebar
	local contentArea = Instance.new("Frame")
	contentArea.Size = UDim2.new(1, -(SIDEBAR_W + 16), 1, -(TOPBAR_H + 12))
	contentArea.Position = UDim2.new(0, SIDEBAR_W + 8, 0, TOPBAR_H + 6)
	contentArea.BackgroundTransparency = 1; contentArea.ClipsDescendants = true; contentArea.Parent = main
	local pages, navButtons, activeTab = {}, {}, nil
	local tabDefs = {
		{name = "Farm", icon = "⚔"},
		{name = "ESP", icon = "👁"},
		{name = "Fruit", icon = "🍎"},
		{name = "Misc", icon = "⚙"},
	}
	for _, def in tabDefs do
		local page = Instance.new("ScrollingFrame")
		page.Size = UDim2.new(1, 0, 1, 0); page.BackgroundTransparency = 1
		page.ScrollBarThickness = 3; page.ScrollBarImageColor3 = ACCENT
		page.BorderSizePixel = 0; page.Visible = false
		page.CanvasSize = UDim2.new(0, 0, 0, 0); page.AutomaticCanvasSize = Enum.AutomaticSize.Y
		page.Parent = contentArea
		local pl = Instance.new("UIListLayout")
		pl.Padding = UDim.new(0, 4); pl.SortOrder = Enum.SortOrder.LayoutOrder; pl.Parent = page
		pages[def.name] = page
	end
	local navContainer = Instance.new("Frame")
	navContainer.Size = UDim2.new(1, -12, 1, -20)
	navContainer.Position = UDim2.new(0, 6, 0, 16)
	navContainer.BackgroundTransparency = 1; navContainer.Parent = sidebar
	local navLayout = Instance.new("UIListLayout")
	navLayout.Padding = UDim.new(0, 3); navLayout.SortOrder = Enum.SortOrder.LayoutOrder; navLayout.Parent = navContainer
	local function switchTab(tabName)
		activeTab = tabName
		for name, page in pages do
			if name == tabName then
				page.Visible = true; page.CanvasPosition = Vector2.new(0, 0)
			else page.Visible = false end
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
		btn.Size = UDim2.new(1, 0, 0, NAV_BTN_H); btn.BackgroundTransparency = 1
		btn.BackgroundColor3 = ACCENT; btn.Text = "  " .. def.icon .. "  " .. def.name
		btn.TextColor3 = TEXT_DIM; btn.TextSize = 13; btn.Font = Enum.Font.GothamMedium
		btn.TextXAlignment = Enum.TextXAlignment.Left; btn.BorderSizePixel = 0
		btn.LayoutOrder = i; btn.AutoButtonColor = false; btn.Parent = navContainer
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		navButtons[def.name] = btn
		btn.MouseButton1Click:Connect(function() switchTab(def.name) end)
	end
	local function makeToggle(parent, label, default, callback, layoutOrder)
		local c = Instance.new("Frame")
		c.Size = UDim2.new(1, 0, 0, 30); c.BackgroundColor3 = CARD_BG
		c.BorderSizePixel = 0; c.LayoutOrder = layoutOrder or 0; c.Parent = parent
		Instance.new("UICorner", c).CornerRadius = UDim.new(0, 6)
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, -60, 1, 0); l.Position = UDim2.new(0, 12, 0, 0)
		l.BackgroundTransparency = 1; l.Text = label; l.TextColor3 = TEXT_WHITE
		l.TextSize = 12; l.Font = Enum.Font.GothamMedium; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = c
		local t = Instance.new("TextButton")
		t.Size = UDim2.new(0, 40, 0, 20); t.Position = UDim2.new(1, -48, 0.5, -10)
		t.BackgroundColor3 = default and GREEN or RED_DIM; t.Text = default and "ON" or "OFF"
		t.TextColor3 = TEXT_WHITE; t.TextSize = 10; t.Font = Enum.Font.GothamBold
		t.BorderSizePixel = 0; t.Parent = c
		Instance.new("UICorner", t).CornerRadius = UDim.new(0, 5)
		local state = default
		local function toggle()
			state = not state; t.Text = state and "ON" or "OFF"
			tween(t, {BackgroundColor3 = state and GREEN or RED_DIM}, TWEEN_FAST)
			pcall(callback, state)
		end
		t.MouseButton1Click:Connect(toggle)
		c.MouseEnter:Connect(function() tween(c, {BackgroundColor3 = Color3.fromRGB(42, 42, 62)}, TWEEN_FAST) end)
		c.MouseLeave:Connect(function() tween(c, {BackgroundColor3 = CARD_BG}, TWEEN_FAST) end)
		return c
	end
	local function makeLabel(parent, text, layoutOrder)
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, 0, 0, 22); l.BackgroundTransparency = 1
		l.Text = text; l.TextColor3 = ACCENT; l.TextSize = 11
		l.Font = Enum.Font.GothamBold; l.TextXAlignment = Enum.TextXAlignment.Left
		l.LayoutOrder = layoutOrder or 0; l.Parent = parent
	end
	local function makeCycle(parent, label, values, default, callback, layoutOrder)
		local idx = 1
		for i, v in values do if v == default then idx = i; break end end
		local c = Instance.new("Frame")
		c.Size = UDim2.new(1, 0, 0, 30); c.BackgroundColor3 = CARD_BG
		c.BorderSizePixel = 0; c.LayoutOrder = layoutOrder or 0; c.Parent = parent
		Instance.new("UICorner", c).CornerRadius = UDim.new(0, 6)
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(0.6, 0, 1, 0); l.Position = UDim2.new(0, 12, 0, 0)
		l.BackgroundTransparency = 1; l.Text = label; l.TextColor3 = TEXT_WHITE
		l.TextSize = 12; l.Font = Enum.Font.GothamMedium; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = c
		local vb = Instance.new("TextButton")
		vb.Size = UDim2.new(0, 55, 0, 20); vb.Position = UDim2.new(1, -63, 0.5, -10)
		vb.BackgroundColor3 = ACCENT; vb.Text = tostring(values[idx]); vb.TextColor3 = TEXT_WHITE
		vb.TextSize = 11; vb.Font = Enum.Font.GothamBold; vb.BorderSizePixel = 0; vb.Parent = c
		Instance.new("UICorner", vb).CornerRadius = UDim.new(0, 5)
		vb.MouseButton1Click:Connect(function()
			idx = idx % #values + 1; vb.Text = tostring(values[idx]); pcall(callback, values[idx])
		end)
		c.MouseEnter:Connect(function() tween(c, {BackgroundColor3 = Color3.fromRGB(42, 42, 62)}, TWEEN_FAST) end)
		c.MouseLeave:Connect(function() tween(c, {BackgroundColor3 = CARD_BG}, TWEEN_FAST) end)
	end
	local farm = pages["Farm"]
	makeLabel(farm, "AUTO FARM", 1)
	makeToggle(farm, "Auto Farm", BFConfig.AutoFarm_Enabled, function(v) BFConfig.AutoFarm_Enabled = v end, 2)
	makeCycle(farm, "Farm Range", {30, 50, 100, 200, 500}, BFConfig.AutoFarm_Range, function(v) BFConfig.AutoFarm_Range = v end, 3)
	makeToggle(farm, "Bring Mobs", BFConfig.BringMobs_Enabled, function(v) BFConfig.BringMobs_Enabled = v end, 4)
	makeCycle(farm, "Bring Range", {50, 100, 200, 500}, BFConfig.BringMobs_Range, function(v) BFConfig.BringMobs_Range = v end, 5)
	makeLabel(farm, "QUESTS", 6)
	makeToggle(farm, "Auto Quest", BFConfig.AutoQuest_Enabled, function(v) BFConfig.AutoQuest_Enabled = v end, 7)
	makeToggle(farm, "Auto Raid", BFConfig.AutoRaid_Enabled, function(v) BFConfig.AutoRaid_Enabled = v end, 8)
	makeLabel(farm, "COMBAT", 9)
	makeToggle(farm, "Fast Attack", BFConfig.FastAttack_Enabled, function(v) BFConfig.FastAttack_Enabled = v end, 10)
	makeToggle(farm, "Auto Bounty", BFConfig.AutoBounty_Enabled, function(v) BFConfig.AutoBounty_Enabled = v end, 11)
	local esp = pages["ESP"]
	makeLabel(esp, "WORLD ESP", 1)
	makeToggle(esp, "Fruit ESP", BFConfig.FruitESP_Enabled, function(v) BFConfig.FruitESP_Enabled = v end, 2)
	makeToggle(esp, "Chest ESP", BFConfig.ChestESP_Enabled, function(v) BFConfig.ChestESP_Enabled = v end, 3)
	local fruit = pages["Fruit"]
	makeLabel(fruit, "FRUIT TOOLS", 1)
	makeToggle(fruit, "Fruit Sniper", BFConfig.FruitSniper_Enabled, function(v) BFConfig.FruitSniper_Enabled = v end, 2)
	makeCycle(fruit, "Snipe Range", {500, 1000, 2000, 5000, 9999}, BFConfig.FruitSniper_Range, function(v) BFConfig.FruitSniper_Range = v end, 3)
	local misc = pages["Misc"]
	makeLabel(misc, "SERVER", 1)
	makeToggle(misc, "Server Hop (low HP)", BFConfig.ServerHop_Enabled, function(v) BFConfig.ServerHop_Enabled = v end, 2)
	makeLabel(misc, "INFO", 3)
	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(1, 0, 0, 50); info.BackgroundTransparency = 1
	info.Text = "⌨  RightCtrl — Toggle UI\n🍎  Blox Fruits Edition\n📦  TeekHub v4"
	info.TextColor3 = TEXT_DIM; info.TextSize = 11; info.Font = Enum.Font.Gotham
	info.TextWrapped = true; info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextYAlignment = Enum.TextYAlignment.Top; info.LayoutOrder = 4; info.Parent = misc
	switchTab("Farm")
	return screenGui
end
local gui = buildBFUI()
RunService.RenderStepped:Connect(function()
	pcall(autoFarm)
	pcall(bringMobs)
	pcall(fruitSniper)
	pcall(updateFruitESP)
	pcall(updateChestESP)
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.RightControl then
		local mf = gui.MainFrame
		if mf.Visible then
			TweenService:Create(mf, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)
			}):Play()
			task.delay(0.25, function() mf.Visible = false end)
		else
			mf.Visible = true; mf.Size = UDim2.new(0, 0, 0, 0); mf.Position = UDim2.new(0.5, 0, 0.5, 0)
			TweenService:Create(mf, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 520, 0, 400), Position = UDim2.new(0.5, -260, 0.5, -200)
			}):Play()
		end
	end
end)
print("[TeekHub] Blox Fruits loaded — RightCtrl to toggle")
print("[TeekHub] Tabs: Farm | ESP | Fruit | Misc")
