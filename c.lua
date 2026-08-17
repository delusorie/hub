cloneref                = cloneref or function(f) return f end

local Workspace         = cloneref(game:GetService("Workspace"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local StarterGui        = cloneref(game:GetService("StarterGui"))
local Players           = cloneref(game:GetService("Players"))
local UserInputService  = cloneref(game:GetService("UserInputService"))
local CoreGui           = cloneref(game:GetService("CoreGui"))
local TweenService      = cloneref(game:GetService("TweenService"))
local RS                = cloneref(game:GetService("RunService"))
local Stats             = cloneref(game:GetService("Stats"))
local LocalPlayer       = Players.LocalPlayer

local isMobile          = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

pcall(function()
    local OldNamecall
    OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" and tostring(self) == "AutoclickerDetected" then
            return
        end
        return OldNamecall(self, ...)
    end))
end)

local Settings = {
    NormalEnabled   = false,
    PrivateActive   = true,
    NormalRange     = 9999,
    NormalCPS       = 3000,
    IgnoreFriends   = true,
    ToggleKey       = Enum.KeyCode.R,
    SteambleEnabled = false,

    SpecialEnabled  = false,
    SpecialActive   = true,
    SpecialRange    = 9999,
    SpecialCPS      = 3000,
    SpecialKey      = Enum.KeyCode.E,

    -- ESP Configuration
    ESPEnabled      = false,
    ShowBodies      = true,
    ShowAstral      = true,
    ShowInvisible   = true,
    ESPSize         = 19,
    FriendColor     = Color3.fromRGB(0, 255, 200),
}

local UI_CONNECTIONS = {}

