--[[
	- Inputs
	- Alienduck
	- 16/10/2025
	- v1.0
]]

-- Object
local Inputs = {}
Inputs.__index = Inputs

-- Services
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Inventory = require(script.Parent.Inventory)
local Utility = require(ReplicatedStorage.Shared.Utility)
local InputActions = require(ReplicatedStorage.Shared.Utils.InputActions)

-- Constants
Inputs.CONTEXTS = {
	NORMAL = "NORMAL",
	CINEMATIC = "CINEMATIC",
	DEAD = "DEAD",
}

Inputs.ACTIONS = {
	SPRINT = "SPRINT",
	CROUCH = "CROUCH",
	ACTION = "ACTION",
	INVENT = "INVENT",
	UEQUIP = "UEQUIP",
	SELECT_SLOT_1 = "SELECT_SLOT_1",
	SELECT_SLOT_2 = "SELECT_SLOT_2",
	SELECT_SLOT_3 = "SELECT_SLOT_3",
}

-- Typing
export type InputsType = {
	Inventory: Inventory.PlayerInventoryType?,
	Connections: { RBXScriptConnection },
	RemoteFolder: Folder,
	StartSprintRemote: RemoteEvent,
	StopSprintRemote: RemoteEvent,
	StartCrouchRemote: RemoteEvent,
	StopCrouchRemote: RemoteEvent,
	ActionRemote: RemoteEvent,
	SendConnRemote: RemoteEvent,
	EquipToolRemote: RemoteEvent,
	UnequipToolRemote: RemoteEvent,

	new: (inventory: Inventory.PlayerInventoryType) -> InputsType,
	SetupRemotes: (self: InputsType) -> (),
	RegisterConnection: (self: InputsType, conn: RBXScriptConnection) -> (),
	TryEquipSlot: (self: InputsType, slotIndex: number) -> (),
	BindInputs: (self: InputsType) -> (),
	Destroy: (self: InputsType) -> (),
}

-- Constructor
function Inputs.new(inventory: Inventory.PlayerInventoryType): InputsType
	local self = setmetatable({}, Inputs)

	self.Inventory = inventory
	self.Connections = {}
	self.RemoteFolder = Utility.CreateFolder("RemoteEvents")

	self:SetupRemotes()
	self:BindInputs()
	InputActions.EnableContext(Inputs.CONTEXTS.NORMAL)

	return self
end

-- Methods

-- Create RemoteEvents
function Inputs:SetupRemotes()
	self.StartSprintRemote = Utility.CreateRemoteEvent("startSprint", self.RemoteFolder)
	self.StopSprintRemote = Utility.CreateRemoteEvent("stopSprint", self.RemoteFolder)
	self.StartCrouchRemote = Utility.CreateRemoteEvent("startCrouch", self.RemoteFolder)
	self.StopCrouchRemote = Utility.CreateRemoteEvent("stopCrouch", self.RemoteFolder)
	self.ActionRemote = Utility.CreateRemoteEvent("action", self.RemoteFolder)
	self.SendConnRemote = Utility.CreateRemoteEvent("addConnections", self.RemoteFolder)
	self.EquipToolRemote = Utility.CreateRemoteEvent("EquipTool", self.RemoteFolder)
	self.UnequipToolRemote = Utility.CreateRemoteEvent("UnequipTool", self.RemoteFolder)
end

-- Register a connection
function Inputs:RegisterConnection(conn: RBXScriptConnection)
	table.insert(self.Connections, conn)
end

-- Try to equip a slot
function Inputs:TryEquipSlot(slotIndex: number)
	if not self.Inventory then
		return
	end

	local slot = self.Inventory:GetSlotByIndex(slotIndex)
	if not slot then
		Utility.Warn(`Warn: no slot found with index: {slotIndex}`, script.Name)
		return
	end

	local player: Player = Players.LocalPlayer
	local character: Model? = player.Character
	if not character then
		return
	end

	local toolName: string = slot.Name
	local equipped = Utility.GetToolFromCharacter(character, toolName)

	if equipped then
		self.UnequipToolRemote:FireServer()
		self.EquipToolRemote:FireServer(toolName)
	else
		self.EquipToolRemote:FireServer(toolName)
	end
