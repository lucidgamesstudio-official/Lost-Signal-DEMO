-- Classe
local PlayerClass = {}
PlayerClass.__index = PlayerClass

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Utility = require(ReplicatedStorage.Shared.Utility)

-- Modules

-- Constantes
-- Stamina
local STAMINA_DRAIN_PER_STUD = 0.2
local STAMINA_REGEN_RATE = 2 -- points régénérés toutes les 0.5s
local REGEN_INTERVAL = 0.5
local MIN_STAMINA = 0
local MAX_STAMINA = 100

-- Player Params
local PLAYER_WALK_SPEED = 16
local PLAYER_RUN_SPEED = 24

-- Types
export type BetterThread = thread & {
	_stopped: boolean,
}

export type PlayerClassType = {
	-- Public
	player: Player,
	character: Model,
	humanoid: Humanoid,
	HumanoidRootPart: BasePart?,
	Inventory: Backpack,
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

-- Enums
local PlayerStateEnum = table.freeze({
	Idle = 1,
	Walk = 2,
	Run = 3,
})
PlayerClass.State = PlayerStateEnum

-- Constructor
function PlayerClass.new(player: Player): PlayerClassType?
	local self = setmetatable({}, PlayerClass)
	local typedSelf: PlayerClassType = self

	typedSelf.player = player
	typedSelf.Inventory = player.Backpack

	typedSelf.stamina = 100
	typedSelf.state = PlayerStateEnum.Idle

	-- Private
	typedSelf._playerRunConn = nil
	typedSelf._playerStaminaRegenThread = nil
	typedSelf._playerDiedConn = nil
	typedSelf._allConnections = {}

	return typedSelf
end

function PlayerClass.Init(self: PlayerClassType)
	self.player:LoadCharacter()
	self.character = self.player.Character or self.player.CharacterAdded:Wait() :: Model
	if not self.character then
		Utility.Warn("No Character found in " .. self.player.Name, script.Name)
		return
	end
	self.humanoid = self.character:FindFirstChildOfClass("Humanoid") :: Humanoid
	if not self.humanoid then
		Utility.Warn("No humanoid found in " .. self.player.Name, script.Name)
		return
	end
	self.humanoid.WalkSpeed = PLAYER_WALK_SPEED
	self.HumanoidRootPart = self.character:WaitForChild("HumanoidRootPart") :: BasePart
	if not self.HumanoidRootPart then
		Utility.Warn("No HumanoidRootPart found in " .. self.player.Name, script.Name)
		return
	end
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

-- Démarre la consommation de stamina
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

	-- stop éventuelle regen en cours
	if self._playerStaminaRegenThread then
		self:RemoveConnection(self._playerStaminaRegenThread)
	end

	-- Jamais censé arriver
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

	-- stop le thread précédent s’il existe
	if self._playerStaminaRegenThread then
		self._playerStaminaRegenThread._stopped = true
		self._playerStaminaRegenThread = nil
	end

	-- lance un thread qui régénère la stamina progressivement
	local regenThread: BetterThread = {} :: BetterThread
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

function PlayerClass.AddConnection(self: PlayerClassType, conn: RBXScriptConnection | thread)
	table.insert(self._allConnections, conn)
end

function PlayerClass.RemoveConnection(self: PlayerClassType, conn: RBXScriptConnection | any)
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

return PlayerClass
