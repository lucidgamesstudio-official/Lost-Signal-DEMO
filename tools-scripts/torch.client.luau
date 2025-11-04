-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Modules
local Utility = require(ReplicatedStorage.Shared.Utility)

-- Player Setup
local camera: Camera = workspace.CurrentCamera
local player: Player = Players.LocalPlayer
local character: Model = player.Character or player.CharacterAdded:Wait()
local humanoid: Humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid

-- Check for Character/Humanoid (Important)
if not humanoid then
	character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	if not humanoid then
		Utility.Warn("[WARN] No humanoid found", script.Name)
		return
	end
end

-- Torch Components
local TorchTool: Tool = script.Parent
local Handle: MeshPart = TorchTool:FindFirstChild("Handle") :: MeshPart
local LightPart: MeshPart = TorchTool:FindFirstChild("Light") :: MeshPart
local TextePart: MeshPart = TorchTool:FindFirstChild("Texte") :: MeshPart
local Light: SpotLight = LightPart:FindFirstChildOfClass("SpotLight") :: SpotLight

if not (Handle and LightPart and Light and TextePart) then
	Utility.Warn("[WARN] Composants de la torche manquants.", script.Name)
	return
end

-- Constantes
local MAX_PITCH_ANGLE = math.rad(80) -- Limite de rotation (60 degrés haut/bas)
local ROTATION_SPEED: number = 0.05 -- Facteur de lissage pour la rotation

-- Variables
local isTurnOn: boolean = false
local smoothedPitch: number = 0 -- Angle vertical lissé actuel
local initialGripC0: CFrame = CFrame.new() -- Stocke le CFrame initiale de l'outil
local initialPitch: number = 0 -- Pitch initial du grip
local initialYaw: number = 0 -- Yaw initial du grip
local initialRoll: number = 0 -- Roll initial du grip

-- Connections
local activated: RBXScriptConnection?
local renderSteppedConn: RBXScriptConnection?
local equippedConn: RBXScriptConnection?

-- Function to safely retrieve the RightGrip Weld
local function getRightGrip()
	local RightHand: BasePart = character:FindFirstChild("RightHand") :: BasePart
	if character and RightHand then
		return RightHand:FindFirstChild("RightGrip") :: Weld
	end
	return nil
end

-- Helper function to calculate target pitch from camera (Formule Cartésienne adaptée)
local function getTargetPitch(): number
	local cameraCFrame = camera.CFrame
	local lookVector = cameraCFrame.LookVector

	-- Calcul pitch angle (vertical rotation). L'inversion de lookVector.Y corrige le sens (je sais pas pourquoi).
	local horizontalMag = math.sqrt(lookVector.X * lookVector.X + lookVector.Z * lookVector.Z)
	local pitch = math.atan2(lookVector.Y, horizontalMag) -- ON NE FAIT PAS -lookVector.Y car atan2 retourne un angle en fonction de Y.
	-- Utiliser l'angle directement en le limitant et appliquer un offset.

	-- Clamp the pitch angle
	return math.clamp(pitch, -MAX_PITCH_ANGLE, MAX_PITCH_ANGLE) -- Limitation de l'angle ICI
end

-- Logique d'équipement pour capturer le CFrame de base
equippedConn = TorchTool.Equipped:Connect(function()
	local rightGrip = getRightGrip()
	if rightGrip then
		-- Capture le CFrame de base (position + orientation)
		initialGripC0 = rightGrip.C0
		-- Extrait les angles initiaux pour les conserver. Ordre: X (Pitch), Y (Yaw), Z (Roll)
		initialPitch, initialYaw, initialRoll = initialGripC0:ToEulerAnglesXYZ()
	end
end)

-- Logic
activated = TorchTool.Activated:Connect(function()
	local rightGrip = getRightGrip()
	if not rightGrip then
		return
	end

	if isTurnOn then
		-- Désactiver
		isTurnOn = false
		TextePart.Material = Enum.Material.SmoothPlastic
		Light.Enabled = false
		LightPart.Material = Enum.Material.Glass

		-- Rétablir l'orientation initiale complète de l'outil
		rightGrip.C0 = initialGripC0

		if renderSteppedConn then
			renderSteppedConn:Disconnect()
			renderSteppedConn = nil
		end
	else
		-- Activer
		isTurnOn = true
		TextePart.Material = Enum.Material.Neon
		Light.Enabled = true
		LightPart.Material = Enum.Material.Neon

		-- Commence au pitch par défaut
		smoothedPitch = initialPitch

		renderSteppedConn = RunService.RenderStepped:Connect(function(deltaTime: number)
			-- 1. Quand le joueur est statique, suivre la vue
			if humanoid.MoveDirection.Magnitude <= 0 then
				-- Récupère l'angle de pitch de la caméra (limité par MAX_PITCH_ANGLE)
				local targetPitch = getTargetPitch()
				local finalPitch = initialPitch + targetPitch

				-- Lissage
				local delta = finalPitch - smoothedPitch
				if delta > math.pi then
					delta = delta - 2 * math.pi
				end
				if delta < -math.pi then
					delta = delta + 2 * math.pi
				end

				smoothedPitch = smoothedPitch + delta * ROTATION_SPEED

				-- Application au RightGrip (Compatible R15 only du coup)
				local finalC0 = CFrame.new(initialGripC0.Position)
					* CFrame.Angles(smoothedPitch, initialYaw, initialRoll)

				rightGrip.C0 = finalC0

			-- 2. Quand le joueur bouge, retourner à la position de repos
			else
				local targetPitch = initialPitch

				-- Lissage vers la position de repos
				local delta = targetPitch - smoothedPitch
				if delta > math.pi then
					delta = delta - 2 * math.pi
				end
				if delta < -math.pi then
					delta = delta + 2 * math.pi
				end

				smoothedPitch = smoothedPitch + delta * ROTATION_SPEED * 2 -- Retour plus rapide (sinon c'était vraiment lent)

				-- Application au RightGrip
				local finalC0 = CFrame.new(initialGripC0.Position)
					* CFrame.Angles(smoothedPitch, initialYaw, initialRoll)

				rightGrip.C0 = finalC0

				-- Si l'angle est proche du neutre, on le snap pour éviter les calculs inutiles
				if math.abs(delta) < 0.005 then
					rightGrip.C0 = initialGripC0
					smoothedPitch = initialPitch
				end
			end
		end)
	end
end)

-- TODO Les events pour éteindre manuellement la lampe avec un script serveur.

TorchTool.Destroying:Once(function()
	if activated then
		activated:Disconnect()
		activated = nil
	end
	if renderSteppedConn then
		renderSteppedConn:Disconnect()
		renderSteppedConn = nil
	end
	if equippedConn then
		equippedConn:Disconnect()
		equippedConn = nil
	end
end)
