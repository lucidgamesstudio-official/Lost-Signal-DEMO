-- Object
local MetalDoor = {}
MetalDoor.__index = MetalDoor

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Modules
local Utility = require(ReplicatedStorage.Shared.Utility)

-- Types
export type MetalDoorType = {
	-- Public properties
	Door: Model,
	Clicker: BasePart,
	PrimaryPart: BasePart,
	ProximityPrompt: ProximityPrompt,
	OpenSound: Sound,
	CloseSound: Sound,

	-- Private properties
	open: boolean,
	originCFrame: CFrame,
	openCFrame: CFrame,
	_animConn: RBXScriptConnection?,
	_proxiConn: RBXScriptConnection?,
	_allConn: { RBXScriptConnection | thread },

	-- Public methods
	new: (model: Model) -> MetalDoorType,
	Init: (self: MetalDoorType) -> (),

	-- Private methods
	_animate: (self: MetalDoorType, targetCFrame: CFrame, duration: number, onFinish: () -> ()) -> (),
}

--=====================================
-- HELPERS
--=====================================

-- Interpolation avec easing sine-out
local function easeOutSine(t)
	return math.sin(t * math.pi * 0.5)
end

--=====================================
-- METHODS
--=====================================

-- Constructor
function MetalDoor.new(model: Model): MetalDoorType
	local self = {} :: MetalDoorType
	self = setmetatable(self, MetalDoor)
	self.Door = model
	self.open = false
	self._animConn = nil
	self._proxiConn = nil
	self._allConn = {}
	return self
end

function MetalDoor:_animate(targetCFrame: CFrame, duration: number, onFinish: () -> ())
	if self._animConn then
		self._animConn:Disconnect()
	end

	local startCFrame = self.Door:GetPivot()
	local startTime = tick()

	self._animConn = RunService.Heartbeat:Connect(function()
		local alpha = math.clamp((tick() - startTime) / duration, 0, 1)
		local eased = easeOutSine(alpha)
		local cf = startCFrame:Lerp(targetCFrame, eased)
		self.Door:PivotTo(cf)
		if alpha >= 1 then
			self._animConn:Disconnect()
			self._animConn = nil
			onFinish()
		end
	end)
end

function MetalDoor.Init(self: MetalDoorType)
	self.Clicker = self.Door:FindFirstChild("Clicker") :: BasePart
	if not self.Clicker then
		Utility.Error("No Clicker found in: " .. self.Door.Name, script.Name)
		return
	end
	self.PrimaryPart = self.Door.PrimaryPart :: BasePart
	if not self.PrimaryPart then
		Utility.Error("No primaryPart found in: " .. self.Door.Name, script.Name)
		return
	end

	self.originCFrame = self.Door:GetPivot()
	self.openCFrame = self.originCFrame * CFrame.Angles(0, math.rad(90), 0)

	local DoorObjects: Folder = self.Door:WaitForChild("DoorObjects") :: Folder
	if not DoorObjects then
		Utility.Error("No DoorObjects found in: " .. self.Door.Name, script.Name)
	end
	self.ProximityPrompt = DoorObjects:FindFirstChildOfClass("ProximityPrompt") :: ProximityPrompt
	self.OpenSound = DoorObjects:FindFirstChild("Open") :: Sound
	self.CloseSound = DoorObjects:FindFirstChild("Close") :: Sound

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

		local goalCFrame = self.open and self.originCFrame or self.openCFrame
		self:_animate(goalCFrame, 1.2, function()
			self.open = not self.open
			self.ProximityPrompt.Enabled = true
		end)
	end)
	table.insert(self._allConn, self._proxiConn :: RBXScriptConnection)
end

return MetalDoor
