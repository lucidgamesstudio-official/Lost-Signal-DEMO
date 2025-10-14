-- Inputs.luau
-- Gère les entrées clavier et les relie aux actions (sprint, crouch, inventaire, etc.)

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
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
}

-- Constructeur
function Inputs.new(inventory)
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
end

-- Enregistrement d'une connexion
function Inputs:RegisterConnection(conn)
	table.insert(self.Connections, conn)
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
			self.Inventory:ShowInventory()
		end
	end))

	-- Envoi des connexions au serveur (si besoin)
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
