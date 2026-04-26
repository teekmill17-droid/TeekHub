local VALID_KEYS = ... or {}
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local result = nil
local done = false
local sg = Instance.new("ScreenGui")
sg.Name = "TeekHubKey"; sg.ResetOnSpawn = false; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() sg.Parent = game:GetService("CoreGui") end)
if not sg.Parent then sg.Parent = LocalPlayer:WaitForChild("PlayerGui") end
local bg = Instance.new("Frame")
bg.Size = UDim2.new(1,0,1,0); bg.BackgroundColor3 = Color3.fromRGB(0,0,0)
bg.BackgroundTransparency = 1; bg.BorderSizePixel = 0; bg.Parent = sg
TweenService:Create(bg, TweenInfo.new(0.5), {BackgroundTransparency = 0.35}):Play()
local C = {
	bg1 = Color3.fromRGB(10, 10, 18), bg2 = Color3.fromRGB(16, 16, 28), bg3 = Color3.fromRGB(22, 22, 36),
	card = Color3.fromRGB(28, 28, 46), accent = Color3.fromRGB(127, 90, 240), accentDim = Color3.fromRGB(90, 65, 180),
	green = Color3.fromRGB(45, 200, 95), red = Color3.fromRGB(220, 55, 65),
	text = Color3.fromRGB(235, 235, 242), textDim = Color3.fromRGB(120, 120, 150), textMuted = Color3.fromRGB(80, 80, 105),
	bolt = Color3.fromRGB(160, 120, 255), boltGlow = Color3.fromRGB(200, 170, 255),
	discord = Color3.fromRGB(88, 101, 242),
}
local TF = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local function tw(o, p, i) TweenService:Create(o, i or TF, p):Play() end
local card = Instance.new("Frame")
card.Size = UDim2.new(0, 440, 0, 0); card.Position = UDim2.new(0.5, -220, 0.5, 0)
card.BackgroundColor3 = C.bg1; card.BorderSizePixel = 0; card.ClipsDescendants = true; card.Parent = sg
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
local cardStroke = Instance.new("UIStroke")
cardStroke.Color = C.accent; cardStroke.Thickness = 1.5; cardStroke.Transparency = 0.4; cardStroke.Parent = card
TweenService:Create(card, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
	Size = UDim2.new(0, 440, 0, 420),
	Position = UDim2.new(0.5, -220, 0.5, -210)
}):Play()
local boltContainer = Instance.new("Frame")
boltContainer.Size = UDim2.new(1,0,1,0); boltContainer.BackgroundTransparency = 1
boltContainer.ClipsDescendants = true; boltContainer.Parent = card
local function createBolt(startX, startY, height, delay)
	local segments = math.random(6, 10)
	local segH = height / segments
	local x = startX
	task.delay(delay, function()
		local bolts = {}
		for s = 1, segments do
			local nextX = x + math.random(-25, 25)
			local seg = Instance.new("Frame")
			seg.Size = UDim2.new(0, 0, 0, 2)
			seg.Position = UDim2.new(0, math.min(x, nextX), 0, startY + (s-1) * segH)
			seg.BackgroundColor3 = C.bolt; seg.BorderSizePixel = 0
			seg.BackgroundTransparency = 0.3; seg.Parent = boltContainer
			local width = math.abs(nextX - x) + 2
			local rot = math.deg(math.atan2(segH, nextX - x))
			seg.Rotation = rot
			table.insert(bolts, seg)
			TweenService:Create(seg, TweenInfo.new(0.08, Enum.EasingStyle.Linear), {
				Size = UDim2.new(0, width, 0, math.random(1, 3)),
				BackgroundTransparency = 0
			}):Play()
			x = nextX
		end
		local glow = Instance.new("Frame")
		glow.Size = UDim2.new(0, 60, 0, height + 20)
		glow.Position = UDim2.new(0, startX - 30, 0, startY - 10)
		glow.BackgroundColor3 = C.boltGlow; glow.BackgroundTransparency = 0.85
		glow.BorderSizePixel = 0; glow.Parent = boltContainer
		Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 30)
		TweenService:Create(glow, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
		task.delay(0.15, function()
			for _, seg in bolts do
				TweenService:Create(seg, TweenInfo.new(0.2), {BackgroundTransparency = 0.7, Size = UDim2.new(0, 0, 0, 1)}):Play()
			end
		end)
		task.delay(0.4, function()
			for _, seg in bolts do pcall(function() seg:Destroy() end) end
			pcall(function() glow:Destroy() end)
		end)
	end)
