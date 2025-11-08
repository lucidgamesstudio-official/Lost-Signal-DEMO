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

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestService = game:GetService("TestService")

---------------------------------------------------------------------
-- Objet principal
---------------------------------------------------------------------

local Utility = {}

---------------------------------------------------------------------
-- LOGS
---------------------------------------------------------------------

-- Information (Studio uniquement)
function Utility.Info(message: string, scriptCall: string?)
	if RunService:IsStudio() then
		TestService:Message(`[INFO]: {message} | [FROM]: {scriptCall or script.Name}`)
	end
end

-- Avertissement (Studio uniquement)
function Utility.Warn(message: string, scriptCall: string?)
	if RunService:IsStudio() then
		warn(`{scriptCall or script.Name}: {message}.`)
	end
end

-- Erreur (Studio uniquement)
function Utility.Error(message: string, scriptCall: string?)
	if RunService:IsStudio() then
		error(`{scriptCall or script.Name}: {message}.`)
	end
end

---------------------------------------------------------------------
-- FOLDERS & REMOTES
---------------------------------------------------------------------

-- Crée un dossier s’il n’existe pas
function Utility.CreateFolder(name: string, parent: Instance?)
	local targetParent = parent or ReplicatedStorage
	local existing = targetParent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end

	if RunService:IsClient() then
		-- Attendre jusqu'à 5s que le serveur le crée
		local replicated = targetParent:WaitForChild(name, 5)
		if replicated and replicated:IsA("Folder") then
			return replicated
		end
		-- Si toujours rien, log et créer en dernier recours
		Utility.Warn(`[Utility] Création forcée du dossier '${name}' côté client`, script.Name)
	end

	local newFolder = Instance.new("Folder")
	newFolder.Name = name
	newFolder.Parent = targetParent
	return newFolder
end

-- Crée ou récupère un RemoteEvent
function Utility.CreateRemoteEvent(
	name: string,
	parent: Instance?,
	callback: ({}) -> ()? | (player: Player, ...any) -> ()?
): RemoteEvent
	local targetParent = parent or ReplicatedStorage
	local remote: RemoteEvent = targetParent:FindFirstChild(name)

	if remote and remote:IsA("RemoteEvent") then
		if callback then
			if RunService:IsServer() and remote.OnServerEvent then
				remote.OnServerEvent:Connect(callback :: (Player, ...any) -> ())
			elseif RunService:IsClient() and remote.OnClientEvent then
				remote.OnClientEvent:Connect(callback)
			end
		end
		return remote
	end

	local newRemote = Instance.new("RemoteEvent")
	newRemote.Name = name
	newRemote.Parent = targetParent

	if callback then
		if RunService:IsServer() then
			newRemote.OnServerEvent:Connect(callback)
		else
			newRemote.OnClientEvent:Connect(callback)
		end
	end

	return newRemote
end

-- Crée ou récupère un RemoteFunction
function Utility.CreateRemoteFunction(name: string, parent: Instance?, callback: ({}) -> ()?): RemoteFunction
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
function Utility.CreateBindableEvent(name: string, parent: Instance?, callback: ({}) -> ()?): BindableEvent
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
function Utility.CreateBindableFunction(name: string, parent: Instance?, callback: ({}) -> ()?): BindableFunction
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
function Utility.GetChildrenOfClass<T>(parent: Instance, childType: string?): { T }
	local result: { T } = {}
	childType = childType or typeof(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA(childType) then
			table.insert(result, child)
		end
	end
	return result
end

-- Retourne un outil depuis le personnage
function Utility.GetToolFromCharacter(character: Model, name: string?): Tool?
	local tool = character:FindFirstChildWhichIsA("Tool")
	if not tool and name then
		tool = character:FindFirstChild(name)
	end
	return tool
end

-- Vérifie si le joueur tient un outil
function Utility.IsHoldingTool(character: Model): boolean
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			return true
		end
	end
	return false
end

-- Récupère un outil depuis le stockage
function Utility.GetToolByName(toolName: string, parent: Instance?): Tool?
	local targetParent = parent or ReplicatedStorage
	return targetParent:FindFirstChild(toolName)
end

-- Ajoute un Motor6D temporaire entre la main droite et le handle
function Utility.AddMotorToTool(tool: Tool): nil
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
function Utility.GetDistance(pos1: Vector3, pos2: Vector3): number
	return (pos1 - pos2).Magnitude
end

-- Compute the HipHeight of HumanoidRootPart
function Utility.ComputeHipHeight(humanoid: Humanoid, root: BasePart, model: Model)
	local rayOrigin = root.Position
	local rayDirection = Vector3.new(0, -10, 0)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { model }
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if result then
		local distance = (root.Position.Y - result.Position.Y)
		humanoid.HipHeight = distance
	end
end

-- Génère un nombre aléatoire entre un minimum et un maximum
function Utility.random(min: number?, max: number?)
	local minNumber: number = min or 0
	local maxNumber: number = max or 1
	return minNumber + math.random() * (maxNumber - minNumber)
end

-- Récupère le shirt d’un personnage
function Utility.GetShirtFromCharacter(character: Model): Shirt?
	return character:FindFirstChildWhichIsA("Shirt")
end

-- Récupère le pantalon d’un personnage
function Utility.GetPantsFromCharacter(character: Model): Pants?
	return character:FindFirstChildWhichIsA("Pants")
end

-- Cut toutes les animations en cours et retourne le nombre d'animations arrêtées
function Utility.StopAllAnimations(animator: Animator): number
	local nb: number = 0
	for _, animTrack in animator:GetPlayingAnimationTracks() do
		animTrack:Stop()
		nb += 1
	end
	return nb
end

-- Debug : affiche le type et la valeur d’un élément
function Utility.DebugItem<T>(item: T)
	print(`typeof: {typeof(item)} | item: {item}`)
end

-- Make visual effect for waypoint
function Utility.VisualizeWaypoint(position: Vector3, index: number, previousWaypoint: any?)
	if not RunService:IsStudio() then
		return
	end

	local marker = Instance.new("Part")
	marker.Size = Vector3.new(0.6, 0.6, 0.6)
	marker.Shape = Enum.PartType.Ball
	marker.Color = Color3.fromRGB(255, 0, 0)
	marker.Anchored = true
	marker.CanCollide = false
	marker.CFrame = CFrame.new(position)
	marker.Parent = workspace
	Debris:AddItem(marker, 5)

	if previousWaypoint and previousWaypoint.Position then
		local prevPos = previousWaypoint.Position
		local dist = (position - prevPos).Magnitude
		local line = Instance.new("Part")
		line.Anchored = true
		line.CanCollide = false
		line.Size = Vector3.new(0.2, 0.2, dist)
		line.CFrame = CFrame.lookAt(prevPos, position) * CFrame.new(0, 0, -dist / 2)
		line.Color = Color3.fromRGB(255, 200, 200)
		line.Material = Enum.Material.Neon
		line.Parent = workspace
		Debris:AddItem(line, 5)
	end
end

---------------------------------------------------------------------
-- RETURN
---------------------------------------------------------------------

return Utility
