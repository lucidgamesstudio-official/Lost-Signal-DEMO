-- Object
local InitObjects = {}

-- Services
local CollectionService: CollectionService = game:GetService("CollectionService")

-- Modules
local MetaldDoorClass = require(script.Parent.MetaldDoorClass)

-- Doors
local MetalDoorsInstance: { Instance } = CollectionService:GetTagged("MetalDoor")
local MetalDoors: {MetaldDoorClass.MetalDoorType} = {}

for _, door in ipairs(MetalDoorsInstance) do
    if door:IsA("Model") then
        local newMetalDoor = MetaldDoorClass.new(door)
        newMetalDoor:Init()
        table.insert(MetalDoors, newMetalDoor)
    end
end

InitObjects["MetalDoors"] = MetalDoorsInstance

return InitObjects