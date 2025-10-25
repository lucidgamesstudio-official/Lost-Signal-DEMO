--[[
	- CustomPrompt5
	- Alienduck
	- 16/10/2025
	- v1.0
]]

-- Object
local CustomPrompt5 = {}
CustomPrompt5.__index = CustomPrompt5
CustomPrompt5.activePrompts = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Modules
local Utility = require(ReplicatedStorage.Shared.Utility)
local TextModule = require(script.Parent.Parent.Modules.PromptText)

-- Gui
local CustomPrompt = ReplicatedStorage:FindFirstChild("ProxisGui"):FindFirstChild(script.Name)

-- Constants
local UI_TWEEN = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Private
local function stopAllTweens(data)
	if data.holdTween then
		data.holdTween:Cancel()
	end
	if data.revertTween then
		data.revertTween:Cancel()
	end
end

local function getPromptFace(part, playerPosition, allowedFacesFolder)
	local direction = (playerPosition - part.Position).Unit
	local localDir = part.CFrame:VectorToObjectSpace(direction)
	local faces = {}

	if typeof(allowedFacesFolder) == "Instance" and allowedFacesFolder:IsA("Folder") then
		for _, child in pairs(allowedFacesFolder:GetChildren()) do
			if child:IsA("BoolValue") and Enum.NormalId[child.Name] then
				faces[child.Name] = child.Value
			end
		end
	end

	if faces.Front and localDir.Z < -0.5 then
		return Enum.NormalId.Front
	end
	if faces.Back and localDir.Z > 0.5 then
		return Enum.NormalId.Back
	end
	if faces.Left and localDir.X < -0.5 then
		return Enum.NormalId.Left
	end
	if faces.Right and localDir.X > 0.5 then
		return Enum.NormalId.Right
	end
	if faces.Top and localDir.Y > 0.5 then
		return Enum.NormalId.Top
	end
	if faces.Bottom and localDir.Y < -0.5 then
		return Enum.NormalId.Bottom
	end

	local scores = {
		Front = math.abs(localDir.Z),
		Back = math.abs(localDir.Z),
		Left = math.abs(localDir.X),
		Right = math.abs(localDir.X),
		Top = math.abs(localDir.Y),
		Bottom = math.abs(localDir.Y),
	}

	local bestFace, bestScore = nil, -math.huge
	for face, _ in pairs(faces) do
		if faces[face] and scores[face] and scores[face] > bestScore then
			bestFace, bestScore = face, scores[face]
		end
	end

	return bestFace and Enum.NormalId[bestFace] or nil
end

-- Methods
function CustomPrompt5:onShown(Prompt, InputType, Player)
	local PromptClone = CustomPrompt:Clone()
	local canvasGroup = PromptClone.CanvasGroup
	local gui = canvasGroup.Frame
	local textFrame = gui.TextFrame
	local inputFrame = gui.InputFrame

	TextModule:SetText(Prompt, InputType, textFrame, inputFrame)

	if InputType == Enum.ProximityPromptInputType.Touch or Prompt.ClickablePrompt then
		local button = Instance.new("TextButton")
		button.BackgroundTransparency = 1
		button.TextTransparency = 1
		button.Size = UDim2.fromScale(1, 1)
		button.Parent = PromptClone

		local buttonDown = false

		button.InputBegan:Connect(function(input)
			if
				(
					input.UserInputType == Enum.UserInputType.Touch
					or input.UserInputType == Enum.UserInputType.MouseButton1
				) and input.UserInputState ~= Enum.UserInputState.Change
			then
				Prompt:InputHoldBegin()
				buttonDown = true
			end
		end)

		button.InputEnded:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				if buttonDown then
					buttonDown = false
					Prompt:InputHoldEnd()
				end
			end
		end)
	end

	local faceFolder = Prompt.CustomPromptConf.Faces
	local face = getPromptFace(Prompt.Parent, Player.Character.HumanoidRootPart.Position, faceFolder)
	if face then
		PromptClone.Face = face
	end

	PromptClone.Name = "CustomPrompt"
	PromptClone.Enabled = true
	canvasGroup.GroupTransparency = 1
	PromptClone.Adornee = Prompt.Parent
	PromptClone.Parent = Player.PlayerGui.CustomPrompts
	Prompt.CustomPromptConf.ObjectValue.Value = PromptClone

	TweenService:Create(canvasGroup, UI_TWEEN, { GroupTransparency = 0 }):Play()
	CustomPrompt5.activePrompts[Prompt] = { clone = PromptClone, gui = gui }
end

function CustomPrompt5:onHidden(Prompt, Player)
	local data = CustomPrompt5.activePrompts[Prompt]
	if not data or not data.clone then
		return
	end

	local canvasGroup = data.clone:FindFirstChild("CanvasGroup")
	if not canvasGroup then
		data.clone:Destroy()
		CustomPrompt5.activePrompts[Prompt] = nil
		return
	end

	local disappearTween = TweenService:Create(canvasGroup, UI_TWEEN, { GroupTransparency = 1 })
	disappearTween:Play()

	disappearTween.Completed:Connect(function()
		if data.clone then
			data.clone:Destroy()
		end
	end)

	CustomPrompt5.activePrompts[Prompt] = nil
end

function CustomPrompt5:onTriggered(Prompt, Player) end

function CustomPrompt5:onHoldStart(Prompt, Player)
	local data = CustomPrompt5.activePrompts[Prompt]
	if not data then
		return
	end

	local gui = data.gui
	local textFrame = gui.TextFrame
	local holdBar = gui.InputFrame.Frame.ProgressBar.Bar
	if not holdBar then
		return
	end
    local beam: Beam = Prompt.Parent:FindFirstChildOfClass("Beam") :: Beam
    if not beam then
        Utility.Warn(`No beam found on prompt: {tostring(Prompt)}`, script.Name)
    end
    local HoldSpeed: NumberValue = beam:FindFirstChild("HoldSpeed") :: NumberValue
    if HoldSpeed then
        beam.TextureSpeed = HoldSpeed.Value
    end

	stopAllTweens(data)

	local currentSize = holdBar.Size
	local remainingScale = currentSize == UDim2.new(1, 0, 0, 0) and (1 - currentSize.Y.Scale)
		or (1.1 - currentSize.Y.Scale)
	local duration = Prompt.HoldDuration * remainingScale

	TweenService:Create(textFrame, UI_TWEEN, { GroupTransparency = 1 }):Play()
	data.holdTween = TweenService:Create(holdBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Size = UDim2.new(1, 0, 1, 0),
	})
	data.holdTween:Play()
end

function CustomPrompt5:onHoldEnd(Prompt, Player)
	local data = CustomPrompt5.activePrompts[Prompt]
	if not data then
		return
	end

	local gui = data.gui
	local textFrame = gui.TextFrame
	local holdBar = gui.InputFrame.Frame.ProgressBar.Bar
	if not holdBar then
		return
	end
    local beam: Beam = Prompt.Parent:FindFirstChildOfClass("Beam") :: Beam
    if not beam then
        Utility.Warn(`No beam found on prompt: {tostring(Prompt)}`, script.Name)
    end
    local DefaultSpeed: NumberValue = beam:FindFirstChild("DefaultSpeed") :: NumberValue
    if DefaultSpeed then
        beam.TextureSpeed = DefaultSpeed.Value
    end

	stopAllTweens(data)

	TweenService:Create(textFrame, UI_TWEEN, { GroupTransparency = 0 }):Play()
	data.revertTween = TweenService:Create(holdBar, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {
		Size = UDim2.new(1, 0, 0, 0),
	})
	data.revertTween:Play()
end

return CustomPrompt5
