--[[
    What actually ends a mobile shot in RH2?

    Two corrections over the first version of this file, both measured:

    1. It probed the button at LOAD time and found nothing connected - "down=no
       up=no", zero boolean slots - while RH2 itself reports one connection on
       MouseButton1Up mid-shot. Both are true: the game connects its shoot
       handlers only while a shot is live. So everything here is probed at FIRE
       time now, and the upvalue route finally has a function to read.

    2. The panel was 660x430 on a viewport that is about 1000x446 logical - the
       phone screenshot is 2x retina, which is what made it look reasonable. It
       covered most of the screen and its buttons sat on the game's own button
       row. Everything is small and pinned to the left now, clear of the
       controls, and nothing here is Active so taps pass through.

    The test itself: fire at power 30. Nobody releases a jumpshot at 30 by
    accident, so the verdict cannot be faked by a finger the way ConnTest's
    could - that one fired at 76 and scored anything under 84 a pass.

        power stops near 30-45  ->  the route WORKS
        power runs past 60      ->  the route does NOTHING

    KEEP HOLDING THE SHOOT BUTTON until the verdict prints.

    Routes:
      FIRE UP    fire the connections on MouseButton1Up, what we ship today
      UPVALUE    connections expose .Function, and that closure shares the
                 local the release loop reads, so debug.setupvalue can set it
                 false directly with no input routing involved
      BOTH       in case one arms the other
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

-- Left edge only. The game's controls live on the right half and along the
-- bottom, and on a ~1000x446 viewport there is not much room to be wrong in.
local f = Instance.new("Frame")
f.Size = UDim2.fromOffset(430, 250)
f.Position = UDim2.fromOffset(8, 8)
f.BackgroundColor3 = Color3.fromRGB(6, 5, 10)
f.BackgroundTransparency = 0.12
f.BorderSizePixel = 0
f.Active = false          -- do not swallow touches meant for the game
f.Parent = sg

local body = Instance.new("TextLabel")
body.Size = UDim2.new(1, -10, 1, -8)
body.Position = UDim2.fromOffset(5, 4)
body.BackgroundTransparency = 1
body.Font = Enum.Font.Code
body.TextSize = 13
body.TextColor3 = Color3.fromRGB(240, 240, 245)
body.TextXAlignment = Enum.TextXAlignment.Left
body.TextYAlignment = Enum.TextYAlignment.Top
body.TextWrapped = true
body.Active = false
body.Parent = f

local lines = {}
local function log(fmt, ...)
    local ok, m = pcall(string.format, fmt, ...)
    lines[#lines + 1] = ok and m or tostring(fmt)
    while #lines > 16 do table.remove(lines, 1) end
    body.Text = table.concat(lines, "\n")
end

local mode = nil
local buttons = {}
local function mkButton(i, text, value, onClick)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(104, 40)
    b.Position = UDim2.fromOffset(8 + (i - 1) * 108, 262)
    b.BackgroundColor3 = Color3.fromRGB(40, 30, 70)
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.BorderSizePixel = 0
    b.Parent = sg
    if onClick then b.MouseButton1Click:Connect(onClick) return b end
    buttons[value] = b
    b.MouseButton1Click:Connect(function()
        mode = (mode == value) and nil or value
        for v, bb in pairs(buttons) do
            bb.BackgroundColor3 = (v == mode) and Color3.fromRGB(30, 120, 60)
                or Color3.fromRGB(40, 30, 70)
        end
        log(mode and ("ARMED %s - hold SHOOT, do not let go"):format(mode) or "disarmed")
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

local function upvaluesOf(fn)
    if type(fn) ~= "function" then return nil end
    local ok, t = pcall(function() return debug.getupvalues(fn) end)
    if ok and type(t) == "table" and next(t) then return t end
    local out, i = {}, 1
    while i <= 40 do
        local ok2, v = pcall(function() return debug.getupvalue(fn, i) end)
        if not ok2 then break end
        out[i] = v
        i += 1
    end
    return next(out) and out or nil
end

local SIGS = {
    "MouseButton1Down", "MouseButton1Up", "MouseButton1Click",
    "InputBegan", "InputEnded", "InputChanged",
    "TouchTap", "TouchLongPress", "Activated", "MouseLeave",
}

-- Everything below runs DURING a shot. That is the whole fix: at rest the
-- button has no handlers connected at all.
local function probe()
    local d, sb = detect()
    if not d then log("probe: no button") return end
    local found = {}
    for _, s in ipairs(SIGS) do
        local c = connsOf(d, s)
        if c and #c > 0 then found[#found + 1] = ("%s=%d"):format(s, #c) end
    end
    if sb ~= d then
        for _, s in ipairs(SIGS) do
            local c = connsOf(sb, s)
            if c and #c > 0 then found[#found + 1] = ("SB.%s=%d"):format(s, #c) end
        end
    end
    log("live signals: %s", #found > 0 and table.concat(found, " ") or "NONE")
end

-- Collect the boolean upvalues of whatever handlers are connected right now.
local function boolSlots()
    local d = detect()
    local slots, seen = {}, {}
    for _, s in ipairs({ "MouseButton1Down", "MouseButton1Up", "InputBegan", "InputEnded" }) do
        local c = connsOf(d, s)
        for _, cn in ipairs(c or {}) do
            local ok, fn = pcall(function() return cn.Function end)
            if ok and type(fn) == "function" and not seen[fn] then
                seen[fn] = true
                local ups = upvaluesOf(fn)
                for i, v in pairs(ups or {}) do
                    if typeof(v) == "boolean" then
                        slots[#slots + 1] = { fn = fn, idx = i, sig = s, was = v }
                    end
                end
            end
        end
    end
    return slots
end

local function fireUp()
    local d = detect()
    local n = 0
    for _, cn in ipairs(connsOf(d, "MouseButton1Up") or {}) do
        if pcall(function() cn:Fire() end) then n += 1 end
    end
    return n
end

-- Flip every boolean the handlers close over. Crude on purpose: we do not know
-- which one the release loop reads, and a wrong flip on a test shot costs
-- nothing. If this works, the next step is to find the single right index.
local function setBools(slots)
    local n = 0
    for _, s in ipairs(slots) do
        if pcall(function() debug.setupvalue(s.fn, s.idx, false) end) then n += 1 end
    end
    return n
end

mkButton(1, "FIRE UP", "fireup")
mkButton(2, "UPVALUE", "upvalue")
mkButton(3, "BOTH", "both")
mkButton(4, "CLOSE", nil, function()
    if getgenv().TeekRT2Stop then getgenv().TeekRT2Stop() end
end)

log("getconnections: %s", GC and "yes" or "MISSING - every route here is dead")
log("setupvalue: %s", (type(debug) == "table" and debug.setupvalue) and "yes" or "MISSING")
log("handlers connect only mid-shot, so probing happens at fire time")
log("pick a route, hold the GAME's SHOOT button, DO NOT let go")

task.spawn(function()
    local live, peak, firedAt, probed = false, 0, nil, false
    while sg.Parent do
        local v = power()
        if v > 0 then
            if not live then live, peak, firedAt, probed = true, v, nil, false end
            if v > peak then peak = v end
            if not probed then probed = true ; pcall(probe) end
            if mode and not firedAt and v >= FIRE_AT then
                firedAt = v
                local a = (mode ~= "upvalue") and fireUp() or 0
                local b = 0
                if mode ~= "fireup" then
                    local slots = boolSlots()
                    b = setBools(slots)
                    log("bool slots found: %d", #slots)
                end
                log("fired at %.1f  (up=%d conns, bools=%d)", v, a, b)
            end
        elseif live then
            live = false
            if firedAt then
                local worked = peak < FIRE_AT + 15
                log("  -> ended at %.1f  %s", peak,
                    worked and "*** ROUTE WORKS ***" or "route did nothing")
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