end
task.spawn(function()
	while not done do
		createBolt(math.random(20, 420), 0, math.random(80, 200), 0)
		createBolt(math.random(20, 420), math.random(200, 350), math.random(50, 100), math.random() * 0.3)
		task.wait(math.random(8, 18) / 10)
	end
end)
local topGlow = Instance.new("Frame")
topGlow.Size = UDim2.new(1, 0, 0, 120); topGlow.BackgroundColor3 = C.accent
topGlow.BackgroundTransparency = 0.88; topGlow.BorderSizePixel = 0; topGlow.Parent = card
Instance.new("UICorner", topGlow).CornerRadius = UDim.new(0, 14)
local topGradient = Instance.new("UIGradient")
topGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.4, 0.5),
	NumberSequenceKeypoint.new(1, 1)
})
topGradient.Rotation = 90; topGradient.Parent = topGlow
local iconBg = Instance.new("Frame")
iconBg.Size = UDim2.new(0, 64, 0, 64); iconBg.Position = UDim2.new(0.5, -32, 0, 28)
iconBg.BackgroundColor3 = C.accent; iconBg.BorderSizePixel = 0; iconBg.Parent = card
Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 16)
local iconStroke = Instance.new("UIStroke"); iconStroke.Color = C.boltGlow; iconStroke.Thickness = 2; iconStroke.Transparency = 0.5; iconStroke.Parent = iconBg
local iconTxt = Instance.new("TextLabel")
iconTxt.Size = UDim2.new(1,0,1,0); iconTxt.BackgroundTransparency = 1
iconTxt.Text = "⚡"; iconTxt.TextSize = 30; iconTxt.Font = Enum.Font.GothamBold
iconTxt.TextColor3 = C.text; iconTxt.Parent = iconBg
task.spawn(function()
	while not done do
		TweenService:Create(iconBg, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			BackgroundColor3 = C.accentDim
		}):Play()
		TweenService:Create(iconStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Transparency = 0.2
		}):Play()
		task.wait(1.5)
		TweenService:Create(iconBg, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			BackgroundColor3 = C.accent
		}):Play()
		TweenService:Create(iconStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Transparency = 0.5
		}):Play()
		task.wait(1.5)
	end
