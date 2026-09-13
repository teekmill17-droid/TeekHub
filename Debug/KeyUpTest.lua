--[[
    Can a VirtualInputManager key-up release a key your finger is on?

    This one question decides whether RH2's hold-to-shoot can work on executors
    with no hookmetamethod - which is every free one, and the reason our script
    falls back to a trigger key there while Countx just works.

    RH2's shot loop ends when UserInputService:IsKeyDown(E) goes false. The
    comment in our script says a synthetic key-up cannot change that while the
    key is physically held, which is why we hook __namecall to lie about it
    instead. Countx does not hook anything - it sends a plain VIM key-up on a
    timer - and it reportedly works on those same executors. Both cannot be
    true, and reading the game's decompiled source cannot settle it: that tells
    you what the game ASKS, not what VIM writes into the table that answers.

    So: run this, THEN hold E. It waits for you - there is nothing to time.

        after = false  ->  VIM key-up beats a held key. We do not need
                           hookmetamethod on desktop at all, and hold-to-shoot
                           can work on every executor.
        after = true   ->  it does not, and Countx's users must be tapping
                           rather than holding.
]]

local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

if getgenv().TeekKeyUpStop then pcall(getgenv().TeekKeyUpStop) end

local sg = Instance.new("ScreenGui")
sg.Name = "TeekKeyUpTest"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.DisplayOrder = 2000000
pcall(function() sg.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not sg.Parent then sg.Parent = lp:WaitForChild("PlayerGui") end

local f = Instance.new("Frame")
f.Size = UDim2.fromOffset(470, 190)
f.Position = UDim2.fromOffset(12, 12)
f.BackgroundColor3 = Color3.fromRGB(6, 5, 10)
f.BackgroundTransparency = 0.08
f.BorderSizePixel = 0
f.Active = false
f.Parent = sg

local body = Instance.new("TextLabel")
body.Size = UDim2.new(1, -12, 1, -10)
body.Position = UDim2.fromOffset(6, 5)
body.BackgroundTransparency = 1
body.Font = Enum.Font.Code
body.TextSize = 14
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
    while #lines > 10 do table.remove(lines, 1) end
    body.Text = table.concat(lines, "\n")
end

getgenv().TeekKeyUpStop = function()
    pcall(function() sg:Destroy() end)
    getgenv().TeekKeyUpStop = nil
end

log("HOLD E now, and keep holding until it prints a verdict.")
log("(nothing to time - this waits for you)")

task.spawn(function()
    -- Wait for the key to actually be down, by the same call the game uses.
    local waited = 0
    while not UIS:IsKeyDown(Enum.KeyCode.E) do
        task.wait(0.05)
        waited += 0.05
        if waited > 30 then
            log("gave up after 30s - E was never held")
            return
        end
    end

    -- Settled, so we are not reading a half-processed press.
    task.wait(0.15)
    local before = UIS:IsKeyDown(Enum.KeyCode.E)
    log("before key-up:  IsKeyDown(E) = %s", tostring(before))

    local sent = pcall(function()
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
    log("sent VIM key-up: %s", sent and "ok" or "THREW - VIM is blocked here")

    task.wait(0.1)
    local after = UIS:IsKeyDown(Enum.KeyCode.E)
    log("after key-up:   IsKeyDown(E) = %s", tostring(after))
    log("")

    if before and not after then
        log(">>> VIM KEY-UP BEATS A HELD KEY")
        log(">>> hold-to-shoot needs no hook - works on any executor")
    elseif before and after then
        log(">>> it does NOT - the hook is required, as the code says")
    else
        log(">>> inconclusive: E was not down when measured, try again")
    end
end)
