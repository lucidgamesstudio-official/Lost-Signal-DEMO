--[[
	- InitObject
	- Alienduck
	- 16/10/2025
	- v1.0
	@summary Initialise les objets taggés par CollectionService (portes, etc.) et crée leurs instances de classe.
]]

-- Services
local CollectionService = game:GetService("CollectionService")

-- Modules
local MetalDoorClass = require(script.Parent.MetaldDoorClass)

-- Object container
local InitObjects = {}

---------------------------------------------------------------------
-- MetalDoors initialization
---------------------------------------------------------------------

local metalDoorInstances = CollectionService:GetTagged("MetalDoor")
local metalDoors = {}

for _, door in ipairs(metalDoorInstances) do
	if door:IsA("Model") then
		local newDoor = MetalDoorClass.new(door)
		newDoor:Init()
		table.insert(metalDoors, newDoor)
	end
end

InitObjects.MetalDoors = metalDoors

---------------------------------------------------------------------
-- Return
---------------------------------------------------------------------

return InitObjects
