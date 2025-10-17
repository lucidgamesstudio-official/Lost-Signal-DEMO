--[[
	- CustomPrompt1
	- Alienduck
	- 16/10/2025
	- v1.0
]]

-- Object
local CustomPrompt1 = {}
CustomPrompt1.__index = CustomPrompt1
CustomPrompt1.activePrompts = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Gui
local CustomPrompt = ReplicatedStorage:FindFirstChild("ProxisGui"):FindFirstChild(script.Name)

-- Methods

--[[
	@params Prompt: ProximityPrompt
	@params InputType: Enum.ProximityPromptInputType
	@params Player: Player
	@returns nil
	@description Called when the prompt is shown. Creates and displays the UI.
]]
function CustomPrompt1:onShown(Prompt, InputType, Player)
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
	CustomPrompt1.activePrompts[Prompt] = { clone = PromptClone, gui = gui }
end

function CustomPrompt1:onHidden(Prompt, Player) end
function CustomPrompt1:onTriggered(Prompt, Player) end
function CustomPrompt1:onHoldStart(Prompt, Player) end
function CustomPrompt1:onHoldEnd(Prompt, Player) end

return CustomPrompt1