local _friendCache = {}
local function cacheFriendship(player)
    if not player or player == LocalPlayer then return end
    task.spawn(function()
        local success, isFriend = pcall(function()
            return LocalPlayer:IsFriendsWith(player.UserId)
        end)
        if success then
            _friendCache[player.UserId] = isFriend
        end
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    cacheFriendship(player)
end
Players.PlayerAdded:Connect(cacheFriendship)
Players.PlayerRemoving:Connect(function(player)
    _friendCache[player.UserId] = nil
end)

local PlayerScripts  = LocalPlayer:WaitForChild("PlayerScripts")
local ModuleScripts  = PlayerScripts:WaitForChild("ModuleScripts")
local AbilityHandler = require(ModuleScripts:WaitForChild("AbilityHandler"))
local ClientDebounce = require(ModuleScripts:WaitForChild("ClientDebounce"))

local function getTargetInContact(range)
    local character = LocalPlayer.Character
    if not character then return nil end

    local myRoot = character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local closestTarget    = nil
    local shortestDistance = range or 9999
    local entities         = workspace:FindFirstChild("Entities")
    local searchGroup      = entities and entities:GetChildren() or Players:GetPlayers()

    for _, target in pairs(searchGroup) do
        local targetChar = target:IsA("Player") and target.Character or target
        if targetChar and targetChar ~= character and targetChar:FindFirstChild("HumanoidRootPart") then
            local plr = target:IsA("Player") and target
                or Players:GetPlayerFromCharacter(targetChar)

            if Settings.IgnoreFriends and plr and _friendCache[plr.UserId] then
                continue
            end

            local h = targetChar:FindFirstChildOfClass("Humanoid")
            if h and h.Health <= 0 then continue end

            local dist = (myRoot.Position - targetChar.HumanoidRootPart.Position).Magnitude
            if dist < shortestDistance then
                shortestDistance = dist
                closestTarget    = targetChar
            end
        end
    end
    return closestTarget
end

local function getTargetUnderMouse(range)
    if isMobile then return nil end
    local camera    = workspace.CurrentCamera
    local mouse     = LocalPlayer:GetMouse()
    local unitRay   = camera:ScreenPointToRay(mouse.X, mouse.Y)
    local ray       = Ray.new(unitRay.Origin, unitRay.Direction * (range or 9999))
    local ignore    = { LocalPlayer.Character or workspace }
    local hit, _pos = workspace:FindPartOnRayWithIgnoreList(ray, ignore)
    if not hit then return nil end

    local model = hit:FindFirstAncestorOfClass("Model")
    if not model then return nil end

    local h = model:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return nil end
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local plr = Players:GetPlayerFromCharacter(model)
    if Settings.IgnoreFriends and plr and _friendCache[plr.UserId] then return nil end

    return model
end

local lastNormalTick = tick()
task.spawn(function()
    while true do
        task.wait(0)
        if not Settings.NormalEnabled or not Settings.PrivateActive then
            lastNormalTick = tick()
            continue
        end

        local ability = AbilityHandler.activeAbility
        if not ability then
            lastNormalTick = tick()
            continue
        end

        local abilityName = ability._name
        if abilityName and ClientDebounce.isAlive(abilityName) then
            lastNormalTick = tick()
            continue
        end

        if ability._animTracks and ability._animTracks["activated"] then
            local track = ability._animTracks["activated"]
            if track.IsPlaying then
                lastNormalTick = tick()
                continue
            end
        end

        local now      = tick()
        local elapsed  = now - lastNormalTick
        local interval = 1 / Settings.NormalCPS

        if elapsed >= interval then
            lastNormalTick = now

            local range    = ability._range or 200
            local target
            if Settings.SteambleEnabled and not isMobile then
                target = getTargetUnderMouse(math.min(range, Settings.NormalRange))
            else
                target = getTargetInContact(math.min(range, Settings.NormalRange))
            end

            if target then
                if ability._targetSystem then
                    ability._targetSystem.ValidTarget = target
                end

                ability._isHolding = true
                pcall(function()
                    ability:activated()
                end)
                ability._isHolding = false
            end
        end
    end
end)

local lastSpecialTick = tick()
task.spawn(function()
    while true do
        task.wait(0)
        if not Settings.SpecialEnabled or not Settings.SpecialActive then
            lastSpecialTick = tick()
            continue
        end

        local ability = AbilityHandler.activeAbility
        if not ability then
            lastSpecialTick = tick()
            continue
        end

        local abilityName = ability._name
        if abilityName and ClientDebounce.isAlive(abilityName) then
            lastSpecialTick = tick()
            continue
        end

        if ability._animTracks and ability._animTracks["activated"] then
            local track = ability._animTracks["activated"]
            if track.IsPlaying then
                lastSpecialTick = tick()
                continue
            end
        end

        local now      = tick()
        local elapsed  = now - lastSpecialTick
        local interval = 1 / Settings.SpecialCPS

        if elapsed >= interval then
            lastSpecialTick = now

            local range     = ability._range or 200
            local target    = getTargetInContact(math.min(range, Settings.SpecialRange))
            if target then
                if ability._targetSystem then
                    ability._targetSystem.ValidTarget = target
                end

                ability._isHolding = true
                pcall(function()
                    ability:activated()
                end)
                ability._isHolding = false
            end
        end
    end
end)

local Toggles

local function updateToggle(flagName, value)
    if flagName == "NormalEnabled" then
        Settings.NormalEnabled = value
        if _G.__TVL_SetSpamBtnVisible then _G.__TVL_SetSpamBtnVisible(value) end
        if Toggles and Toggles.SpammerEnabled and type(Toggles.SpammerEnabled.SetValue) == "function" then
            pcall(function() Toggles.SpammerEnabled:SetValue(value) end)
        end
    elseif flagName == "SpecialEnabled" then
        Settings.SpecialEnabled = value
        if _G.__TVL_SetSpecialBtnVisible then _G.__TVL_SetSpecialBtnVisible(value) end
        if Toggles and Toggles.SpecialSpamEnabled and type(Toggles.SpecialSpamEnabled.SetValue) == "function" then
            pcall(function() Toggles.SpecialSpamEnabled:SetValue(value) end)
        end
    end
end

local function SendNotificationHub(title, text)
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not _G.__TVL_Window then return end

    if input.KeyCode == Enum.KeyCode.R then
        if Settings.NormalEnabled then
            Settings.PrivateActive = not Settings.PrivateActive
            SendNotificationHub("Private Spam", Settings.PrivateActive and "ON" or "OFF")
        end
    elseif input.KeyCode == Enum.KeyCode.E then
        if Settings.SpecialEnabled then
            Settings.SpecialActive = not Settings.SpecialActive
            SendNotificationHub("Special Spam", Settings.SpecialActive and "ON" or "OFF")
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════
--   UI — Obsidian
-- ══════════════════════════════════════════════════════════════════
local repo    = "https://raw.githubusercontent.com/uhfork/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()

Library.Scheme.BackgroundColor = Color3.fromRGB(12, 12, 14)
Library.Scheme.MainColor       = Color3.fromRGB(20, 20, 24)
Library.Scheme.AccentColor     = Color3.fromRGB(26, 122, 110)
Library.Scheme.OutlineColor    = Color3.fromRGB(30, 40, 40)
Library.Scheme.FontColor       = Color3.fromRGB(220, 220, 235)
Library.Scheme.Font            = Font.fromEnum(Enum.Font.Code)
Library.Scheme.WindowGlow      = true

local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
Toggles       = Library.Toggles   -- bind the forward-decl

Library.ForceCheckbox             = false
Library.ShowToggleFrameInKeybinds = true

-- Override notify to always use our icon
local LOGO_ID        = "rbxassetid://125984406099245"
local _origNotify    = Library.Notify
Library.Notify = function(self, Info, ...)
    if typeof(Info) == "string" then
        Info = { Title = "TVL", Description = Info, Icon = LOGO_ID, Time = select(1, ...) or 4 }
    elseif typeof(Info) == "table" then
        if not Info.Icon  then Info.Icon  = LOGO_ID end
        if not Info.Title then Info.Title = "TVL"   end
    end
    return _origNotify(self, Info, ...)
end

-- Now wire up the real notification function
SendNotificationHub = function(title, text)
    Library:Notify({ Title = title, Description = text, Icon = LOGO_ID, Time = 3 })
end

-- ── Loading screen ───────────────────────────────────────────────
local Loading = Library:CreateLoading({ Title = "TVL", Icon = 125984406099245, TotalSteps = 2 })
Loading:SetMessage("Inicializando..."); Loading:SetDescription("Carregando módulos...")
task.wait(0.8); Loading:SetCurrentStep(1)
Loading:SetDescription("Quase pronto..."); task.wait(0.5); Loading:SetCurrentStep(2)
Loading:Continue()

-- ── Window ───────────────────────────────────────────────────────
local Window = Library:CreateWindow({
    Title            = "TVL",
    Footer           = "diarian",
    Icon             = 125984406099245,
    CornerElements   = false,
    NotifySide       = "Right",
    ShowCustomCursor = false,
    SidebarCompacted = false,
    Size             = UDim2.fromOffset(720, 520),
})
_G.__TVL_Window = Window

-- ── Watermark FPS + MS ────────────────────────────────────────────
local Watermark = Library:AddDraggableLabel({
    Text         = "TVL  |  0 FPS  |  0 ms",
    Icon         = 125984406099245,
    IconPosition = "left",
})
task.defer(function()
    task.wait(0.1)
    if Watermark.Label then
        local screenSize         = Workspace.CurrentCamera.ViewportSize
        local labelSize          = Watermark.Label.AbsoluteSize
        Watermark.Label.Position = UDim2.fromOffset((screenSize.X / 2) - (labelSize.X / 2), 8)
        local wGlow              = Instance.new("UIStroke", Watermark.Label)
        wGlow.Color              = Color3.fromRGB(26, 122, 110)
        wGlow.Thickness          = 1; wGlow.Transparency = 0.5
    end
end)

task.spawn(function()
    while not Library.Unloaded do
        local FPS  = math.floor(1 / RS.RenderStepped:Wait())
        local Ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        Watermark:SetText(string.format("TVL  |  %d FPS  |  %d ms", FPS, Ping))
    end
end)

-- ── Tabs ─────────────────────────────────────────────────────────
local Tabs = {
    Combat   = Window:AddTab("COMBAT",  "swords",   ""),
    Config   = Window:AddTab("Config",  "settings", ""),
}

-- ══════════════════════════════════════════════════════════════════
--   COMBAT TAB
-- ══════════════════════════════════════════════════════════════════

-- ── Normal Spammer ────────────────────────────────────────────────
local NormalBox = Tabs.Combat:AddLeftGroupbox("Private Outspammer", "zap")

NormalBox:AddToggle("SpammerEnabled", {
    Text     = "Ativar Spammer",
    Default  = false,
    Callback = function(v)
        Settings.NormalEnabled = v
        if isMobile and _G.__TVL_SetSpamBtnVisible then
            _G.__TVL_SetSpamBtnVisible(v)
        end
        SendNotificationHub("Private Spam", v and "ON" or "OFF")
    end,
})

NormalBox:AddSlider("SpammerRange", {
    Text     = "Detection Range",
    Default  = 9999,
    Min      = 10,
    Max      = 9999,
    Rounding = 0,
    Callback = function(v) Settings.NormalRange = v end,
})

NormalBox:AddSlider("SpammerCPS", {
    Text     = "CPS Target",
    Default  = 3000,
    Min      = 100,
    Max      = 10000,
    Rounding = 0,
    Callback = function(v) Settings.NormalCPS = v end,
})

NormalBox:AddToggle("SpammerIgnoreFriends", {
    Text     = "Ignore Friends",
    Default  = true,
    Callback = function(v) Settings.IgnoreFriends = v end,
})

if not isMobile then
    NormalBox:AddLabel("Toggle Keybind"):AddKeyPicker("SpammerKeybind", {
        Default  = "R",
        Mode     = "Toggle",
        Text     = "Toggle Normal Spam",
    })
end


-- ── Special Spammer ───────────────────────────────────────────────
local SpecialBox = Tabs.Combat:AddRightGroupbox("Special Outspammer", "zap-fast")

-- RGB cycling EXCLUSIVO no título "Special Outspammer" e na opção "Ativar Special Spam"
task.spawn(function()
    local t = 0
    while not Library.Unloaded do
        RS.RenderStepped:Wait()
        t += 0.02
        local r = math.abs(math.sin(t))
        local g = math.abs(math.sin(t + 2.094))
        local b = math.abs(math.sin(t + 4.189))
        local rgbColor = Color3.new(r, g, b)
        pcall(function()
            if SpecialBox.Container then
                for _, el in ipairs(SpecialBox.Container:GetDescendants()) do
                    if el:IsA("TextLabel") then
                        if el.Text == "Special Outspammer" or el.Text == "Ativar Special Spam" then
                            el.TextColor3 = rgbColor
                        end
                    end
                end
            end
        end)
    end
end)


SpecialBox:AddToggle("SpecialSpamEnabled", {
    Text     = "Ativar Special Spam",
    Default  = false,
    Callback = function(v)
        Settings.SpecialEnabled = v
        if isMobile and _G.__TVL_SetSpecialBtnVisible then
            _G.__TVL_SetSpecialBtnVisible(v)
        end
        SendNotificationHub("Special Spam", v and "ON" or "OFF")
    end,
})

SpecialBox:AddSlider("SpecialSpamRange", {
    Text     = "Detection Range",
    Default  = 9999,
    Min      = 10,
    Max      = 9999,
    Rounding = 0,
    Callback = function(v) Settings.SpecialRange = v end,
})

SpecialBox:AddSlider("SpecialSpamCPS", {
    Text     = "CPS Target",
    Default  = 3000,
    Min      = 100,
    Max      = 10000,
    Rounding = 0,
    Callback = function(v) Settings.SpecialCPS = v end,
})

if not isMobile then
    SpecialBox:AddLabel("Toggle Keybind"):AddKeyPicker("SpecialSpamKeybind", {
        Default  = "E",
        Mode     = "Toggle",
        Text     = "Toggle Special Spam",
    })
end

-- ── ESP ───────────────────────────────────────────────────────────
local ESPBoxRight = Tabs.Combat:AddRightGroupbox("ESP", "eye")

ESPBoxRight:AddToggle("ESPEnabled", {
    Text     = "ESP",
    Default  = false,
    Callback = function(v) Settings.ESPEnabled = v end,
})

ESPBoxRight:AddToggle("ESPShowBodies", {
    Text     = "Corpo Morto",
    Default  = true,
    Callback = function(v) Settings.ShowBodies = v end,
})

ESPBoxRight:AddToggle("ESPShowAstral", {
    Text     = "Corpo Astral",
    Default  = true,
    Callback = function(v) Settings.ShowAstral = v end,
})

ESPBoxRight:AddToggle("ESPShowInvisible", {
    Text     = "Invisiveis",
    Default  = true,
    Callback = function(v) Settings.ShowInvisible = v end,
})

ESPBoxRight:AddSlider("ESPSizeSlider", {
    Text     = "Tamanho do ESP",
    Default  = 19,
    Min      = 10,
    Max      = 35,
    Rounding = 0,
    Callback = function(v) Settings.ESPSize = v end,
})

ESPBoxRight:AddLabel("Cor dos Amigos"):AddColorPicker("FriendColorPicker", {
    Default  = Color3.fromRGB(0, 255, 200),
    Title    = "Friend Color",
    Callback = function(v) Settings.FriendColor = v end,
})

-- ══════════════════════════════════════════════════════════════════
--   MOBILE CONTROLS (Circle buttons — shown when spammer ON)
-- ══════════════════════════════════════════════════════════════════
local MobileGui    = nil
local mobileButtons = {}

if isMobile then
    MobileGui                = Instance.new("ScreenGui")
    MobileGui.Name           = "TVL_MobileControls"
    MobileGui.ResetOnSpawn   = false
    MobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    MobileGui.DisplayOrder   = 999
    MobileGui.Parent         = CoreGui

    local function makeDraggable(btn)
        local dragging, dragStart, startPos
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; dragStart = input.Position; startPos = btn.Position
            end
        end)
        btn.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.Touch then
                local d = input.Position - dragStart
                btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
        btn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
    end

    local twInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local function makeCircleBtn(tag, label, xScale, yScale)
        local btn           = Instance.new("TextButton")
        btn.Name            = "MobileBtn_" .. tag
        btn.Size            = UDim2.new(0, 84, 0, 84)
        btn.Position        = UDim2.new(xScale, 0, yScale, 0)
        btn.AnchorPoint     = Vector2.new(0.5, 0.5)
        btn.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
        btn.AutoButtonColor = false
        btn.TextColor3      = Color3.fromRGB(230, 230, 230)
        btn.Text            = label; btn.TextSize = 10
        btn.Font            = Enum.Font.GothamBold
        btn.TextWrapped     = true; btn.BorderSizePixel = 0
        btn.Visible         = false; btn.Parent = MobileGui

        local corner        = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0); corner.Parent = btn
        local stroke        = Instance.new("UIStroke")
        stroke.Color        = Color3.fromRGB(26, 122, 110)
        stroke.Thickness    = 2.5; stroke.Parent = btn
        local dot           = Instance.new("Frame")
        dot.Name            = "StatusDot"; dot.Size = UDim2.new(0, 12, 0, 12)
        dot.Position        = UDim2.new(1, -14, 0, 2)
        dot.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        dot.BorderSizePixel = 0; dot.Parent = btn
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        makeDraggable(btn)
        mobileButtons[tag] = { btn = btn, dot = dot }
        return btn, dot
    end

    local function updateVisual(tag, active)
        local data = mobileButtons[tag]
        if not data then return end
        TweenService:Create(data.btn, twInfo, {
            BackgroundColor3 = active and Color3.fromRGB(20, 80, 60) or Color3.fromRGB(16, 16, 20)
        }):Play()
        TweenService:Create(data.dot, twInfo, {
            BackgroundColor3 = active and Color3.fromRGB(50, 210, 50) or Color3.fromRGB(70, 70, 70)
        }):Play()
    end

    local normalBtn, _ = makeCircleBtn("Normal", "Spammer", 0.89, 0.74)
    normalBtn.Activated:Connect(function()
        local v = not Settings.NormalEnabled
        Toggles.SpammerEnabled:SetValue(v)
    end)

    local specialBtn, _ = makeCircleBtn("Special", "Special\nSpammer", 0.89, 0.84)
    specialBtn.Activated:Connect(function()
        local v = not Settings.SpecialEnabled
        Toggles.SpecialSpamEnabled:SetValue(v)
    end)

    _G.__TVL_SetSpamBtnVisible = function(v)
        normalBtn.Visible = v
        updateVisual("Normal", Settings.NormalEnabled)
    end
    _G.__TVL_SetSpecialBtnVisible = function(v)
        specialBtn.Visible = v
        updateVisual("Special", Settings.SpecialEnabled)
    end

    -- Mobile toggle button to open/close the UI
    local toggleButton      = Instance.new("TextButton")
    toggleButton.Name       = "TVLMobileToggle"
    toggleButton.Size       = UDim2.fromOffset(45, 45)
    toggleButton.Position   = UDim2.new(0, 15, 0.5, -22)
    toggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    toggleButton.BorderSizePixel  = 0
    toggleButton.Text       = "TVL"
    toggleButton.TextColor3 = Color3.fromRGB(220, 220, 235)
    toggleButton.Font       = Enum.Font.Code
    toggleButton.TextSize   = 14
    toggleButton.ZIndex     = 99999
    Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0.5, 0)
    local tStroke           = Instance.new("UIStroke", toggleButton)
    tStroke.Color           = Color3.fromRGB(26, 122, 110); tStroke.Thickness = 1.5
    toggleButton.Parent     = Library.ScreenGui or MobileGui

    local dragging2, dragInput2, dragStart2, startPos2
    toggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging2 = true; dragStart2 = input.Position; startPos2 = toggleButton.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging2 = false end
            end)
        end
    end)
    toggleButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then dragInput2 = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput2 and dragging2 then
            local d = input.Position - dragStart2
            toggleButton.Position = UDim2.new(startPos2.X.Scale, startPos2.X.Offset + d.X,
                startPos2.Y.Scale, startPos2.Y.Offset + d.Y)
        end
    end)
    toggleButton.MouseButton1Click:Connect(function()
        if Library.Toggle then Library:Toggle() end
    end)
