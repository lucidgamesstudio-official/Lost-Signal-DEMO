--[[
	- PlayerManager
	- Alienduck
	- 16/10/2025
	- v1.0
	@summary Gère les instances de PlayerClass et les appels distants associés.
]]

---------------------------------------------------------------------
-- Services
---------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")

---------------------------------------------------------------------
-- Modules
---------------------------------------------------------------------

local Utility = require(ReplicatedStorage.Shared.Utility)
local PlayerClass = require(script.Parent.PlayerClass)

---------------------------------------------------------------------
-- Constantes
---------------------------------------------------------------------

local REMOTE_EVENT_FOLDER = Utility.CreateFolder("RemoteEvents")

---------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------

local Players = {}

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------

local function playerUnfound(player)
	return "No player with id: " .. tostring(player.UserId)
end

---------------------------------------------------------------------
-- Classe
---------------------------------------------------------------------

local PlayerManager = {}

---------------------------------------------------------------------
-- Méthodes principales
---------------------------------------------------------------------

function PlayerManager.addPlayer(player)
	local newPlayer = PlayerClass.new(player)
	if newPlayer then
		print("Add player: " .. player.Name .. " in Players")
		Players[player.UserId] = newPlayer
	end
	print(Players)
end

function PlayerManager.removePlayer(player)
	Players[player.UserId] = nil
end

function PlayerManager.getPlayer(player)
	return Players[player.UserId]
end

function PlayerManager.getAll()
	return Players
end

---------------------------------------------------------------------
-- Remote Events
---------------------------------------------------------------------

Utility.CreateRemoteEvent("spawnPlayer", REMOTE_EVENT_FOLDER, function(player)
	local playerObj = PlayerManager.getPlayer(player)
	if not playerObj then
		Utility.Warn(playerUnfound(player), script.Name)
		return
	end
	print("spawn: " .. player.Name)
	playerObj:Init()
end)

Utility.CreateRemoteEvent("addConnections", REMOTE_EVENT_FOLDER, function(player, connections)
	local playerObj = PlayerManager.getPlayer(player)
	if not playerObj then
		Utility.Warn(playerUnfound(player), script.Name)
		return
	end
	for _, conn in ipairs(connections) do
		playerObj:AddConnection(conn)
	end
end)

Utility.CreateRemoteEvent("startSprint", REMOTE_EVENT_FOLDER, function(player)
	local playerObj = PlayerManager.getPlayer(player)
	if not playerObj then
		Utility.Warn(playerUnfound(player), script.Name)
		return
	end
	playerObj:StartRun()
end)

Utility.CreateRemoteEvent("stopSprint", REMOTE_EVENT_FOLDER, function(player)
	local playerObj = PlayerManager.getPlayer(player)
	if not playerObj then
		Utility.Warn(playerUnfound(player), script.Name)
		return
	end
	playerObj:StopRun()
end)

Utility.CreateRemoteEvent("AddItem", REMOTE_EVENT_FOLDER, function(player, toolName)
	local playerObj = PlayerManager.getPlayer(player)
	if not playerObj then
		Utility.Warn(playerUnfound(player), script.Name)
		return
	end
	playerObj:AddItem(toolName)
end)

Utility.CreateRemoteEvent("EquipTool", REMOTE_EVENT_FOLDER, function(player, toolName)
	local playerObj = PlayerManager.getPlayer(player)
	if not playerObj then
		Utility.Warn(playerUnfound(player), script.Name)
		return
	end
	playerObj:EquipTool(toolName)
end)

Utility.CreateRemoteEvent("UnequipTool", REMOTE_EVENT_FOLDER, function(player)
	local playerObj = PlayerManager.getPlayer(player)
	if not playerObj then
		Utility.Warn(playerUnfound(player), script.Name)
		return
	end
	playerObj:UnequipTool()
end)

---------------------------------------------------------------------
-- Retour
---------------------------------------------------------------------

return PlayerManager
