--[[
	- Utility
	- Alienduck
	- 16/10/2025
	- v1.0
	@summary Fournit des fonctions utilitaires communes : logs, remote creation, outils joueurs, etc.
]]

---------------------------------------------------------------------
-- Services
---------------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---------------------------------------------------------------------
-- Objet principal
---------------------------------------------------------------------

local Utility = {}

---------------------------------------------------------------------
-- LOGS
---------------------------------------------------------------------

-- Avertissement (Studio uniquement)
function Utility.Warn(message, scriptCall)
	if RunService:IsStudio() then
		warn(`{scriptCall or script.Name}: {message}.`)
	end
end

-- Erreur (Studio uniquement)
function Utility.Error(message, scriptCall)
	if RunService:IsStudio() then
		error(`{scriptCall or script.Name}: {message}.`)
	end
end

---------------------------------------------------------------------
-- FOLDERS & REMOTES
---------------------------------------------------------------------

-- Crée un dossier s’il n’existe pas
function Utility.CreateFolder(name, parent)
	local targetParent = parent or ReplicatedStorage
	local folder = targetParent:FindFirstChild(name)
	if folder and folder:IsA("Folder") then
		return folder
	end
	local newFolder = Instance.new("Folder")
	newFolder.Name = name
	newFolder.Parent = targetParent
	return newFolder
end

-- Crée ou récupère un RemoteEvent
function Utility.CreateRemoteEvent(name, parent, callback)
	local targetParent = parent or ReplicatedStorage
	local remote = targetParent:FindFirstChild(name)

	if remote and remote:IsA("RemoteEvent") then
		if callback then
			if RunService:IsServer() and remote.OnServerEvent then
				if #remote.OnServerEvent:GetConnections() == 0 then
					remote.OnServerEvent:Connect(callback)
				end
			elseif RunService:IsClient() and remote.OnClientEvent then
				if #remote.OnClientEvent:GetConnections() == 0 then
					remote.OnClientEvent:Connect(callback)
				end
			end
		end
		return remote
	end

	remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = targetParent

	if callback then
		if RunService:IsServer() then
			remote.OnServerEvent:Connect(callback)
		else
			remote.OnClientEvent:Connect(callback)
		end
	end

	return remote
end

-- Crée ou récupère un RemoteFunction
function Utility.CreateRemoteFunction(name, parent, callback)
	local targetParent = parent or ReplicatedStorage
	local remote = targetParent:FindFirstChild(name)

	if remote and remote:IsA("RemoteFunction") then
		if callback then
			if RunService:IsServer() and not remote.OnServerInvoke then
				remote.OnServerInvoke = callback
			elseif RunService:IsClient() and not remote.OnClientInvoke then
				remote.OnClientInvoke = callback
			end
		end
		return remote
	end

	remote = Instance.new("RemoteFunction")
	remote.Name = name
	remote.Parent = targetParent

	if callback then
		if RunService:IsServer() then
			remote.OnServerInvoke = callback
		else
			remote.OnClientInvoke = callback
		end
	end

	return remote
end

-- Crée ou récupère un BindableEvent
function Utility.CreateBindableEvent(name, parent, callback)
	local targetParent = parent or ReplicatedStorage
	local existing = targetParent:FindFirstChild(name)
	if existing then
		return existing
	end

	local event = Instance.new("BindableEvent")
	event.Name = name
	event.Parent = targetParent
	if callback then
		event.Event:Connect(callback)
	end
	return event
end

-- Crée ou récupère un BindableFunction
function Utility.CreateBindableFunction(name, parent, callback)
	local targetParent = parent or ReplicatedStorage
	local existing = targetParent:FindFirstChild(name)
	if existing then
		return existing
	end

	local func = Instance.new("BindableFunction")
	func.Name = name
	func.Parent = targetParent
	if callback then
		func.OnInvoke = callback
	end
	return func
end

---------------------------------------------------------------------
-- OBJETS ET OUTILS
---------------------------------------------------------------------

-- Retourne les enfants d’un type donné
function Utility.GetChildrenOfClass(parent, childType)
	local result = {}
	childType = childType or typeof(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA(childType) then
			table.insert(result, child)
		end
	end
	return result
end

-- Retourne un outil depuis le personnage
function Utility.GetToolFromCharacter(character, name)
	local tool = character:FindFirstChildWhichIsA("Tool")
	if not tool and name then
		tool = character:FindFirstChild(name)
	end
	return tool
end

-- Vérifie si le joueur tient un outil
function Utility.IsHoldingTool(character)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			return true
		end
	end
	return false
end

-- Récupère un outil depuis le stockage
function Utility.GetToolByName(toolName, parent)
	local targetParent = parent or ReplicatedStorage
	return targetParent:FindFirstChild(toolName)
end

-- Ajoute un Motor6D temporaire entre la main droite et le handle
function Utility.AddMotorToTool(tool): nil
	local character = tool.Parent
	if not character or not Players:GetPlayerFromCharacter(character) then
		return Utility.Warn("no valid character found", script.Name)
	end

	local handle = tool:FindFirstChild("Handle")
	if not handle then
		return Utility.Warn("no handle found on tool", script.Name)
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return Utility.Warn("no humanoid found", script.Name)
	end

	local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15
	local rightArm = character:FindFirstChild(isR15 and "RightHand" or "Right Arm")
	if not rightArm then
		return Utility.Warn("no right arm found", script.Name)
	end

	local rightGrip = rightArm:FindFirstChild("RightGrip")
	if not rightGrip then
		return Utility.Warn("no RightGrip found", script.Name)
	end

	rightGrip.Enabled = false

	local motor = Instance.new("Motor6D")
	motor.Name = "ToolMotor"
	motor.Part0 = rightArm
	motor.Part1 = handle
	motor.C0 = CFrame.new(0, -rightArm.Size.Y / 2, 0) * CFrame.Angles(-math.pi / 2, 0, 0)
	motor.C1 = tool.Grip
	motor.Parent = rightArm

	local ancestryConn
	ancestryConn = tool.AncestryChanged:Connect(function(_, parent)
		if not parent or parent == workspace then
			if motor.Parent then
				motor:Destroy()
			end
			rightGrip.Enabled = true
			if ancestryConn then
				ancestryConn:Disconnect()
			end
		end
	end)
	return nil
end

---------------------------------------------------------------------
-- INFOS / OUTILS GÉNÉRIQUES
---------------------------------------------------------------------

-- Distance entre deux points
function Utility.GetDistance(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

-- Récupère le shirt d’un personnage
function Utility.GetShirtFromCharacter(character)
	return character:FindFirstChildWhichIsA("Shirt")
end

-- Récupère le pantalon d’un personnage
function Utility.GetPantsFromCharacter(character)
	return character:FindFirstChildWhichIsA("Pants")
end

-- Debug : affiche le type et la valeur d’un élément
function Utility.DebugItem(item)
	print(`typeof: {typeof(item)} | item: {item}`)
end

---------------------------------------------------------------------
-- RETURN
---------------------------------------------------------------------

return Utility