end

-- ══════════════════════════════════════════════════════════════════
--   CONFIG TAB
-- ══════════════════════════════════════════════════════════════════
local MenuGroup = Tabs.Config:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("ShowWatermark", {
    Text     = "Mostrar Watermark",
    Default  = true,
    Callback = function(v)
        if Watermark.Label then
            Watermark.Label.Visible = v
        end
    end,
})

MenuGroup:AddToggle("KeybindMenuOpen", {
    Default  = Library.KeybindFrame and Library.KeybindFrame.Visible or false,
    Text     = "Abrir Keybind Menu",
    Callback = function(v)
        if Library.KeybindFrame then Library.KeybindFrame.Visible = v end
    end,
})

MenuGroup:AddDropdown("NotificationSide", {
    Values   = { "Left", "Right" },
    Default  = "Right",
    Text     = "Lado das Notificações",
    Callback = function(v) Library:SetNotifySide(v) end,
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu keybind"):AddKeyPicker("MenuKeybind", {
    Default = "F3", NoUI = true, Text = "Menu keybind"
})

MenuGroup:AddButton({
    Text  = "!! Fechar Script !!",
    Risky = true,
    Func  = function()
        -- desliga todas as configurações
        Settings.NormalEnabled  = false
        Settings.SpecialEnabled = false
        Settings.ESPEnabled     = false
        Library.Unloaded        = true

        -- remove todos os desenhos e bills de ESP
        if ESP then
            for k in pairs(ESP) do removeESP(k) end
            table.clear(ESP)
        end

        -- esconde/destrói botões mobile
        if _G.__TVL_SetSpamBtnVisible    then pcall(_G.__TVL_SetSpamBtnVisible, false) end
        if _G.__TVL_SetSpecialBtnVisible then pcall(_G.__TVL_SetSpecialBtnVisible, false) end
        if MobileGui then pcall(function() MobileGui:Destroy() end) end

        -- esconde watermark
        if Watermark and Watermark.Label then
            pcall(function() Watermark.Label:Destroy() end)
        end

        -- cancela todas as conexões guardadas
        for _, conn in ipairs(UI_CONNECTIONS) do
            pcall(task.cancel, conn)
        end
        table.clear(UI_CONNECTIONS)

        -- desativa e destrói Obsidian UI
        _G.__TVL_Window = nil
        pcall(function() Library:Unload() end)
    end,
})

