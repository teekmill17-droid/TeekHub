local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local ParryAttempt = Remotes and Remotes:FindFirstChild("ParryAttempt")
local BallsFolder = Workspace:FindFirstChild("Balls")
local AliveFolder = Workspace:FindFirstChild("Alive")
local BBConfig = {
	AutoParry_Enabled = false,
	AutoParry_Distance = 35,
	AutoParry_Mode = "Safe",
	BallESP_Enabled = false,
	PlayerESP_Enabled = false,
	ParryCount = 0,
}
local DrawingSupported = pcall(function() local t = Drawing.new("Line"); t:Remove() end)
local BallESPDot, BallESPLabel, BallESPTracer
if DrawingSupported then
	pcall(function()
		BallESPDot = Drawing.new("Circle")
		BallESPDot.Radius = 8; BallESPDot.Filled = true
		BallESPDot.Color = Color3.fromRGB(255, 50, 50); BallESPDot.Visible = false
		BallESPDot.Thickness = 2
		BallESPLabel = Drawing.new("Text")
		BallESPLabel.Center = true; BallESPLabel.Outline = true
		BallESPLabel.Size = 14; BallESPLabel.Color = Color3.fromRGB(255, 255, 100)
		BallESPLabel.Visible = false
		BallESPTracer = Drawing.new("Line")
		BallESPTracer.Thickness = 1.5
		BallESPTracer.Color = Color3.fromRGB(255, 80, 80); BallESPTracer.Visible = false
	end)
end
local function worldToScreen(pos)
	local sp, on = Camera:WorldToViewportPoint(pos)
	return Vector2.new(sp.X, sp.Y), on
end
local function getActiveBall()
	if not BallsFolder then BallsFolder = Workspace:FindFirstChild("Balls") end
	if not BallsFolder then return nil end
	for _, ball in BallsFolder:GetChildren() do
		local part = ball:IsA("BasePart") and ball or ball:FindFirstChildWhichIsA("BasePart")
		if part then return part end
	end
	return nil
end
local function getMyRoot()
	local char = LocalPlayer.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
end
local lastBallPos = nil
local lastBallTime = 0
local function getBallVelocity(ballPart)
	local now = tick()
	local currentPos = ballPart.Position
	local vel = Vector3.zero
	if lastBallPos and (now - lastBallTime) > 0 then
		vel = (currentPos - lastBallPos) / (now - lastBallTime)
	end
	lastBallPos = currentPos
	lastBallTime = now
	return vel
end
local function isBallComingAtMe(ballPart, myRoot)
	local toBall = ballPart.Position - myRoot.Position
	local dist = toBall.Magnitude
	local vel = getBallVelocity(ballPart)
	if vel.Magnitude < 5 then return false, dist end
	local dirToBall = toBall.Unit
	local ballDir = vel.Unit
	local dot = dirToBall:Dot(ballDir)
	return dot < -0.3, dist
end
local parryCooldown = 0
local function autoParry()
	if not BBConfig.AutoParry_Enabled then return end
	if not ParryAttempt then
		ParryAttempt = Remotes and Remotes:FindFirstChild("ParryAttempt")
		if not ParryAttempt then return end
	end
	if tick() - parryCooldown < 0.4 then return end
	local ball = getActiveBall()
	if not ball then return end
	local myRoot = getMyRoot()
	if not myRoot then return end
	local comingAtMe, dist = isBallComingAtMe(ball, myRoot)
	local parryDist = BBConfig.AutoParry_Distance
	if BBConfig.AutoParry_Mode == "Safe" then
		parryDist = 25
	elseif BBConfig.AutoParry_Mode == "Normal" then
		parryDist = 35
	elseif BBConfig.AutoParry_Mode == "Risky" then
		parryDist = 50
	end
	if comingAtMe and dist <= parryDist then
		pcall(function()
			ParryAttempt:FireServer()
		end)
		parryCooldown = tick()
		BBConfig.ParryCount += 1
	end
