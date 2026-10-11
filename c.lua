local cr         = cloneref or function(x) return x end
local RS         = cr(game:GetService("ReplicatedStorage"))
local CS         = cr(game:GetService("CollectionService"))
local UIS        = cr(game:GetService("UserInputService"))
local RunS       = cr(game:GetService("RunService"))
local SG         = cr(game:GetService("StarterGui"))
local Players    = cr(game:GetService("Players"))
local TweenSvc   = cr(game:GetService("TweenService"))
local LP         = Players.LocalPlayer

local RANGE      = 350
local INTERVAL   = 0
local PACK       = 1000
local RESPECT_CD = false
local EXCLUDE_FRIENDS = true

local Trigger    = RS:WaitForChild("Network"):WaitForChild("AbilityTrigger")
local SUP        = { Area = 1, Hit = 1, Click = 1, Hold = 1, DualHold = 1 }
local NAMES      = { "Equip", "Unequip", "SetTarget" }
local F, T       = {}, {}

local function add(m) if m:IsA("Model") then T[m] = true end end
for _, m in CS:GetTagged("Target") do add(m) end
CS:GetInstanceAddedSignal("Target"):Connect(add)
CS:GetInstanceRemovedSignal("Target"):Connect(function(m) T[m] = nil end)

local friendCache = {}
local function refreshFriend(player)
    if not player or player == LP then return end
    task.spawn(function()
        local ok, result = pcall(function() return LP:IsFriendsWith(player.UserId) end)
        friendCache[player.UserId] = ok and result or false
    end)
end
for _, p in ipairs(Players:GetPlayers()) do refreshFriend(p) end
Players.PlayerAdded:Connect(refreshFriend)
Players.PlayerRemoving:Connect(function(p) friendCache[p.UserId] = nil end)

local function isFriendModel(model)
    if not EXCLUDE_FRIENDS then return false end
    local player = Players:GetPlayerFromCharacter(model)
    if not player or player == LP then return false end
    if friendCache[player.UserId] ~= nil then
        return friendCache[player.UserId]
    end
    local ok, res = pcall(function() return LP:IsFriendsWith(player.UserId) end)
    local isF = ok and res or false
    friendCache[player.UserId] = isF
    return isF
end

local function load(gc)
    pcall(function()
        local env = getsenv(RS.Scene.Player.UIs)
        for _, k in NAMES do F[k] = rawget(env, k) end
    end)
    if gc and not next(F) then
        pcall(function()
            for _, f in getgc() do
                local n = type(f) == "function" and debug.info(f, "n")
                if table.find(NAMES, n) then
                    local ok, s = pcall(function() return getfenv(f).script end)
                    if ok and s and s.Name == "UIs" then F[n] = f end
                end
            end
        end)
    end
end

local fn, idx, nxt = nil, nil, 0
local function equipped()
    if not idx then
        if os.clock() < nxt then return end
        nxt = os.clock() + 0.25
        for _, k in NAMES do
            if F[k] then
                for i, v in pairs(debug.getupvalues(F[k])) do
                    if type(v) == "table" and type(v.Name) == "string" and type(v.Data) == "table" then
                        fn, idx = F[k], i
                        return v
                    end
                end
            end
        end
        return
    end
    local a, b = debug.getupvalue(fn, idx)
    local v = type(a) == "table" and a or b
    if type(v) == "table" and type(v.Data) == "table" then
        return v
    end
    idx = nil
    return nil
end

local function pick(root, range)
    local cam = workspace.CurrentCamera
    local vp  = cam.ViewportSize
    local m   = UIS:GetMouseLocation()
    if m.X <= 0 and m.Y <= 0 then
        m = Vector2.new(vp.X / 2, vp.Y / 2)
    end
    local rp       = root.Position
    local me       = LP.Character
    local best, bs = nil, math.huge
    for t in T do
        if not isFriendModel(t) then
            local pp = t.PrimaryPart
            local h  = pp and t ~= me and t:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 and (pp.Position - rp).Magnitude <= range
                and t:FindFirstChild("CharacterValues") then
                local p, on = cam:WorldToViewportPoint(pp.Position)
                local dx, dy = p.X - m.X, p.Y - m.Y
                local dist = dx * dx + dy * dy
                if on and p.Z > 0 and dist < bs then
                    best, bs = t, dist
                end
            end
        end
    end
    if not best then
        local cd = math.huge
        for t in T do
            if not isFriendModel(t) then
                local pp = t.PrimaryPart
                local h  = pp and t ~= me and t:FindFirstChildOfClass("Humanoid")
                if h and h.Health > 0 and t:FindFirstChild("CharacterValues") then
                    local d = (pp.Position - rp).Magnitude
                    if d <= range and d < cd then
                        best, cd = t, d
                    end
                end
            end
        end
    end
    return best
end

local last, ceq, key, larg, pack = 0, nil, nil, nil, nil
local function step()
    local c       = LP.Character
    local root, h = c and c.PrimaryPart, c and c:FindFirstChildOfClass("Humanoid")
    local eq      = root and h and h.Health > 0 and equipped()
    if not eq or not SUP[eq.Data.Type] or os.clock() - last < INTERVAL then return end
    local d, n = eq.Data, eq.Name
    if eq ~= ceq then ceq, key = eq, (n:gsub("[^%w_]", "_")) end

    if RESPECT_CD then
        local cd = LP:FindFirstChild("Cooldowns")
        local e  = cd and cd:GetAttribute(key)
        if e and workspace:GetServerTimeNow() < e then return end
        if d.Mana then
            local cv = c:FindFirstChild("CharacterValues")
            local mv = cv and cv:FindFirstChild(d.ManaType or "Magic")
            if not mv or mv.Value < d.Mana then return end
        end
    end

    local t = d.Type ~= "Area" and pick(root, d.Magnitude or RANGE)
    if d.Type ~= "Area" and not t then return end
    last = os.clock()
    local arg = t and (d.Type == "Hit" and CFrame.new(t.PrimaryPart.Position) or t)
    if arg ~= larg then larg, pack = arg, table.create(PACK, arg) end
    Trigger:FireServer(n, table.unpack(pack))