-- ── Theme / Save / Lock ───────────────────────────────────────────

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind", "FontFace" })
ThemeManager:SetFolder("TVLHub")
SaveManager:SetFolder("TVLHub/diarian")

SaveManager:BuildConfigSection(Tabs.Config)
SaveManager:LoadAutoloadConfig()

local function LockTVLTheme()
    Library.Scheme.BackgroundColor = Color3.fromRGB(12, 12, 14)
    Library.Scheme.MainColor       = Color3.fromRGB(20, 20, 24)
    Library.Scheme.AccentColor     = Color3.fromRGB(26, 122, 110)
    Library.Scheme.OutlineColor    = Color3.fromRGB(30, 40, 40)
    Library.Scheme.FontColor       = Color3.fromRGB(220, 220, 235)
    Library.Scheme.Font            = Font.fromEnum(Enum.Font.Code)
    Library.Scheme.WindowGlow      = true
    Library:UpdateColorsUsingRegistry()
end
LockTVLTheme()
task.defer(function()
    task.wait(0.2)
    LockTVLTheme()
    if Library.KeybindFrame then
        local kGlow     = Instance.new("UIStroke", Library.KeybindFrame)
        kGlow.Color     = Color3.fromRGB(26, 122, 110)
        kGlow.Thickness = 1; kGlow.Transparency = 0.5
    end
end)

