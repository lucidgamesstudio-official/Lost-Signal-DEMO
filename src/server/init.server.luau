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

---------------------------------------------------------------------
-- Modules
---------------------------------------------------------------------

local PlayerManager = require(script.Player.PlayerManager)
local InitObjects = require(script.Objects.InitObjects)

---------------------------------------------------------------------
-- Initialisation
---------------------------------------------------------------------

print(InitObjects)

---------------------------------------------------------------------
-- Connexions
---------------------------------------------------------------------

local playerConnect
local playerDisconnect

playerConnect = Players.PlayerAdded:Connect(function(player)
	PlayerManager.addPlayer(player)
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