end
local function updateBallESP()
	if not DrawingSupported then return end
	if not BBConfig.BallESP_Enabled then
		if BallESPDot then BallESPDot.Visible = false end
		if BallESPLabel then BallESPLabel.Visible = false end
		if BallESPTracer then BallESPTracer.Visible = false end
		return
	end
	local ball = getActiveBall()
	if not ball then
		if BallESPDot then BallESPDot.Visible = false end
		if BallESPLabel then BallESPLabel.Visible = false end
		if BallESPTracer then BallESPTracer.Visible = false end
		return
	end
	local sp, on = worldToScreen(ball.Position)
	local myRoot = getMyRoot()
	local dist = myRoot and math.floor((myRoot.Position - ball.Position).Magnitude) or 0
	if on and BallESPDot then
		BallESPDot.Position = sp; BallESPDot.Visible = true
		local comingAtMe = myRoot and select(1, isBallComingAtMe(ball, myRoot))
		BallESPDot.Color = comingAtMe and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 200, 0)
	elseif BallESPDot then
		BallESPDot.Visible = false
	end
	if on and BallESPLabel then
		BallESPLabel.Position = Vector2.new(sp.X, sp.Y - 18)
		BallESPLabel.Text = "Ball [" .. dist .. "]"
		BallESPLabel.Visible = true
	elseif BallESPLabel then
		BallESPLabel.Visible = false
	end
	if on and BallESPTracer and myRoot then
		local viewSize = Camera.ViewportSize
		BallESPTracer.From = Vector2.new(viewSize.X / 2, viewSize.Y)
		BallESPTracer.To = sp
		BallESPTracer.Visible = true
	elseif BallESPTracer then
		BallESPTracer.Visible = false
	end
end
local PlayerESPCache = {}
local function createPlayerESP()
	if not DrawingSupported then return nil end
	local ok, d = pcall(function()
		local box = Drawing.new("Square")
		box.Thickness = 1; box.Filled = false
		box.Color = Color3.fromRGB(0, 200, 255); box.Visible = false
		local name = Drawing.new("Text")
		name.Center = true; name.Outline = true
		name.Size = 13; name.Color = Color3.fromRGB(255, 255, 255); name.Visible = false
		return {Box = box, Name = name}
	end)
	return ok and d or nil
end
local function hidePlayerESP(d)
	if not d then return end
	pcall(function() d.Box.Visible = false end)
	pcall(function() d.Name.Visible = false end)
end
local function updatePlayerESP()
	if not DrawingSupported then return end
	for _, player in Players:GetPlayers() do
		if player == LocalPlayer then continue end
		if not PlayerESPCache[player] then
			PlayerESPCache[player] = createPlayerESP()
		end
		local d = PlayerESPCache[player]
		if not d then continue end
		if not BBConfig.PlayerESP_Enabled then hidePlayerESP(d); continue end
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local head = char and char:FindFirstChild("Head")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not root or not head or not hum or hum.Health <= 0 then hidePlayerESP(d); continue end
		local topPos, topOn = worldToScreen(head.Position + Vector3.new(0, 1.5, 0))
		local bottomPos, botOn = worldToScreen(root.Position - Vector3.new(0, 3, 0))
		if not topOn and not botOn then hidePlayerESP(d); continue end
		local boxH = math.abs(bottomPos.Y - topPos.Y)
		local boxW = boxH * 0.55
		d.Box.Size = Vector2.new(boxW, boxH)
		d.Box.Position = Vector2.new(topPos.X - boxW / 2, topPos.Y)
		d.Box.Visible = true
		d.Name.Text = player.DisplayName
		d.Name.Position = Vector2.new(topPos.X, topPos.Y - 16)
		d.Name.Visible = true
	end
