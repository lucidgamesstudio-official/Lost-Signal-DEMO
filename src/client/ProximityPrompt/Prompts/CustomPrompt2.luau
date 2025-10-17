--[[
	- CustomPrompt2
	- Alienduck
	- 16/10/2025
	- v1.0
]]

-- Object
local CustomPrompt2 = {}
CustomPrompt2.__index = CustomPrompt2
CustomPrompt2.activePrompts = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Modules
local TextModule = require(script.Parent.Parent.Modules.PromptText)

-- Gui
local CustomPrompt = ReplicatedStorage:FindFirstChild("ProxisGui"):FindFirstChild(script.Name)

-- Constants
local TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Private functions
local function stopAllTweens(data)
	if data.holdTween then
		data.holdTween:Cancel()
	end
	if data.revertTween then
		data.revertTween:Cancel()
	end
end

-- Methods

--[[
	@description Called when the prompt becomes visible.
]]
function CustomPrompt2:onShown(Prompt, InputType, Player)
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

	local appearTween = TweenService:Create(canvasGroup, TWEEN_INFO, { GroupTransparency = 0 })
	appearTween:Play()

	CustomPrompt2.activePrompts[Prompt] = { clone = PromptClone, gui = gui }
end

--[[
	@description Called when the prompt is hidden.
]]
function CustomPrompt2:onHidden(Prompt, Player)
	local data = CustomPrompt2.activePrompts[Prompt]
	if not data or not data.clone then
		return
	end

	local canvasGroup = data.clone:FindFirstChild("CanvasGroup")
	if not canvasGroup then
		data.clone:Destroy()
		CustomPrompt2.activePrompts[Prompt] = nil
		return
	end

	local disappearTween = TweenService:Create(canvasGroup, TWEEN_INFO, { GroupTransparency = 1 })
	disappearTween:Play()

	disappearTween.Completed:Connect(function()
		if data.clone then
			data.clone:Destroy()
		end
	end)

	CustomPrompt2.activePrompts[Prompt] = nil
end

function CustomPrompt2:onTriggered(Prompt, Player) end

function CustomPrompt2:onHoldStart(Prompt, Player)
	local data = CustomPrompt2.activePrompts[Prompt]
	if not data then
		return
	end

	local gui = data.gui
	local textFrame = gui.TextFrame
	local holdBar = gui.InputFrame.Frame.ProgressBar.Bar
	if not holdBar then
		return
	end

	stopAllTweens(data)

	local currentSize = holdBar.Size
	local remainingScale = currentSize == UDim2.new(1, 0, 0, 0) and (1 - currentSize.Y.Scale)
		or (1.1 - currentSize.Y.Scale)
	local duration = Prompt.HoldDuration * remainingScale
	local goal = { Size = UDim2.new(1, 0, 1, 0) }

	TweenService:Create(textFrame, TWEEN_INFO, { GroupTransparency = 1 }):Play()
	data.holdTween = TweenService:Create(holdBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), goal)
	data.holdTween:Play()
end

function CustomPrompt2:onHoldEnd(Prompt, Player)
	local data = CustomPrompt2.activePrompts[Prompt]
	if not data then
		return
	end

	local gui = data.gui
	local textFrame = gui.TextFrame
	local holdBar = gui.InputFrame.Frame.ProgressBar.Bar
	if not holdBar then
		return
	end

	stopAllTweens(data)

	local goal = { Size = UDim2.new(1, 0, 0, 0) }
	TweenService:Create(textFrame, TWEEN_INFO, { GroupTransparency = 0 }):Play()
	data.revertTween = TweenService:Create(holdBar, TweenInfo.new(0.1, Enum.EasingStyle.Linear), goal)
	data.revertTween:Play()
end

return CustomPrompt2
