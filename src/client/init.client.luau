--[[
	- init.client
	- Alienduck
	- 16/10/2025
	- v1.0
	@summary Point d’entrée client. Initialise les systèmes d’inputs, d’inventaire, de prompts et les connexions du sac à dos.
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local FootstepController = require(script.Player.FootstepController)
local Utility = require(ReplicatedStorage.Shared.Utility)
local Inputs = require(script.Player.Inputs)
local InventoryModule = require(script.Player.Inventory)
require(script.ProximityPrompt.CustomPromptHandler)

-- Remote folder
local REMOTE_FOLDER = Utility.CreateFolder("RemoteEvents")

-- Player & backpack
local player = Players.LocalPlayer
local backpack = player.Backpack
local inventory = InventoryModule.new(player)
Inputs.new(inventory)

local backpackAddedConn
local backpackRemovedConn

---------------------------------------------------------------------
-- Backpack listeners
---------------------------------------------------------------------

backpackAddedConn = backpack.ChildAdded:Connect(function(instance)
	if not instance:IsA("Tool") then
		Utility.Warn("[Inventory] Non-tool instance detected in backpack. Destroying.", script.Name)
		instance:Destroy()
		return
	end

	inventory:AddItem(instance)
end)

backpackRemovedConn = backpack.ChildRemoved:Connect(function(instance)
	if not instance:IsA("Tool") then
		Utility.Warn("[Inventory] Non-tool removal detected. Possible exploit. Kicking player.", script.Name)
		player:Kick("CHEATER")
		return
	end

	inventory:RemoveItem(instance)
end)

---------------------------------------------------------------------
-- Register connections on server
---------------------------------------------------------------------

Utility.CreateRemoteEvent("addConnections", REMOTE_FOLDER):FireServer({
	backpackAddedConn,
	backpackRemovedConn,
})

-- START INITIATE CLIENT (client side)
FootstepController.Load()
