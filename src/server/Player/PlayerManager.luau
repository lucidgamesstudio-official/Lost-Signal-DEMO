local PlayerManager = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Utility = require(ReplicatedStorage.Shared.Utility)
local PlayerClass = require(script.Parent.PlayerClass)

-- Constantes
local REMOTE_EVENT_FOLDER = Utility.CreateFolder("RemoteEvents")

-- Variables
local Players: { [number]: PlayerClass.PlayerClassType } = {}

--=============================
-- HELPERS
--=============================

local function playerUnfound(player: Player): string
	return string.format("No player with id: %s", tostring(player.UserId))
end

--=============================
-- FUNCTIONS
--=============================

function PlayerManager.addPlayer(player: Player)
	local newPlayerClass: PlayerClass.PlayerClassType = PlayerClass.new(player) :: PlayerClass.PlayerClassType
	if newPlayerClass then
		print("Add player: " .. player.Name .. "in Players")
		Players[player.UserId] = newPlayerClass
	end
	print(Players)
end

function PlayerManager.removePlayer(player: Player)
	Players[player.UserId] = nil
end

function PlayerManager.getPlayer(player: Player): PlayerClass.PlayerClassType
	return Players[player.UserId]
end

function PlayerManager.getAll()
	return Players
end

-- Remotes | Bindables

Utility.CreateRemoteEvent("spawnPlayer", REMOTE_EVENT_FOLDER, function(player: Player)
	local playerObj: PlayerClass.PlayerClassType = PlayerManager.getPlayer(player)
	if not playerObj then
		Utility.Warn(playerUnfound(player), script.Name)
		return
	end
	print("spawn: " .. player.Name)
	playerObj:Init()
end)

Utility.CreateRemoteEvent(
	"addConnections",
	REMOTE_EVENT_FOLDER,
	function(player: Player, connections: { RBXScriptConnection | thread })
		local playerObj: PlayerClass.PlayerClassType = PlayerManager.getPlayer(player)
		if not playerObj then
			Utility.Warn(playerUnfound(player), script.Name)
			return
		end
		for _, conn in ipairs(connections) do
			playerObj:AddConnection(conn)
		end
	end
)

Utility.CreateRemoteEvent("startSprint", REMOTE_EVENT_FOLDER, function(player: Player)
	local playerObj: PlayerClass.PlayerClassType = PlayerManager.getPlayer(player)
	if not playerObj then
		Utility.Warn(playerUnfound(player), script.Name)
		return
	end
	playerObj:StartRun()
end)

Utility.CreateRemoteEvent("stopSprint", REMOTE_EVENT_FOLDER, function(player: Player)
	local playerObj: PlayerClass.PlayerClassType = PlayerManager.getPlayer(player)
	if not playerObj then
		Utility.Warn(playerUnfound(player), script.Name)
		return
	end
	playerObj:StopRun()
end)

return PlayerManager
