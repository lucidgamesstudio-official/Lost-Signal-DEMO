-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Modules
local Utility = require(ReplicatedStorage.Shared.Utility)
local Inputs = require(script.Player.Inputs)
local InventoryModule = require(script.Player.Inventory)
local CustomPromptHandler = require(script.ProximityPrompt.CustomPromptHandler)

-- RemoteFolder
local REMOTE_FOLDER = Utility.CreateFolder("RemoteEvents")

-- Disable default GUI
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

-- Handle backpack
local Backpack: Backpack = Players.LocalPlayer.Backpack
local Inventory = InventoryModule.new(Players.LocalPlayer)
local BackpackAddedConn: RBXScriptConnection
local BackpackRemoveConn: RBXScriptConnection

BackpackAddedConn = Backpack.ChildAdded:Connect(function (instance: Instance)
    local tool: Tool = instance :: Tool
    if not tool:IsA("Tool") then
        Utility.Warn("Warn: WTF you can't put something that isn't a tool", script.Name)
        instance:Destroy()
        return
    end
    Inventory:AddItem(tool)
end)

BackpackRemoveConn = Backpack.ChildRemoved:Connect(function (instance: Instance)
    local tool: Tool = instance :: Tool
    if not tool:IsA("Tool") then
        Utility.Warn("Warn: Okay, you are definitively cheating, I ban you.", script.Name)
        Players.LocalPlayer:Kick("CHEATER")
    end
    Inventory:RemoveItem(tool)
end)

Utility.CreateRemoteEvent("addConnections", REMOTE_FOLDER):FireServer({
    BackpackAddedConn,
    BackpackRemoveConn
})