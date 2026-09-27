setthreadidentity(8)

local cloneref = cloneref or function(obj) return obj end

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/sametexe001/sametlibs/main/nexonix/Library.lua"))()

Library.Animation.Time = 0.15
Library.Theme["Accent"] = Color3.fromRGB(14, 28, 55)

local Window = Library:Window({
    Logo = "rbxassetid://94733361910796"
})

-- esconde o botão Open/Close nativo da lib
task.defer(function()
    local openCloseBtn = Window.Items["OpenClose"]
    if openCloseBtn and openCloseBtn.Instance then
        openCloseBtn.Instance.Visible = false
    end
end)

local Page = Window:Page({ Icon = "rbxassetid://9405931578" })
local MergeSection = Page:Section({ Name = "Merge Exploits", Side = 1 })
local ConfigSection = Page:Section({ Name = "Config", Side = 2 })

local SavedChannelRemote = nil
local RemetenteChannel = "Nenhum"
local SavedInspireRemote = nil
local RemetenteInspire = "Nenhum"

task.spawn(function()
    for _, obj in pairs(getgc(true)) do
        if type(obj) == "table" and rawget(obj, "requestPrompt") then
            local isChannel = rawget(obj, "setChanneling") ~= nil
            local isInspire = rawget(obj, "setInspiring") ~= nil
            local originalPrompt = rawget(obj, "requestPrompt")

            local hookFunc = newcclosure(function(invokerName, statAmount, acceptRemote)
                if acceptRemote then
                    local safeRemote = cloneref(acceptRemote)
                    if isChannel then
                        SavedChannelRemote = safeRemote
                        RemetenteChannel   = tostring(invokerName)
                        print("[✓] Channel salvo de: " .. tostring(invokerName))
                    elseif isInspire then
                        SavedInspireRemote = safeRemote
                        RemetenteInspire   = tostring(invokerName)
                        print("[✓] Inspire salvo de: " .. tostring(invokerName))
                    else
                        SavedChannelRemote = safeRemote
                        RemetenteChannel   = tostring(invokerName)
                    end
                end
                if typeof(originalPrompt) == "function" then
                    return originalPrompt(invokerName, statAmount, acceptRemote)
                end
            end)

            setstackhidden(hookFunc, true)
            rawset(obj, "requestPrompt", hookFunc)
        end
    end
end)

local MagicStatusLabel = MergeSection:Label({
    Name = "Channel: Nenhum\nInspire: Nenhum"
})

task.spawn(function()
    while task.wait(1) do
        if MagicStatusLabel then
            pcall(function()
                MagicStatusLabel:SetText(
                    "Channel: " .. RemetenteChannel ..
                    "\nInspire: " .. RemetenteInspire
                )
            end)
        end
    end
end)

MergeSection:Button({
    Name = "Force Accept Channel",
    Callback = newcclosure(function()
        if SavedChannelRemote then
            pcall(function()
                SavedChannelRemote:FireServer()
            end)
            Library:Notification("Usou Channel de " .. RemetenteChannel, 2, Color3.fromRGB(78, 95, 255))
        else
            Library:Notification("Nenhum Channel salvo!", 2, Color3.fromRGB(255, 0, 0))
        end
    end)
})

MergeSection:Button({
    Name = "Force Accept Inspire",
    Callback = newcclosure(function()
        if SavedInspireRemote then
            pcall(function()
                SavedInspireRemote:FireServer()
            end)
            Library:Notification("Usou Inspire de " .. RemetenteInspire, 2, Color3.fromRGB(78, 95, 255))
        else
            Library:Notification("Nenhum Inspire salvo!", 2, Color3.fromRGB(255, 0, 0))
        end
    end)
})

local RessurectSection = Page:Section({ Name = "Ressurect", Side = 1 })

local function getSelfRessurectRemote()
    local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local npcService = remotes and remotes:FindFirstChild("NPCService")
    local toServer = npcService and npcService:FindFirstChild("ToServer")
    local remote = toServer and toServer:FindFirstChild("ConfirmFerrymanResurrection")
    return remote and cloneref(remote) or nil
end

RessurectSection:Button({
    Name = "Self Ressurect",
    Callback = newcclosure(function()
        local remote = getSelfRessurectRemote()
        if remote then
            local ok, err = pcall(function()
                if remote:IsA("RemoteFunction") then
                    return remote:InvokeServer()
                else
                    return remote:FireServer()
                end
            end)
            if ok then
                Library:Notification("ConfirmFerrymanResurrection enviado!", 2, Color3.fromRGB(78, 95, 255))
            else
                Library:Notification("Erro ao enviar ressurect!", 2, Color3.fromRGB(255, 0, 0))
            end
        else
            Library:Notification("Remote de Ressurect não encontrado!", 2, Color3.fromRGB(255, 0, 0))
        end
    end)
})

local CloseKey = Enum.KeyCode.RightControl
local UserInputService = cloneref(game:GetService("UserInputService"))
local toggleHotkeyEnabled = true

ConfigSection:Toggle({
    Name = "Ativar Tecla Ocultar/Abrir (RightControl)",
    Default = true,
    Callback = newcclosure(function(value)
        toggleHotkeyEnabled = value
    end)
})

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if not toggleHotkeyEnabled then return end
    if input.KeyCode == CloseKey then
        Window:SetOpen(not Window.IsOpen)
    end
end)

ConfigSection:Button({
    Name = "Fechar Script",
    Callback = newcclosure(function()
        pcall(function() Library:Exit() end)
    end)
})

print("--meigas--")
Library:Notification("mas que pronta!", 3, Color3.fromRGB(78, 95, 255))
