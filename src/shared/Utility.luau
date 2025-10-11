-- Services
local RunService = game:GetService("RunService")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Classe
local Utility = {}
Utility = Utility

-- Modules

-- Variables

-- Constants

-----------------------------------------------------------------------
-- HELPERS
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- FUNCTIONS
-----------------------------------------------------------------------

-- Warn only in studio
function Utility.Warn(message: string, scriptCall: string?)
	if RunService:IsStudio() then
		warn(`{scriptCall or script.Name}: {message}.`)
	end
end

-- Error only in studio
function Utility.Error(message: string, scriptCall: string?)
	if RunService:IsStudio() then
		error(`{scriptCall or script.Name}: {message}.`)
	end
end

--[[
	@params name: string | parentInstance: Instance?
	@returns Folder
	@description Create a folder, name it by the given name and parent to it to the given Parent or ReplicatedStorage, return the folder
]]
function Utility.CreateFolder(name: string, parentInstance: Instance?): Folder
	local parent: Instance = parentInstance or ReplicatedStorage
	local folder: Folder = parent:FindFirstChild(name) :: Folder
	if folder and folder:IsA("Folder") then
		return folder
	end
	local newFolder: Folder = Instance.new("Folder")
	newFolder.Name = name
	newFolder.Parent = parent
	return newFolder
end

--[[
	@params name: string | parentInstance: Instance?
	@returns RemoteEvent
	@description Creates a RemoteEvent and return it, if it already exists, it returns it
]]
function Utility.CreateRemoteEvent(name: string, parentInstance: Instance?, callback: ((...any) -> any)?): RemoteEvent
	local parent: Instance = parentInstance or ReplicatedStorage
	if parent:FindFirstChild(name) then
		return parent[name] :: RemoteEvent
	end
	local RemoteEvent: RemoteEvent = Instance.new("RemoteEvent")
	RemoteEvent.Name = name
	RemoteEvent.Parent = parent or ReplicatedStorage
	if callback then
		RemoteEvent.OnServerEvent:Connect(callback)
	end
	return RemoteEvent
end

--[[
	@params name: string | parentInstance: Instance?
	@returns RemoteFunction
	@description Creates a RemoteFunction and returns it, if it already exists, it returns it
]]
function Utility.CreateRemoteFunction(
	name: string,
	parentInstance: Instance?,
	callback: ((...any) -> any)?
): RemoteFunction
	local parent: Instance = parentInstance or ReplicatedStorage
	if parent:FindFirstChild(name) then
		return parent[name] :: RemoteFunction
	end
	local RemoteFunction: RemoteFunction = Instance.new("RemoteFunction")
	RemoteFunction.Name = name
	RemoteFunction.Parent = parent or ReplicatedStorage
	if callback then
		RemoteFunction.OnServerInvoke = callback
	end
	return RemoteFunction
end

--[[
	@params name: string | parentInstance: Instance?
	@returns Bindable Event
	@description Creates a BindableEvent and returns it, if it already exists, it returns it
]]
function Utility.CreateBindableEvent(
	name: string,
	parentInstance: Instance?,
	callback: ((...any) -> any)?
): BindableEvent
	local parent: Instance = parentInstance or ReplicatedStorage
	if parent:FindFirstChild(name) then
		return parent[name] :: BindableEvent
	end
	local bindableEvent: BindableEvent = Instance.new("BindableEvent")
	bindableEvent.Name = name
	bindableEvent.Parent = parent
	if callback then
		bindableEvent.Event:Connect(callback)
	end
	return bindableEvent
end

--[[
	@params name: string | parentInstance: Instance?
	@returns Bindable Function
	@description Creates a BindableFunction and returns it, if it already exists, it returns it
]]
function Utility.CreateBindableFunction(
	name: string,
	parentInstance: Instance?,
	callback: ((...any) -> any)?
): BindableFunction
	local parent: Instance = parentInstance or ReplicatedStorage
	if parent:FindFirstChild(name) then
		return parent[name] :: BindableFunction
	end
	local bindableFunction: BindableFunction = Instance.new("BindableFunction")
	bindableFunction.Name = name
	bindableFunction.Parent = parent
	if callback then
		bindableFunction.OnInvoke = callback
	end
	return bindableFunction
end

--[[
	@params name: string | parent: string?
	@returns tool: Tool?
	@description Returns the tool from the character, if it doesn't exist, it returns nil
]]
function Utility.GetToolFromCharacter(character: Model, name: string?)
	local tool: Tool? = character:FindFirstChildWhichIsA("Tool")
	if not tool and name then
		local toolName: string = name
		tool = character:FindFirstChild(toolName) :: Tool?
	end
	return tool
end

--[[
	@params toolName: string
	@returns tool: Tool?
	@description Returns the tool from the ReplicatedStorage, if it doesn't exist, it returns nil
]]
function Utility.GetToolByName(toolName: string)
	local parent: Instance = ReplicatedStorage:FindFirstChild("Tools") or ReplicatedStorage
	return parent:FindFirstChild(toolName)
end

--[[
	@params pos1: Vector3 | pos2: Vector3
	@returns number
	@description Returns the distance between two Vector3
]]
function Utility.GetDistance(pos1: Vector3, pos2: Vector3): number
	return (pos1 - pos2).Magnitude
end

--[[
	@params character: Model
	@returns shirt: Shirt?
	@description Returns the Shirt from the character, if it doesn't exist, it returns nil
]]
function Utility.GetShirtFromCharacter(character: Model): Shirt?
	return character:FindFirstChildWhichIsA("Shirt") :: Shirt?
end

--[[
	@params character: Model
	@returns pants: Pants?
	@description Returns the Pants from the character, if it doesn't exist, it returns nil
]]
function Utility.GetPantsFromCharacter(character: Model): Pants?
	return character:FindFirstChildWhichIsA("Pants") :: Pants?
end

return Utility