-- src/client/Player/FootstepController.luau (Refactorisé)
local InitClient = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Modules
local Utility = require(ReplicatedStorage.Shared.Utility)

-- Constantes
local PLAYER_RUN_SPEED = 16
local WALK_STEP_COOLDOWN = 0.45
local RUN_STEP_COOLDOWN = 0.3

-- Constantes pour la caméra
local CAMERA_SWAY_MAGNITUDE_WALK_Y = 0.02 -- Amplitude verticale en marchant Default: 0.05
local CAMERA_SWAY_MAGNITUDE_WALK_X = 0.01 -- Amplitude latérale en marchant Default: 0.02
local CAMERA_SWAY_FREQUENCY_WALK = 15 -- Vitesse de l'oscillation en marchant Default: 15

local CAMERA_SWAY_MAGNITUDE_RUN_Y = 0.08 -- Amplitude verticale en courant Default: 0.12
local CAMERA_SWAY_MAGNITUDE_RUN_X = 0.02 -- Amplitude latérale en courant Default: 0.04
local CAMERA_SWAY_FREQUENCY_RUN = 30 -- Vitesse de l'oscillation en courant Default: 30

local CAMERA_TILT_MAGNITUDE_WALK = 0.01 -- Inclinaison latérale de la caméra Default: 0.01
local CAMERA_TILT_MAGNITUDE_RUN = 0.02 -- Inclinaison latérale de la caméra Default: 0.02

local cameraSwayTime = 0 -- Compteur de temps pour l'onde sinusoïdale de la caméra
local cameraRenderConn: RBXScriptConnection? = nil
local NOISE_SEED = math.random() * 1000

local soundMap = {
	[Enum.Material.Grass] = "rbxassetid://7003103812",
	[Enum.Material.Wood] = "rbxassetid://87921439933530",
	[Enum.Material.Concrete] = "rbxassetid://5676547800",
	[Enum.Material.Metal] = "rbxassetid://78580994772675",
	[Enum.Material.Sand] = "rbxassetid://105793766638092",
	[Enum.Material.Glass] = "rbxassetid://3437778169",
}
local DEFAULT_SOUND = "rbxassetid://86112804976337"

-- Variables de scope du Module
local Player: Player = Players.LocalPlayer
local connections = {}

local function RootPartChildAdded(child: Instance)
	if child:IsA("Sound") and child.Name ~= "FootstepSound" then
		child:Destroy()
	end
end

local function updateCameraSway(deltaTime: number, Humanoid: Humanoid)
	local currentCamera = workspace.CurrentCamera
	if not currentCamera or currentCamera.CameraType ~= Enum.CameraType.Custom then
		return
	end

	local moveDirectionMagnitude = Humanoid.MoveDirection.Magnitude
	local currentSpeed = Humanoid.WalkSpeed

	local targetSwayMagnitudeY = 0
	local targetSwayMagnitudeX = 0
	local targetSwayFrequency = 0
	local targetTiltMagnitude = 0

	local isMoving = moveDirectionMagnitude > 0 and Humanoid.FloorMaterial ~= Enum.Material.Air

	if isMoving then
		if currentSpeed == PLAYER_RUN_SPEED then
			targetSwayMagnitudeY = CAMERA_SWAY_MAGNITUDE_RUN_Y
			targetSwayMagnitudeX = CAMERA_SWAY_MAGNITUDE_RUN_X
			targetSwayFrequency = CAMERA_SWAY_FREQUENCY_RUN
			targetTiltMagnitude = CAMERA_TILT_MAGNITUDE_RUN
		else -- Marcher
			targetSwayMagnitudeY = CAMERA_SWAY_MAGNITUDE_WALK_Y
			targetSwayMagnitudeX = CAMERA_SWAY_MAGNITUDE_WALK_X
			targetSwayFrequency = CAMERA_SWAY_FREQUENCY_WALK
			targetTiltMagnitude = CAMERA_TILT_MAGNITUDE_WALK
		end
	end

	if isMoving then
		cameraSwayTime = cameraSwayTime + (deltaTime * targetSwayFrequency)
	else
		cameraSwayTime = cameraSwayTime - (deltaTime * targetSwayFrequency * 0.5)
		cameraSwayTime = math.max(0, cameraSwayTime)
	end

	local noiseTimeFactor = cameraSwayTime / 10 -- Ralentir le bruit pour des variations douces

	-- Calcule un bruit de Perlin 1D pour chaque axe
	local noiseY = math.noise(NOISE_SEED, noiseTimeFactor)
	local noiseX = math.noise(NOISE_SEED + 100, noiseTimeFactor) -- Utilise un décalage de graine
	local noiseZ = math.noise(NOISE_SEED + 200, noiseTimeFactor) -- Utilise un autre décalage

	-- Mouvement de base (rythmé par les pas) + Mouvement organique (irrégulier)
	local swayY = targetSwayMagnitudeY * (math.sin(cameraSwayTime) + (noiseY * 0.5))
	local swayX = targetSwayMagnitudeX * (math.sin(cameraSwayTime * 0.5 + math.pi / 2) + (noiseX * 0.5))
	local tiltZ = targetTiltMagnitude * (math.sin(cameraSwayTime * 0.5) + (noiseZ * 0.5))

	-- Normalisation: Limiter l'amplitude totale pour éviter les mouvements excessifs
	swayY = swayY / 1.5
	swayX = swayX / 1.5
	tiltZ = tiltZ / 1.5

	local cameraCFrame = currentCamera.CFrame

	-- Le hack: changer le type, appliquer, et revenir en arrière immédiatement
	-- Cela permet de "forcer" le mouvement de balancement sur le CFrame calculé par le Custom/Classic

	-- Sauvegarder l'état
	local originalType = currentCamera.CameraType

	-- Appliquer la transformation
	currentCamera.CameraType = Enum.CameraType.Scriptable
	local newCFrame = cameraCFrame * CFrame.new(swayX, swayY, 0) * CFrame.Angles(0, 0, tiltZ)
	currentCamera.CFrame = newCFrame

	-- Rétablir l'état
	currentCamera.CameraType = originalType
