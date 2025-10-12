-- selene: allow(unused_variable)

-- Services
local Players = game:GetService("Players")

-- Modules
local PlayerManager = require(script.Player.PlayerManager)
local InitObjects = require(script.Objects.InitObjects)

-- Connections
local playerConnect: RBXScriptConnection?
local playerDisconnect: RBXScriptConnection?

playerConnect = Players.PlayerAdded:Connect(function(player: Player)
	PlayerManager.addPlayer(player)
end)

playerDisconnect = Players.PlayerRemoving:Connect(function(player) 
    PlayerManager.removePlayer(player)
end)

game.Close:Once(function()
    if playerConnect then
        playerConnect:Disconnect()
    end
    if playerDisconnect then
        playerDisconnect:Disconnect()
    end
end)