end

local function getParent()
    if type(gethui) == "function" then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    local ok, pg = pcall(function() return LP:WaitForChild("PlayerGui") end)
    if ok and pg then return pg end
    return game:GetService("CoreGui")
end

local gui = Instance.new("ScreenGui")
gui.Name  = "_G"
if syn and syn.protect_gui then
    syn.protect_gui(gui)
elseif protect_gui then
    protect_gui(gui)
end
gui.ResetOnSpawn                  = false
gui.IgnoreGuiInset                = true
gui.DisplayOrder                  = 999999
gui.ZIndexBehavior                = Enum.ZIndexBehavior.Sibling
gui.Parent                        = getParent()

local button                      = Instance.new("ImageButton")
button.Name                       = "ToggleButton"
button.ZIndex                     = 10
button.Size                       = UDim2.fromOffset(56, 56)
button.Position                   = UDim2.new(0, 18, 0.12, 0)
button.BackgroundColor3           = Color3.fromRGB(20, 25, 38)
button.BackgroundTransparency     = 0.12
button.Image                      = "rbxassetid://114826584686381"
button.ScaleType                  = Enum.ScaleType.Fit
button.AutoButtonColor            = false
button.Active                     = true
button.Parent                     = gui

local corner                      = Instance.new("UICorner")
corner.CornerRadius               = UDim.new(1, 0)
corner.Parent                     = button

local stroke                      = Instance.new("UIStroke")
stroke.Thickness                  = 2
stroke.Color                      = Color3.fromRGB(220, 65, 75)
stroke.Parent                     = button

local TS                          = TweenSvc
local toast                       = Instance.new("Frame")
toast.Name                        = "Toast"
toast.Size                        = UDim2.fromOffset(90, 30)
toast.AnchorPoint                 = Vector2.new(0, 0.5)
toast.BackgroundColor3            = Color3.fromRGB(12, 15, 24)
toast.BackgroundTransparency      = 1
toast.BorderSizePixel             = 0
toast.Parent                      = gui

local toastCorner                 = Instance.new("UICorner")
toastCorner.CornerRadius          = UDim.new(1, 0)
toastCorner.Parent                = toast

local toastLabel                  = Instance.new("TextLabel")
toastLabel.Size                   = UDim2.fromScale(1, 1)
toastLabel.BackgroundTransparency = 1
toastLabel.Font                   = Enum.Font.GothamBold
toastLabel.TextSize               = 13
toastLabel.TextTransparency       = 1
toastLabel.TextColor3             = Color3.fromRGB(65, 220, 125)
toastLabel.Text                   = "ATIVO"
toastLabel.Parent                 = toast

local toastThread                 = nil
local function showToast(on)
    if toastThread then task.cancel(toastThread) end
    local bpos            = button.Position
    toast.Position        = UDim2.new(
        bpos.X.Scale, bpos.X.Offset + 64,
        bpos.Y.Scale, bpos.Y.Offset - 28
    )
    toastLabel.Text       = on and "ATIVO" or "OFF"
    toastLabel.TextColor3 = on
        and Color3.fromRGB(65, 220, 125)
        or Color3.fromRGB(220, 65, 75)

    TS:Create(toast, TweenInfo.new(0.15), { BackgroundTransparency = 0.2 }):Play()
    TS:Create(toastLabel, TweenInfo.new(0.15), { TextTransparency = 0 }):Play()

    toastThread = task.delay(0.9, function()
        TS:Create(toast, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
        TS:Create(toastLabel, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
    end)
end

local conn    = nil
local enabled = false

local function setEnabled(state)
    enabled = state
    stroke.Color = enabled
        and Color3.fromRGB(65, 220, 125)
        or Color3.fromRGB(220, 65, 75)

    if enabled then
        if not next(F) then task.spawn(load, true) end
        conn = RunS.Heartbeat:Connect(function()
            pcall(step)
        end)
    else
        if conn then
            conn:Disconnect()
            conn = nil
        end
    end

    showToast(enabled)
end

local function clampButton()
    local vp = workspace.CurrentCamera.ViewportSize
    local px = math.clamp(button.Position.X.Offset, 0, math.max(0, vp.X - 60))
    local py = math.clamp(button.Position.Y.Offset, 0, math.max(0, vp.Y - 60))
    button.Position = UDim2.new(
        button.Position.X.Scale, px,
        button.Position.Y.Scale, py
    )
end

button.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local dragStart = input.Position
    local startPos  = button.Position
    local moved     = false
    local cChange, cEnd

    cChange         = input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.Change then
            local delta = input.Position - dragStart
            if delta.Magnitude > 8 then
                moved = true
                button.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end
    end)

    cEnd            = input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then
            if cChange then cChange:Disconnect() end
            if cEnd then cEnd:Disconnect() end
            clampButton()
            if not moved then
                setEnabled(not enabled)
            end
        end
    end)
end)

UIS.InputBegan:Connect(function(i, gpe)
    if gpe or i.KeyCode ~= Enum.KeyCode.F then return end
    setEnabled(not enabled)
end)

LP.CharacterAdded:Connect(function()
    fn, idx = nil, nil
    table.clear(F)
    task.delay(0.5, function() load(true) end)
end)

load(false)
if not next(F) then task.spawn(load, true) end
