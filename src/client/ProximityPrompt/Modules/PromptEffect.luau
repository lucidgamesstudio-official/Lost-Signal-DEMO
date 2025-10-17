--[[
	- PromptEffect
	- Alienduck
	- 16/10/2025
	- v1.0
]]

-- Object
local PromptEffect = {}
PromptEffect.__index = PromptEffect

-- Typing
export type PromptConf = Configuration & {
	Beam: BoolValue & {
		BeamColor: Color3Value,
		BeamTexture: StringValue,
		BeamTransparency: NumberValue,
		BeamWidth: NumberValue,
	},
	CustomPrompt: BoolValue & {
		PromptName: StringValue,
	},
	Highlight: BoolValue & {
		HighlightColor: Color3Value,
		HighlightParent: ObjectValue,
		HighlightTransparency: NumberValue,
	},
}

-- Methods

--[[
	@params Part1: BasePart
	@params Part2: BasePart
	@params Conf: Configuration
	@returns nil
	@description Create a Beam between two parts with given configuration.
]]
function PromptEffect:CreateBeam(Part1: BasePart, Part2: BasePart, Conf: PromptConf)
	local fromAttachment: Attachment = Instance.new("Attachment")
	fromAttachment.Name = "BeamFrom"
	fromAttachment.Parent = Part1

	local toAttachment: Attachment = Instance.new("Attachment")
	toAttachment.Name = "BeamTo"
	toAttachment.Parent = Part2

	local beam: Beam = Instance.new("Beam")
	beam.Attachment0 = fromAttachment
	beam.Attachment1 = toAttachment
	beam.Width0 = Conf.Beam.BeamWidth.Value
	beam.Width1 = Conf.Beam.BeamWidth.Value
	beam.Texture = (#Conf.Beam.BeamTexture.Value > 3) and Conf.Beam.BeamTexture.Value or ""
	beam.Color = ColorSequence.new(Conf.Beam.BeamColor.Value)
	beam.Transparency = NumberSequence.new(Conf.Beam.BeamTransparency.Value)
	beam.FaceCamera = true
	beam.Name = "PromptBeam"
	beam.Parent = Part1
end

--[[
	@params Part1: BasePart
	@params Part2: BasePart
	@returns nil
	@description Destroy the Beam and its attachments.
]]
function PromptEffect:DestroyBeam(Part1: BasePart, Part2: BasePart)
	local beam: Instance? = Part1:FindFirstChild("PromptBeam")
	if beam then
		beam:Destroy()
	end

	local fromAttachment: Attachment? = Part1:FindFirstChild("BeamFrom") :: Attachment
	local toAttachment: Attachment? = Part2:FindFirstChild("BeamTo") :: Attachment

	if fromAttachment then
		fromAttachment:Destroy()
	end
	if toAttachment then
		toAttachment:Destroy()
	end
end

--[[
	@params Part1: BasePart
	@params Conf: Configuration
	@returns nil
	@description Create a Highlight effect on the part or its configured parent.
]]
function PromptEffect:CreateHighlight(Part1: BasePart, Conf: PromptConf)
	local highlight: Highlight = Instance.new("Highlight")
	highlight.Name = "PromptHighlight"
	highlight.FillTransparency = 1
	highlight.OutlineColor = Conf.Highlight.HighlightColor.Value
	highlight.OutlineTransparency = Conf.Highlight.HighlightTransparency.Value
	highlight.Parent = Conf.Highlight.HighlightParent.Value or Part1
end

--[[
	@params Part1: BasePart
	@params Conf: Configuration
	@returns nil
	@description Destroy a previously created Highlight.
]]
function PromptEffect:DestroyHighlight(Part1: BasePart, Conf: PromptConf)
	local highlight = Part1:FindFirstChild("PromptHighlight")
		or (
			Conf.Highlight.HighlightParent.Value
			and Conf.Highlight.HighlightParent.Value:FindFirstChild("PromptHighlight")
		)

	if highlight then
		highlight:Destroy()
	end
end

return PromptEffect
