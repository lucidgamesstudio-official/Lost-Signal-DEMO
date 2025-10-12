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
    @params name: string \
    @params parentInstance: Instance? <br>
    @params callback: ((Player, ...any) -> ())? \
    @returns RemoteEvent \
    @description Creates or retrieves a RemoteEvent. Callback can be set on server and client automatically.
]]
function Utility.CreateRemoteEvent(
    name: string,
    parentInstance: Instance?,
    callback: ((Player, ...any) -> ())?
): RemoteEvent
    local parent = parentInstance or ReplicatedStorage
    local remote = parent:FindFirstChild(name)
    if remote and remote:IsA("RemoteEvent") then
        if callback then
            local hasConnection = false
            if RunService:IsServer() then
                hasConnection = remote.OnServerEvent and #remote.OnServerEvent:GetConnections() > 0
                if not hasConnection then
                    remote.OnServerEvent:Connect(callback)
                end
            elseif RunService:IsClient() then
                hasConnection = remote.OnClientEvent and #remote.OnClientEvent:GetConnections() > 0
                if not hasConnection then
                    remote.OnClientEvent:Connect(callback)
                end
            end
        end
        return remote
    end
    remote = Instance.new("RemoteEvent")
    remote.Name = name
    remote.Parent = parent
    if callback then
        if RunService:IsServer() then
            remote.OnServerEvent:Connect(callback)
        elseif RunService:IsClient() then
            remote.OnClientEvent:Connect(callback)
        end
    end
    return remote
end

--[[ 
    @params name: string
    @params parentInstance: Instance? 
    @params callback: ((Player, ...any) -> any)?
    @returns RemoteFunction
    @description Creates or retrieves a RemoteFunction. Callback can be set on server and client automatically.
]]
function Utility.CreateRemoteFunction(
    name: string,
    parentInstance: Instance?,
    callback: ((Player, ...any) -> any)?
): RemoteFunction
    local parent = parentInstance or ReplicatedStorage
    local remote = parent:FindFirstChild(name)

    if remote and remote:IsA("RemoteFunction") then
        if callback then
            if RunService:IsServer() and remote.OnServerInvoke == nil then
                remote.OnServerInvoke = callback
            elseif RunService:IsClient() and remote.OnClientInvoke == nil then
                remote.OnClientInvoke = callback
            end
        end
        return remote
    end
    remote = Instance.new("RemoteFunction")
    remote.Name = name
    remote.Parent = parent
    if callback then
        if RunService:IsServer() then
            remote.OnServerInvoke = callback
        elseif RunService:IsClient() then
            remote.OnClientInvoke = callback
        end
    end

    return remote
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