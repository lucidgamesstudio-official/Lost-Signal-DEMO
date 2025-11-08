local DialoguesController = {}
DialoguesController.__index = DialoguesController

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Modules
local Utility = require(ReplicatedStorage.Shared.Utility)

-- Folders
local RemoteEventsFolder: Folder = Utility.CreateFolder("RemoteEvents")

-- Remotes
local SendDialoguesRemote: RemoteEvent = Utility.CreateRemoteEvent("SendDialogues", RemoteEventsFolder)

-- Rich text tag patterns
local RICH_TEXT_PATTERNS = {
	"(<b>)(.-)(</b>)",
	"(<i>)(.-)(</i>)",
	"(<u>)(.-)(</u>)",
	"(<s>)(.-)(</s>)",
	"(<font%s+color%s*=%s*[\"']#?%w+[\"']>)(.-)(</font>)",
	"(<font%s+size%s*=%s*[\"']?%d+[\"']?>)(.-)(</font>)",
	"(<font%s+face%s*=%s*[\"'][^\"']+[\"']>)(.-)(</font>)",
}

-- Constantes
local DEFAULT_TIME_TO_WAIT = 0.05

-- Parse content into segments with tags
local function parseRichText(text: string): { { type: string, content: string, openTag: string?, closeTag: string? } }
	local segments = {}
	local currentPos = 1

	while currentPos <= #text do
		local nearestMatch = nil
		local nearestStart = #text + 1

		-- Find the nearest tag
		for _, pattern in ipairs(RICH_TEXT_PATTERNS) do
			local tagStart, tagEnd, openTag, content, closeTag = string.find(text, pattern, currentPos)
			if tagStart and tagStart < nearestStart then
				nearestStart = tagStart
				nearestMatch = {
					start = tagStart,
					finish = tagEnd,
					openTag = openTag,
					content = content,
					closeTag = closeTag,
				}
			end
		end

		-- Add plain text before tag (if any)
		if nearestStart > currentPos then
			local plainText = string.sub(text, currentPos, nearestStart - 1)
			if #plainText > 0 then
				table.insert(segments, {
					type = "plain",
					content = plainText,
				})
			end
		end

		-- Add tagged segment
		if nearestMatch then
			table.insert(segments, {
				type = "tagged",
				content = nearestMatch.content,
				openTag = nearestMatch.openTag,
				closeTag = nearestMatch.closeTag,
			})
			currentPos = nearestMatch.finish + 1
		else
			-- No more tags, add remaining text
			if currentPos <= #text then
				local remainingText = string.sub(text, currentPos)
				if #remainingText > 0 then
					table.insert(segments, {
						type = "plain",
						content = remainingText,
					})
				end
			end
			break
		end
	end

	return segments
end

-- Punctuation table
local PonctuationTable = {
	[","] = 0.5,
	[";"] = 0.75,
	["."] = 1,
}

-- Enums
local DialoguesStyles = {
	Basic = 1,
	Info = 2,
	Speak = 3,
	Menacing = 4,
}

-- Typing
export type DialoguesDict = {
	title: string,
	lines: { string },
	speaker: string?,
	portrait: string?,
	style: number?,
}

export type DialogControllerType = {
	-- Objects
	Screen: ScreenGui,
	Container: CanvasGroup,
	Bar: Frame,
	Title: TextLabel,
	Content: TextLabel,
	Button: ImageButton,

	-- Properties
	show: boolean,
	style: number,
	canToggle: boolean,
	isPrinting: boolean,
	_print_lines_thread: thread?,
	_dialogueQueue: { DialoguesDict },

	-- Public Methods
	load: () -> (),
	Show: (self: DialogControllerType, data: DialoguesDict) -> (),
	Close: (self: DialogControllerType) -> (),
	_toggle: (self: DialogControllerType, isActive: boolean?) -> BindableEvent?,
	StartPrintContent: (self: DialogControllerType, content: { string }, pass: boolean?) -> BindableEvent,
}

-- Constructor
function DialoguesController.load()
	local self = {} :: DialogControllerType
	setmetatable(self, DialoguesController)

	local playerGui: PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	self.Screen = playerGui:FindFirstChild("DialoguesGui")
	self.Screen.Enabled = false
	if not self.Screen then
		Utility.Warn(`[WARN] No DialoguesGui found`, script.Name)
		return
	end

	self.Container = self.Screen:WaitForChild("Container") :: CanvasGroup
	self.Bar = self.Container:WaitForChild("Bar") :: Frame
	self.Title = self.Container:WaitForChild("Title") :: TextLabel
	self.Content = self.Container:WaitForChild("Content") :: TextLabel

	-- Set the button
	self.Button = Instance.new("ImageButton")
	self.Button.Parent = self.Container
	self.Button.Image = ""
	self.Button.BackgroundTransparency = 1
	self.Button.ImageTransparency = 1
	self.Button.AnchorPoint = self.Content.AnchorPoint
	self.Button.Size = self.Content.Size
	self.Button.Position = self.Content.Position

	self.show = false
	self.isPrinting = false
	self.style = DialoguesStyles.Basic
	self.canToggle = true
	self._print_lines_thread = nil
	self._dialogueQueue = {}

	-- Add a dialogue in the queue
	local function enqueueDialogue(data)
		table.insert(self._dialogueQueue, data)
		if not self.isPrinting then
			task.spawn(function()
				while #self._dialogueQueue > 0 do
					self.isPrinting = true
					local currentData = table.remove(self._dialogueQueue, 1)
					local finishPrintEvent = self:Show(currentData)

					-- Wait the end of the print
					if finishPrintEvent then
						finishPrintEvent.Event:Wait()
					end

					-- Wait to
					task.wait(0.5)
				end
				self.isPrinting = false
			end)
		end
	end

	-- Connect RemoteEvent
	SendDialoguesRemote.OnClientEvent:Connect(function(data: DialoguesDict)
		enqueueDialogue(data)
	end)

	return self
