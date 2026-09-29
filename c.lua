local cloneref = cloneref or function(v)
	return v
end

local clonefunction = clonefunction or function(v)
	return v
end

local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))

local SkillCheck = clonefunction(require)(
	ReplicatedStorage
		:WaitForChild("Libraries")
		:WaitForChild("SkillCheck")
)

local originalStart = SkillCheck.Start
local connections = setmetatable({}, { __mode = "k" })

SkillCheck.Start = function(self, ...)
	local old = connections[self]

	if old then
		old:Disconnect()
		connections[self] = nil
	end

	local result = originalStart(self, ...)

	if self.Destroyed
		or not self.Active
		or not self.CheckZone
		or not self.Needle then
		return result
	end

	local targetRotation = self.CheckZone.Rotation - 26.5
	local connection

	connection = self.Needle
		:GetPropertyChangedSignal("Rotation")
		:Connect(function()

			if self.Destroyed or not self.Active then
				if connection then
					connection:Disconnect()
				end

				connections[self] = nil
				return
			end

			if self.Needle.Rotation < targetRotation then
				return
			end

			if connection then
				connection:Disconnect()
			end

			connections[self] = nil

			if not self.Destroyed
				and self.Active
				and not self.CooldownActive then

				self:_resolve()
			end
		end)

	connections[self] = connection

	return result
end