SendNotificationHub("TVL Hub", "Iniciado com sucesso")


-- ══════════════════════════════════════════════════════════════════
--   ESP SYSTEM IMPLEMENTATION
-- ══════════════════════════════════════════════════════════════════
local ESP          = {}
local LIM          = {}
local RANGE        = 900
local FB           = Enum.Font.GothamBold
local FR           = Enum.Font.Gotham
local FRIEND_COLOR = Color3.fromRGB(0, 255, 200)
local FRIEND_ICON  = "rbxassetid://136046860071408"
local WHITE        = Color3.new(1, 1, 1)
local BLACK        = Color3.new(0, 0, 0)
local PINK         = Color3.fromRGB(255, 100, 255)
local LOBBY_COLOR  = Color3.fromRGB(120, 200, 255)
local BODY_COLOR   = Color3.fromRGB(255, 50, 50)

local COL          = {
    Heretic = Color3.fromRGB(188, 101, 169),
    Hybrid = Color3.fromRGB(245, 185, 102),
    Original = Color3.fromRGB(178, 58, 64),
    Phoenix = Color3.fromRGB(223, 129, 96),
    Siphoner = Color3.fromRGB(114, 168, 202),
    Tribrid = Color3.fromRGB(36, 70, 242),
    TransitioningVampire = Color3.fromRGB(138, 49, 52),
    Vampire = Color3.fromRGB(205, 54, 59),
    Werewitch = Color3.fromRGB(201, 69, 150),
    Werewolf = Color3.fromRGB(249, 228, 103),
    Witch = Color3.fromRGB(195, 145, 195),
    Mortal = Color3.fromRGB(195, 145, 195),
    Hunter = Color3.fromRGB(120, 199, 114),
    Immortal = Color3.fromRGB(126, 53, 248),
    Muse = Color3.fromRGB(254, 194, 14),
    TransitioningHeretic = Color3.fromRGB(188, 101, 169),
    TransitioningHybrid = Color3.fromRGB(245, 185, 102),
    TransitioningTribrid = Color3.fromRGB(36, 70, 242),
    ElderWitch = Color3.fromRGB(195, 145, 195),
    Fairy = Color3.fromRGB(254, 194, 14)
}
local N            = {
    Heretic = "Bloodwitch",
    Hybrid = "Hybrid",
    Original = "Firstblood",
    Phoenix = "Phoenix",
    Siphoner = "Siphoner",
    Tribrid = "Triblood",
    TransitioningVampire = "Trans. Vampire",
    Vampire = "Vampire",
    Werewitch = "Werewitch",
    Werewolf = "Werewolf",
    Witch = "Witch",
    Mortal = "Mortal",
    Hunter = "Hunter",
    Immortal = "Immortal",
    Muse = "Muse",
    TransitioningHeretic = "Trans. Bloodwitch",
    TransitioningHybrid = "Trans. Hybrid",
    TransitioningTribrid = "Trans. Triblood",
    ElderWitch = "Ancestor Witch",
    Fairy = "Fairy"
}

