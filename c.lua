--========================================================
-- PARTE 1 - AUTOFIGHTBACK
--========================================================
do
	local cloneref = cloneref or function(v)
		return v
	end

	local clonefunction = clonefunction or function(v)
		return v
	end

	local SETTINGS = {
		Enabled = true,
		ToggleKey = Enum.KeyCode.F6,
		SpamInterval = 0.03,
	}

	local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")

	local NetworkLib = clonefunction(require)(ReplicatedStorage:WaitForChild("Network"))

	local function getRemote(name)
		local networkFolder = ReplicatedStorage:WaitForChild("Network", 10)
		return networkFolder and networkFolder:WaitForChild(name, 10)
	end

	local FightBackRemote = getRemote("FightBack")
	local LocalPlayer = Players.LocalPlayer

	local CLASH_FLAGS = {
		HoldingOn = true,
		InExecution = true,
		NeckSnap = true,
		HeadCrushed = true,
		Executed = true,
	}

	local function inClashState()
		local character = LocalPlayer.Character

		if not character then
			return false
		end

		for flag in CLASH_FLAGS do
			if character:FindFirstChild(flag) then
				return true
			end
		end

		return false
	end

	local SkillCheck = clonefunction(require)(
		ReplicatedStorage
			:WaitForChild("Libraries")
			:WaitForChild("SkillCheck")
	)

	local originalStart = SkillCheck.Start
	local enabled = SETTINGS.Enabled

	local GREAT_OFFSET = 25

	SkillCheck.Start = function(self, ...)
		local result = originalStart(self, ...)

		if self.Destroyed
			or not self.Active
			or not self.CheckZone
			or not self.Needle then
			return result
		end

		if not enabled or self.CooldownActive then
			return result
		end

		self.Needle.Rotation =
			self.CheckZone.Rotation - GREAT_OFFSET

		self:_resolve()

		return result
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end

		if input.KeyCode == SETTINGS.ToggleKey then
			enabled = not enabled

			print(
				"[AutoFightback] "
					.. (enabled and "ATIVADO" or "DESATIVADO")
			)
		end
	end)

	task.spawn(function()
		while true do
			if enabled and inClashState() then
				if FightBackRemote then
					FightBackRemote:FireServer()
				elseif NetworkLib then
					pcall(function()
						NetworkLib:FireServer("FightBack")
					end)
				end

				task.wait(SETTINGS.SpamInterval)
			else
				task.wait(0.1)
			end
		end
	end)
end


