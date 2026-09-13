--[[
    Can we fire RH2's shoot button connections directly?

    Everything else is ruled out on mobile, measured on this phone:
      - the release polls nothing, so no hook can end a shot        (3 shots)
      - synthetic touch is ignored at both coordinates              (tested)
      - a synthetic keypress kills the joystick and does not shoot  (kb=false)

    One route left. The game's mobile release reads a local, u2979, which its
    own MouseButton1Up connection sets to false. If getconnections works on
    this executor we can fire that connection ourselves - and then the player
    presses the REAL shoot button with their finger, the game starts the shot
    normally, and we only end it at the right moment.

    That is exactly what was asked for: no button of ours anywhere.

    Two parts:
      1. Report whether getconnections works and how many connections exist.
      2. Arm: you take a normal shot with the game's button, and at the target
         it fires Up. If the shot ends there, this works.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

if getgenv().TeekConnStop then pcall(getgenv().TeekConnStop) end

local sg = Instance.new("ScreenGui")
sg.Name = "TeekConnTest"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.DisplayOrder = 2000000
pcall(function() sg.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not sg.Parent then sg.Parent = lp:WaitForChild("PlayerGui") end

local f = Instance.new("Frame")
f.Size = UDim2.new(1, -20, 0, 300)
f.Position = UDim2.fromOffset(10, 10)
f.BackgroundColor3 = Color3.fromRGB(6, 5, 10)
f.BackgroundTransparency = 0.06
f.BorderSizePixel = 0
f.Parent = sg

local body = Instance.new("TextLabel")
body.Size = UDim2.new(1, -12, 1, -62)
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
    while #lines > 13 do table.remove(lines, 1) end
    body.Text = table.concat(lines, "\n")
end

local arm = Instance.new("TextButton")
arm.Size = UDim2.fromOffset(230, 50)
arm.Position = UDim2.new(0, 10, 1, -56)
arm.BackgroundColor3 = Color3.fromRGB(60, 40, 110)
arm.Text = "ARM auto-release"
arm.TextColor3 = Color3.fromRGB(255, 255, 255)
arm.Font = Enum.Font.GothamBold
arm.TextSize = 15
arm.BorderSizePixel = 0
arm.Parent = f

local function detect()
    local pg = lp:FindFirstChild("PlayerGui")
    local tg = pg and pg:FindFirstChild("TouchGui")
    local fr = tg and tg:FindFirstChild("TouchControlFrame")
    local sb = fr and fr:FindFirstChild("ShootBTN")
    return sb and (sb:FindFirstChild("ButtonDetect") or sb) or nil
end

local function power()
    local bp = lp:FindFirstChild("Backpack")
    local av = bp and bp:FindFirstChild("ActionValues")
    local p = av and av:FindFirstChild("Power")
    return p and p.Value or -1
end

-- ---------------------------------------------------------------- part 1
local GC = nil
do
    local ok, fn = pcall(function() return getgenv().getconnections end)
    if ok and type(fn) == "function" then GC = fn end
    if not GC then
        local ok2, fn2 = pcall(function() return getconnections end)
        if ok2 and type(fn2) == "function" then GC = fn2 end
    end
end
log("getconnections: %s", GC and "available" or "MISSING - route is dead")

local d = detect()
log("ButtonDetect: %s", d and d:GetFullName():sub(-40) or "not found (hold the ball)")

local upConns, downConns = nil, nil
if GC and d then
    local ok, c = pcall(GC, d.MouseButton1Up)
    upConns = ok and c or nil
    log("MouseButton1Up connections: %s", upConns and #upConns or "failed")
    local ok2, c2 = pcall(GC, d.MouseButton1Down)
    downConns = ok2 and c2 or nil
    log("MouseButton1Down connections: %s", downConns and #downConns or "failed")
    if upConns and upConns[1] then
        local cn = upConns[1]
        local has = {}
        for _, k in ipairs({ "Fire", "Function", "Enabled" }) do
            local okk, v = pcall(function() return cn[k] end)
            if okk and v ~= nil then has[#has + 1] = k end
        end
        log("connection exposes: %s", #has > 0 and table.concat(has, " ") or "nothing usable")
    end
end

-- ---------------------------------------------------------------- part 2
local armed, fired = false, false
local TARGET = 76

arm.MouseButton1Click:Connect(function()
    if not (GC and detect()) then
        log("cannot arm - see above")
        return
    end
    armed = not armed
    fired = false
    arm.Text = armed and "ARMED - take a shot" or "ARM auto-release"
    log(armed and "armed: shoot with the GAME's button" or "disarmed")
end)

task.spawn(function()
    local live, peak = false, 0
    while sg.Parent do
        local v = power()
        if v > 0 then
            if not live then live, peak, fired = true, v, false end
            if v > peak then peak = v end
            if armed and not fired and v >= TARGET then
                fired = true
                local dd = detect()
                local conns = dd and select(2, pcall(GC, dd.MouseButton1Up)) or nil
                local n = 0
                if type(conns) == "table" then
                    for _, c in ipairs(conns) do
                        if pcall(function() c:Fire() end) then n += 1 end
                    end
                end
                log("fired Up on %d connection(s) at power %.1f", n, v)
            end
        elseif live then
            live = false
            if fired then
                log("   -> shot ended at %.1f  %s", peak,
                    peak < TARGET + 8 and "LOOKS LIKE IT WORKED" or "(too late - did not take)")
            end
            peak = 0
        end
        RunService.Heartbeat:Wait()
    end
end)

getgenv().TeekConnStop = function()
    pcall(function() sg:Destroy() end)
    getgenv().TeekConnStop = nil
end

log("hold the ball, press ARM, then shoot with the GAME's button")
