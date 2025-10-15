-- Inputs.luau
-- Gère les entrées clavier et les relie aux actions (sprint, crouch, inventaire, etc.)

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Inventory = require(script.Parent.Inventory)
local Utility = require(ReplicatedStorage.Shared.Utility)
local InputActions = require(ReplicatedStorage.Shared.Utils.InputActions)

-- Classe
local Inputs = {}
Inputs.__index = Inputs

-- Constantes
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

-- Constructeur
function Inputs.new(inventory: Inventory.PlayerInventoryType)
	local self = setmetatable({}, Inputs)
	self.Inventory = inventory
	self.Connections = {}

	self.RemoteFolder = Utility.CreateFolder("RemoteEvents")
	self:SetupRemotes()
	self:BindInputs()
	InputActions.EnableContext(Inputs.CONTEXTS.NORMAL)

	return self
end

-- Création des RemoteEvents
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

-- Enregistrement d'une connexion
function Inputs:RegisterConnection(conn)
	table.insert(self.Connections, conn)
end

-- Helper pour tenter d’équiper un slot
function Inputs:TryEquipSlot(slotIndex: number)
	if not self.Inventory then return end

	local container = self.Inventory.SlotContainer
	if not container then return end

	local slot = self.Inventory:GetSlotByIndex(slotIndex)
	if not slot then
		Utility.Warn("Warn: no slot found with index: " .. tostring(slotIndex), script.Name)
		return -- slot inexistant
	end

	local toolName = slot.Name
	local player = Players.LocalPlayer
	local character = player.Character

	if not character then return end

	-- Si le joueur a déjà ce tool équipé, on le retire
	if Utility.GetToolFromCharacter(character, toolName) then
		self.UnequipToolRemote:FireServer()
		self.EquipToolRemote:FireServer(toolName)
	else
		self.EquipToolRemote:FireServer(toolName)
	end
end

-- Liaison des touches
function Inputs:BindInputs()
	local player = Players.LocalPlayer
	local function hasCharacter()
		return player and player.Character
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

	-- Inventaire
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

	-- Unequip (clic droit)
	local unequip = InputActions.GetAction(self.CONTEXTS.NORMAL, self.ACTIONS.UEQUIP)
	unequip.KeyboardBinding.KeyCode = Enum.KeyCode.MouseRightButton

	self:RegisterConnection(unequip.Pressed:Connect(function()
		if hasCharacter() and Utility.IsHoldingTool(hasCharacter()) then
			self.UnequipToolRemote:FireServer()
		end
	end))

	-- Raccourcis slots (touches & ~ ")
	local slotBindings = {
		[1] = Enum.KeyCode.One, 	-- &
		[2] = Enum.KeyCode.Two,  	-- ~
		[3] = Enum.KeyCode.Three, 	-- "
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

	-- Envoi des connexions au serveur
	self.SendConnRemote:FireServer(self.Connections)
end

-- Nettoyage des connexions
function Inputs:Destroy()
	for _, conn in ipairs(self.Connections) do
		if conn.Disconnect then
			conn:Disconnect()
		end
	end
	table.clear(self.Connections)
end

return Inputs
