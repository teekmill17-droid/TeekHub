local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local FConfig = {
	AutoFish_Enabled = false,
	AutoShake_Enabled = false,
	AutoSell_Enabled = false,
	AutoSell_Type = "All",
	FishESP_Enabled = false,
	AutoCast_Delay = 1.5,
}
local Net = RS:FindFirstChild("packages") and RS.packages:FindFirstChild("Net")
local Events = RS:FindFirstChild("events")
local SharedMods = RS:FindFirstChild("shared")
local CastRF = Net and Net:FindFirstChild("RF/FishingRod/Cast")
local ReelStartRF = Net and Net:FindFirstChild("RF/Reel/Start")
local ReelFinishRE = Net and Net:FindFirstChild("RE/Reel/Finish")
local ReelAbortRE = Net and Net:FindFirstChild("RE/Reel/Abort")
local ShakeStartRF = Net and Net:FindFirstChild("RF/LureShake/Start")
local ShakeRE = Net and Net:FindFirstChild("RE/LureShake/Shake")
local ShakeStopRE = Net and Net:FindFirstChild("RE/LureShake/Stop")
local BobberHandleRE = Net and Net:FindFirstChild("RE/FishingRod/HandleBobber")
local ResetRE = Net and Net:FindFirstChild("RE/FishingRod/Reset")
local SellEverything = Events and Events:FindFirstChild("selleverything")
local SellAll = Events and Events:FindFirstChild("SellAll")
local Sell = Events and Events:FindFirstChild("Sell")
local RodCast = Events and Events:FindFirstChild("rod_cast")
local CatchFinish = SharedMods and SharedMods:FindFirstChild("modules")
	and SharedMods.modules:FindFirstChild("fishing")
	and SharedMods.modules.fishing:FindFirstChild("rodresources")
	and SharedMods.modules.fishing.rodresources:FindFirstChild("events")
	and SharedMods.modules.fishing.rodresources.events:FindFirstChild("catchfinish")
local SPOTS = {
	{name = "Moosewood", pos = CFrame.new(390, 140, 200)},
	{name = "Roslit Bay", pos = CFrame.new(-1565, 140, 600)},
	{name = "Snowcap", pos = CFrame.new(2850, 180, 2700)},
	{name = "Sunstone", pos = CFrame.new(-930, 225, -990)},
	{name = "Mushgrove", pos = CFrame.new(2790, 140, -630)},
	{name = "Vertigo Whirlpool", pos = CFrame.new(0, 135, 0)},
	{name = "Statue of Sovereignty", pos = CFrame.new(1375, 140, -300)},
}
local function getMyRoot()
	local char = LocalPlayer.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end
local function teleportTo(cf)
	local root = getMyRoot()
	if root then root.CFrame = cf end
end
local function doSell()
	if not FConfig.AutoSell_Enabled then return end
	pcall(function()
		if SellEverything then SellEverything:InvokeServer() end
		if SellAll then SellAll:InvokeServer() end
	end)
end
local sellCooldown = 0
local function autoSellLoop()
	if not FConfig.AutoSell_Enabled then return end
	if tick() - sellCooldown < 30 then return end
	sellCooldown = tick()
	pcall(function() doSell() end)
end
local fishCooldown = 0
local function autoFish()
	if not FConfig.AutoFish_Enabled then return end
	if tick() - fishCooldown < FConfig.AutoCast_Delay then return end
	fishCooldown = tick()
	pcall(function()
		if CastRF then CastRF:InvokeServer() end
	end)
	task.delay(0.5, function()
		pcall(function()
			if ReelFinishRE then ReelFinishRE:FireServer() end
		end)
	end)
end
local shakeCooldown = 0
local function autoShake()
	if not FConfig.AutoShake_Enabled then return end
	if tick() - shakeCooldown < 0.3 then return end
	shakeCooldown = tick()
	pcall(function()
		if ShakeRE then ShakeRE:FireServer() end
	end)
