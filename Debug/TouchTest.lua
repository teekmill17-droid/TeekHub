--[[
    Does a synthetic touch drive RH2's shoot button?

    This is the last unknown for mobile, and everything else depends on it.

    Established already: the game polls nothing during a mobile shot - the
    release is a local variable, not a method call - so a hook cannot end a
    shot the player started. The only route left is for the script to own the
    press, behind an invisible button over the game's own. That needs
    SendTouchEvent to actually work on the ShootBTN.

    Measured on this phone:
        btn abs=716,223 size=64x64
        inset=0,58  IgnoreGuiInset=false
        so raw centre is 748,255 (as-is) or 748,313 (inset added)

    748,255 was tried by an earlier build and produced no meter. 748,313 has
    never been tried. This tries both, in order, and says which - if either -
    opened the meter.

    HOLD THE BALL, then press TEST. It takes about four seconds.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local lp = Players.LocalPlayer

if getgenv().TeekTouchStop then pcall(getgenv().TeekTouchStop) end

local sg = Instance.new("ScreenGui")
sg.Name = "TeekTouchTest"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.DisplayOrder = 2000000
pcall(function() sg.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not sg.Parent then sg.Parent = lp:WaitForChild("PlayerGui") end

local f = Instance.new("Frame")
f.Size = UDim2.new(1, -20, 0, 250)
f.Position = UDim2.fromOffset(10, 10)
f.BackgroundColor3 = Color3.fromRGB(6, 5, 10)
f.BackgroundTransparency = 0.08
f.BorderSizePixel = 0
f.Parent = sg

local body = Instance.new("TextLabel")
body.Size = UDim2.new(1, -12, 1, -60)
body.Position = UDim2.fromOffset(6, 5)
body.BackgroundTransparency = 1
body.Font = Enum.Font.Code
body.TextSize = 16
body.TextColor3 = Color3.fromRGB(240, 240, 245)
body.TextXAlignment = Enum.TextXAlignment.Left
body.TextYAlignment = Enum.TextYAlignment.Top
body.TextWrapped = true
body.Parent = f

local lines = {}
local function log(fmt, ...)
    local ok, m = pcall(string.format, fmt, ...)
    lines[#lines + 1] = ok and m or tostring(fmt)
    while #lines > 11 do table.remove(lines, 1) end
    body.Text = table.concat(lines, "\n")
end

local btn = Instance.new("TextButton")
btn.Size = UDim2.fromOffset(200, 48)
btn.Position = UDim2.new(0, 10, 1, -54)
btn.BackgroundColor3 = Color3.fromRGB(60, 40, 110)
btn.Text = "TEST (hold ball first)"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 15
btn.BorderSizePixel = 0
btn.Parent = f

local function power()
    local bp = lp:FindFirstChild("Backpack")
    local av = bp and bp:FindFirstChild("ActionValues")
    local p = av and av:FindFirstChild("Power")
    return p and p.Value or -1
end

local function shootPoint()
    local pg = lp:FindFirstChild("PlayerGui")
    local tg = pg and pg:FindFirstChild("TouchGui")
    local fr = tg and tg:FindFirstChild("TouchControlFrame")
    local sb = fr and fr:FindFirstChild("ShootBTN")
    if not sb then return nil, "no ShootBTN" end
    if not sb.Visible then return nil, "ShootBTN hidden (are you on defense?)" end
    local hit = sb:FindFirstChild("ButtonDetect") or sb
    local p, z = hit.AbsolutePosition, hit.AbsoluteSize
    local inset = Vector2.new(0, 0)
    pcall(function() inset = game:GetService("GuiService"):GetGuiInset() end)
    local cx, cy = p.X + z.X / 2, p.Y + z.Y / 2
    return { { cx, cy, "as-is" }, { cx + inset.X, cy + inset.Y, "inset added" } }
end

-- One attempt: touch down, watch Power for a moment, touch up.
local function attempt(x, y, label)
    log("try %s at %d,%d ...", label, x, y)
    local sent = pcall(function() VIM:SendTouchEvent(7, 0, x, y) end)
    if not sent then
        log("   SendTouchEvent THREW - not supported here")
        return false, true
    end
    local moved = false
    local t = os.clock()
    while os.clock() - t < 0.9 do
        if power() > 0 then moved = true break end
        RunService.Heartbeat:Wait()
    end
    pcall(function() VIM:SendTouchEvent(7, 2, x, y) end)
    if moved then
        log("   METER OPENED - this is the one")
    else
        log("   nothing")
    end
    return moved, false
end

btn.MouseButton1Click:Connect(function()
    btn.Text = "testing..."
    task.spawn(function()
        lines = {}
        local pts, why = shootPoint()
        if not pts then
            log("cannot test: %s", why)
            btn.Text = "TEST (hold ball first)"
            return
        end
        if power() > 0 then
            log("a shot is already up - wait for it to finish")
            btn.Text = "TEST (hold ball first)"
            return
        end
        for _, pt in ipairs(pts) do
            local ok, threw = attempt(pt[1], pt[2], pt[3])
            if threw then break end
            if ok then break end
            task.wait(1.2)   -- let the game settle between attempts
        end
        log("done")
        btn.Text = "TEST again"
    end)
end)

getgenv().TeekTouchStop = function()
    pcall(function() sg:Destroy() end)
    getgenv().TeekTouchStop = nil
end

log("ready. HOLD THE BALL, then press TEST.")
log("it tries both coordinates and says which opens the meter.")
