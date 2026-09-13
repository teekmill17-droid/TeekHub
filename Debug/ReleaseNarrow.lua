--[[
    Which ONE upvalue ends a mobile shot?

    ReleaseTest2 settled the route, measured on the phone:

        fireup   fired at 32.3 on 1 connection  ->  ran to 100.0   nothing
        upvalue  fired at 30.1, flipped 21 bools ->  ended at 36.6  WORKS
        both     identical to upvalue, so the connection fire adds nothing

    So the release reads a boolean the shoot handlers close over, and
    debug.setupvalue reaches it. But flipping 21 booleans to end one shot means
    20 unknown writes into the game's handler state on every shot, on every
    user's client. One of them is the shot flag; the rest are somebody else's.
    That is not something to ship blind.

    This narrows it to one, by bisection, without you having to think about it:

      each shot it flips HALF the remaining candidates
      shot ends early -> the flag is in that half
      shot runs to 100 -> it is in the other half
      repeat, about 5 shots for 21 candidates

    Slots are keyed by signal, handler order and upvalue index rather than by
    function identity, because the handlers are re-connected per shot and the
    closure is a new object each time - the index inside it is what is stable.

    Hold the SHOOT button and do not let go until each verdict prints. A shot
    you release by hand records a false answer and sends the bisect down the
    wrong branch - press RESET if that happens.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

if getgenv().TeekNarrowStop then pcall(getgenv().TeekNarrowStop) end

local FIRE_AT = 30

-- ---------------------------------------------------------------- ui
local sg = Instance.new("ScreenGui")
sg.Name = "TeekReleaseNarrow"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.DisplayOrder = 2000000
pcall(function() sg.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not sg.Parent then sg.Parent = lp:WaitForChild("PlayerGui") end

local f = Instance.new("Frame")
f.Size = UDim2.fromOffset(430, 250)
f.Position = UDim2.fromOffset(8, 8)
f.BackgroundColor3 = Color3.fromRGB(6, 5, 10)
f.BackgroundTransparency = 0.12
f.BorderSizePixel = 0
f.Active = false
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

-- ---------------------------------------------------------------- helpers
local function detect()
    local pg = lp:FindFirstChild("PlayerGui")
    local tg = pg and pg:FindFirstChild("TouchGui")
    local fr = tg and tg:FindFirstChild("TouchControlFrame")
    local sb = fr and fr:FindFirstChild("ShootBTN")
    if not sb then return nil end
    return sb:FindFirstChild("ButtonDetect") or sb
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

local SIGS = { "MouseButton1Down", "MouseButton1Up", "InputBegan", "InputEnded" }

-- Keyed by position, not by function identity: the handlers are reconnected
-- per shot, so the closure is new every time but its layout is not.
local function slotsNow()
    local d = detect()
    local slots = {}
    for _, s in ipairs(SIGS) do
        local c = connsOf(d, s)
        for ci, cn in ipairs(c or {}) do
            local ok, fn = pcall(function() return cn.Function end)
            if ok and type(fn) == "function" then
                for i, v in pairs(upvaluesOf(fn) or {}) do
                    if typeof(v) == "boolean" then
                        slots[#slots + 1] = {
                            key = ("%s#%d:%d"):format(s, ci, i),
                            fn = fn, idx = i, was = v,
                        }
                    end
                end
            end
        end
    end
    return slots
end

-- ---------------------------------------------------------------- bisect
local cands = nil       -- list of keys still in play
local pending = nil     -- keys flipped on the shot in flight
local rest = nil        -- the other half
local answer = nil

local function resetBisect()
    cands, pending, rest, answer = nil, nil, nil, nil
    log("reset - next shot starts over")
end

local function applyShot()
    local slots = slotsNow()
    if #slots == 0 then log("no boolean upvalues found") return end

    local byKey = {}
    for _, s in ipairs(slots) do byKey[s.key] = s end

    if not cands then
        cands = {}
        for _, s in ipairs(slots) do cands[#cands + 1] = s.key end
        table.sort(cands)
        log("starting with %d candidates", #cands)
    end

    if #cands <= 1 then
        answer = cands[1]
        local s = answer and byKey[answer]
        log("ANSWER: %s  (was=%s)", tostring(answer), s and tostring(s.was) or "?")
        return
    end

    local half = math.floor(#cands / 2)
    pending, rest = {}, {}
    for i, k in ipairs(cands) do
        if i <= half then pending[#pending + 1] = k else rest[#rest + 1] = k end
    end

    local n = 0
    for _, k in ipairs(pending) do
        local s = byKey[k]
        if s and pcall(function() debug.setupvalue(s.fn, s.idx, false) end) then n += 1 end
    end
    log("testing %d of %d  (flipped %d)", #pending, #cands, n)
end

local function verdict(peak)
    if answer or not pending then return end
    local worked = peak < FIRE_AT + 15
    cands = worked and pending or rest
    log("  -> %.1f  %s, %d left", peak,
        worked and "in this half" or "in the other half", #cands)
    pending, rest = nil, nil
    if #cands == 1 then
        answer = cands[1]
        log("ANSWER: %s", tostring(answer))
        log("one more shot to confirm it ends the shot on its own")
    end
end

-- ---------------------------------------------------------------- buttons
local armed = false
local function mkButton(i, text, onClick)
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
    b.MouseButton1Click:Connect(function() onClick(b) end)
    return b
end

local armBtn
armBtn = mkButton(1, "ARM", function(b)
    armed = not armed
    b.BackgroundColor3 = armed and Color3.fromRGB(30, 120, 60) or Color3.fromRGB(40, 30, 70)
    b.Text = armed and "ARMED" or "ARM"
    log(armed and "armed - hold SHOOT, do not let go" or "disarmed")
end)
mkButton(2, "RESET", function() resetBisect() end)
mkButton(3, "CLOSE", function()
    if getgenv().TeekNarrowStop then getgenv().TeekNarrowStop() end
end)

log("getconnections %s   setupvalue %s",
    GC and "ok" or "MISSING",
    (type(debug) == "table" and debug.setupvalue) and "ok" or "MISSING")
log("press ARM, then take shots. hold SHOOT until each verdict prints.")

task.spawn(function()
    local live, peak, fired = false, 0, false
    while sg.Parent do
        local v = power()
        if v > 0 then
            if not live then live, peak, fired = true, v, false end
            if v > peak then peak = v end
            if armed and not fired and v >= FIRE_AT then
                fired = true
                pcall(applyShot)
            end
        elseif live then
            live = false
            if fired then pcall(verdict, peak) end
            peak = 0
        end
        RunService.Heartbeat:Wait()
    end
end)

getgenv().TeekNarrowStop = function()
    pcall(function() sg:Destroy() end)
    getgenv().TeekNarrowStop = nil
end