end
local DrawingSupported = pcall(function() local t = Drawing.new("Line"); t:Remove() end)
local function buildUI()
	local sg = Instance.new("ScreenGui")
	sg.Name = "TeekHubFisch"; sg.ResetOnSpawn = false; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	pcall(function() sg.Parent = game:GetService("CoreGui") end)
	if not sg.Parent then sg.Parent = LocalPlayer:WaitForChild("PlayerGui") end
	local C = {
		bg1 = Color3.fromRGB(13, 13, 22), bg2 = Color3.fromRGB(18, 18, 30), bg3 = Color3.fromRGB(23, 23, 38),
		card = Color3.fromRGB(28, 28, 46), cardHover = Color3.fromRGB(35, 35, 56),
		accent = Color3.fromRGB(30, 140, 200), accentDim = Color3.fromRGB(20, 100, 160),
		green = Color3.fromRGB(45, 200, 95), red = Color3.fromRGB(220, 55, 65), redDim = Color3.fromRGB(50, 40, 55),
		text = Color3.fromRGB(235, 235, 242), textDim = Color3.fromRGB(120, 120, 150), textMuted = Color3.fromRGB(80, 80, 105),
		divider = Color3.fromRGB(40, 40, 60), warning = Color3.fromRGB(255, 180, 40),
	}
	local WW, WH, SW, TH = 500, 400, 135, 42
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
	local icoT = Instance.new("TextLabel"); icoT.Size = UDim2.new(1,0,1,0); icoT.BackgroundTransparency = 1; icoT.Text = "🐟"; icoT.TextColor3 = C.text; icoT.TextSize = 14; icoT.Font = Enum.Font.GothamBold; icoT.Parent = ico
	local ttl = Instance.new("TextLabel"); ttl.Size = UDim2.new(0,120,0,16); ttl.Position = UDim2.new(0,44,0,5); ttl.BackgroundTransparency = 1; ttl.Text = "TeekHub"; ttl.TextColor3 = C.text; ttl.TextSize = 14; ttl.Font = Enum.Font.GothamBold; ttl.TextXAlignment = Enum.TextXAlignment.Left; ttl.Parent = top
	local subt = Instance.new("TextLabel"); subt.Size = UDim2.new(0,120,0,13); subt.Position = UDim2.new(0,44,0,22); subt.BackgroundTransparency = 1; subt.Text = "Fisch"; subt.TextColor3 = C.textDim; subt.TextSize = 11; subt.Font = Enum.Font.Gotham; subt.TextXAlignment = Enum.TextXAlignment.Left; subt.Parent = top
	local function mkWinBtn(txt, col, pos, cb)
		local b = Instance.new("TextButton"); b.Size = UDim2.new(0,24,0,24); b.Position = pos; b.BackgroundColor3 = col; b.BackgroundTransparency = 0.85
		b.Text = txt; b.TextColor3 = C.textDim; b.TextSize = 12; b.Font = Enum.Font.GothamBold; b.BorderSizePixel = 0; b.AutoButtonColor = false; b.Parent = top
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
		b.MouseEnter:Connect(function() tw(b, {BackgroundTransparency = 0.3, TextColor3 = C.text}, TF) end)
		b.MouseLeave:Connect(function() tw(b, {BackgroundTransparency = 0.85, TextColor3 = C.textDim}, TF) end)
		b.MouseButton1Click:Connect(cb)
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
	local navC = Instance.new("Frame"); navC.Size = UDim2.new(1,-14,1,-20); navC.Position = UDim2.new(0,7,0,14); navC.BackgroundTransparency = 1; navC.Parent = sidebar
	local nl = Instance.new("UIListLayout"); nl.Padding = UDim.new(0,2); nl.SortOrder = Enum.SortOrder.LayoutOrder; nl.Parent = navC
	local content = Instance.new("Frame"); content.Size = UDim2.new(1,-(SW+14),1,-(TH+10)); content.Position = UDim2.new(0,SW+7,0,TH+5)
	content.BackgroundTransparency = 1; content.ClipsDescendants = true; content.Parent = main
	local pages, navBtns, activeTab = {}, {}, nil
	local tabs = {
		{n="Auto Farm",i="🎣",d="Fish automation"},
		{n="Items",i="📦",d="Sell & manage"},
		{n="Teleports",i="🗺",d="Fast travel"},
		{n="Visuals",i="👁",d="ESP overlays"},
		{n="Misc",i="⚙",d="Settings"},
	}
	for _, t in tabs do
		local p = Instance.new("ScrollingFrame"); p.Size = UDim2.new(1,0,1,0); p.BackgroundTransparency = 1
		p.ScrollBarThickness = 2; p.ScrollBarImageColor3 = C.accent; p.BorderSizePixel = 0; p.Visible = false
		p.CanvasSize = UDim2.new(0,0,0,0); p.AutomaticCanvasSize = Enum.AutomaticSize.Y; p.Parent = content
		local pl = Instance.new("UIListLayout"); pl.Padding = UDim.new(0,4); pl.SortOrder = Enum.SortOrder.LayoutOrder; pl.Parent = p
		pages[t.n] = p
	end
	local function switchTab(name)
		activeTab = name
		for n, p in pages do p.Visible = (n == name); if n == name then p.CanvasPosition = Vector2.new(0,0) end end
		for n, b in navBtns do
			if n == name then tw(b.f, {BackgroundColor3 = C.accent, BackgroundTransparency = 0}, TF); tw(b.l, {TextColor3 = C.text}, TF); tw(b.s, {TextColor3 = Color3.fromRGB(180,220,240)}, TF)
			else tw(b.f, {BackgroundTransparency = 1}, TF); tw(b.l, {TextColor3 = C.textDim}, TF); tw(b.s, {TextColor3 = C.textMuted}, TF) end
		end
	end
	for i, t in tabs do
		local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1,0,0,40); btn.BackgroundTransparency = 1; btn.BackgroundColor3 = C.accent
		btn.Text = ""; btn.BorderSizePixel = 0; btn.LayoutOrder = i; btn.AutoButtonColor = false; btn.Parent = navC
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
	local function mkButton(par, txt, col, cb, ord)
		local b = Instance.new("TextButton"); b.Size = UDim2.new(1,0,0,32); b.BackgroundColor3 = col or C.accent; b.Text = txt; b.TextColor3 = C.text; b.TextSize = 12; b.Font = Enum.Font.GothamBold; b.BorderSizePixel = 0; b.LayoutOrder = ord or 0; b.AutoButtonColor = false; b.Parent = par
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
		b.MouseButton1Click:Connect(function()
			pcall(cb)
			tw(b, {BackgroundColor3 = C.green}, TF)
			task.delay(0.4, function() tw(b, {BackgroundColor3 = col or C.accent}, TF) end)
		end)
		b.MouseEnter:Connect(function() tw(b, {BackgroundColor3 = Color3.new(math.min(col.R*1.2,1), math.min(col.G*1.2,1), math.min(col.B*1.2,1))}, TF) end)
		b.MouseLeave:Connect(function() tw(b, {BackgroundColor3 = col or C.accent}, TF) end)
	end
	local af = pages["Auto Farm"]
	mkLabel(af, "FISHING", 1)
	mkToggle(af, "Auto Fish", FConfig.AutoFish_Enabled, function(v) FConfig.AutoFish_Enabled = v end, 2)
	mkCycle(af, "Cast Delay", {0.5, 1, 1.5, 2, 3}, FConfig.AutoCast_Delay, function(v) FConfig.AutoCast_Delay = v end, 3)
	mkToggle(af, "Auto Shake", FConfig.AutoShake_Enabled, function(v) FConfig.AutoShake_Enabled = v end, 4)
	mkDivider(af, 5)
	mkLabel(af, "SELLING", 6)
	mkToggle(af, "Auto Sell (every 30s)", FConfig.AutoSell_Enabled, function(v) FConfig.AutoSell_Enabled = v end, 7)
	mkButton(af, "Sell All Fish Now", C.accent, function() doSell() end, 8)
	local it = pages["Items"]
	mkLabel(it, "QUICK SELL", 1)
	mkButton(it, "Sell Everything", C.accent, function()
		pcall(function() if SellEverything then SellEverything:InvokeServer() end end)
	end, 2)
	mkButton(it, "Sell All", C.accentDim, function()
		pcall(function() if SellAll then SellAll:InvokeServer() end end)
	end, 3)
	mkDivider(it, 4)
	mkLabel(it, "REMOTES FOUND", 5)
	local function mkStatus(par, name, found, ord)
		local row = Instance.new("Frame"); row.Size = UDim2.new(1,0,0,24); row.BackgroundColor3 = C.card; row.BorderSizePixel = 0; row.LayoutOrder = ord; row.Parent = par
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
		local dot = Instance.new("Frame"); dot.Size = UDim2.new(0,8,0,8); dot.Position = UDim2.new(0,10,0.5,-4); dot.BackgroundColor3 = found and C.green or C.red; dot.BorderSizePixel = 0; dot.Parent = row
		Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
		local l = Instance.new("TextLabel"); l.Size = UDim2.new(1,-30,1,0); l.Position = UDim2.new(0,24,0,0); l.BackgroundTransparency = 1; l.Text = name; l.TextColor3 = found and C.text or C.textMuted; l.TextSize = 11; l.Font = Enum.Font.Gotham; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = row
	end
	mkStatus(it, "Cast Remote", CastRF ~= nil, 6)
	mkStatus(it, "Reel Start", ReelStartRF ~= nil, 7)
	mkStatus(it, "Reel Finish", ReelFinishRE ~= nil, 8)
	mkStatus(it, "Shake", ShakeRE ~= nil, 9)
	mkStatus(it, "Sell Everything", SellEverything ~= nil, 10)
	mkStatus(it, "Sell All", SellAll ~= nil, 11)
	mkStatus(it, "Catch Finish", CatchFinish ~= nil, 12)
	local tp = pages["Teleports"]
	mkLabel(tp, "FISHING SPOTS", 1)
	for i, spot in SPOTS do
		mkButton(tp, "📍  " .. spot.name, C.card, function()
			teleportTo(spot.pos)
		end, i + 1)
	end
	local vis = pages["Visuals"]
	mkLabel(vis, "ESP", 1)
	mkToggle(vis, "Fish ESP (coming soon)", false, function() end, 2)
	local misc = pages["Misc"]
	mkLabel(misc, "CONTROLS", 1)
	local function mkInfoRow(par, k, v, ord)
		local r = Instance.new("Frame"); r.Size = UDim2.new(1,0,0,28); r.BackgroundColor3 = C.card; r.BorderSizePixel = 0; r.LayoutOrder = ord; r.Parent = par
		Instance.new("UICorner", r).CornerRadius = UDim.new(0, 6)
		local kl = Instance.new("TextLabel"); kl.Size = UDim2.new(0.5,0,1,0); kl.Position = UDim2.new(0,14,0,0); kl.BackgroundTransparency = 1; kl.Text = k; kl.TextColor3 = C.textDim; kl.TextSize = 11; kl.Font = Enum.Font.Gotham; kl.TextXAlignment = Enum.TextXAlignment.Left; kl.Parent = r
		local vl = Instance.new("TextLabel"); vl.Size = UDim2.new(0.45,0,1,0); vl.Position = UDim2.new(0.5,0,0,0); vl.BackgroundTransparency = 1; vl.Text = v; vl.TextColor3 = C.text; vl.TextSize = 11; vl.Font = Enum.Font.GothamMedium; vl.TextXAlignment = Enum.TextXAlignment.Right; vl.Parent = r
	end
	mkInfoRow(misc, "Toggle UI", "RightCtrl", 2)
	mkInfoRow(misc, "Cast Rod", "Hold Click", 3)
	mkInfoRow(misc, "Equip Rod", "1 Key", 4)
	mkDivider(misc, 5)
	mkLabel(misc, "STATUS", 6)
	mkInfoRow(misc, "Remotes found", tostring((CastRF and 1 or 0) + (ReelFinishRE and 1 or 0) + (SellEverything and 1 or 0) + (ShakeRE and 1 or 0)) .. "/4", 7)
	mkInfoRow(misc, "Game", "Fisch", 8)
	mkInfoRow(misc, "Hub", "TeekHub v4", 9)
	switchTab("Auto Farm")
	return sg
end
local gui = buildUI()
RunService.Heartbeat:Connect(function()
	pcall(autoFish)
	pcall(autoShake)
	pcall(autoSellLoop)
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
			TweenService:Create(mf, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0,500,0,400), Position = UDim2.new(0.5,-250,0.5,-200)}):Play()
		end
	end
end)
print("[TeekHub] Fisch loaded — RightCtrl to toggle")
print("[TeekHub] Tabs: Auto Farm | Items | Teleports | Visuals | Misc")
