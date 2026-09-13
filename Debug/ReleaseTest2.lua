--[[
    What actually ends a mobile shot in RH2?

    ConnTest.lua said firing MouseButton1Up worked. It did not prove that.
    It fired at power 76 and called any shot ending below 84 a success - and
    a finger lifting anywhere in that band scores exactly the same. The tester
    said at the time they were still timing the jumpshot by hand, so those
    readings were probably the finger, not the fire.

    So this test fires at power 30. Nobody releases a jumpshot at 30 by
    accident, which makes the result unambiguous:

        power stops near 30-40  ->  the route WORKS
        power runs past 60      ->  the route does NOTHING

    KEEP HOLDING THE SHOOT BUTTON until the verdict prints. Letting go early
    is what made the last test lie.

    Three routes, one per button, because guessing between them has already
    cost four rounds:

      FIRE UP    fire the connections on MouseButton1Up, what we ship today
      UPVALUE    the release reads a local (u2979 in the decompile) that the
                 button's own handler sets. Connections expose .Function, and
                 that function closes over the same local, so debug.setupvalue
                 can set it false directly - no input routing involved at all.
      BOTH       in case one arms the other

    Part 1 prints every signal on the button that has connections, so if all
    three fail we can at least see what the game is really listening to.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

if getgenv().TeekRT2Stop then pcall(getgenv().TeekRT2Stop) end

local FIRE_AT = 30      -- far below any human release

-- ---------------------------------------------------------------- ui
local sg = Instance.new("ScreenGui")
sg.Name = "TeekReleaseTest2"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.DisplayOrder = 2000000
pcall(function() sg.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not sg.Parent then sg.Parent = lp:WaitForChild("PlayerGui") end

local f = Instance.new("Frame")
f.Size = UDim2.new(0, 660, 0, 430)
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
body.TextSize = 14
body.TextColor3 = Color3.fromRGB(240, 240, 245)
body.TextXAlignment = Enum.TextXAlignment.Left
body.TextYAlignment = Enum.TextYAlignment.Top
body.TextWrapped = true
body.Parent = f

local lines = {}
local function log(fmt, ...)
    local ok, m = pcall(string.format, fmt, ...)
    lines[#lines + 1] = ok and m or tostring(fmt)
    while #lines > 22 do table.remove(lines, 1) end
    body.Text = table.concat(lines, "\n")
end

local mode = nil
local buttons = {}
local function mkButton(i, text, value)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(200, 48)
    b.Position = UDim2.new(0, 8 + (i - 1) * 210, 1, -54)
    b.BackgroundColor3 = Color3.fromRGB(40, 30, 70)
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 15
    b.BorderSizePixel = 0
    b.Parent = f
    buttons[value] = b
    b.MouseButton1Click:Connect(function()
        mode = (mode == value) and nil or value
        for v, bb in pairs(buttons) do
            bb.BackgroundColor3 = (v == mode) and Color3.fromRGB(30, 120, 60)
                or Color3.fromRGB(40, 30, 70)
        end
        log(mode and ("ARMED: %s - hold SHOOT and DO NOT let go"):format(mode)
            or "disarmed")
    end)
    return b
end

-- ---------------------------------------------------------------- helpers
local function detect()
    local pg = lp:FindFirstChild("PlayerGui")
    local tg = pg and pg:FindFirstChild("TouchGui")
    local fr = tg and tg:FindFirstChild("TouchControlFrame")
    local sb = fr and fr:FindFirstChild("ShootBTN")
    if not sb then return nil, nil end
    return sb:FindFirstChild("ButtonDetect") or sb, sb
end

local function power()
    local bp = lp:FindFirstChild("Backpack")
    local av = bp and bp:FindFirstChild("ActionValues")
    local p = av and av:FindFirstChild("Power")
    return p and p.Value or -1
end

local GC do
    local ok, fn = pcall(function() return getconnections end)
    GC = (ok and type(fn) == "function") and fn or nil
end

local function connsOf(obj, sigName)
    if not (GC and obj) then return nil end
    local ok, sig = pcall(function() return obj[sigName] end)
    if not ok or sig == nil then return nil end
    local ok2, c = pcall(GC, sig)
    if not ok2 or type(c) ~= "table" then return nil end
    return c
end

-- getupvalues is not spelled the same everywhere, so try both shapes.
local function upvaluesOf(fn)
    if type(fn) ~= "function" then return nil end
    local ok, t = pcall(function() return debug.getupvalues(fn) end)
    if ok and type(t) == "table" then return t end
    local out, i = {}, 1
    while i <= 40 do
        local ok2, v = pcall(function() return debug.getupvalue(fn, i) end)
        if not ok2 then break end
        out[i] = v
        i += 1
    end
    return next(out) and out or nil
end

-- ---------------------------------------------------------------- part 1
log("getconnections: %s", GC and "yes" or "MISSING - every route here is dead")

local d, sb = detect()
log("button: %s", d and "found" or "NOT FOUND - hold the ball first, then reload")

if d then
    local SIGS = {
        "MouseButton1Down", "MouseButton1Up", "MouseButton1Click",
        "InputBegan", "InputEnded", "InputChanged",
        "TouchTap", "TouchLongPress", "Activated", "MouseLeave",
    }
    local found = {}
    for _, which in ipairs({ { d, "detect" }, { sb, "ShootBTN" } }) do
        local obj, tag = which[1], which[2]
        for _, s in ipairs(SIGS) do
            local c = connsOf(obj, s)
            if c and #c > 0 then found[#found + 1] = ("%s.%s=%d"):format(tag, s, #c) end
        end
        if obj == sb then break end
    end
    log("connected signals: %s", #found > 0 and table.concat(found, "  ") or "none")
end

-- The handler that owns the flag. MouseButton1Down is the one that sets it
-- true, so the local we want is an upvalue of that closure.
local downFn, upFn
do
    local c = connsOf(d, "MouseButton1Down")
    if c and c[1] then
        local ok, fn = pcall(function() return c[1].Function end)
        downFn = ok and fn or nil
    end
    local c2 = connsOf(d, "MouseButton1Up")
    if c2 and c2[1] then
        local ok, fn = pcall(function() return c2[1].Function end)
        upFn = ok and fn or nil
    end
end
log("handler functions: down=%s up=%s",
    downFn and "yes" or "no", upFn and "yes" or "no")

-- Booleans are what we are after: the release loop reads one of them.
local boolSlots = {}
for _, pair in ipairs({ { downFn, "down" }, { upFn, "up" } }) do
    local fn, tag = pair[1], pair[2]
    local ups = upvaluesOf(fn)
    if ups then
        local desc = {}
        for i, v in pairs(ups) do
            desc[#desc + 1] = ("%d:%s"):format(i, typeof(v))
            if typeof(v) == "boolean" then
                boolSlots[#boolSlots + 1] = { fn = fn, idx = i, tag = tag, was = v }
            end
        end
        table.sort(desc)
        log("%s upvalues: %s", tag, table.concat(desc, " "))
    else
        log("%s upvalues: unavailable", tag)
    end
end
log("boolean slots to try: %d", #boolSlots)

-- ---------------------------------------------------------------- part 2
local function fireUp()
    local dd = detect()
    local c = connsOf(dd, "MouseButton1Up")
    local n = 0
    if c then
        for _, cn in ipairs(c) do
            if pcall(function() cn:Fire() end) then n += 1 end
        end
    end
    return n
end

local function setBools()
    local n = 0
    for _, s in ipairs(boolSlots) do
        if pcall(function() debug.setupvalue(s.fn, s.idx, false) end) then n += 1 end
    end
    return n
end

mkButton(1, "FIRE UP", "fireup")
mkButton(2, "UPVALUE", "upvalue")
mkButton(3, "BOTH", "both")

task.spawn(function()
    local live, peak, firedAt = false, 0, nil
    while sg.Parent do
        local v = power()
        if v > 0 then
            if not live then live, peak, firedAt = true, v, nil end
            if v > peak then peak = v end
            if mode and not firedAt and v >= FIRE_AT then
                firedAt = v
                local a = (mode ~= "upvalue") and fireUp() or 0
                local b = (mode ~= "fireup") and setBools() or 0
                log("fired at %.1f  (up=%d conns, bools=%d)", v, a, b)
            end
        elseif live then
            live = false
            if firedAt then
                -- The only thing that matters. A shot that keeps climbing
                -- past 60 was ended by the finger, not by us.
                local worked = peak < FIRE_AT + 15
                log("  -> ended at %.1f   %s", peak,
                    worked and "*** THIS ROUTE WORKS ***" or "route did nothing")
            end
            peak = 0
        end
        RunService.Heartbeat:Wait()
    end
end)

getgenv().TeekRT2Stop = function()
    pcall(function() sg:Destroy() end)
    getgenv().TeekRT2Stop = nil
end

log("pick a route, hold the GAME's SHOOT button, DO NOT let go until verdict")