end)
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,24); title.Position = UDim2.new(0,0,0,100)
title.BackgroundTransparency = 1; title.Text = "TeekHub"
title.TextColor3 = C.text; title.TextSize = 22; title.Font = Enum.Font.GothamBold; title.Parent = card
local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1,0,0,16); subtitle.Position = UDim2.new(0,0,0,126)
subtitle.BackgroundTransparency = 1; subtitle.Text = "Enter your key to unlock"
subtitle.TextColor3 = C.textDim; subtitle.TextSize = 13; subtitle.Font = Enum.Font.Gotham; subtitle.Parent = card
local divider1 = Instance.new("Frame")
divider1.Size = UDim2.new(0.7,0,0,1); divider1.Position = UDim2.new(0.15,0,0,152)
divider1.BackgroundColor3 = C.accent; divider1.BackgroundTransparency = 0.7
divider1.BorderSizePixel = 0; divider1.Parent = card
local inputLabel = Instance.new("TextLabel")
inputLabel.Size = UDim2.new(1,-60,0,14); inputLabel.Position = UDim2.new(0,30,0,164)
inputLabel.BackgroundTransparency = 1; inputLabel.Text = "KEY"; inputLabel.TextColor3 = C.textMuted
inputLabel.TextSize = 10; inputLabel.Font = Enum.Font.GothamBold
inputLabel.TextXAlignment = Enum.TextXAlignment.Left; inputLabel.Parent = card
local inputFrame = Instance.new("Frame")
inputFrame.Size = UDim2.new(1,-60,0,44); inputFrame.Position = UDim2.new(0,30,0,180)
inputFrame.BackgroundColor3 = C.bg3; inputFrame.BorderSizePixel = 0; inputFrame.Parent = card
Instance.new("UICorner", inputFrame).CornerRadius = UDim.new(0, 10)
local inputStroke = Instance.new("UIStroke")
inputStroke.Color = C.accent; inputStroke.Thickness = 1; inputStroke.Transparency = 0.7; inputStroke.Parent = inputFrame
local inputIcon = Instance.new("TextLabel")
inputIcon.Size = UDim2.new(0,30,0,44); inputIcon.Position = UDim2.new(0,8,0,0)
inputIcon.BackgroundTransparency = 1; inputIcon.Text = "🔑"; inputIcon.TextSize = 16; inputIcon.Parent = inputFrame
local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(1,-50,1,0); inputBox.Position = UDim2.new(0,42,0,0)
inputBox.BackgroundTransparency = 1; inputBox.Text = ""; inputBox.PlaceholderText = "TEEK-XXXX-XXXX"
inputBox.PlaceholderColor3 = C.textMuted; inputBox.TextColor3 = C.text
inputBox.TextSize = 15; inputBox.Font = Enum.Font.GothamMedium
inputBox.ClearTextOnFocus = false; inputBox.Parent = inputFrame
inputBox.Focused:Connect(function()
	tw(inputStroke, {Transparency = 0, Color = C.accent})
	tw(inputFrame, {BackgroundColor3 = Color3.fromRGB(28, 28, 44)})
end)
inputBox.FocusLost:Connect(function(enter)
	tw(inputStroke, {Transparency = 0.7})
	tw(inputFrame, {BackgroundColor3 = C.bg3})
end)
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1,-60,0,18); statusLabel.Position = UDim2.new(0,30,0,230)
statusLabel.BackgroundTransparency = 1; statusLabel.Text = ""
statusLabel.TextColor3 = C.red; statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.GothamMedium; statusLabel.Parent = card
local submitBtn = Instance.new("TextButton")
submitBtn.Size = UDim2.new(1,-60,0,42); submitBtn.Position = UDim2.new(0,30,0,254)
submitBtn.BackgroundColor3 = C.accent; submitBtn.Text = "Verify Key"
submitBtn.TextColor3 = C.text; submitBtn.TextSize = 15; submitBtn.Font = Enum.Font.GothamBold
submitBtn.BorderSizePixel = 0; submitBtn.AutoButtonColor = false; submitBtn.Parent = card
Instance.new("UICorner", submitBtn).CornerRadius = UDim.new(0, 10)
submitBtn.MouseEnter:Connect(function()
	tw(submitBtn, {BackgroundColor3 = Color3.fromRGB(145, 110, 255)})
end)
submitBtn.MouseLeave:Connect(function()
	tw(submitBtn, {BackgroundColor3 = C.accent})
end)
local divider2 = Instance.new("Frame")
divider2.Size = UDim2.new(0.7,0,0,1); divider2.Position = UDim2.new(0.15,0,0,310)
divider2.BackgroundColor3 = C.accent; divider2.BackgroundTransparency = 0.7
divider2.BorderSizePixel = 0; divider2.Parent = card
local btnRow = Instance.new("Frame")
btnRow.Size = UDim2.new(1,-60,0,38); btnRow.Position = UDim2.new(0,30,0,322)
btnRow.BackgroundTransparency = 1; btnRow.Parent = card
local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.Padding = UDim.new(0, 8); btnLayout.SortOrder = Enum.SortOrder.LayoutOrder; btnLayout.Parent = btnRow
local getKeyBtn = Instance.new("TextButton")
getKeyBtn.Size = UDim2.new(0.48,0,1,0); getKeyBtn.BackgroundColor3 = C.bg3
getKeyBtn.Text = "🔓  Get Free Key"; getKeyBtn.TextColor3 = C.textDim
getKeyBtn.TextSize = 12; getKeyBtn.Font = Enum.Font.GothamMedium
getKeyBtn.BorderSizePixel = 0; getKeyBtn.LayoutOrder = 1; getKeyBtn.AutoButtonColor = false; getKeyBtn.Parent = btnRow
Instance.new("UICorner", getKeyBtn).CornerRadius = UDim.new(0, 8)
local getKeyStroke = Instance.new("UIStroke"); getKeyStroke.Color = C.accent; getKeyStroke.Thickness = 1; getKeyStroke.Transparency = 0.7; getKeyStroke.Parent = getKeyBtn
getKeyBtn.MouseEnter:Connect(function() tw(getKeyBtn, {BackgroundColor3 = C.card}); tw(getKeyStroke, {Transparency = 0.3}) end)
getKeyBtn.MouseLeave:Connect(function() tw(getKeyBtn, {BackgroundColor3 = C.bg3}); tw(getKeyStroke, {Transparency = 0.7}) end)
local discordBtn = Instance.new("TextButton")
discordBtn.Size = UDim2.new(0.48,0,1,0); discordBtn.BackgroundColor3 = C.discord
discordBtn.Text = "💬  Discord"; discordBtn.TextColor3 = C.text
discordBtn.TextSize = 12; discordBtn.Font = Enum.Font.GothamBold
discordBtn.BorderSizePixel = 0; discordBtn.LayoutOrder = 2; discordBtn.AutoButtonColor = false; discordBtn.Parent = btnRow
Instance.new("UICorner", discordBtn).CornerRadius = UDim.new(0, 8)
discordBtn.MouseEnter:Connect(function() tw(discordBtn, {BackgroundColor3 = Color3.fromRGB(100, 115, 255)}) end)
discordBtn.MouseLeave:Connect(function() tw(discordBtn, {BackgroundColor3 = C.discord}) end)
discordBtn.MouseButton1Click:Connect(function()
	pcall(function()
		setclipboard("https://discord.gg/frs46JaP")
	end)
	local orig = discordBtn.Text
	discordBtn.Text = "✔ Copied!"
	tw(discordBtn, {BackgroundColor3 = C.green})
	task.delay(1.5, function()
		discordBtn.Text = orig
		tw(discordBtn, {BackgroundColor3 = C.discord})
	end)
end)
local footerTxt = Instance.new("TextLabel")
footerTxt.Size = UDim2.new(1,0,0,14); footerTxt.Position = UDim2.new(0,0,0,374)
footerTxt.BackgroundTransparency = 1; footerTxt.Text = "TeekHub v4  •  @Teek  •  Free & Open"
footerTxt.TextColor3 = C.textMuted; footerTxt.TextSize = 10
footerTxt.Font = Enum.Font.Gotham; footerTxt.Parent = card
local versionDot = Instance.new("Frame")
versionDot.Size = UDim2.new(0, 6, 0, 6); versionDot.Position = UDim2.new(0, 30, 0, 396)
versionDot.BackgroundColor3 = C.green; versionDot.BorderSizePixel = 0; versionDot.Parent = card
Instance.new("UICorner", versionDot).CornerRadius = UDim.new(1, 0)
local versionTxt = Instance.new("TextLabel")
versionTxt.Size = UDim2.new(0, 200, 0, 12); versionTxt.Position = UDim2.new(0, 42, 0, 393)
versionTxt.BackgroundTransparency = 1; versionTxt.Text = "System online  •  All services operational"
versionTxt.TextColor3 = C.green; versionTxt.TextSize = 9
versionTxt.Font = Enum.Font.Gotham; versionTxt.TextXAlignment = Enum.TextXAlignment.Left; versionTxt.Parent = card
task.spawn(function()
	while not done do
		tw(versionDot, {BackgroundTransparency = 0.6}, TweenInfo.new(0.8))
		task.wait(0.8)
		tw(versionDot, {BackgroundTransparency = 0}, TweenInfo.new(0.8))
		task.wait(0.8)
	end
end)
local function shake(obj)
	local orig = obj.Position
	for i = 1, 3 do
		tw(obj, {Position = orig + UDim2.new(0, 8, 0, 0)}, TweenInfo.new(0.04))
		task.wait(0.04)
		tw(obj, {Position = orig + UDim2.new(0, -8, 0, 0)}, TweenInfo.new(0.04))
		task.wait(0.04)
	end
	tw(obj, {Position = orig}, TweenInfo.new(0.04))
