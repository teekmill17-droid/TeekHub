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
local BBConfig = {
	AutoParry_Enabled = false,
	AutoParry_Mode = "Safe",
	BallESP_Enabled = false,
	PlayerESP_Enabled = false,
	ParryCount = 0,
}
local PARRY_DISTS = {Safe = 25, Normal = 35, Risky = 50}
local DrawingSupported = pcall(function() local t = Drawing.new("Line"); t:Remove() end)
local BallESPDot, BallESPLabel, BallESPTracer
if DrawingSupported then
	pcall(function()
		BallESPDot = Drawing.new("Circle")
		BallESPDot.Radius = 8; BallESPDot.Filled = true
		BallESPDot.Color = Color3.fromRGB(255, 50, 50); BallESPDot.Visible = false; BallESPDot.Thickness = 2
		BallESPLabel = Drawing.new("Text")
		BallESPLabel.Center = true; BallESPLabel.Outline = true
		BallESPLabel.Size = 14; BallESPLabel.Color = Color3.fromRGB(255, 255, 100); BallESPLabel.Visible = false
		BallESPTracer = Drawing.new("Line")
		BallESPTracer.Thickness = 1.5; BallESPTracer.Color = Color3.fromRGB(255, 80, 80); BallESPTracer.Visible = false
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
	return char and char:FindFirstChild("HumanoidRootPart")
end
local lastBallPos, lastBallTime = nil, 0
local currentBallDist, currentBallSpeed = 0, 0
local ballTargetingMe = false
local function getBallVelocity(ballPart)
	local now = tick()
	local pos = ballPart.Position
	local vel = Vector3.zero
	if lastBallPos and (now - lastBallTime) > 0 then
		vel = (pos - lastBallPos) / (now - lastBallTime)
	end
	lastBallPos = pos; lastBallTime = now
	return vel
end
local function isBallComingAtMe(ballPart, myRoot)
	local toBall = ballPart.Position - myRoot.Position
	local dist = toBall.Magnitude
	local vel = getBallVelocity(ballPart)
	currentBallDist = math.floor(dist)
	currentBallSpeed = math.floor(vel.Magnitude)
	if vel.Magnitude < 5 then ballTargetingMe = false; return false, dist end
	ballTargetingMe = toBall.Unit:Dot(vel.Unit) < -0.3
	return ballTargetingMe, dist
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
	local coming, dist = isBallComingAtMe(ball, myRoot)
	if coming and dist <= (PARRY_DISTS[BBConfig.AutoParry_Mode] or 35) then
		pcall(function() ParryAttempt:FireServer() end)
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
	local col = ballTargetingMe and Color3.fromRGB(255, 30, 30) or Color3.fromRGB(255, 200, 0)
	if on and BallESPDot then BallESPDot.Position = sp; BallESPDot.Color = col; BallESPDot.Visible = true
	elseif BallESPDot then BallESPDot.Visible = false end
	if on and BallESPLabel then
		BallESPLabel.Position = Vector2.new(sp.X, sp.Y - 18)
		BallESPLabel.Text = "Ball [" .. currentBallDist .. "]"; BallESPLabel.Visible = true
	elseif BallESPLabel then BallESPLabel.Visible = false end
	if on and BallESPTracer then
		BallESPTracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
		BallESPTracer.To = sp; BallESPTracer.Color = col; BallESPTracer.Visible = true
	elseif BallESPTracer then BallESPTracer.Visible = false end
end
local PlayerESPCache = {}
local function createPESP()
	if not DrawingSupported then return nil end
	local ok, d = pcall(function()
		local box = Drawing.new("Square"); box.Thickness = 1; box.Filled = false; box.Color = Color3.fromRGB(0, 200, 255); box.Visible = false
		local name = Drawing.new("Text"); name.Center = true; name.Outline = true; name.Size = 13; name.Color = Color3.fromRGB(255, 255, 255); name.Visible = false
		return {Box = box, Name = name}
	end)
	return ok and d or nil
end
local function updatePlayerESP()
	if not DrawingSupported then return end
	for _, player in Players:GetPlayers() do
		if player == LocalPlayer then continue end
		if not PlayerESPCache[player] then PlayerESPCache[player] = createPESP() end
		local d = PlayerESPCache[player]
		if not d then continue end
		if not BBConfig.PlayerESP_Enabled then pcall(function() d.Box.Visible = false; d.Name.Visible = false end); continue end
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local head = char and char:FindFirstChild("Head")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not root or not head or not hum or hum.Health <= 0 then pcall(function() d.Box.Visible = false; d.Name.Visible = false end); continue end
		local tp, to = worldToScreen(head.Position + Vector3.new(0, 1.5, 0))
		local bp, bo = worldToScreen(root.Position - Vector3.new(0, 3, 0))
		if not to and not bo then pcall(function() d.Box.Visible = false; d.Name.Visible = false end); continue end
		local h = math.abs(bp.Y - tp.Y); local w = h * 0.55
		d.Box.Size = Vector2.new(w, h); d.Box.Position = Vector2.new(tp.X - w/2, tp.Y); d.Box.Visible = true
		d.Name.Text = player.DisplayName; d.Name.Position = Vector2.new(tp.X, tp.Y - 16); d.Name.Visible = true
	end
end
local function buildUI()
	local sg = Instance.new("ScreenGui")
	sg.Name = "TeekHubBB"; sg.ResetOnSpawn = false; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	pcall(function() sg.Parent = game:GetService("CoreGui") end)
	if not sg.Parent then sg.Parent = LocalPlayer:WaitForChild("PlayerGui") end
	local C = {
		bg1 = Color3.fromRGB(13, 13, 22), bg2 = Color3.fromRGB(18, 18, 30), bg3 = Color3.fromRGB(23, 23, 38),
		card = Color3.fromRGB(28, 28, 46), cardHover = Color3.fromRGB(35, 35, 56),
		accent = Color3.fromRGB(127, 90, 240), accentDim = Color3.fromRGB(90, 65, 180),
		green = Color3.fromRGB(45, 200, 95), red = Color3.fromRGB(220, 55, 65), redDim = Color3.fromRGB(50, 40, 55),
		text = Color3.fromRGB(235, 235, 242), textDim = Color3.fromRGB(120, 120, 150), textMuted = Color3.fromRGB(80, 80, 105),
		divider = Color3.fromRGB(40, 40, 60), warning = Color3.fromRGB(255, 180, 40), safe = Color3.fromRGB(45, 200, 95),
	}
	local WW, WH, SW, TH = 480, 380, 135, 42
	local TF = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local TM = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local TS = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local function tw(o, p, i) TweenService:Create(o, i or TF, p):Play() end
	local main = Instance.new("Frame")
	main.Name = "MainFrame"; main.Size = UDim2.new(0,0,0,0); main.Position = UDim2.new(0.5,0,0.5,0)
	main.BackgroundColor3 = C.bg3; main.BorderSizePixel = 0; main.Active = true; main.ClipsDescendants = true; main.Parent = sg
	Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
	local mst = Instance.new("UIStroke"); mst.Color = C.accent; mst.Thickness = 1; mst.Transparency = 0.6; mst.Parent = main
	tw(main, {Size = UDim2.new(0, WW, 0, WH), Position = UDim2.new(0.5, -WW/2, 0.5, -WH/2)}, TM)
	local top = Instance.new("Frame"); top.Size = UDim2.new(1,0,0,TH); top.BackgroundColor3 = C.bg2; top.BorderSizePixel = 0; top.Parent = main
	Instance.new("UICorner", top).CornerRadius = UDim.new(0, 10)
	local topF = Instance.new("Frame"); topF.Size = UDim2.new(1,0,0,10); topF.Position = UDim2.new(0,0,1,-10); topF.BackgroundColor3 = C.bg2; topF.BorderSizePixel = 0; topF.Parent = top
	local ico = Instance.new("Frame"); ico.Size = UDim2.new(0,30,0,30); ico.Position = UDim2.new(0,8,0.5,-15); ico.BackgroundColor3 = C.accent; ico.BorderSizePixel = 0; ico.Parent = top
	Instance.new("UICorner", ico).CornerRadius = UDim.new(0, 7)
	local icoT = Instance.new("TextLabel"); icoT.Size = UDim2.new(1,0,1,0); icoT.BackgroundTransparency = 1; icoT.Text = "⚔"; icoT.TextColor3 = C.text; icoT.TextSize = 14; icoT.Font = Enum.Font.GothamBold; icoT.Parent = ico
	local ttl = Instance.new("TextLabel"); ttl.Size = UDim2.new(0,120,0,16); ttl.Position = UDim2.new(0,44,0,5); ttl.BackgroundTransparency = 1; ttl.Text = "TeekHub"; ttl.TextColor3 = C.text; ttl.TextSize = 14; ttl.Font = Enum.Font.GothamBold; ttl.TextXAlignment = Enum.TextXAlignment.Left; ttl.Parent = top
	local subt = Instance.new("TextLabel"); subt.Size = UDim2.new(0,120,0,13); subt.Position = UDim2.new(0,44,0,22); subt.BackgroundTransparency = 1; subt.Text = "Blade Ball"; subt.TextColor3 = C.textDim; subt.TextSize = 11; subt.Font = Enum.Font.Gotham; subt.TextXAlignment = Enum.TextXAlignment.Left; subt.Parent = top
	local sDot = Instance.new("Frame"); sDot.Size = UDim2.new(0,8,0,8); sDot.Position = UDim2.new(0,166,0,26); sDot.BackgroundColor3 = C.safe; sDot.BorderSizePixel = 0; sDot.Parent = top
	Instance.new("UICorner", sDot).CornerRadius = UDim.new(1, 0)
	local sTxt = Instance.new("TextLabel"); sTxt.Size = UDim2.new(0,60,0,13); sTxt.Position = UDim2.new(0,178,0,22); sTxt.BackgroundTransparency = 1; sTxt.Text = "Ready"; sTxt.TextColor3 = C.safe; sTxt.TextSize = 10; sTxt.Font = Enum.Font.GothamMedium; sTxt.TextXAlignment = Enum.TextXAlignment.Left; sTxt.Parent = top
	local tagF = Instance.new("Frame"); tagF.Size = UDim2.new(0,120,0,20); tagF.Position = UDim2.new(0,245,0.5,-10); tagF.BackgroundTransparency = 1; tagF.Parent = top
	local tl = Instance.new("UIListLayout"); tl.FillDirection = Enum.FillDirection.Horizontal; tl.Padding = UDim.new(0,5); tl.VerticalAlignment = Enum.VerticalAlignment.Center; tl.Parent = tagF
	local function mkTag(txt, col, ord)
		local f = Instance.new("Frame"); f.Size = UDim2.new(0, #txt*6.5+14, 0, 18); f.BackgroundColor3 = col; f.BackgroundTransparency = 0.15; f.BorderSizePixel = 0; f.LayoutOrder = ord; f.Parent = tagF
		Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)
		local l = Instance.new("TextLabel"); l.Size = UDim2.new(1,0,1,0); l.BackgroundTransparency = 1; l.Text = txt; l.TextColor3 = col; l.TextSize = 9; l.Font = Enum.Font.GothamBold; l.Parent = f
	end
	mkTag("v2", C.accent, 1); mkTag("FREE", C.green, 2)
	local function mkWinBtn(txt, col, pos, cb)
		local b = Instance.new("TextButton"); b.Size = UDim2.new(0,24,0,24); b.Position = pos; b.BackgroundColor3 = col; b.BackgroundTransparency = 0.85
		b.Text = txt; b.TextColor3 = C.textDim; b.TextSize = 12; b.Font = Enum.Font.GothamBold; b.BorderSizePixel = 0; b.AutoButtonColor = false; b.Parent = top
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
		b.MouseEnter:Connect(function() tw(b, {BackgroundTransparency = 0.3, TextColor3 = C.text}, TF) end)
		b.MouseLeave:Connect(function() tw(b, {BackgroundTransparency = 0.85, TextColor3 = C.textDim}, TF) end)
		b.MouseButton1Click:Connect(cb); return b
	end
	local minimized = false
	mkWinBtn("—", C.warning, UDim2.new(1,-60,0.5,-12), function()
		minimized = not minimized
		if minimized then tw(main, {Size = UDim2.new(0,WW,0,TH)}, TS) else tw(main, {Size = UDim2.new(0,WW,0,WH)}, TM) end
	end)
	mkWinBtn("✕", C.red, UDim2.new(1,-32,0.5,-12), function()
		tw(main, {Size = UDim2.new(0,0,0,0), Position = UDim2.new(0.5,0,0.5,0)}, TS)
		task.delay(0.3, function() main.Visible = false end)
	end)
	local dragging, dragStart, startPos = false, nil, nil
	top.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = input.Position; startPos = main.Position
			input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	local sidebar = Instance.new("Frame"); sidebar.Size = UDim2.new(0,SW,1,-TH); sidebar.Position = UDim2.new(0,0,0,TH); sidebar.BackgroundColor3 = C.bg1; sidebar.BorderSizePixel = 0; sidebar.Parent = main
	Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 10)
	local sf1 = Instance.new("Frame"); sf1.Size = UDim2.new(1,0,0,10); sf1.BackgroundColor3 = C.bg1; sf1.BorderSizePixel = 0; sf1.Parent = sidebar
	local sf2 = Instance.new("Frame"); sf2.Size = UDim2.new(0,10,1,0); sf2.Position = UDim2.new(1,-10,0,0); sf2.BackgroundColor3 = C.bg1; sf2.BorderSizePixel = 0; sf2.Parent = sidebar
	local dv = Instance.new("Frame"); dv.Size = UDim2.new(0,1,1,-24); dv.Position = UDim2.new(1,0,0,12); dv.BackgroundColor3 = C.divider; dv.BorderSizePixel = 0; dv.Parent = sidebar
	local navC = Instance.new("Frame"); navC.Size = UDim2.new(1,-14,1,-70); navC.Position = UDim2.new(0,7,0,14); navC.BackgroundTransparency = 1; navC.Parent = sidebar
	local nl = Instance.new("UIListLayout"); nl.Padding = UDim.new(0,2); nl.SortOrder = Enum.SortOrder.LayoutOrder; nl.Parent = navC
	local pcBox = Instance.new("Frame"); pcBox.Size = UDim2.new(1,-14,0,44); pcBox.Position = UDim2.new(0,7,1,-52); pcBox.BackgroundColor3 = C.bg2; pcBox.BorderSizePixel = 0; pcBox.Parent = sidebar
	Instance.new("UICorner", pcBox).CornerRadius = UDim.new(0, 7)
	local pcL = Instance.new("TextLabel"); pcL.Size = UDim2.new(1,-10,0,14); pcL.Position = UDim2.new(0,8,0,5); pcL.BackgroundTransparency = 1; pcL.Text = "PARRIES"; pcL.TextColor3 = C.textMuted; pcL.TextSize = 9; pcL.Font = Enum.Font.GothamBold; pcL.TextXAlignment = Enum.TextXAlignment.Left; pcL.Parent = pcBox
	local pcV = Instance.new("TextLabel"); pcV.Size = UDim2.new(1,-10,0,18); pcV.Position = UDim2.new(0,8,0,20); pcV.BackgroundTransparency = 1; pcV.Text = "0"; pcV.TextColor3 = C.accent; pcV.TextSize = 16; pcV.Font = Enum.Font.GothamBold; pcV.TextXAlignment = Enum.TextXAlignment.Left; pcV.Parent = pcBox
	local content = Instance.new("Frame"); content.Size = UDim2.new(1,-(SW+14),1,-(TH+10)); content.Position = UDim2.new(0,SW+7,0,TH+5); content.BackgroundTransparency = 1; content.ClipsDescendants = true; content.Parent = main
	local pages, navBtns, activeTab = {}, {}, nil
	local tabs = {{n="Parry",i="⚔",d="Auto deflect"},{n="ESP",i="👁",d="Visual overlays"},{n="Info",i="📋",d="Controls"}}
	for _, t in tabs do
		local p = Instance.new("ScrollingFrame"); p.Size = UDim2.new(1,0,1,0); p.BackgroundTransparency = 1; p.ScrollBarThickness = 2; p.ScrollBarImageColor3 = C.accent; p.BorderSizePixel = 0; p.Visible = false; p.CanvasSize = UDim2.new(0,0,0,0); p.AutomaticCanvasSize = Enum.AutomaticSize.Y; p.Parent = content
		local pl = Instance.new("UIListLayout"); pl.Padding = UDim.new(0,4); pl.SortOrder = Enum.SortOrder.LayoutOrder; pl.Parent = p
		pages[t.n] = p
	end
	local function switchTab(name)
		activeTab = name
		for n, p in pages do p.Visible = (n == name); if n == name then p.CanvasPosition = Vector2.new(0,0) end end
		for n, b in navBtns do
			if n == name then tw(b.f, {BackgroundColor3 = C.accent, BackgroundTransparency = 0}, TF); tw(b.l, {TextColor3 = C.text}, TF); tw(b.s, {TextColor3 = Color3.fromRGB(200,190,255)}, TF)
			else tw(b.f, {BackgroundTransparency = 1}, TF); tw(b.l, {TextColor3 = C.textDim}, TF); tw(b.s, {TextColor3 = C.textMuted}, TF) end
		end
	end
	for i, t in tabs do
		local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1,0,0,40); btn.BackgroundTransparency = 1; btn.BackgroundColor3 = C.accent; btn.Text = ""; btn.BorderSizePixel = 0; btn.LayoutOrder = i; btn.AutoButtonColor = false; btn.Parent = navC
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
		local iL = Instance.new("TextLabel"); iL.Size = UDim2.new(0,20,0,20); iL.Position = UDim2.new(0,8,0.5,-10); iL.BackgroundTransparency = 1; iL.Text = t.i; iL.TextSize = 13; iL.Parent = btn
		local nL = Instance.new("TextLabel"); nL.Size = UDim2.new(1,-34,0,14); nL.Position = UDim2.new(0,32,0,5); nL.BackgroundTransparency = 1; nL.Text = t.n; nL.TextColor3 = C.textDim; nL.TextSize = 12; nL.Font = Enum.Font.GothamBold; nL.TextXAlignment = Enum.TextXAlignment.Left; nL.Parent = btn
		local dL = Instance.new("TextLabel"); dL.Size = UDim2.new(1,-34,0,11); dL.Position = UDim2.new(0,32,0,20); dL.BackgroundTransparency = 1; dL.Text = t.d; dL.TextColor3 = C.textMuted; dL.TextSize = 9; dL.Font = Enum.Font.Gotham; dL.TextXAlignment = Enum.TextXAlignment.Left; dL.Parent = btn
		navBtns[t.n] = {f = btn, l = nL, s = dL}
		btn.MouseButton1Click:Connect(function() switchTab(t.n) end)
		btn.MouseEnter:Connect(function() if activeTab ~= t.n then tw(btn, {BackgroundColor3 = C.cardHover, BackgroundTransparency = 0}, TF) end end)
		btn.MouseLeave:Connect(function() if activeTab ~= t.n then tw(btn, {BackgroundTransparency = 1}, TF) end end)
	end
	local function mkLabel(par, txt, ord)
		local l = Instance.new("TextLabel"); l.Size = UDim2.new(1,0,0,20); l.BackgroundTransparency = 1; l.Text = "  "..txt; l.TextColor3 = C.textMuted; l.TextSize = 9; l.Font = Enum.Font.GothamBold; l.TextXAlignment = Enum.TextXAlignment.Left; l.LayoutOrder = ord or 0; l.Parent = par
	end
	local function mkToggle(par, txt, def, cb, ord)
		local row = Instance.new("Frame"); row.Size = UDim2.new(1,0,0,34); row.BackgroundColor3 = C.card; row.BorderSizePixel = 0; row.LayoutOrder = ord or 0; row.Parent = par
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)
		local l = Instance.new("TextLabel"); l.Size = UDim2.new(1,-65,1,0); l.Position = UDim2.new(0,14,0,0); l.BackgroundTransparency = 1; l.Text = txt; l.TextColor3 = C.text; l.TextSize = 12; l.Font = Enum.Font.GothamMedium; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = row
		local pill = Instance.new("Frame"); pill.Size = UDim2.new(0,38,0,20); pill.Position = UDim2.new(1,-48,0.5,-10); pill.BackgroundColor3 = def and C.green or C.redDim; pill.BorderSizePixel = 0; pill.Parent = row
		Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
		local knob = Instance.new("Frame"); knob.Size = UDim2.new(0,16,0,16); knob.Position = def and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8); knob.BackgroundColor3 = C.text; knob.BorderSizePixel = 0; knob.Parent = pill
		Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
		local state = def
		local ca = Instance.new("TextButton"); ca.Size = UDim2.new(1,0,1,0); ca.BackgroundTransparency = 1; ca.Text = ""; ca.Parent = row
		ca.MouseButton1Click:Connect(function()
			state = not state
			tw(pill, {BackgroundColor3 = state and C.green or C.redDim}, TF)
			tw(knob, {Position = state and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)}, TF)
			pcall(cb, state)
		end)
		row.MouseEnter:Connect(function() tw(row, {BackgroundColor3 = C.cardHover}, TF) end)
		row.MouseLeave:Connect(function() tw(row, {BackgroundColor3 = C.card}, TF) end)
	end
	local function mkCycle(par, txt, vals, def, cb, ord)
		local idx = 1; for i, v in vals do if v == def then idx = i; break end end
		local row = Instance.new("Frame"); row.Size = UDim2.new(1,0,0,34); row.BackgroundColor3 = C.card; row.BorderSizePixel = 0; row.LayoutOrder = ord or 0; row.Parent = par
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)
		local l = Instance.new("TextLabel"); l.Size = UDim2.new(0.55,0,1,0); l.Position = UDim2.new(0,14,0,0); l.BackgroundTransparency = 1; l.Text = txt; l.TextColor3 = C.text; l.TextSize = 12; l.Font = Enum.Font.GothamMedium; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = row
		local vb = Instance.new("TextButton"); vb.Size = UDim2.new(0,60,0,22); vb.Position = UDim2.new(1,-68,0.5,-11); vb.BackgroundColor3 = C.accentDim; vb.Text = tostring(vals[idx]); vb.TextColor3 = C.text; vb.TextSize = 11; vb.Font = Enum.Font.GothamBold; vb.BorderSizePixel = 0; vb.AutoButtonColor = false; vb.Parent = row
		Instance.new("UICorner", vb).CornerRadius = UDim.new(0, 5)
		vb.MouseButton1Click:Connect(function() idx = idx % #vals + 1; vb.Text = tostring(vals[idx]); pcall(cb, vals[idx]) end)
		vb.MouseEnter:Connect(function() tw(vb, {BackgroundColor3 = C.accent}, TF) end)
		vb.MouseLeave:Connect(function() tw(vb, {BackgroundColor3 = C.accentDim}, TF) end)
		row.MouseEnter:Connect(function() tw(row, {BackgroundColor3 = C.cardHover}, TF) end)
		row.MouseLeave:Connect(function() tw(row, {BackgroundColor3 = C.card}, TF) end)
	end
	local function mkDivider(par, ord)
		local d = Instance.new("Frame"); d.Size = UDim2.new(1,-20,0,1); d.Position = UDim2.new(0,10,0,0); d.BackgroundColor3 = C.divider; d.BorderSizePixel = 0; d.LayoutOrder = ord or 0; d.Parent = par
	end
	local pp = pages["Parry"]
	local bsc = Instance.new("Frame"); bsc.Size = UDim2.new(1,0,0,56); bsc.BackgroundColor3 = C.bg2; bsc.BorderSizePixel = 0; bsc.LayoutOrder = 1; bsc.Parent = pp
	Instance.new("UICorner", bsc).CornerRadius = UDim.new(0, 8)
	local bsStr = Instance.new("UIStroke"); bsStr.Color = C.divider; bsStr.Thickness = 1; bsStr.Parent = bsc
	local bsDt = Instance.new("Frame"); bsDt.Size = UDim2.new(0,10,0,10); bsDt.Position = UDim2.new(0,12,0,12); bsDt.BackgroundColor3 = C.textMuted; bsDt.BorderSizePixel = 0; bsDt.Parent = bsc
	Instance.new("UICorner", bsDt).CornerRadius = UDim.new(1, 0)
	local bsTtl = Instance.new("TextLabel"); bsTtl.Size = UDim2.new(0,120,0,14); bsTtl.Position = UDim2.new(0,28,0,8); bsTtl.BackgroundTransparency = 1; bsTtl.Text = "No Ball Active"; bsTtl.TextColor3 = C.textDim; bsTtl.TextSize = 11; bsTtl.Font = Enum.Font.GothamBold; bsTtl.TextXAlignment = Enum.TextXAlignment.Left; bsTtl.Parent = bsc
	local bsDist = Instance.new("TextLabel"); bsDist.Size = UDim2.new(0.3,0,0,14); bsDist.Position = UDim2.new(0,12,0,32); bsDist.BackgroundTransparency = 1; bsDist.Text = "Dist: —"; bsDist.TextColor3 = C.textMuted; bsDist.TextSize = 10; bsDist.Font = Enum.Font.Gotham; bsDist.TextXAlignment = Enum.TextXAlignment.Left; bsDist.Parent = bsc
	local bsSpd = Instance.new("TextLabel"); bsSpd.Size = UDim2.new(0.3,0,0,14); bsSpd.Position = UDim2.new(0.33,0,0,32); bsSpd.BackgroundTransparency = 1; bsSpd.Text = "Speed: —"; bsSpd.TextColor3 = C.textMuted; bsSpd.TextSize = 10; bsSpd.Font = Enum.Font.Gotham; bsSpd.TextXAlignment = Enum.TextXAlignment.Left; bsSpd.Parent = bsc
	local bsSts = Instance.new("TextLabel"); bsSts.Size = UDim2.new(0.33,0,0,14); bsSts.Position = UDim2.new(0.66,0,0,32); bsSts.BackgroundTransparency = 1; bsSts.Text = "—"; bsSts.TextColor3 = C.textMuted; bsSts.TextSize = 10; bsSts.Font = Enum.Font.GothamBold; bsSts.TextXAlignment = Enum.TextXAlignment.Left; bsSts.Parent = bsc
	mkDivider(pp, 2); mkLabel(pp, "AUTO PARRY", 3)
	mkToggle(pp, "Auto Parry", BBConfig.AutoParry_Enabled, function(v) BBConfig.AutoParry_Enabled = v end, 4)
	mkCycle(pp, "Timing", {"Safe", "Normal", "Risky"}, BBConfig.AutoParry_Mode, function(v) BBConfig.AutoParry_Mode = v end, 5)
	local ep = pages["ESP"]; mkLabel(ep, "BALL TRACKING", 1)
	mkToggle(ep, "Ball ESP", BBConfig.BallESP_Enabled, function(v) BBConfig.BallESP_Enabled = v end, 2)
	mkDivider(ep, 3); mkLabel(ep, "PLAYER VISUALS", 4)
	mkToggle(ep, "Player ESP", BBConfig.PlayerESP_Enabled, function(v) BBConfig.PlayerESP_Enabled = v end, 5)
	local ip = pages["Info"]; mkLabel(ip, "CONTROLS", 1)
	local function mkInfoRow(par, k, v, ord)
		local r = Instance.new("Frame"); r.Size = UDim2.new(1,0,0,28); r.BackgroundColor3 = C.card; r.BorderSizePixel = 0; r.LayoutOrder = ord; r.Parent = par
		Instance.new("UICorner", r).CornerRadius = UDim.new(0, 6)
		local kl = Instance.new("TextLabel"); kl.Size = UDim2.new(0.5,0,1,0); kl.Position = UDim2.new(0,14,0,0); kl.BackgroundTransparency = 1; kl.Text = k; kl.TextColor3 = C.textDim; kl.TextSize = 11; kl.Font = Enum.Font.Gotham; kl.TextXAlignment = Enum.TextXAlignment.Left; kl.Parent = r
		local vl = Instance.new("TextLabel"); vl.Size = UDim2.new(0.45,0,1,0); vl.Position = UDim2.new(0.5,0,0,0); vl.BackgroundTransparency = 1; vl.Text = v; vl.TextColor3 = C.text; vl.TextSize = 11; vl.Font = Enum.Font.GothamMedium; vl.TextXAlignment = Enum.TextXAlignment.Right; vl.Parent = r
	end
	mkInfoRow(ip, "Toggle UI", "RightCtrl", 2); mkInfoRow(ip, "Manual Parry", "F / Left Click", 3); mkInfoRow(ip, "Ability", "Q / Right Click", 4)
	mkDivider(ip, 5); mkLabel(ip, "TIMING MODES", 6)
	mkInfoRow(ip, "Safe (25 studs)", "Early, reliable", 7); mkInfoRow(ip, "Normal (35 studs)", "Balanced", 8); mkInfoRow(ip, "Risky (50 studs)", "Late, may miss", 9)
	switchTab("Parry")
	task.spawn(function()
		while task.wait(0.15) do
			pcall(function()
				pcV.Text = tostring(BBConfig.ParryCount)
				local ball = getActiveBall()
				if ball then
					bsDist.Text = "Dist: " .. currentBallDist; bsSpd.Text = "Speed: " .. currentBallSpeed
					if ballTargetingMe then
						bsTtl.Text = "TARGETING YOU"; bsTtl.TextColor3 = C.red; bsDt.BackgroundColor3 = C.red; bsSts.Text = "DEFLECT!"; bsSts.TextColor3 = C.red; bsStr.Color = C.red
						sDot.BackgroundColor3 = C.red; sTxt.Text = "Danger"; sTxt.TextColor3 = C.red
					else
						bsTtl.Text = "Ball Active"; bsTtl.TextColor3 = C.warning; bsDt.BackgroundColor3 = C.warning; bsSts.Text = "Safe"; bsSts.TextColor3 = C.safe; bsStr.Color = C.divider
						sDot.BackgroundColor3 = C.warning; sTxt.Text = "Active"; sTxt.TextColor3 = C.warning
					end
				else
					bsTtl.Text = "No Ball Active"; bsTtl.TextColor3 = C.textDim; bsDt.BackgroundColor3 = C.textMuted; bsStr.Color = C.divider
					bsDist.Text = "Dist: —"; bsSpd.Text = "Speed: —"; bsSts.Text = "—"; bsSts.TextColor3 = C.textMuted
					sDot.BackgroundColor3 = C.safe; sTxt.Text = "Ready"; sTxt.TextColor3 = C.safe
				end
			end)
		end
	end)
	return sg
end
local gui = buildUI()
RunService.RenderStepped:Connect(function()
	pcall(autoParry); pcall(updateBallESP); pcall(updatePlayerESP)
end)
Players.PlayerRemoving:Connect(function(p)
	if PlayerESPCache[p] then pcall(function() PlayerESPCache[p].Box:Remove(); PlayerESPCache[p].Name:Remove() end); PlayerESPCache[p] = nil end
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
			TweenService:Create(mf, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0,480,0,380), Position = UDim2.new(0.5,-240,0.5,-190)}):Play()
		end
	end
end)
print("[TeekHub] Blade Ball v2 loaded")
