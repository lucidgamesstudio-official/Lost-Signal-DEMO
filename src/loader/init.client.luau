-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Modules
local Loading = require(script.Loading)
local Utility = require(ReplicatedStorage.Shared.Utility)

--===============================================================================
-- LOAD PLAYER
--===============================================================================

if RunService:IsServer() then
	local loader: Loading.LoadingModuleType? = Loading.new()
	if not loader then
		Utility.Error("Error: fail to create loading screen", script.Name)
	else
		loader:Init()
	end
else
	Utility.CreateRemoteEvent("spawnPlayer", Utility.CreateFolder("RemoteEvents")):FireServer()
end

--===============================================================================