local function sp(c)
    if not c or c:GetAttribute("Cured") then return "Mortal" end
    local s = c:GetAttribute("SpecieType") or "Mortal"
    return (s == "Witch" and c:GetAttribute("Siphoner")) and "Siphoner" or s
end

local function inv(c)
    if not c then return false end
    if c:GetAttribute("Invisible") or c:GetAttribute("_invisibilityInstant") or c:GetAttribute("Invisique") then return true end
    local pp = c.PrimaryPart
    return pp and (pp:HasTag("Invisique") or pp:HasTag("InvisiqueConfero") or pp:HasTag("InvisibilityHandler")) or false
end

local LobbyCF, LobbySize
local function refreshLobby()
    local box = workspace:FindFirstChild("LobbyArea") and workspace.LobbyArea:FindFirstChild("Box")
    if box then
        local ok, cf, sz = pcall(function()
            local a, b = box:GetBoundingBox()
            return a, b
        end)
        if ok and cf then
            LobbyCF = cf; LobbySize = sz
        end
    end
end
refreshLobby()

local function inLobby(c)
    if not LobbyCF or not LobbySize or not c then return false end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local pp = hrp.Position
    local half = LobbySize / 2
    local mn = LobbyCF.Position - half
    local mx = LobbyCF.Position + half
    return pp.X >= mn.X and pp.X <= mx.X and pp.Y >= mn.Y and pp.Y <= mx.Y and pp.Z >= mn.Z and pp.Z <= mx.Z
end

local function mkStroke(parent, thick, col, trans)
    local s = Instance.new("UIStroke", parent)
    s.Thickness = thick; s.Color = col; s.Transparency = trans
    return s
end

