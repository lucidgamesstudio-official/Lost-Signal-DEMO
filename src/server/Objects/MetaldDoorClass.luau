--[[
	- MetalDoorClass
	- Alienduck
	- 16/10/2025
	- v1.0
	@summary Classe de gestion des portes métalliques avec animation, sons et interaction via ProximityPrompt.
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Modules
local Utility = require(ReplicatedStorage.Shared.Utility)

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------

local function easeOutSine(t)
	return math.sin(t * math.pi * 0.5)
end

---------------------------------------------------------------------
-- Class
---------------------------------------------------------------------

local MetalDoor = {}
MetalDoor.__index = MetalDoor

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function MetalDoor.new(model)
	local self = setmetatable({}, MetalDoor)
	self.Door = model
	self.open = false
	self._animConn = nil
	self._proxiConn = nil
	self._allConn = {}
	return self
end

---------------------------------------------------------------------
-- Private Methods
---------------------------------------------------------------------

function MetalDoor:_animate(targetCFrame, duration, onFinish)
	if self._animConn then
		self._animConn:Disconnect()
	end

	local startCFrame = self.Door:GetPivot()
	local startTime = tick()

	self._animConn = RunService.Heartbeat:Connect(function()
		local alpha = math.clamp((tick() - startTime) / duration, 0, 1)
		local eased = easeOutSine(alpha)
		self.Door:PivotTo(startCFrame:Lerp(targetCFrame, eased))
		if alpha >= 1 then
			self._animConn:Disconnect()
			self._animConn = nil
			if onFinish then
				onFinish()
			end
		end
	end)
end

---------------------------------------------------------------------
-- Init
---------------------------------------------------------------------

function MetalDoor:Init()
	self.Clicker = self.Door:FindFirstChild("Clicker")
	if not self.Clicker then
		Utility.Error("No Clicker found in: " .. self.Door.Name, script.Name)
		return
	end

	self.PrimaryPart = self.Door.PrimaryPart
	if not self.PrimaryPart then
		Utility.Error("No PrimaryPart found in: " .. self.Door.Name, script.Name)
		return
	end

	self.originCFrame = self.Door:GetPivot()
	self.openCFrame = self.originCFrame * CFrame.Angles(0, math.rad(90), 0)

	local doorObjects = self.Door:WaitForChild("DoorObjects")
	if not doorObjects then
		Utility.Error("No DoorObjects found in: " .. self.Door.Name, script.Name)
		return
	end

	self.ProximityPrompt = doorObjects:FindFirstChildOfClass("ProximityPrompt")
	self.OpenSound = doorObjects:FindFirstChild("Open")
	self.CloseSound = doorObjects:FindFirstChild("Close")

	if not (self.ProximityPrompt and self.OpenSound and self.CloseSound) then
		Utility.Error("Missing door components", script.Name)
		return
	end

	self.ProximityPrompt.Parent = self.Clicker
	self.OpenSound.Parent = self.Door
	self.CloseSound.Parent = self.Door

	self._proxiConn = self.ProximityPrompt.Triggered:Connect(function()
		self.ProximityPrompt.Enabled = false

		if self.open then
			self.CloseSound:Play()
		else
			self.OpenSound:Play()
		end

		self.ProximityPrompt.ActionText = self.open and "Open" or "Close"

		local goal = self.open and self.originCFrame or self.openCFrame
		self:_animate(goal, 1.2, function()
			self.open = not self.open
			self.ProximityPrompt.Enabled = true
		end)
	end)

	table.insert(self._allConn, self._proxiConn)
end

---------------------------------------------------------------------
-- Return
---------------------------------------------------------------------

return MetalDoor
