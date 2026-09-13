--[[
    RH2 mobile shot diagnostic - runs on the PHONE

    The question: when you press the game's own SHOOT button, what does the
    game poll to decide you let go? If it calls a method, we can hook it and
    you keep using the real button - which is exactly what Dahi asked for. If
    it only reads a local variable, we cannot, and synthetic touch is the only
    route.

    Reading the source would answer it too, but decompiling RH2's Gameplay
    handler wedges the client every time - it is ~28,000 lines. Measuring the
    calls live costs nothing and is the same answer from the other side.

    Run this, then press the GAME's shoot button (the green one) and take one
    normal shot. Screenshot the panel.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer

if getgenv().TeekShotStop then pcall(getgenv().TeekShotStop) end

local CONNS = {}
local function track(c) CONNS[#CONNS + 1] = c return c end
local t0 = os.clock()

-- ---------------------------------------------------------------- panel
local sg = Instance.new("ScreenGui")
sg.Name = "TeekShotDiag"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.DisplayOrder = 2000000
pcall(function() sg.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not sg.Parent then sg.Parent = lp:WaitForChild("PlayerGui") end

local f = Instance.new("Frame")
f.Size = UDim2.new(1, -20, 0, 320)
f.Position = UDim2.fromOffset(10, 10)
f.BackgroundColor3 = Color3.fromRGB(6, 5, 10)
f.BackgroundTransparency = 0.1
f.BorderSizePixel = 0
f.Parent = sg

local body = Instance.new("TextLabel")
body.Size = UDim2.new(1, -12, 1, -10)
body.Position = UDim2.fromOffset(6, 5)
body.BackgroundTransparency = 1
body.Font = Enum.Font.Code
body.TextSize = 16
body.TextColor3 = Color3.fromRGB(240, 240, 245)
body.TextXAlignment = Enum.TextXAlignment.Left
body.TextYAlignment = Enum.TextYAlignment.Top
body.TextWrapped = true
body.Text = ""
body.Parent = f

local lines = {}
local function log(fmt, ...)
    local ok, m = pcall(string.format, fmt, ...)
    lines[#lines + 1] = string.format("%5.1f %s", os.clock() - t0, ok and m or tostring(fmt))
    while #lines > 15 do table.remove(lines, 1) end
    body.Text = table.concat(lines, "\n")
end

-- ---------------------------------------------------------------- the button
local function shootBtn()
    local pg = lp:FindFirstChild("PlayerGui")
    local tg = pg and pg:FindFirstChild("TouchGui")
    local fr = tg and tg:FindFirstChild("TouchControlFrame")
    return fr and fr:FindFirstChild("ShootBTN") or nil
end

local sb = shootBtn()
log("ShootBTN found: %s", tostring(sb ~= nil))
if sb then
    local hit = sb:FindFirstChild("ButtonDetect") or sb
    local p, z = hit.AbsolutePosition, hit.AbsoluteSize
    local inset = Vector2.new(0, 0)
    pcall(function() inset = game:GetService("GuiService"):GetGuiInset() end)
    local tg = lp.PlayerGui:FindFirstChild("TouchGui")
    log("btn abs=%d,%d size=%dx%d", p.X, p.Y, z.X, z.Y)
    log("inset=%d,%d  TouchGui.IgnoreGuiInset=%s",
        inset.X, inset.Y, tostring(tg and tg.IgnoreGuiInset))
    log("so raw screen centre is %d,%d OR %d,%d",
        p.X + z.X / 2, p.Y + z.Y / 2,
        p.X + z.X / 2 + inset.X, p.Y + z.Y / 2 + inset.Y)
end

-- ---------------------------------------------------------------- counting
-- Records only. The shot behaves exactly as it normally would.
local counts = {}
local oldNC
local ok = pcall(function()
    oldNC = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        if self == UIS then
            local m = getnamecallmethod()
            counts[m] = (counts[m] or 0) + 1
        end
        return oldNC(self, ...)
    end))
end)
log("namecall counter: %s", tostring(ok and oldNC ~= nil))

-- ---------------------------------------------------------------- the shot
task.spawn(function()
    local bp = lp:WaitForChild("Backpack", 15)
    local av = bp and bp:WaitForChild("ActionValues", 15)
    local power = av and av:FindFirstChild("Power")
    if not power then log("no Power value") return end

    local live, peak, snapshot = false, 0, nil
    while sg.Parent do
        local v = power.Value
        if v > 0 and not live then
            live, peak = true, v
            snapshot = {}
            for k, n in pairs(counts) do snapshot[k] = n end
            log("--- SHOT START ---")
        elseif v > 0 then
            if v > peak then peak = v end
        elseif live then
            live = false
            log("--- SHOT END, released at %.1f ---", peak)
            -- What the game asked UserInputService during the shot. Anything
            -- with a meaningful count is something we could hook.
            local any = false
            for k, n in pairs(counts) do
                local before = snapshot[k] or 0
                if n - before > 0 then
                    any = true
                    log("   %s x%d", k, n - before)
                end
            end
            if not any then
                log("   NOTHING polled - release is a local, not a call")
            end
            peak = 0
        end
        RunService.Heartbeat:Wait()
    end
end)

getgenv().TeekShotStop = function()
    for _, c in ipairs(CONNS) do pcall(function() c:Disconnect() end) end
    if oldNC then pcall(function() hookmetamethod(game, "__namecall", oldNC) end) end
    pcall(function() sg:Destroy() end)
    getgenv().TeekShotStop = nil
end

log("armed - press the GAME's shoot button, take one shot")