end
local function buildBBUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TeekHubBB"
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
	local TAG_RED      = Color3.fromRGB(220, 50, 50)
	local TAG_GREEN    = Color3.fromRGB(50, 180, 100)
	local DIVIDER      = Color3.fromRGB(45, 45, 65)
	local WINDOW_W, WINDOW_H = 480, 360
	local SIDEBAR_W, TOPBAR_H, NAV_BTN_H = 130, 40, 34
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
	main.BorderSizePixel = 0; main.Active = true; main.ClipsDescendants = true
	main.Parent = screenGui
	Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
	local ms = Instance.new("UIStroke")
	ms.Color = ACCENT; ms.Thickness = 1; ms.Transparency = 0.7; ms.Parent = main
	tween(main, {
		Size = UDim2.new(0, WINDOW_W, 0, WINDOW_H),
		Position = UDim2.new(0.5, -WINDOW_W/2, 0.5, -WINDOW_H/2)
	}, TWEEN_MED)
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, TOPBAR_H)
	topBar.BackgroundColor3 = TOPBAR_BG; topBar.BorderSizePixel = 0; topBar.Parent = main
	Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 12)
	local tbFill = Instance.new("Frame")
	tbFill.Size = UDim2.new(1, 0, 0, 12); tbFill.Position = UDim2.new(0, 0, 1, -12)
	tbFill.BackgroundColor3 = TOPBAR_BG; tbFill.BorderSizePixel = 0; tbFill.Parent = topBar
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 32, 0, 32); icon.Position = UDim2.new(0, 10, 0.5, -16)
	icon.BackgroundColor3 = TAG_RED; icon.Text = "⚔"
	icon.TextSize = 16; icon.Font = Enum.Font.GothamBold; icon.TextColor3 = TEXT_WHITE
	icon.BorderSizePixel = 0; icon.Parent = topBar
	Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 8)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0, 170, 0, 18); title.Position = UDim2.new(0, 48, 0, 4)
	title.BackgroundTransparency = 1; title.Text = "TeekHub — Blade Ball"
	title.TextColor3 = TEXT_WHITE; title.TextSize = 14; title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = topBar
	local dev = Instance.new("TextLabel")
	dev.Size = UDim2.new(0, 100, 0, 14); dev.Position = UDim2.new(0, 48, 0, 22)
	dev.BackgroundTransparency = 1; dev.Text = "Dev  @Teek"
	dev.TextColor3 = TEXT_DIM; dev.TextSize = 11; dev.Font = Enum.Font.Gotham
	dev.TextXAlignment = Enum.TextXAlignment.Left; dev.Parent = topBar
	local tagC = Instance.new("Frame")
	tagC.Size = UDim2.new(0, 200, 0, 22); tagC.Position = UDim2.new(0, 225, 0.5, -11)
	tagC.BackgroundTransparency = 1; tagC.Parent = topBar
	local tl = Instance.new("UIListLayout")
	tl.FillDirection = Enum.FillDirection.Horizontal; tl.Padding = UDim.new(0, 6)
	tl.SortOrder = Enum.SortOrder.LayoutOrder; tl.Parent = tagC
	local function makeTag(text, color, order)
		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(0, #text * 7 + 16, 0, 20); t.BackgroundColor3 = color
		t.Text = text; t.TextColor3 = TEXT_WHITE; t.TextSize = 10
		t.Font = Enum.Font.GothamBold; t.BorderSizePixel = 0; t.LayoutOrder = order; t.Parent = tagC
		Instance.new("UICorner", t).CornerRadius = UDim.new(0, 6)
	end
	makeTag("Auto Parry", TAG_RED, 1)
	makeTag("Ball ESP", TAG_GREEN, 2)
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 28, 0, 28); closeBtn.Position = UDim2.new(1, -34, 0.5, -14)
	closeBtn.BackgroundTransparency = 1; closeBtn.Text = "✕"; closeBtn.TextColor3 = TEXT_DIM
	closeBtn.TextSize = 16; closeBtn.Font = Enum.Font.GothamBold; closeBtn.BorderSizePixel = 0
	closeBtn.AutoButtonColor = false; closeBtn.Parent = topBar
	closeBtn.MouseButton1Click:Connect(function()
		tween(main, {Size = UDim2.new(0,0,0,0), Position = UDim2.new(0.5,0,0.5,0)}, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In))
		task.delay(0.25, function() main.Visible = false end)
	end)
	closeBtn.MouseEnter:Connect(function() tween(closeBtn, {TextColor3 = TEXT_WHITE}, TWEEN_FAST) end)
	closeBtn.MouseLeave:Connect(function() tween(closeBtn, {TextColor3 = TEXT_DIM}, TWEEN_FAST) end)
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
			local d = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	local sidebar = Instance.new("Frame")
	sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -TOPBAR_H)
	sidebar.Position = UDim2.new(0, 0, 0, TOPBAR_H)
	sidebar.BackgroundColor3 = SIDEBAR_BG; sidebar.BorderSizePixel = 0; sidebar.Parent = main
	Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 12)
	local sf1 = Instance.new("Frame")
	sf1.Size = UDim2.new(1, 0, 0, 12); sf1.BackgroundColor3 = SIDEBAR_BG
	sf1.BorderSizePixel = 0; sf1.Parent = sidebar
	local sf2 = Instance.new("Frame")
	sf2.Size = UDim2.new(0, 12, 1, 0); sf2.Position = UDim2.new(1, -12, 0, 0)
	sf2.BackgroundColor3 = SIDEBAR_BG; sf2.BorderSizePixel = 0; sf2.Parent = sidebar
	local navC = Instance.new("Frame")
	navC.Size = UDim2.new(1, -12, 1, -20); navC.Position = UDim2.new(0, 6, 0, 16)
	navC.BackgroundTransparency = 1; navC.Parent = sidebar
	local nl = Instance.new("UIListLayout")
	nl.Padding = UDim.new(0, 3); nl.SortOrder = Enum.SortOrder.LayoutOrder; nl.Parent = navC
	local contentArea = Instance.new("Frame")
	contentArea.Size = UDim2.new(1, -(SIDEBAR_W + 16), 1, -(TOPBAR_H + 12))
	contentArea.Position = UDim2.new(0, SIDEBAR_W + 8, 0, TOPBAR_H + 6)
	contentArea.BackgroundTransparency = 1; contentArea.ClipsDescendants = true; contentArea.Parent = main
	local pages, navButtons, activeTab = {}, {}, nil
	local tabDefs = {
		{name = "Parry", icon = "⚔"},
		{name = "ESP", icon = "👁"},
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
	local function switchTab(tabName)
		activeTab = tabName
		for name, page in pages do
			page.Visible = (name == tabName)
			if name == tabName then page.CanvasPosition = Vector2.new(0, 0) end
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
		btn.LayoutOrder = i; btn.AutoButtonColor = false; btn.Parent = navC
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		navButtons[def.name] = btn
		btn.MouseButton1Click:Connect(function() switchTab(def.name) end)
		btn.MouseEnter:Connect(function()
			if activeTab ~= def.name then tween(btn, {BackgroundColor3 = Color3.fromRGB(40,40,60), BackgroundTransparency = 0}, TWEEN_FAST) end
		end)
		btn.MouseLeave:Connect(function()
			if activeTab ~= def.name then tween(btn, {BackgroundTransparency = 1}, TWEEN_FAST) end
		end)
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
		t.MouseButton1Click:Connect(function()
			state = not state; t.Text = state and "ON" or "OFF"
			tween(t, {BackgroundColor3 = state and GREEN or RED_DIM}, TWEEN_FAST)
			tween(t, {Size = UDim2.new(0, 44, 0, 22)}, TweenInfo.new(0.08))
			task.delay(0.08, function() tween(t, {Size = UDim2.new(0, 40, 0, 20)}, TweenInfo.new(0.08)) end)
			pcall(callback, state)
		end)
		c.MouseEnter:Connect(function() tween(c, {BackgroundColor3 = Color3.fromRGB(42,42,62)}, TWEEN_FAST) end)
		c.MouseLeave:Connect(function() tween(c, {BackgroundColor3 = CARD_BG}, TWEEN_FAST) end)
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
		c.MouseEnter:Connect(function() tween(c, {BackgroundColor3 = Color3.fromRGB(42,42,62)}, TWEEN_FAST) end)
		c.MouseLeave:Connect(function() tween(c, {BackgroundColor3 = CARD_BG}, TWEEN_FAST) end)
	end
	local function makeDivider(parent, layoutOrder)
		local d = Instance.new("Frame")
		d.Size = UDim2.new(1, 0, 0, 1); d.BackgroundColor3 = DIVIDER
		d.BorderSizePixel = 0; d.LayoutOrder = layoutOrder or 0; d.Parent = parent
	end
	local parry = pages["Parry"]
	makeLabel(parry, "AUTO PARRY", 1)
	makeToggle(parry, "Auto Parry", BBConfig.AutoParry_Enabled, function(v) BBConfig.AutoParry_Enabled = v end, 2)
	makeDivider(parry, 3)
	makeLabel(parry, "TIMING", 4)
	makeCycle(parry, "Mode", {"Safe", "Normal", "Risky"}, BBConfig.AutoParry_Mode, function(v) BBConfig.AutoParry_Mode = v end, 5)
	makeDivider(parry, 6)
	makeLabel(parry, "STATS", 7)
	local parryCountLabel = Instance.new("TextLabel")
	parryCountLabel.Size = UDim2.new(1, 0, 0, 30); parryCountLabel.BackgroundColor3 = CARD_BG
	parryCountLabel.BorderSizePixel = 0; parryCountLabel.LayoutOrder = 8
	parryCountLabel.Text = "  Parries: 0"; parryCountLabel.TextColor3 = TEXT_WHITE
	parryCountLabel.TextSize = 12; parryCountLabel.Font = Enum.Font.GothamMedium
	parryCountLabel.TextXAlignment = Enum.TextXAlignment.Left; parryCountLabel.Parent = parry
	Instance.new("UICorner", parryCountLabel).CornerRadius = UDim.new(0, 6)
	local esp = pages["ESP"]
	makeLabel(esp, "BALL", 1)
	makeToggle(esp, "Ball ESP", BBConfig.BallESP_Enabled, function(v) BBConfig.BallESP_Enabled = v end, 2)
	makeDivider(esp, 3)
	makeLabel(esp, "PLAYERS", 4)
	makeToggle(esp, "Player ESP", BBConfig.PlayerESP_Enabled, function(v) BBConfig.PlayerESP_Enabled = v end, 5)
	local misc = pages["Misc"]
	makeLabel(misc, "INFO", 1)
	local infoCard = Instance.new("Frame")
	infoCard.Size = UDim2.new(1, 0, 0, 90); infoCard.BackgroundColor3 = CARD_BG
	infoCard.BorderSizePixel = 0; infoCard.LayoutOrder = 2; infoCard.Parent = misc
	Instance.new("UICorner", infoCard).CornerRadius = UDim.new(0, 6)
	local infoText = Instance.new("TextLabel")
	infoText.Size = UDim2.new(1, -16, 1, -8); infoText.Position = UDim2.new(0, 8, 0, 4)
	infoText.BackgroundTransparency = 1
	infoText.Text = "⌨  RightCtrl — Toggle UI\n⚔  Auto Parry fires when ball\n    is close + heading at you\n🔴  Ball ESP turns red when\n    ball is targeting you\n📦  TeekHub — Blade Ball"
	infoText.TextColor3 = TEXT_DIM; infoText.TextSize = 11; infoText.Font = Enum.Font.Gotham
	infoText.TextWrapped = true; infoText.TextXAlignment = Enum.TextXAlignment.Left
	infoText.TextYAlignment = Enum.TextYAlignment.Top; infoText.Parent = infoCard
	switchTab("Parry")
	task.spawn(function()
		while task.wait(0.5) do
			pcall(function()
				parryCountLabel.Text = "  Parries: " .. BBConfig.ParryCount
			end)
		end
	end)
	return screenGui
end
local gui = buildBBUI()
RunService.RenderStepped:Connect(function()
	pcall(autoParry)
	pcall(updateBallESP)
	pcall(updatePlayerESP)
end)
Players.PlayerRemoving:Connect(function(player)
	if PlayerESPCache[player] then
		pcall(function() PlayerESPCache[player].Box:Remove() end)
		pcall(function() PlayerESPCache[player].Name:Remove() end)
		PlayerESPCache[player] = nil
	end
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.RightControl then
		local mf = gui.MainFrame
		if mf.Visible then
			TweenService:Create(mf, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Size = UDim2.new(0,0,0,0), Position = UDim2.new(0.5,0,0.5,0)
			}):Play()
			task.delay(0.25, function() mf.Visible = false end)
		else
			mf.Visible = true; mf.Size = UDim2.new(0,0,0,0); mf.Position = UDim2.new(0.5,0,0.5,0)
			TweenService:Create(mf, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 480, 0, 360), Position = UDim2.new(0.5, -240, 0.5, -180)
			}):Play()
		end
	end
end)
print("[TeekHub] Blade Ball loaded — RightCtrl to toggle")
print("[TeekHub] Tabs: Parry | ESP | Misc")
