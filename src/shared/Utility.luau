-- Services
local Players = game:GetService("Players")
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
	@params parent: Instance <br>
	@params childType: string? <br>
	@return childs: { T }
	@description Return a table of the children with the type given, if no type give then the type of the parent is take
]]
function Utility.GetChildrenOfClass<T>(parent: Instance, childType: string?): { T }
	childType = childType or typeof(parent)
	local childs: { T } = {}
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA(childType) then
			table.insert(childs, child)
		end
	end
	return childs
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

--[=[
	@params **character**: `Model`<br>
	@returns **found**: `boolean`<br>
	@description Return `true` if the player hold a `tool`, return `false` if not
]=]
function Utility.IsHoldingTool(character: Model): boolean
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			return true
		end
	end
	return false
end

--[[
	@params toolName: string
	@returns tool: Tool?
	@description Returns the tool from the ReplicatedStorage, if it doesn't exist, it returns nil
]]
function Utility.GetToolByName(toolName: string, parentInstance: Instance?)
	local parent: Instance = parentInstance and parentInstance or ReplicatedStorage
	return parent:FindFirstChild(toolName)
end

--[[
	@params tool: Tool
	@returns nil
	@description Attach a temporary Motor6D between the right arm and the tool handle.
]]
function Utility.AddMotorToTool(tool: Tool)
	local character = tool.Parent
	if not character or not Players:GetPlayerFromCharacter(character) then
		return Utility.Warn("Warn: no valid character found", script.Name)
	end

	local handle = tool:FindFirstChild("Handle") :: BasePart?
	if not handle then
		return Utility.Warn("Warn: no handle found on tool", script.Name)
	end

	-- Détection du rig
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return Utility.Warn("Warn: no humanoid found", script.Name)
	end

	local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15
	local rightArm = character:FindFirstChild(isR15 and "RightHand" or "Right Arm") :: BasePart?
	if not rightArm then
		return Utility.Warn("Warn: no right arm found", script.Name)
	end

	local rightGrip = rightArm:FindFirstChild("RightGrip") :: Weld?
	if not rightGrip then
		return Utility.Warn("Warn: no RightGrip found", script.Name)
	end

	-- Crée le Motor6D et désactive le grip
	rightGrip.Enabled = false

	local motor = Instance.new("Motor6D")
	motor.Name = "ToolMotor"
	motor.Part0 = rightArm
	motor.Part1 = handle
	motor.C0 = CFrame.new(0, -rightArm.Size.Y / 2, 0) * CFrame.Angles(-math.pi / 2, 0, 0)
	motor.C1 = tool.Grip
	motor.Parent = rightArm

	-- Nettoyage automatique si le tool est retiré
	local ancestryConn
	ancestryConn = tool.AncestryChanged:Connect(function(_, parent)
		if not parent or parent == workspace then
			if motor.Parent then motor:Destroy() end
			rightGrip.Enabled = true
			if ancestryConn then ancestryConn:Disconnect() end
		end
	end)
	return
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

--[[
	@params item: T
	@returns nil
	@description Display the type of the item and the item itself
]]
function Utility.DebugItem<T>(item: T)
	print(`typeof: {typeof(item)} | item: {item}`)
end

return Utility
