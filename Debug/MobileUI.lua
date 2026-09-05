--[[
    TeekHub - mobile UI disappearance diagnostic

    Reported: on mobile the script works, but right after the first green the
    UI goes and there is no way to shoot again. On a phone there is no console
    to read, so this draws its own log on screen in text big enough to
    screenshot.

    It is deliberately standalone - no UILib, no TeekOps, its own ScreenGui in
    its own parent. If the thing that dies is the hub, this has to outlive it.

    Run it BEFORE loading the hub, then load the hub and take one shot.

    Reports, with a timestamp on each line:
      + / -   a ScreenGui appeared or was destroyed, and where
      ~       one was enabled or disabled
      !       the character or PlayerGui itself was replaced
      >       shot meter opened / closed, so the log can be read against it
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

if getgenv().TeekDiagStop then pcall(getgenv().TeekDiagStop) end

local CONNS = {}
local function track(c) CONNS[#CONNS + 1] = c return c end

local t0 = os.clock()
local function stamp() return string.format("%6.2f", os.clock() - t0) end

-- ---------------------------------------------------------------- the panel
local sg = Instance.new("ScreenGui")
sg.Name = "TeekDiag"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.DisplayOrder = 2000000        -- above the hub, which is at 100000
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local parented = pcall(function()
    sg.Parent = (gethui and gethui()) or game:GetService("CoreGui")
end)
if not parented or not sg.Parent then sg.Parent = lp:WaitForChild("PlayerGui") end

local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, -20, 0, 300)
frame.Position = UDim2.fromOffset(10, 10)
frame.BackgroundColor3 = Color3.fromRGB(6, 5, 10)
frame.BackgroundTransparency = 0.12
frame.BorderSizePixel = 0
frame.Parent = sg

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -10, 0, 24)
title.Position = UDim2.fromOffset(6, 4)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(200, 166, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "TEEK DIAG - parent: " .. tostring(sg.Parent)
title.Parent = frame

local body = Instance.new("TextLabel")
body.Size = UDim2.new(1, -12, 1, -32)
body.Position = UDim2.fromOffset(6, 28)
body.BackgroundTransparency = 1
body.Font = Enum.Font.Code
body.TextSize = 15               -- readable on a phone screenshot
body.TextColor3 = Color3.fromRGB(240, 240, 245)
body.TextXAlignment = Enum.TextXAlignment.Left
body.TextYAlignment = Enum.TextYAlignment.Top
body.TextWrapped = true
body.Text = ""
body.Parent = frame

local lines = {}
local function log(fmt, ...)
    local ok, msg = pcall(string.format, fmt, ...)
    if not ok then msg = tostring(fmt) end
    lines[#lines + 1] = stamp() .. "  " .. msg
    while #lines > 14 do table.remove(lines, 1) end
    body.Text = table.concat(lines, "\n")
    print("[teekdiag] " .. msg)
end

-- ---------------------------------------------------------------- watching
-- Watch both roots. Which one the hub landed in matters: mobile executors
-- often cannot parent to CoreGui and fall back to PlayerGui, and PlayerGui is
-- the one the game itself clears.
local function watchRoot(root, label)
    if not root then return end
    track(root.ChildAdded:Connect(function(c)
        if c:IsA("ScreenGui") or c:IsA("GuiObject") then
            log("+ %s  %s", label, c.Name)
        end
    end))
    track(root.ChildRemoved:Connect(function(c)
        if c:IsA("ScreenGui") or c:IsA("GuiObject") then
            log("- %s  %s   DESTROYED", label, c.Name)
        end
    end))
    for _, c in ipairs(root:GetChildren()) do
        if c:IsA("ScreenGui") then
            track(c:GetPropertyChangedSignal("Enabled"):Connect(function()
                log("~ %s  %s enabled=%s", label, c.Name, tostring(c.Enabled))
            end))
        end
    end
end

local pg = lp:FindFirstChild("PlayerGui")
watchRoot(pg, "PlayerGui")
pcall(function() watchRoot(game:GetService("CoreGui"), "CoreGui") end)
pcall(function() if gethui then watchRoot(gethui(), "gethui") end end)

-- PlayerGui itself being replaced would take every ScreenGui with it, hub
-- included, and would look exactly like "everything vanished".
track(lp.ChildAdded:Connect(function(c)
    if c.Name == "PlayerGui" then log("! PlayerGui REPLACED") ; watchRoot(c, "PlayerGui") end
end))
track(lp.CharacterAdded:Connect(function() log("! character respawned") end))

-- Mark the shot on the same timeline, so a removal can be read against it.
task.spawn(function()
    local av = lp.Backpack:WaitForChild("ActionValues", 20)
    local power = av and av:FindFirstChild("Power")
    local peak, open = 0, false
    while sg.Parent do
        local ch = lp.Character
        local head = ch and ch:FindFirstChild("Head")
        local up = false
        if head then
            for _, c in ipairs(head:GetChildren()) do
                if c:IsA("BillboardGui") and string.find(c.Name, "Meter") and c.Enabled then
                    up = true break
                end
            end
        end
        if up and not open then open, peak = true, 0 ; log("> meter OPEN") end
        if up and power and power.Value > peak then peak = power.Value end
        if open and not up then open = false ; log("> meter CLOSED, released at %.1f", peak) end
        task.wait(0.05)
    end
end)

-- Count what is alive every second, so a slow drain shows up as well as a
-- sudden one.
task.spawn(function()
    local last = -1
    while sg.Parent do
        local g = lp:FindFirstChild("PlayerGui")
        local n = 0
        if g then for _, c in ipairs(g:GetChildren()) do if c:IsA("ScreenGui") then n += 1 end end end
        if n ~= last then log("  PlayerGui ScreenGuis: %d", n) ; last = n end
        task.wait(1)
    end
end)

-- The game's own grade for each shot. This is the half that says whether the
-- release was actually good, rather than just where it landed.
do
    local fb = lp:FindFirstChild("PlayerGui")
    fb = fb and fb:FindFirstChild("Feedback.Ui")
    fb = fb and fb:FindFirstChild("Frame")
    fb = fb and fb:FindFirstChild("Background")
    fb = fb and fb:FindFirstChild("TimingFeedBack")
    if fb then
        track(fb:GetPropertyChangedSignal("Text"):Connect(function()
            local txt = tostring(fb.Text or "")
            if txt:gsub("%s", "") ~= "" then log("* VERDICT: %s", txt) end
        end))
    else
        log("! no TimingFeedBack label - verdicts unavailable")
    end
end

-- Whether the hub drove the shot or the player tapped the game's own button.
-- Without this a manual test reads exactly like a solver result, which has
-- already cost one round of wrong conclusions.
task.spawn(function()
    local UIS = game:GetService("UserInputService")
    local was = false
    while sg.Parent do
        local down = UIS:IsKeyDown(Enum.KeyCode.E)
        if down ~= was then log("  E %s", down and "DOWN (script)" or "up") ; was = down end
        task.wait(0.03)
    end
end)

getgenv().TeekDiagStop = function()
    for _, c in ipairs(CONNS) do pcall(function() c:Disconnect() end) end
    pcall(function() sg:Destroy() end)
end

log("armed - now load the hub and take ONE shot")
log("PlayerGui found: %s", tostring(pg ~= nil))
