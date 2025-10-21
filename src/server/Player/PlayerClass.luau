--[[
	- PlayerClass
	- Alienduck
	- 16/10/2025
	- v1.0
	@summary Gestion du joueur : stamina, équipement et état de déplacement.
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Modules
local Utility = require(ReplicatedStorage.Shared.Utility)

---------------------------------------------------------------------
-- Constantes
---------------------------------------------------------------------

local STAMINA_DRAIN_PER_STUD = 0.2
local STAMINA_REGEN_RATE = 2
local REGEN_INTERVAL = 0.5
local MIN_STAMINA = 0
local MAX_STAMINA = 100

local PLAYER_WALK_SPEED = 16
local PLAYER_RUN_SPEED = 24

local ITEM_FOLDER = Utility.CreateFolder("Items")

---------------------------------------------------------------------
-- Types
---------------------------------------------------------------------

export type BetterThread = thread & {
	_stopped: boolean,
}

export type PlayerClassType = {
	-- Public
	player: Player,
	character: Model,
	humanoid: Humanoid,
	HumanoidRootPart: BasePart?,
	stamina: number,
	state: number,

	-- Private
	_playerRunConn: RBXScriptConnection?,
	_playerStaminaRegenThread: BetterThread?,
	_playerDiedConn: RBXScriptConnection?,
	_allConnections: { RBXScriptConnection | thread },

	-- Public Methods
	new: (player: Player) -> PlayerClassType,
	Init: (self: PlayerClassType) -> (),
	StartRun: (self: PlayerClassType) -> (),
	StopRun: (self: PlayerClassType) -> (),
	AddItem: (self: PlayerClassType, toolName: string) -> (),
	RemoveItem: (self: PlayerClassType, tool: Tool) -> (),
	EquipTool: (self: PlayerClassType, toolName: string) -> (),
	UnequipTool: (self: PlayerClassType) -> (),
	Disconnect: (self: PlayerClassType) -> (),
	AddConnection: (self: PlayerClassType, conn: RBXScriptConnection | thread) -> (),
	RemoveConnection: (self: PlayerClassType, conn: RBXScriptConnection | thread) -> (),

	-- Private Methods
}

export type PlayerStateEnumType = {
	Idle: number,
	Walk: number,
	Run: number,
}

---------------------------------------------------------------------
-- Enums
---------------------------------------------------------------------

local PlayerStateEnum = table.freeze({
	Idle = 1,
	Walk = 2,
	Run = 3,
})

---------------------------------------------------------------------
-- Classe
---------------------------------------------------------------------

local PlayerClass = {}
PlayerClass.__index = PlayerClass
PlayerClass.State = PlayerStateEnum

---------------------------------------------------------------------
-- HELPER
---------------------------------------------------------------------

local function hasCopy(Backpack: Backpack, toolName: string): boolean
	for _, item: Instance in ipairs(Backpack:GetChildren() :: { Instance }) do
		if item:IsA("Tool") and item.Name == toolName then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
-- Constructeur
---------------------------------------------------------------------

function PlayerClass.new(player)
	local self = setmetatable({}, PlayerClass)

	self.player = player
	self.stamina = 100
	self.state = PlayerStateEnum.Idle

	self._playerRunConn = nil
	self._playerStaminaRegenThread = nil
	self._playerDiedConn = nil
	self._allConnections = {}

	return self
end

---------------------------------------------------------------------
-- Initialisation
---------------------------------------------------------------------

function PlayerClass.Init(self: PlayerClassType)
	self.player:LoadCharacter()
	self.character = self.player.Character or self.player.CharacterAdded:Wait()
	if not self.character then
		Utility.Warn("No Character found in " .. self.player.Name, script.Name)
		return
	end

	self.humanoid = self.character:FindFirstChildOfClass("Humanoid") :: Humanoid
	if not self.humanoid or not self.humanoid:IsA("Humanoid") then
		Utility.Warn("No Humanoid found in " .. self.player.Name, script.Name)
		return
	end

	self.HumanoidRootPart = self.character:WaitForChild("HumanoidRootPart") :: BasePart
	if not self.HumanoidRootPart then
		Utility.Warn("No HumanoidRootPart found in " .. self.player.Name, script.Name)
		return
	end

	self.humanoid.WalkSpeed = PLAYER_WALK_SPEED

	self._playerDiedConn = self.humanoid.Died:Connect(function()
		if self._playerRunConn then
			self._playerRunConn:Disconnect()
		end
		if self._playerStaminaRegenThread then
			self._playerStaminaRegenThread._stopped = true
			self._playerStaminaRegenThread = nil
		end
	end)
end

---------------------------------------------------------------------
-- Course et stamina
---------------------------------------------------------------------

function PlayerClass.StartRun(self: PlayerClassType)
	local character = self.player.Character
	if not character then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local lastPos = root.Position

	if self._playerStaminaRegenThread then
		self:RemoveConnection(self._playerStaminaRegenThread)
	end
	if self._playerRunConn then
		self:RemoveConnection(self._playerRunConn)
	end

	self._playerRunConn = RunService.Heartbeat:Connect(function()
		if not root or not root.Parent then
			if self._playerRunConn then
				self._playerRunConn:Disconnect()
			end
			self._playerRunConn = nil
			return
		end

		self.humanoid.WalkSpeed = PLAYER_RUN_SPEED

		local currentPos = root.Position
		local distance = (currentPos - lastPos).Magnitude
		lastPos = currentPos

		self.stamina -= distance * STAMINA_DRAIN_PER_STUD
		if self.stamina <= MIN_STAMINA then
			self.stamina = MIN_STAMINA
			self:StopRun()
		end
	end)

	if self._playerRunConn then
		self:AddConnection(self._playerRunConn)
	end
end

function PlayerClass.StopRun(self: PlayerClassType)
	if self._playerRunConn then
		self:RemoveConnection(self._playerRunConn)
	end

	self.humanoid.WalkSpeed = PLAYER_WALK_SPEED

	if self._playerStaminaRegenThread then
		self._playerStaminaRegenThread._stopped = true
		self._playerStaminaRegenThread = nil
	end

	local regenThread: BetterThread = { _stopped = false } :: BetterThread
	self._playerStaminaRegenThread = regenThread
	self:AddConnection(regenThread)

	task.spawn(function()
		while not regenThread._stopped and self.stamina < MAX_STAMINA do
			self.stamina = math.clamp(self.stamina + STAMINA_REGEN_RATE, 0, MAX_STAMINA)
			task.wait(REGEN_INTERVAL)
		end
		self:RemoveConnection(regenThread)
	end)
end

---------------------------------------------------------------------
-- Gestion d'items
---------------------------------------------------------------------

function PlayerClass.AddItem(self: PlayerClassType, toolName: string): nil
	local tool = Utility.GetToolByName(toolName, ITEM_FOLDER)
	if not tool then
		return Utility.Error("Warn: item " .. toolName .. " does not exist", script.Name)
	end
	if #self.player.Backpack:GetChildren() >= 3 then
		return Utility.Info(`Backpack of {self.player.Name} is full`, script.Name)
	end
	if hasCopy(self.player.Backpack, toolName) then
		return
	end

	local clone = tool:Clone()
	clone.Parent = self.player.Backpack
	return
end

function PlayerClass.RemoveItem(self: PlayerClassType, tool: Tool): nil
	for _, item: Instance in ipairs(self.player.Backpack:GetChildren()) do
		if item:IsA("Tool") and item == tool then
			item:Destroy()
			return
		end
	end
	return
end

function PlayerClass.EquipTool(self: PlayerClassType, toolName): nil
	local tool = self.player.Backpack:FindFirstChild(toolName)
	if not tool then
		Utility.DebugItem(tool)
		return Utility.Warn("Warn: No tool found with the name: " .. toolName, script.Name)
	end
	self.humanoid:EquipTool(tool)
	return
end

function PlayerClass:UnequipTool()
	self.humanoid:UnequipTools()
end

---------------------------------------------------------------------
-- Connexions
---------------------------------------------------------------------

function PlayerClass.AddConnection(self: PlayerClassType, conn)
	table.insert(self._allConnections, conn)
end

function PlayerClass.RemoveConnection(self: PlayerClassType, conn)
	local index = table.find(self._allConnections, conn)
	if not index then
		return
	end

	if typeof(conn) == "RBXScriptConnection" then
		conn:Disconnect()
	elseif typeof(conn) == "table" and conn._stopped ~= nil then
		conn._stopped = true
	end

	table.remove(self._allConnections, index)
end

---------------------------------------------------------------------
-- Retour
---------------------------------------------------------------------

return PlayerClass