end
local function flashBorder(color)
	tw(cardStroke, {Color = color, Transparency = 0}, TweenInfo.new(0.1))
	task.delay(0.8, function()
		tw(cardStroke, {Color = C.accent, Transparency = 0.4}, TweenInfo.new(0.3))
	end)
end
local function trySubmit()
	local key = inputBox.Text:gsub("%s+", "")
	if key == "" then
		statusLabel.Text = "Please enter a key"
		statusLabel.TextColor3 = C.textDim
		shake(inputFrame)
		return
	end
	if VALID_KEYS[key] then
		statusLabel.Text = "✔  Key verified — loading TeekHub..."
		statusLabel.TextColor3 = C.green
		flashBorder(C.green)
		tw(submitBtn, {BackgroundColor3 = C.green})
		submitBtn.Text = "✔  Verified!"
		for i = 1, 5 do
			createBolt(math.random(20, 420), 0, 420, i * 0.05)
		end
		task.wait(0.8)
		tw(card, {Size = UDim2.new(0, 440, 0, 0), Position = UDim2.new(0.5, -220, 0.5, 0)}, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In))
		tw(bg, {BackgroundTransparency = 1}, TweenInfo.new(0.4))
		task.wait(0.5)
		sg:Destroy()
		result = key
		done = true
	else
		statusLabel.Text = "✘  Invalid key — try again"
		statusLabel.TextColor3 = C.red
		flashBorder(C.red)
		shake(inputFrame)
		tw(inputStroke, {Color = C.red}, TweenInfo.new(0.1))
		task.delay(1, function()
			tw(inputStroke, {Color = C.accent}, TweenInfo.new(0.3))
		end)
	end
end
submitBtn.MouseButton1Click:Connect(trySubmit)
inputBox.FocusLost:Connect(function(enter)
	tw(inputStroke, {Transparency = 0.7})
	tw(inputFrame, {BackgroundColor3 = C.bg3})
	if enter then trySubmit() end
end)
getKeyBtn.MouseButton1Click:Connect(function()
	statusLabel.Text = "⚡  Key: TEEK-FREE-2026"
	statusLabel.TextColor3 = C.accent
	flashBorder(C.accent)
	pcall(function() setclipboard("TEEK-FREE-2026") end)
	local orig = getKeyBtn.Text
	getKeyBtn.Text = "✔  Copied to clipboard!"
	tw(getKeyBtn, {BackgroundColor3 = C.green})
	task.delay(2, function()
		getKeyBtn.Text = orig
		tw(getKeyBtn, {BackgroundColor3 = C.bg3})
	end)
end)
while not done do task.wait(0.1) end
return result