end

local function startCameraSway(Humanoid: Humanoid)
	if cameraRenderConn then
		cameraRenderConn:Disconnect()
	end
	-- Utiliser RenderStepped pour la caméra
	cameraRenderConn = RunService.RenderStepped:Connect(function(deltaTime)
		updateCameraSway(deltaTime, Humanoid)
	end)
	table.insert(connections, cameraRenderConn) -- Ajouté à la table connections pour le nettoyage
end

local function startFootstepLogic(Humanoid: Humanoid, RootPart: BasePart): RBXScriptConnection
	local footstepSound = Instance.new("Sound")
	footstepSound.Name = "FootstepSound"
	footstepSound.Volume = 0.25
	footstepSound.Parent = RootPart

	local lastStepTime = 0

	local heartbeatConn = RunService.Heartbeat:Connect(function(deltaTime: number)
		local currentTime = time()
		local moveDirectionMagnitude = Humanoid.MoveDirection.Magnitude
		local floorMaterial = Humanoid.FloorMaterial

		if not Humanoid.Parent then
			Utility.Warn(`No humanoid found for {Player.Name}`, script.Name)
			return
		end

		if moveDirectionMagnitude > 0 and floorMaterial ~= Enum.Material.Air then
			local currentCooldown = Humanoid.WalkSpeed == PLAYER_RUN_SPEED and RUN_STEP_COOLDOWN or WALK_STEP_COOLDOWN

			if currentTime - lastStepTime > currentCooldown then
				local soundId = soundMap[floorMaterial] or DEFAULT_SOUND

				if footstepSound.SoundId ~= soundId then
					footstepSound.SoundId = soundId
				end
				footstepSound.PlaybackSpeed = math.random(90, 110) / 100
				footstepSound:Play()

				lastStepTime = currentTime
			end
		else
			if footstepSound.IsPlaying then
				footstepSound:Stop()
			end
		end
	end)

	return heartbeatConn
end

-- Dans characterLifeCycle
local function characterLifeCycle()
	local Character = Player.Character or Player.CharacterAdded:Wait()

	local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
	local RootPart = Character:WaitForChild("HumanoidRootPart") :: BasePart
	for _, child in ipairs(RootPart:GetChildren()) do
		if child:IsA("Sound") then
			child:Destroy()
		end
	end

	local rootConn = RootPart.ChildAdded:Connect(RootPartChildAdded)
	table.insert(connections, rootConn) -- Ajouté à la table connections
	local heartbeatConn = startFootstepLogic(Humanoid, RootPart)
	table.insert(connections, heartbeatConn) -- Ajouté à la table connections

	-- NOUVEAU: Démarrer la logique de balancement de caméra
	startCameraSway(Humanoid)

	Humanoid.Died:Wait()

	-- Le nettoyage sera fait par PlayerRemoving, mais déconnectons explicitement ici pour la clarté.
	-- Surtout, déconnecter les connexions spécifiques à ce personnage:
	rootConn:Disconnect()
	heartbeatConn:Disconnect()

	-- La connexion de caméra sera déconnectée par PlayerRemoving, mais vous pouvez aussi la déconnecter ici
	-- pour s'assurer que l'effet s'arrête immédiatement après la mort, puis redémarrera au respawn.
	if cameraRenderConn then
		cameraRenderConn:Disconnect()
		cameraRenderConn = nil
	end
end

-- Loader
function InitClient.Load()
	connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
		if player == Player then
			for _, conn in pairs(connections) do
				conn:Disconnect()
			end
		end
	end)

	task.spawn(function()
		while Player.Parent do
			characterLifeCycle()
		end
	end)
end

return InitClient
