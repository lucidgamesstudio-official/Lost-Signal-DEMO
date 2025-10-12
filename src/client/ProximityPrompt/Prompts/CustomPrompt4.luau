-- This is a prompt module, so it's easier to create multiple prompts with different animations, and you don't have to write everything in a separate script, so you can have multiple custom prompts.

-- Object
local Module = {}
Module.activePrompts = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Modules
local TextModule = require(script.Parent.Parent.Modules.PromptText)

-- Gui
local CustomPrompt = ReplicatedStorage:FindFirstChild("ProxisGui"):FindFirstChild(script.Name)

local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function GetPromptFace(part, playerPosition, allowedFacesFolder)
	local directionToPlayer = (playerPosition - part.Position).Unit
	local localDir = part.CFrame:VectorToObjectSpace(directionToPlayer)
	local faces = {}
	if typeof(allowedFacesFolder) == "Instance" and allowedFacesFolder:IsA("Folder") then
		for _, child in pairs(allowedFacesFolder:GetChildren()) do
			if child:IsA("BoolValue") and Enum.NormalId[child.Name] ~= nil then
				faces[child.Name] = child.Value
			end
		end
	end
	if faces.Front and localDir.Z < -0.5 then
		return Enum.NormalId.Front
	elseif faces.Back and localDir.Z > 0.5 then
		return Enum.NormalId.Back
	elseif faces.Left and localDir.X < -0.5 then
		return Enum.NormalId.Left
	elseif faces.Right and localDir.X > 0.5 then
		return Enum.NormalId.Right
	elseif faces.Top and localDir.Y > 0.5 then
		return Enum.NormalId.Top
	elseif faces.Bottom and localDir.Y < -0.5 then
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

	local bestScore = -math.huge
	local bestFace = nil

	for faceName, _ in pairs(faces) do
		if faces[faceName] and scores[faceName] and scores[faceName] > bestScore then
			bestScore = scores[faceName]
			bestFace = faceName
		end
	end

	if bestFace then
		return Enum.NormalId[bestFace]
	end

	return nil
end

local function stopAllTweens(data)
	if data.holdTween then
		data.holdTween:Cancel()
	end
	if data.revertTween then
		data.revertTween:Cancel()
	end
end

function Module:onShown(Prompt, InputType, Player)
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
	local face = GetPromptFace(Prompt.Parent, Player.Character.HumanoidRootPart.Position, faceFolder)
	if face then
		PromptClone.Face = face
	end

	PromptClone.Face = face
	PromptClone.Name = "CustomPrompt"
	PromptClone.Enabled = true
	canvasGroup.GroupTransparency = 1
	PromptClone.Adornee = Prompt.Parent
	PromptClone.Parent = Player.PlayerGui.CustomPrompts

	Prompt.CustomPromptConf.ObjectValue.Value = PromptClone

	local appearTween = TweenService:Create(canvasGroup, tweenInfo, {
		GroupTransparency = 0,
	})
	appearTween:Play()

	Module.activePrompts[Prompt] = {
		clone = PromptClone,
		gui = gui,
	}
end

function Module:onHidden(Prompt, Player)
	local data = Module.activePrompts[Prompt]
	if not data or not data.clone then
		return
	end

	local canvasGroup = data.clone:FindFirstChild("CanvasGroup")
	if not canvasGroup then
		data.clone:Destroy()
		Module.activePrompts[Prompt] = nil
		return
	end

	local disappearTween = TweenService:Create(canvasGroup, tweenInfo, {
		GroupTransparency = 1,
	})
	disappearTween:Play()

	disappearTween.Completed:Connect(function()
		if data.clone then
			data.clone:Destroy()
		end
	end)

	Module.activePrompts[Prompt] = nil
end

function Module:onTriggered(Prompt, Player) end

function Module:onHoldStart(Prompt, Player)
	local data = Module.activePrompts[Prompt]
	if not data then
		return
	end
	local gui = data.gui
	local textFrame = gui.TextFrame
	local holdBar = data.gui.InputFrame.Frame.ProgressBar.Bar
	if not holdBar then
		return
	end

	stopAllTweens(data)

	local currentSize = holdBar.Size
	local remainingScale
	if currentSize == UDim2.new(1, 0, 0, 0) then
		remainingScale = 1 - currentSize.Y.Scale
	else
		remainingScale = 1.1 - currentSize.Y.Scale
	end

	local duration = Prompt.HoldDuration * remainingScale
	local info = TweenInfo.new(duration, Enum.EasingStyle.Linear)
	local goal = { Size = UDim2.new(1, 0, 1, 0) }
	TweenService:Create(textFrame, tweenInfo, { GroupTransparency = 1 }):Play()
	data.holdTween = TweenService:Create(holdBar, info, goal)
	data.holdTween:Play()
end

function Module:onHoldEnd(Prompt, Player)
	local data = Module.activePrompts[Prompt]
	if not data then
		return
	end
	local gui = data.gui
	local textFrame = gui.TextFrame
	local holdBar = data.gui.InputFrame.Frame.ProgressBar.Bar
	if not holdBar then
		return
	end

	stopAllTweens(data)

	local info = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
	local goal = { Size = UDim2.new(1, 0, 0, 0) }
	TweenService:Create(textFrame, tweenInfo, { GroupTransparency = 0 }):Play()
	data.revertTween = TweenService:Create(holdBar, info, goal)
	data.revertTween:Play()
end

return Module
