-- This is a prompt module, so it's easier to create multiple prompts with different animations, and you don't have to write everything in a separate script, so you can have multiple custom prompts.

-- Object
local Module = {}
Module.activePrompts = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Modules
local TextModule = require(script.Parent.Parent.Modules.PromptText)

local uiTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function stopTweens(data)
	if data.holdTween then
		data.holdTween:Cancel()
	end
	if data.revertTween then
		data.revertTween:Cancel()
	end
end

function Module:onShown(prompt, inputType, player)
	local PromptClone = ReplicatedStorage:FindFirstChild("ProxisGui"):FindFirstChild(script.Name):Clone()
	local gui = PromptClone.CanvasGroup.Frame
	local textFrame = gui.TextFrame
	local inputFrame = gui.InputFrame

	if prompt.ObjectText == "" and prompt.ActionText == "" then
		textFrame.GroupTransparency = 1
		inputFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	end

	TextModule:SetText(prompt, inputType, textFrame, inputFrame)
	if inputType == Enum.ProximityPromptInputType.Touch or prompt.ClickablePrompt then
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
				prompt:InputHoldBegin()
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
					prompt:InputHoldEnd()
				end
			end
		end)
	end
	PromptClone.Name = "CustomPrompt"
	PromptClone.Enabled = true
	PromptClone.CanvasGroup.GroupTransparency = 1
	PromptClone.Parent = player.PlayerGui.CustomPrompts
	PromptClone.Adornee = prompt.Parent
	prompt.CustomPromptConf.ObjectValue.Value = PromptClone

	local appearTween = TweenService:Create(PromptClone.CanvasGroup, uiTweenInfo, {
		GroupTransparency = 0,
	})
	appearTween:Play()

	self.activePrompts[prompt] = {
		gui = gui,
		clone = PromptClone,
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

	local disappearTween = TweenService:Create(canvasGroup, uiTweenInfo, {
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
function Module:onTriggered(prompt, player) end

function Module:onHoldStart(prompt, player)
	local data = self.activePrompts[prompt]
	if not data then
		return
	end

	local gui = data.gui
	local holdBar = gui.InputFrame.Frame.ProgressBar.Bar
	local textFrame = gui.TextFrame
	local inputFrame = gui.InputFrame

	if not holdBar then
		return
	end
	stopTweens(data)

	local currentRotation = holdBar.Rotation
	local targetRotation = 135
	local angleRange = currentRotation == -135 and 270 or 195 - currentRotation
	local progressRatio = math.clamp(angleRange / 270, 0, 1)
	local holdDuration = prompt.HoldDuration * progressRatio

	if prompt.ObjectText ~= "" or prompt.ActionText ~= "" then
		TweenService:Create(inputFrame, uiTweenInfo, { Position = UDim2.new(0.5, 0, 0.5, 0) }):Play()
		TweenService:Create(textFrame, uiTweenInfo, { GroupTransparency = 1 }):Play()
	end

	data.holdTween = TweenService:Create(holdBar, TweenInfo.new(holdDuration, Enum.EasingStyle.Linear), {
		Rotation = targetRotation,
	})
	data.holdTween:Play()
end

function Module:onHoldEnd(prompt, player)
	local data = self.activePrompts[prompt]
	if not data then
		return
	end

	local gui = data.gui
	local holdBar = gui.InputFrame.Frame.ProgressBar.Bar
	local textFrame = gui.TextFrame
	local inputFrame = gui.InputFrame

	stopTweens(data)
	data.revertTween = TweenService:Create(holdBar, uiTweenInfo, { Rotation = -135 })
	data.revertTween:Play()

	if prompt.ObjectText ~= "" or prompt.ActionText ~= "" then
		TweenService:Create(inputFrame, uiTweenInfo, { Position = UDim2.new(0.35, 0, 0.5, 0) }):Play()
		TweenService:Create(textFrame, uiTweenInfo, { GroupTransparency = 0 }):Play()
	end
end

return Module
