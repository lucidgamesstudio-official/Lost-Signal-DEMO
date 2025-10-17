-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Loading = require(script.Loading)
local Utility = require(ReplicatedStorage.Shared.Utility)

--===============================================================================
-- LOAD PLAYER
--===============================================================================

local loader: Loading.LoadingModuleType? = Loading.new()
if not loader then
	Utility.Error("Error: fail to create loading screen", script.Name)
else
	loader:Init()
end

--===============================================================================