end

-- Show dialogue
function DialoguesController.Show(self: DialogControllerType, data: DialoguesDict): BindableEvent?
	Utility.Info(`Show`, script.Name)
	local titleText: string = data.speaker and `<b>{data.speaker}</b>: {data.title}` or `{data.title}`
	self.Title.Text = titleText
	self.Content.Text = ""

	local bindableEvent: BindableEvent? = self:_toggle(self.show)
	if not bindableEvent then
		return nil
	end

	local finishDialogueEvent = Utility.CreateBindableEvent("FinishDialogue", script)
	bindableEvent.Event:Once(function()
		local finishPrintEvent = self:StartPrintContent(data.lines)
		finishPrintEvent.Event:Once(function()
			task.wait(1)
			self:Close()
			finishDialogueEvent:Fire()
		end)
	end)

	return finishDialogueEvent
end

-- Close dialogue
function DialoguesController.Close(self: DialogControllerType)
	Utility.Info(`Close`, script.Name)
	self:_toggle(self.show)
end

-- Toggle the visual
function DialoguesController._toggle(self: DialogControllerType, isActive: boolean?): BindableEvent?
	if not self.canToggle then
		return nil
	end
	Utility.Info(`_toggle`, script.Name)
	self.Screen.Enabled = true
	local bindableEvent: BindableEvent = Utility.CreateBindableEvent("ToggleFinished", script)
	self.canToggle = false
	local active = isActive or false
	local containerGoal = {
		GroupTransparency = active and 1 or 0,
		Visible = not active,
	}
	local containerTI: TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine)
	local containerTween: Tween = TweenService:Create(self.Container, containerTI, containerGoal)
	self.Container.Visible = true
	containerTween:Play()
	containerTween.Completed:Once(function(a0: Enum.PlaybackState)
		local barGoal = {
			Size = active and UDim2.new(0, 0, 0, 2) or UDim2.new(0.5, 0, 0, 2),
			Visible = not active,
		}
		local barTI: TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		local barTween: Tween = TweenService:Create(self.Bar, barTI, barGoal)
		self.Bar.Visible = true
		barTween:Play()
		barTween.Completed:Once(function(a0: Enum.PlaybackState)
			self.canToggle = true
			self.show = not self.show
			bindableEvent:Fire()
		end)
	end)
	return bindableEvent
end

-- Start printing content
function DialoguesController.StartPrintContent(
	self: DialogControllerType,
	content: { string },
	pass: boolean?
): BindableEvent
	-- Cancel existing print thread
	if self._print_lines_thread then
		task.cancel(self._print_lines_thread)
		self._print_lines_thread = nil
	end

	Utility.Info(`StartPrint`, script.Name)
	local finishPrintEvent: BindableEvent = Utility.CreateBindableEvent("FinishPrint", script)

	self._print_lines_thread = task.spawn(function()
		-- If pass is true, display everything immediately
		if pass then
			local fullText = table.concat(content, "\n")
			self.Content.Text = fullText
			finishPrintEvent:Fire()
			return
		end

		-- Process each line
		for lineIndex, line in ipairs(content) do
			local segments = parseRichText(line)
			local displayedText = ""

			-- Process each segment
			for segmentIndex, segment in ipairs(segments) do
				if segment.type == "plain" then
					-- Display plain text character by character
					for i = 1, #segment.content do
						local letter = string.sub(segment.content, i, i)
						local timeToWait = PonctuationTable[letter] or DEFAULT_TIME_TO_WAIT
						displayedText ..= letter
						self.Content.Text = displayedText
						task.wait(timeToWait)
					end
				elseif segment.type == "tagged" then
					-- Display tagged text character by character with tags
					local taggedContent = ""
					for i = 1, #segment.content do
						local letter = string.sub(segment.content, i, i)
						local timeToWait = PonctuationTable[letter] or DEFAULT_TIME_TO_WAIT
						taggedContent ..= letter
						displayedText = displayedText:gsub(segment.openTag .. ".*" .. segment.closeTag, "")
						self.Content.Text = displayedText .. segment.openTag .. taggedContent .. segment.closeTag
						task.wait(timeToWait)
					end
					-- Update displayed text to include full tagged content
					displayedText = displayedText .. segment.openTag .. segment.content .. segment.closeTag
				end
			end

			-- Add line break if not last line
			if lineIndex < #content then
				displayedText = displayedText .. "\n"
				self.Content.Text = displayedText
			end
			task.wait(1)
		end

		-- Fire completion event
		finishPrintEvent:Fire()
	end)

	return finishPrintEvent
end

return DialoguesController
