-- This is just a demo module on how you can start making your own prompt, a tip to check out the other prompt modules

-- Object
local Module = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Gui
local CustomPrompt = ReplicatedStorage:FindFirstChild("ProxisGui"):FindFirstChild(script.Name)

Module.activePrompts = {}

function Module:onShown(Prompt, InputType, Player)
	local PromptClone = CustomPrompt:Clone()
	local canvasGroup = PromptClone.CanvasGroup
	local gui = canvasGroup.Frame

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
	Prompt.CustomPromptConf.ObjectValue.Value = PromptClone

	Module.activePrompts[Prompt] = {
		clone = PromptClone,
		gui = gui,
	}
end

function Module:onHidden(Prompt, Player) end

function Module:onTriggered(Prompt, Player) end

function Module:onHoldStart(Prompt, Player) end

function Module:onHoldEnd(Prompt, Player) end

return Module