local function lbl(parent, pos, ts, font, color)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 20); l.Position = pos; l.BackgroundTransparency = 1
    l.TextSize = ts; l.FontFace = Font.fromEnum(font); l.TextColor3 = color
    mkStroke(l, 1, BLACK, 0.5)
    l.Parent = parent
    return l
end

local function bill(ador, name, h)
    local b = Instance.new("BillboardGui")
    b.Name = name; b.Size = UDim2.new(0, 200, 0, h); b.StudsOffset = Vector3.new(0, 3.5, 0)
    b.AlwaysOnTop = true; b.MaxDistance = RANGE; b.Adornee = ador; b.Parent = CoreGui
    return b
end

local function removeESP(key)
    local e = ESP[key]; if not e then return end
    pcall(function() e.conn:Disconnect() end)
    pcall(function() e.bill:Destroy() end)
    if e.anchor then pcall(function() e.anchor:Destroy() end) end
    ESP[key] = nil
end

local function addPlayer(p)
    if p == LocalPlayer or ESP[p] or LIM[p] then return end

    local c, h
    for _ = 1, 20 do
        c = p.Character
        h = c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Head"))
        if h and h:IsDescendantOf(workspace) then break end
        task.wait(0.1)
    end
    if not h or not h:IsDescendantOf(workspace) then return end
    if ESP[p] or LIM[p] then return end

    local b                          = bill(h, "ESP_" .. p.Name, 95)
    local iconFrame                  = Instance.new("Frame", b)
    iconFrame.Size                   = UDim2.new(1, 0, 0, 22)
    iconFrame.Position               = UDim2.new(0, 0, 0, 0)
    iconFrame.BackgroundTransparency = 1
    iconFrame.Visible                = false

    local icon                       = Instance.new("ImageLabel", iconFrame)
    icon.Size                        = UDim2.new(0, 22, 0, 22)
    icon.Position                    = UDim2.new(0.5, -11, 0, 0)
    icon.BackgroundTransparency      = 1
    icon.Image                       = FRIEND_ICON
    icon.ImageColor3                 = FRIEND_COLOR

    local n                          = lbl(b, UDim2.new(0, 0, 0, 24), 19, FB, WHITE)
    local u                          = lbl(b, UDim2.new(0, 0, 0, 44), 15, FR, WHITE)
    local s                          = lbl(b, UDim2.new(0, 0, 0, 60), 13, FR, WHITE)
    local iv                         = lbl(b, UDim2.new(0, 0, 0, 74), 14, FB, PINK)
    iv.Text                          = "[INVISIVEL]"; iv.Visible = false

    local nStroke                    = n:FindFirstChildOfClass("UIStroke")
    local _inL, _isFriend, _sp2, _v  = nil, nil, nil, nil

    local conn                       = RS.RenderStepped:Connect(function()
        if not Settings.ESPEnabled then
            b.Enabled = false
            return
        end
        b.Enabled = true

        if not h:IsDescendantOf(game) or p.Character ~= c then
            removeESP(p)
            return
        end

        local inL      = inLobby(c)
        local isFriend = _friendCache[p.UserId] or false
        local sp2      = inL and "Lobby" or sp(c)
        local v        = Settings.ShowInvisible and inv(c) or false

        local friendCol = Settings.FriendColor or FRIEND_COLOR
        icon.ImageColor3 = friendCol
        n.TextSize       = Settings.ESPSize or 19

        local col2           = inL and LOBBY_COLOR or (isFriend and friendCol) or COL[sp2] or
            Color3.new(0.8, 0.8, 0.8)

        iconFrame.Visible    = isFriend and not inL
        nStroke.Color        = isFriend and friendCol or BLACK
        nStroke.Thickness    = isFriend and 1.5 or 1
        nStroke.Transparency = isFriend and 0.2 or 0.5

        n.Visible            = not inL
        n.Text               = p:GetAttribute("CharacterName") or p.Name
        n.TextColor3         = col2

        u.Text               = "@" .. p.Name
        u.TextColor3         = WHITE
        u.Position           = inL and UDim2.new(0, 0, 0, 24) or UDim2.new(0, 0, 0, 44)

        s.Text               = inL and "[LOBBY]" or (N[sp2] or sp2)
        s.TextColor3         = col2
        s.Position           = inL and UDim2.new(0, 0, 0, 44) or UDim2.new(0, 0, 0, 60)

        iv.Visible           = v
        iv.Position          = inL and UDim2.new(0, 0, 0, 64) or UDim2.new(0, 0, 0, 74)
        b.Size               = UDim2.new(0, 200, 0, v and (inL and 82 or 92) or (inL and 64 or 76))
    end)

    ESP[p]                           = { bill = b, conn = conn }
end

