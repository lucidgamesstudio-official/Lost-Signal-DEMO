-- Object
local MetalDoor = {}
MetalDoor.__index = MetalDoor

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Utility = require(ReplicatedStorage.Shared.Utility)

-- Types
export type MetalDoorType = {
	-- Public properties
	Door: Model,
	PrimaryPart: BasePart,
	ProximityPrompt: ProximityPrompt,
	OpenSound: Sound,
	CloseSound: Sound,

	-- Private properties
	open: boolean,
    originCFrame: CFrame,
    openCFrame: CFrame,
	_proxiConn: RBXScriptConnection?,
	_allConnections: { RBXScriptConnection | thread },

	-- Public functions
	new: (Model) -> MetalDoorType,
}

-- Constructor
function MetalDoor.new(model: Model): MetalDoorType
	local self = {} :: MetalDoorType
	self = setmetatable(self, MetalDoor)

	-- Public
	self.Door = model
	self.open = false

	-- Private
	self._proxiConn = nil
    self._allConnections = {}

	return self
end

function MetalDoor.Init(self: MetalDoorType)
	self.PrimaryPart = self.Door.PrimaryPart :: BasePart
	if not self.PrimaryPart then
		Utility.Error("No primaryPart found in: " .. self.Door.Name, script.Name)
		return
	end
    self.originCFrame = self.PrimaryPart.CFrame
    self.openCFrame = self.originCFrame * CFrame.Angles(0, math.rad(120), 0)
	local DoorObjects: Folder = self.Door:WaitForChild("DoorObjects") :: Folder
	if not DoorObjects then
		Utility.Error("No DoorObjects found in: " .. self.Door.Name, script.Name)
		return
	end
	self.ProximityPrompt = DoorObjects:FindFirstChildOfClass("ProximityPrompt") :: ProximityPrompt
	if not self.ProximityPrompt then
		Utility.Error("No ProximityPrompt found in: " .. self.Door.Name, script.Name)
		return
	end
	self.ProximityPrompt.Parent = self.Door
	self.OpenSound = DoorObjects:FindFirstChild("Open") :: Sound
	if not self.OpenSound then
		Utility.Error("No OpenSound found in: " .. DoorObjects.Name, script.Name)
		return
	end
	self.OpenSound.Parent = self.Door
	self.CloseSound = DoorObjects:FindFirstChild("Close") :: Sound
	if not self.CloseSound then
		Utility.Error("No CloseSound found in: " .. DoorObjects.Name, script.Name)
		return
	end
	self.CloseSound.Parent = self.Door

	-- Connections
	self.ProximityPrompt.Triggered:Connect(function(player: Player)
		if self.open then
			self.CloseSound:Play()
		else
			self.OpenSound:Play()
		end
        local rad: number = self.open and math.rad(-5) or math.rad(5)
        local cframe: CFrame = CFrame.Angles(0, rad, 0)
		self.ProximityPrompt.ActionText = self.open and "Open" or "Close"
		task.spawn(function ()
            self.ProximityPrompt.Enabled = false
            for i = 1, 20 do
                self.Door:PivotTo(self.PrimaryPart.CFrame * cframe)
                task.wait()
            end
            self.ProximityPrompt.Enabled = true
            self.open = not self.open
		end)
	end)
end

return MetalDoor