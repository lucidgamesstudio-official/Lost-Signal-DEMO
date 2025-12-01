--[[
	- init.server
	- Alienduck
	- 16/10/2025
	- v1.0
	@summary Initialise les objets du jeu et gère l'ajout/suppression des joueurs.
]]

---------------------------------------------------------------------
-- Services
---------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---------------------------------------------------------------------
-- Modules
---------------------------------------------------------------------

local DialoguesText = require(ReplicatedStorage.Shared.DialoguesText)
local Utility = require(ReplicatedStorage.Shared.Utility)
local DialoguesApi = require(script.Apis.DialoguesApi)
local LightingController = require(script.Lighting.LightingController)
local PlayerManager = require(script.Player.PlayerManager)
local InitObjects = require(script.Objects.InitObjects)

---------------------------------------------------------------------
-- Create Folders
---------------------------------------------------------------------

Utility.CreateFolder("BindableEvents")
Utility.CreateFolder("BindableFuncctions")
Utility.CreateFolder("RemoteEvents")
Utility.CreateFolder("RemoteFunctions")

---------------------------------------------------------------------
-- Initialisation
---------------------------------------------------------------------

LightingController:Init()
print(InitObjects)

---------------------------------------------------------------------
-- Connexions
---------------------------------------------------------------------

local playerConnect
local playerDisconnect

playerConnect = Players.PlayerAdded:Connect(function(player)
	PlayerManager.addPlayer(player)
	task.wait(5)
	local data: DialoguesApi.DialoguesDict = DialoguesText.fr.Test
	while true do
		DialoguesApi.SendDialogue(player, data)
		print("wow")
		task.wait(10)
	end
end)

playerDisconnect = Players.PlayerRemoving:Connect(function(player)
	PlayerManager.removePlayer(player)
end)

---------------------------------------------------------------------
-- Nettoyage à la fermeture
---------------------------------------------------------------------

game.Close:Once(function()
	if playerConnect then
		playerConnect:Disconnect()
	end
	if playerDisconnect then
		playerDisconnect:Disconnect()
	end
end)
