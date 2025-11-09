local CharacterApi = {}
CharacterApi.__index = CharacterApi

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Utility = require(ReplicatedStorage.Shared.Utility)

-- RemoteFolder
local RemoteFolder: Folder = Utility.CreateFolder("RemoteEvents")

-- Remote Events
local CharacterRemote: RemoteEvent = Utility.CreateRemoteEvent("CharacterRemote", RemoteFolder)

function CharacterApi.EnablePlayerMovements(player: Player)
	CharacterRemote:FireClient(player, "EnableMovement")
end

function CharacterApi.DisablePlayerMovements(player: Player)
	CharacterRemote:FireClient(player, "DisableMovement")
end

return CharacterApi
