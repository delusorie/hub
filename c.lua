if not game:IsLoaded() then
    game.Loaded:Wait()
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

pcall(function()
    local DeviceInfo = require(ReplicatedStorage.ModuleScripts.DeviceInfo)
    if DeviceInfo and DeviceInfo.deviceType then
        local originalSet = DeviceInfo.deviceType.set
        DeviceInfo.deviceType.set = function(self, value)
            return originalSet(self, "console")
        end
        DeviceInfo.deviceType:set("console")
    end
end)

pcall(function()
    local ToServer = ReplicatedStorage:WaitForChild("Remotes")
        :WaitForChild("GameServices")
        :WaitForChild("ToServer")

    local ToClient = ReplicatedStorage:WaitForChild("Remotes")
        :WaitForChild("GameServices")
        :WaitForChild("ToClient")

    local ReportDevice = ToServer:WaitForChild("ReportDevice")
    local IsConsolePlayer = ToClient:WaitForChild("IsConsolePlayer")

    IsConsolePlayer.OnClientInvoke = function()
        return true
    end

    LocalPlayer:SetAttribute("Device", "console")
    ReportDevice:FireServer("console")

    LocalPlayer:GetAttributeChangedSignal("Device"):Connect(function()
        if LocalPlayer:GetAttribute("Device") ~= "console" then
            LocalPlayer:SetAttribute("Device", "console")
        end
    end)

    task.spawn(function()
        while true do
            pcall(function()
                ReportDevice:FireServer("console")
                IsConsolePlayer.OnClientInvoke = function()
                    return true
                end
                LocalPlayer:SetAttribute("Device", "console")
            end)
            task.wait(2)
        end
    end)
end)