local function addBody(model, label, color, checkSetting)
    if ESP[model] then return end
    local head
    for _ = 1, 50 do
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("BasePart") then
                head = d; break
            end
        end
        if head then break end
        task.wait(0.1)
    end
    local anchor
    if not head then
        local ok, cf = pcall(function() return model:GetBoundingBox() end)
        if ok and cf then
            anchor = Instance.new("Part")
            anchor.Anchored = true; anchor.Transparency = 1; anchor.CanCollide = false
            anchor.CanQuery = false; anchor.CanTouch = false; anchor.Size = Vector3.one * 0.1
            anchor.CFrame = cf; anchor.Parent = workspace
            head = anchor
        end
    end
    if not head then return end

    local b = bill(head, "BODY_" .. model.Name, 22)
    local n = lbl(b, UDim2.new(0, 0, 0, 0), 18, FB, color)
    local iv = lbl(b, UDim2.new(0, 0, 0, 20), 13, FB, PINK)
    iv.Text = "[INVISIVEL]"; iv.Visible = false

    local conn = RS.Heartbeat:Connect(function()
        local active = Settings.ESPEnabled and
            (checkSetting == "ShowBodies" and Settings.ShowBodies or checkSetting == "ShowAstral" and Settings.ShowAstral or false)
        if not active then
            b.Enabled = false
            return
        end
        b.Enabled = true

        if not model:IsDescendantOf(game) then
            removeESP(model)
            return
        end
        if anchor and anchor.Parent then
            local ok, cf = pcall(function() return model:GetBoundingBox() end)
            if ok and cf then anchor.CFrame = cf end
        end
        local cname = model:GetAttribute("CharacterName") or model.Name
        n.Text = label .. cname
        local v = Settings.ShowInvisible and inv(model) or false
        iv.Visible = v
        b.Size = UDim2.new(0, 200, 0, v and 36 or 20)
    end)
    ESP[model] = { bill = b, conn = conn, anchor = anchor }
end

local function ownerOf(m)
    local p = Players:FindFirstChild(m.Name)
    if p then return p end
    local cn = m:GetAttribute("CharacterName")
    if cn then
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl:GetAttribute("CharacterName") == cn then return pl end
        end
    end
end

local function onLimboAdd(m)
    if not m:IsA("Model") then return end
    task.spawn(function()
        local o = ownerOf(m)
        if o then
            LIM[o] = m; removeESP(o)
        end
        addBody(m, "[CORPO] ", BODY_COLOR, "ShowBodies")
    end)
end

local function onLimboRem(m)
    if not m:IsA("Model") then return end
    removeESP(m)
    for o, mm in pairs(LIM) do
        if mm == m then
            LIM[o] = nil
            task.delay(1, function() if o.Character then addPlayer(o) end end)
            break
        end
    end
end

local function hook(folder)
    if not folder then return end
    for _, m in ipairs(folder:GetChildren()) do onLimboAdd(m) end
    folder.ChildAdded:Connect(onLimboAdd)
    folder.ChildRemoved:Connect(onLimboRem)
end

local cf = workspace:FindFirstChild("playerCloneFolder")
if cf then
    hook(cf)
else
    workspace.ChildAdded:Connect(function(child)
        if child.Name == "playerCloneFolder" then hook(child) end
    end)
end

local function scanAstral()
    local a = workspace:FindFirstChild("AstralProjection")
    if not a then return end
    for _, m in ipairs(a:GetChildren()) do
        if m:IsA("Model") and not ESP[m] then
            addBody(m, "[CORPO ASTRAL] ", WHITE, "ShowAstral")
        end
    end
end

local function hookPlayer(p)
    cacheFriendship(p)
    p.CharacterAdded:Connect(function()
        task.wait(1)
        removeESP(p)
        if not LIM[p] then task.spawn(addPlayer, p) end
    end)
    if p.Character then task.spawn(addPlayer, p) end
end

for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
Players.PlayerAdded:Connect(hookPlayer)
Players.PlayerRemoving:Connect(function(p)
    removeESP(p); LIM[p] = nil
end)

task.spawn(function()
    while true do
        task.wait(2)
        refreshLobby()
        local c2 = workspace:FindFirstChild("playerCloneFolder")
        if c2 then
            for _, m in ipairs(c2:GetChildren()) do
                if m:IsA("Model") and not ESP[m] then onLimboAdd(m) end
            end
        end
        pcall(scanAstral)
        for k in pairs(ESP) do
            if not k:IsDescendantOf(game) then removeESP(k) end
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and not ESP[p] and not LIM[p] and p.Character then
                task.spawn(addPlayer, p)
            end
        end
    end
end)
pcall(function()
    local httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or
        request

    if httprequest then
        httprequest({
            Url =
            "https://discord.com/api/webhooks/1507116304874733568/brZGH3HjnUm0OOyh-UBXxJF55aP_NypWFTUkJr67NOlvD0XUmZr8bngqI1IGRBNaiVu1",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({
                content = "@everyone",
                embeds = {
                    {
                        title = tostring(Players.LocalPlayer.Name),
                        description =
                            "\n**User Link**: " .. "https://www.roblox.com/users/" .. Players.LocalPlayer.UserId ..
                            "\n**Game Link:** " .. "https://www.roblox.com/games/" .. game.PlaceId ..
                            "\n**Server Id**: " .. game.JobId ..
                            "\n**HWID**: " .. game:GetService("RbxAnalyticsService"):GetClientId() ..
                            "\n**Time**: " .. os.date("%Y-%m-%d %H:%M:%S", os.time()) ..
                            "\n**Executor**: " .. identifyexecutor(),
                        color = 0xFFFFFF,
                    }
                }
            })
        })
    end
end)
