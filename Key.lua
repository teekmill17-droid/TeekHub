local VALID_KEYS = ... or {}
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local result = nil
local done = false
local sg = Instance.new("ScreenGui")
sg.Name = "TeekHubKey"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() sg.Parent = game:GetService("CoreGui") end)
if not sg.Parent then sg.Parent = LocalPlayer:WaitForChild("PlayerGui") end
local bg = Instance.new("Frame")
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bg.BackgroundTransparency = 0.4
bg.BorderSizePixel = 0
bg.Parent = sg
local card = Instance.new("Frame")
card.Size = UDim2.new(0, 340, 0, 220)
card.Position = UDim2.new(0.5, -170, 0.5, -110)
card.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
card.BorderSizePixel = 0
card.Parent = sg
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(110, 90, 230)
stroke.Thickness = 1.5
stroke.Transparency = 0.5
stroke.Parent = card
card.Size = UDim2.new(0, 340, 0, 0)
card.Position = UDim2.new(0.5, -170, 0.5, 0)
TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
	Size = UDim2.new(0, 340, 0, 220),
	Position = UDim2.new(0.5, -170, 0.5, -110)
}):Play()
local icon = Instance.new("TextLabel")
icon.Size = UDim2.new(0, 44, 0, 44)
icon.Position = UDim2.new(0.5, -22, 0, 16)
icon.BackgroundColor3 = Color3.fromRGB(110, 90, 230)
icon.Text = "🔑"
icon.TextSize = 22
icon.BorderSizePixel = 0
icon.Parent = card
Instance.new("UICorner", icon).CornerRadius = UDim.new(1, 0)
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 22)
title.Position = UDim2.new(0, 0, 0, 66)
title.BackgroundTransparency = 1
title.Text = "TeekHub — Key System"
title.TextColor3 = Color3.fromRGB(240, 240, 245)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.Parent = card
local sub = Instance.new("TextLabel")
sub.Size = UDim2.new(1, -40, 0, 16)
sub.Position = UDim2.new(0, 20, 0, 90)
sub.BackgroundTransparency = 1
sub.Text = "Enter your key to continue"
sub.TextColor3 = Color3.fromRGB(130, 130, 155)
sub.TextSize = 12
sub.Font = Enum.Font.Gotham
sub.Parent = card
local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(1, -40, 0, 36)
inputBox.Position = UDim2.new(0, 20, 0, 115)
inputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 48)
inputBox.Text = ""
inputBox.PlaceholderText = "TEEK-XXXX-XXXX"
inputBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 100)
inputBox.TextColor3 = Color3.fromRGB(240, 240, 245)
inputBox.TextSize = 14
inputBox.Font = Enum.Font.GothamMedium
inputBox.ClearTextOnFocus = false
inputBox.BorderSizePixel = 0
inputBox.Parent = card
Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 8)
local submitBtn = Instance.new("TextButton")
submitBtn.Size = UDim2.new(0.48, 0, 0, 32)
submitBtn.Position = UDim2.new(0.02, 20, 0, 162)
submitBtn.BackgroundColor3 = Color3.fromRGB(110, 90, 230)
submitBtn.Text = "Submit Key"
submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
submitBtn.TextSize = 13
submitBtn.Font = Enum.Font.GothamBold
submitBtn.BorderSizePixel = 0
submitBtn.Parent = card
Instance.new("UICorner", submitBtn).CornerRadius = UDim.new(0, 8)
local getKeyBtn = Instance.new("TextButton")
getKeyBtn.Size = UDim2.new(0.42, 0, 0, 32)
getKeyBtn.Position = UDim2.new(0.56, 10, 0, 162)
getKeyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
getKeyBtn.Text = "Get Key"
getKeyBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
getKeyBtn.TextSize = 13
getKeyBtn.Font = Enum.Font.GothamMedium
getKeyBtn.BorderSizePixel = 0
getKeyBtn.Parent = card
Instance.new("UICorner", getKeyBtn).CornerRadius = UDim.new(0, 8)
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 16)
statusLabel.Position = UDim2.new(0, 0, 0, 198)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.Parent = card
local function shake(obj)
	local orig = obj.Position
	for i = 1, 3 do
		TweenService:Create(obj, TweenInfo.new(0.05), {Position = orig + UDim2.new(0, 6, 0, 0)}):Play()
		task.wait(0.05)
		TweenService:Create(obj, TweenInfo.new(0.05), {Position = orig + UDim2.new(0, -6, 0, 0)}):Play()
		task.wait(0.05)
	end
	TweenService:Create(obj, TweenInfo.new(0.05), {Position = orig}):Play()
end
local function trySubmit()
	local key = inputBox.Text:gsub("%s+", "")
	if VALID_KEYS[key] then
		statusLabel.Text = "✔ Key accepted!"
		statusLabel.TextColor3 = Color3.fromRGB(50, 200, 90)
		TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 340, 0, 0),
			Position = UDim2.new(0.5, -170, 0.5, 0)
		}):Play()
		task.wait(0.35)
		sg:Destroy()
		result = key
		done = true
	else
		statusLabel.Text = "✘ Invalid key"
		statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		shake(inputBox)
	end
end
submitBtn.MouseButton1Click:Connect(trySubmit)
inputBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then trySubmit() end
end)
getKeyBtn.MouseButton1Click:Connect(function()
	statusLabel.Text = "Key: TEEK-FREE-2026"
	statusLabel.TextColor3 = Color3.fromRGB(110, 90, 230)
end)
while not done do task.wait(0.1) end
return result
