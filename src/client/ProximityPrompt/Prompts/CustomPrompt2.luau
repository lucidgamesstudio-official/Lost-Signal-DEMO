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

local tweenInfo: TweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

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
