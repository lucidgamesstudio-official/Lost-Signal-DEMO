-- // This module sets the input text and the ActionText and ObjectText
local module = {}

local UserInputService = game:GetService("UserInputService")

local PlayStationButtonImage = {
	["ButtonCross"] = { ID = "rbxassetid://102273970996663", Offset = Vector2.new(0, 0), Size = Vector2.new(0, 0) },
	["ButtonCircle"] = { ID = "rbxassetid://113464898463616", Offset = Vector2.new(0, 0), Size = Vector2.new(0, 0) },
	["ButtonSquare"] = { ID = "rbxassetid://79660650728784", Offset = Vector2.new(0, 0), Size = Vector2.new(0, 0) },
	["ButtonTriangle"] = { ID = "rbxassetid://94148253199756", Offset = Vector2.new(0, 0), Size = Vector2.new(0, 0) },
	["DPadLeft"] = { ID = "rbxassetid://110173040983770", Offset = Vector2.new(0, 0), Size = Vector2.new(0, 0) },
	["DPadRight"] = { ID = "rbxassetid://130907108249322", Offset = Vector2.new(0, 0), Size = Vector2.new(0, 0) },
	["DPadUp"] = { ID = "rbxassetid://135281158107893", Offset = Vector2.new(0, 0), Size = Vector2.new(0, 0) },
	["DPadDown"] = { ID = "rbxassetid://124627561952012", Offset = Vector2.new(0, 0), Size = Vector2.new(0, 0) },
	["ButtonTouchpad"] = { ID = "rbxassetid://104425278890126", Offset = Vector2.new(0, 0), Size = Vector2.new(0, 0) },
	["ButtonOptions"] = { ID = "rbxassetid://121059193316301", Offset = Vector2.new(0, 0), Size = Vector2.new(0, 0) },
	["ButtonL1"] = { ID = "rbxassetid://81969656395403", Offset = Vector2.new(0, 0), Size = Vector2.new(0, 0) },
	["ButtonR1"] = { ID = "rbxassetid://112320437641809", Offset = Vector2.new(0, 0), Size = Vector2.new(0, 0) },
	["ButtonL2"] = { ID = "rbxassetid://104369864924301", Offset = Vector2.new(0, 0), Size = Vector2.new(0, 0) },
	["ButtonR2"] = { ID = "rbxassetid://110790038619506", Offset = Vector2.new(0, 0), Size = Vector2.new(0, 0) },
	["ButtonL3"] = { ID = "rbxassetid://116504583475485", Offset = Vector2.new(0, 0), Size = Vector2.new(0, 0) },
	["ButtonR3"] = { ID = "rbxassetid://74618739514481", Offset = Vector2.new(0, 0), Size = Vector2.new(0, 0) },
	["Thumbstick1"] = { ID = "rbxassetid://139927556895762", Offset = Vector2.new(0, 0), Size = Vector2.new(0, 0) },
	["Thumbstick2"] = { ID = "rbxassetid://125303865660129", Offset = Vector2.new(0, 0), Size = Vector2.new(0, 0) },
}

local XboxButtonImage = {
	["ButtonA"] = { ID = "rbxassetid://138108315255546" },
	["ButtonB"] = { ID = "rbxassetid://116092688517875" },
	["ButtonX"] = { ID = "rbxassetid://112207765535717" },
	["ButtonY"] = { ID = "rbxassetid://109533975399767" },
	["DPadLeft"] = { ID = "rbxassetid://95925457952225" },
	["DPadRight"] = { ID = "rbxassetid://136135140660227" },
	["DPadUp"] = { ID = "rbxassetid://72596205752408" },
	["DPadDown"] = { ID = "rbxassetid://84622283202589" },
	["ButtonSelect"] = { ID = "rbxassetid://117845280307486" },
	["ButtonStart"] = { ID = "rbxassetid://134751820429515" },
	["ButtonLB"] = { ID = "rbxassetid://137630089826403" },
	["ButtonRB"] = { ID = "rbxassetid://88767529786919" },
	["ButtonLT"] = { ID = "rbxassetid://87686098194434" },
	["ButtonRT"] = { ID = "rbxassetid://71431029624337" },
	["ButtonLS"] = { ID = "rbxassetid://128473359374034" },
	["ButtonRS"] = { ID = "rbxassetid://127794729042773" },
	["Thumbstick1"] = { ID = "rbxassetid://122990010976566" },
	["Thumbstick2"] = { ID = "rbxassetid://115042316737067" },
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

function module:SetText(Prompt, InputType, TextFrame, InputFrame)
	TextFrame.ActionText.Text = Prompt.ActionText
	TextFrame.ObjectText.Text = Prompt.ObjectText

	if InputType == Enum.ProximityPromptInputType.Gamepad then
		local GamepadTest = UserInputService:GetStringForKeyCode(Enum.KeyCode.ButtonA)
		local buttonText = UserInputService:GetStringForKeyCode(Prompt.GamepadKeyCode)
		if PlayStationButtonImage[GamepadTest] then
			local img = PlayStationButtonImage[buttonText]
			InputFrame.Frame.InputImage.Image = img.ID
			InputFrame.Frame.InputImage.ImageRectOffset = Vector2.new(0, 0)
			InputFrame.Frame.InputImage.ImageRectSize = Vector2.new(0, 0)
			InputFrame.Frame.InputText.Visible = false
			InputFrame.Frame.InputImage.Visible = true
		elseif XboxButtonImage[GamepadTest] then
			local img = XboxButtonImage[buttonText]
			InputFrame.Frame.InputImage.Image = img.ID
			InputFrame.Frame.InputImage.ImageRectOffset = Vector2.new(0, 0)
			InputFrame.Frame.InputImage.ImageRectSize = Vector2.new(0, 0)
			InputFrame.Frame.InputText.Visible = false
			InputFrame.Frame.InputImage.Visible = true
		end
	elseif InputType == Enum.ProximityPromptInputType.Touch then
		InputFrame.Frame.InputImage.Image = "rbxassetid://77313068470031"
		InputFrame.Frame.InputText.Visible = false
		InputFrame.Frame.InputImage.Visible = true
	else
		local buttonTextString = UserInputService:GetStringForKeyCode(Prompt.KeyboardKeyCode)

		local buttonTextImage = KeyboardButtonImage[Prompt.KeyboardKeyCode]
		if buttonTextImage == nil then
			buttonTextImage = KeyboardButtonIconMapping[buttonTextString]
		end

		if buttonTextImage == nil then
			local keyCodeMappedText = KeyCodeToTextMapping[Prompt.KeyboardKeyCode]
			if keyCodeMappedText then
				buttonTextString = keyCodeMappedText
			end
		end
		if buttonTextImage then
			InputFrame.Frame.InputImage.Image = buttonTextImage.ID
			InputFrame.Frame.InputImage.ImageRectOffset = Vector2.new(0, 0)
			InputFrame.Frame.InputImage.ImageRectSize = Vector2.new(0, 0)
			InputFrame.Frame.InputText.Visible = false
			InputFrame.Frame.InputImage.Visible = true
		elseif buttonTextString ~= nil and buttonTextString ~= "" then
			InputFrame.Frame.InputText.Text = buttonTextString
			InputFrame.Frame.InputImage.Visible = false
			InputFrame.Frame.InputText.Visible = true
		end
	end
end

return module