end

-- Bind all inputs
function Inputs:BindInputs()
	local player: Player = Players.LocalPlayer
	local function hasCharacter(): boolean
		return player and player.Character ~= nil
	end

	-- Sprint
	local sprint = InputActions.GetAction(self.CONTEXTS.NORMAL, self.ACTIONS.SPRINT)
	sprint.KeyboardBinding.KeyCode = Enum.KeyCode.LeftShift

	self:RegisterConnection(sprint.Pressed:Connect(function()
		if hasCharacter() then
			self.StartSprintRemote:FireServer()
		end
	end))

	self:RegisterConnection(sprint.Released:Connect(function()
		if hasCharacter() then
			self.StopSprintRemote:FireServer()
		end
	end))

	-- Crouch
	local crouch = InputActions.GetAction(self.CONTEXTS.NORMAL, self.ACTIONS.CROUCH)
	crouch.KeyboardBinding.KeyCode = Enum.KeyCode.C

	self:RegisterConnection(crouch.Pressed:Connect(function()
		if hasCharacter() then
			self.StartCrouchRemote:FireServer()
		end
	end))

	self:RegisterConnection(crouch.Released:Connect(function()
		if hasCharacter() then
			self.StopCrouchRemote:FireServer()
		end
	end))

	-- Action
	local action = InputActions.GetAction(self.CONTEXTS.NORMAL, self.ACTIONS.ACTION)
	action.KeyboardBinding.KeyCode = Enum.KeyCode.MouseLeftButton

	self:RegisterConnection(action.Pressed:Connect(function()
		if hasCharacter() then
			self.ActionRemote:FireServer()
		end
	end))

	-- Inventory
	local invent = InputActions.GetAction(self.CONTEXTS.NORMAL, self.ACTIONS.INVENT)
	invent.KeyboardBinding.KeyCode = Enum.KeyCode.Tab

	self:RegisterConnection(invent.Pressed:Connect(function()
		if hasCharacter() and self.Inventory then
			if not self.Inventory.isVisible then
				self.Inventory:ShowInventory()
			else
				self.Inventory:HideInventory()
			end
		end
	end))

	-- Unequip (right click)
	local unequip = InputActions.GetAction(self.CONTEXTS.NORMAL, self.ACTIONS.UEQUIP)
	unequip.KeyboardBinding.KeyCode = Enum.KeyCode.MouseRightButton

	self:RegisterConnection(unequip.Pressed:Connect(function()
		if hasCharacter() and Utility.IsHoldingTool(player.Character :: Model) then
			self.UnequipToolRemote:FireServer()
		end
	end))

	-- Slot shortcuts (1, 2, 3)
	local slotBindings: { [number]: Enum.KeyCode } = {
		[1] = Enum.KeyCode.One,
		[2] = Enum.KeyCode.Two,
		[3] = Enum.KeyCode.Three,
	}

	for index, keycode in ipairs(slotBindings) do
		local selectAction = InputActions.GetAction(self.CONTEXTS.NORMAL, "SELECT_SLOT_" .. index)
		selectAction.KeyboardBinding.KeyCode = keycode

		self:RegisterConnection(selectAction.Pressed:Connect(function()
			if hasCharacter() then
				self:TryEquipSlot(index)
			end
		end))
	end

	self.SendConnRemote:FireServer(self.Connections)
end

-- Destroy all connections
function Inputs:Destroy()
	for _, conn in ipairs(self.Connections) do
		if conn.Disconnect then
			conn:Disconnect()
		end
	end
	table.clear(self.Connections)
end

return Inputs
