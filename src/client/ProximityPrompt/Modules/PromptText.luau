--[[
	- PromptText
	- Alienduck
	- 16/10/2025
	- v1.0
]]

-- Object
local PromptText = {}
PromptText.__index = PromptText

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Utility = require(ReplicatedStorage.Shared.Utility)

-- Typing
export type InputFrameContainer = Frame & {
	UiScale: UIScale,
	ProgressBar: Frame,
	InputImage: ImageLabel,
	InputText: TextLabel,
}

-- Constants
local PlayStationButtonImage = {
	ButtonCross = { ID = "rbxassetid://102273970996663" },
	ButtonCircle = { ID = "rbxassetid://113464898463616" },
	ButtonSquare = { ID = "rbxassetid://79660650728784" },
	ButtonTriangle = { ID = "rbxassetid://94148253199756" },
	DPadLeft = { ID = "rbxassetid://110173040983770" },
	DPadRight = { ID = "rbxassetid://130907108249322" },
	DPadUp = { ID = "rbxassetid://135281158107893" },
	DPadDown = { ID = "rbxassetid://124627561952012" },
	ButtonTouchpad = { ID = "rbxassetid://104425278890126" },
	ButtonOptions = { ID = "rbxassetid://121059193316301" },
	ButtonL1 = { ID = "rbxassetid://81969656395403" },
	ButtonR1 = { ID = "rbxassetid://112320437641809" },
	ButtonL2 = { ID = "rbxassetid://104369864924301" },
	ButtonR2 = { ID = "rbxassetid://110790038619506" },
	ButtonL3 = { ID = "rbxassetid://116504583475485" },
	ButtonR3 = { ID = "rbxassetid://74618739514481" },
	Thumbstick1 = { ID = "rbxassetid://139927556895762" },
	Thumbstick2 = { ID = "rbxassetid://125303865660129" },
}

local XboxButtonImage = {
	ButtonA = { ID = "rbxassetid://138108315255546" },
	ButtonB = { ID = "rbxassetid://116092688517875" },
	ButtonX = { ID = "rbxassetid://112207765535717" },
	ButtonY = { ID = "rbxassetid://109533975399767" },
	DPadLeft = { ID = "rbxassetid://95925457952225" },
	DPadRight = { ID = "rbxassetid://136135140660227" },
	DPadUp = { ID = "rbxassetid://72596205752408" },
	DPadDown = { ID = "rbxassetid://84622283202589" },
	ButtonSelect = { ID = "rbxassetid://117845280307486" },
	ButtonStart = { ID = "rbxassetid://134751820429515" },
	ButtonLB = { ID = "rbxassetid://137630089826403" },
	ButtonRB = { ID = "rbxassetid://88767529786919" },
	ButtonLT = { ID = "rbxassetid://87686098194434" },
	ButtonRT = { ID = "rbxassetid://71431029624337" },
	ButtonLS = { ID = "rbxassetid://128473359374034" },
	ButtonRS = { ID = "rbxassetid://127794729042773" },
	Thumbstick1 = { ID = "rbxassetid://122990010976566" },
	Thumbstick2 = { ID = "rbxassetid://115042316737067" },
}

local KeyboardButtonImage = {
	[Enum.KeyCode.Backspace] = { ID = "rbxassetid://120303028808564" },
	[Enum.KeyCode.Return] = { ID = "rbxassetid://71348757834238" },
	[Enum.KeyCode.LeftShift] = { ID = "rbxassetid://116131127429113" },
	[Enum.KeyCode.RightShift] = { ID = "rbxassetid://116131127429113" },
	[Enum.KeyCode.Tab] = { ID = "rbxassetid://104199803310063" },
}

local KeyboardButtonIconMapping = {
	["'"] = { ID = "rbxassetid://100277577749504" },
	[","] = { ID = "rbxassetid://108580101056782" },
	["`"] = { ID = "rbxassetid://71142668338879" },
	["."] = { ID = "rbxassetid://109469810581346" },
	[" "] = { ID = "rbxassetid://79231018990252" },
}

local KeyCodeToTextMapping = {
	[Enum.KeyCode.LeftControl] = "Ctrl",
	[Enum.KeyCode.RightControl] = "Ctrl",
	[Enum.KeyCode.LeftAlt] = "Alt",
	[Enum.KeyCode.RightAlt] = "Alt",
	[Enum.KeyCode.F1] = "F1",
	[Enum.KeyCode.F2] = "F2",
	[Enum.KeyCode.F3] = "F3",
	[Enum.KeyCode.F4] = "F4",
	[Enum.KeyCode.F5] = "F5",
	[Enum.KeyCode.F6] = "F6",
	[Enum.KeyCode.F7] = "F7",
	[Enum.KeyCode.F8] = "F8",
	[Enum.KeyCode.F9] = "F9",
	[Enum.KeyCode.F10] = "F10",
	[Enum.KeyCode.F11] = "F11",
	[Enum.KeyCode.F12] = "F12",
}

-- Methods

--[[
	@params Prompt: ProximityPrompt
	@params InputType: Enum.ProximityPromptInputType
	@params TextFrame: Frame
	@params InputFrame: Frame
	@returns nil
	@description Sets the input text and image for the given prompt.
]]
function PromptText:SetText(Prompt, InputType, TextFrame, InputFrame)
	if TextFrame.ActionText then
		TextFrame.ActionText.Text = Prompt.ActionText
	end
	if TextFrame.ObjectText then
		TextFrame.ObjectText.Text = Prompt.ObjectText
	end
	local frame: InputFrameContainer = InputFrame:FindFirstChild("Frame")
	if not frame then
		Utility.Warn("[WARN] No frame container found", script.Name)
		return
	end
	if InputType == Enum.ProximityPromptInputType.Gamepad then
		local testButton = UserInputService:GetStringForKeyCode(Enum.KeyCode.ButtonA)
		local key = UserInputService:GetStringForKeyCode(Prompt.GamepadKeyCode)

		local img
		if PlayStationButtonImage[testButton] then
			img = PlayStationButtonImage[key]
		elseif XboxButtonImage[testButton] then
			img = XboxButtonImage[key]
		end

		if img then
			frame.InputImage.Image = img.ID
			frame.InputText.Visible = false
			frame.InputImage.Visible = true
		end
	elseif InputType == Enum.ProximityPromptInputType.Touch then
		frame.InputImage.Image = "rbxassetid://77313068470031"
		frame.InputText.Visible = false
		frame.InputImage.Visible = true
	else
		local keyString = UserInputService:GetStringForKeyCode(Prompt.KeyboardKeyCode)
		local img = KeyboardButtonImage[Prompt.KeyboardKeyCode] or KeyboardButtonIconMapping[keyString]
		local mappedText = KeyCodeToTextMapping[Prompt.KeyboardKeyCode]

		if mappedText then
			keyString = mappedText
		end

		if img then
			frame.InputImage.Image = img.ID
			frame.InputText.Visible = false
			frame.InputImage.Visible = true
		elseif keyString and keyString ~= "" then
			frame.InputText.Text = keyString
			frame.InputImage.Visible = false
			frame.InputText.Visible = true
		end
	end
end

return PromptText
