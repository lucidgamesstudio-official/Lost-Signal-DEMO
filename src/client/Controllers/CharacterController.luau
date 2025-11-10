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
local BindablesFolder: Folder = Utility.CreateFolder("BindableEvents")

-- Remotes
local CharacterRemote = Utility.CreateRemoteEvent("CharacterRemote", RemotesFolder)

-- Bindables
local CharacterBindable = Utility.CreateBindableEvent("CharacterBindable", BindablesFolder)

-- ActionsEnum
local ActionsEnum = {
	EnableMovement = function()
		Controller:Enable()
	end,
	DisableMovement = function()
		Controller:Disable()
	end,
}

local function executeAction(action: string)
	local fn = ActionsEnum[action] -- Rust ref
	if fn then
		fn()
	else
		Utility.Warn(`Unknown action: {action}`, script.Name)
	end
end

function CharacterController.load()
	CharacterRemote.OnClientEvent:Connect(executeAction)
	CharacterBindable.Event:Connect(executeAction)
end

return CharacterController