--========================================================
-- PARTE 2 - ABILITY SPAM
--========================================================
do
	local RS, CS, UIS =
		game:GetService("ReplicatedStorage"),
		game:GetService("CollectionService"),
		game:GetService("UserInputService")

	local RunS, SG, LP =
		game:GetService("RunService"),
		game:GetService("StarterGui"),
		game:GetService("Players").LocalPlayer

	local KEY = Enum.KeyCode.F
	local RANGE = 350

	local INTERVAL = 0
	local PACK = 100
	local RESPECT_CD = false

	local Trigger =
		RS:WaitForChild("Network")
			:WaitForChild("AbilityTrigger")

	local SUP = {
		Area = 1,
		Hit = 1,
		Click = 1,
		Hold = 1,
		DualHold = 1,
	}

	local NAMES = {
		"Equip",
		"Unequip",
		"SetTarget",
	}

	local F = {}
	local T = {}

	local function add(m)
		if m:IsA("Model") then
			T[m] = true
		end
	end

	for _, m in CS:GetTagged("Target") do
		add(m)
	end

	CS:GetInstanceAddedSignal("Target"):Connect(add)

	CS:GetInstanceRemovedSignal("Target"):Connect(function(m)
		T[m] = nil
	end)

	local function load(gc)
		pcall(function()
			local env = getsenv(RS.Scene.Player.UIs)

			for _, k in NAMES do
				F[k] = rawget(env, k)
			end
		end)

		if gc and not next(F) then
			pcall(function()
				for _, f in getgc() do
					local n =
						type(f) == "function"
						and debug.info(f, "n")

					if table.find(NAMES, n) then
						local ok, s = pcall(function()
							return getfenv(f).script
						end)

						if ok and s and s.Name == "UIs" then
							F[n] = f
						end
					end
				end
			end)
		end
	end

	local fn
	local idx
	local nxt = 0

	local function equipped()
		if not idx then
			if os.clock() < nxt then
				return
			end

			nxt = os.clock() + 0.25

			for _, k in NAMES do
				if F[k] then
					for i, v in pairs(debug.getupvalues(F[k])) do
						if type(v) == "table"
							and type(v.Name) == "string"
							and type(v.Data) == "table" then

							fn = F[k]
							idx = i

							return v
						end
					end
				end
			end

			return
		end

		local a, b = debug.getupvalue(fn, idx)

		local v =
			type(a) == "table"
			and a
			or b

		if type(v) == "table"
			and type(v.Data) == "table" then

			return v
		end

		return nil
	end

	local function pick(root, range)
		local cam = workspace.CurrentCamera
		local m = UIS:GetMouseLocation()
		local rp = root.Position
		local me = LP.Character

		local best
		local bs = math.huge

		for t in T do
			local pp = t.PrimaryPart

			local h =
				pp
				and t ~= me
				and t:FindFirstChildOfClass("Humanoid")

			if h
				and h.Health > 0
				and (pp.Position - rp).Magnitude <= range
				and t:FindFirstChild("CharacterValues") then

				local p, on =
					cam:WorldToViewportPoint(pp.Position)

				local dx = p.X - m.X
				local dy = p.Y - m.Y

				local dist = dx * dx + dy * dy

				if on
					and p.Z > 0
					and dist < bs then

					best = t
					bs = dist
				end
			end
		end

		return best
	end

	local last = 0
	local ceq
	local key
	local larg
	local pack

	local function step()
		local c = LP.Character

		local root =
			c and c.PrimaryPart

		local h =
			c and c:FindFirstChildOfClass("Humanoid")

		local eq =
			root
			and h
			and h.Health > 0
			and equipped()

		if not eq
			or not SUP[eq.Data.Type]
			or os.clock() - last < INTERVAL then
			return
		end

		local d = eq.Data
		local n = eq.Name

		if eq ~= ceq then
			ceq = eq
			key = n:gsub("[^%w_]", "_")
		end

		if RESPECT_CD then
			local cd =
				LP:FindFirstChild("Cooldowns")

			local e =
				cd and cd:GetAttribute(key)

			if e
				and workspace:GetServerTimeNow() < e then
				return
			end

			if d.Mana then
				local cv =
					c:FindFirstChild("CharacterValues")

				local mv =
					cv
					and cv:FindFirstChild(
						d.ManaType or "Magic"
					)

				if not mv
					or mv.Value < d.Mana then
					return
				end
			end
		end

		local t =
			d.Type ~= "Area"
			and pick(
				root,
				d.Magnitude or RANGE
			)

		if d.Type ~= "Area" and not t then
			return
		end

		last = os.clock()

		local arg =
			t
			and (
				d.Type == "Hit"
					and CFrame.new(
						t.PrimaryPart.Position
					)
					or t
			)

		if arg ~= larg then
			larg = arg
			pack = table.create(PACK, arg)
		end

		Trigger:FireServer(
			n,
			table.unpack(pack)
		)
	end

	local conn

	UIS.InputBegan:Connect(function(i, gpe)
		if gpe or i.KeyCode ~= KEY then
			return
		end

		if conn then
			conn:Disconnect()
			conn = nil
		else
			if not next(F) then
				task.spawn(load, true)
			end

			conn = RunS.Heartbeat:Connect(function()
				if not pcall(step) then
					conn:Disconnect()
					conn = nil
				end
			end)
		end

		pcall(
			SG.SetCore,
			SG,
			"SendNotification",
			{
				Title = conn
						and "Ativado"
						or "Desativado",
				Text = "",
				Duration = 1.5,
			}
		)
	end)

	load(false)
end
