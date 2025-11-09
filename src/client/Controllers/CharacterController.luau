--!nocheck

local CharacterController = {}
CharacterController.__index = CharacterController

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Player Stuff
local Player: Player = Players.LocalPlayer
local PlayerScript: PlayerScripts = Player.PlayerScripts

-- Modules
local Utility = require(ReplicatedStorage.Shared.Utility)
local PlayerModule = require(PlayerScript:WaitForChild("PlayerModule")) -- no check only for this

-- Character Stuff
local Character: Model = Player.Character or Player.CharacterAdded:Wait()
local Humanoid: Humanoid = Character:FindFirstChildOfClass("Humanoid") :: Humanoid
if not Humanoid or not Humanoid:IsA("Humanoid") then
	Utility.Warn(`[WARN] no humanoid found on {Player.Name}`, script.Name)
	return CharacterController
end
local Controller = PlayerModule:GetControls()

-- Folders
local RemotesFolder: Folder = Utility.CreateFolder("RemoteEvents")

-- Remotes
local CharacterRemote = Utility.CreateRemoteEvent("CharacterRemote", RemotesFolder)

-- ActionsEnum
local ActionsEnum = {
	EnableMovement = function()
		Controller:Enable()
	end,
	DisableMovement = function()
		Controller:Disable()
	end,
}

function CharacterController.load()
	CharacterRemote.OnClientEvent:Connect(function(action: string)
		local fn = ActionsEnum[action] -- Rust ref
		if fn then
			fn()
		else
			Utility.Warn(`Unknown action: {action}`, script.Name)
		end
	end)
end

return CharacterController
