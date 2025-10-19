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
	local BeamWidth = Conf.Beam:FindFirstChild("BeamWidth")
	local BeamTexture = Conf.Beam:FindFirstChild("BeamTexture")
	local BeamColor = Conf.Beam:FindFirstChild("BeamColor")
	local BeamTransparency = Conf.Beam:FindFirstChild("BeamTransparency")

	beam.Width0 = (BeamWidth and BeamWidth:IsA("NumberValue")) and BeamWidth.Value or 0.1
	beam.Width1 = beam.Width0
	beam.Texture = (BeamTexture and BeamTexture:IsA("StringValue") and #BeamTexture.Value > 3) and BeamTexture.Value
		or ""
	beam.Color =
		ColorSequence.new((BeamColor and BeamColor:IsA("Color3Value")) and BeamColor.Value or Color3.new(1, 1, 1))
	beam.Transparency =
		NumberSequence.new((BeamTransparency and BeamTransparency:IsA("NumberValue")) and BeamTransparency.Value or 0)
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
function PromptEffect:CreateHighlight(Part1, Conf)
	local highlight = Instance.new("Highlight")
	highlight.Name = "PromptHighlight"
	highlight.FillTransparency = 1

	local HighlightColor = Conf.Highlight:FindFirstChild("HighlightColor")
	local HighlightTransparency = Conf.Highlight:FindFirstChild("HighlightTransparency")
	local HighlightOccluded = Conf.Highlight:FindFirstChild("HighlightOccluded")
	local HighlightParent = Conf.Highlight:FindFirstChild("HighlightParent")

	highlight.OutlineColor = (HighlightColor and HighlightColor:IsA("Color3Value")) and HighlightColor.Value
		or Color3.new(1, 1, 1)
	highlight.OutlineTransparency = (HighlightTransparency and HighlightTransparency:IsA("NumberValue"))
			and HighlightTransparency.Value
		or 0
	highlight.DepthMode = (HighlightOccluded and HighlightOccluded:IsA("BoolValue"))
			and HighlightOccluded.Value
			and Enum.HighlightDepthMode.Occluded
		or Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = (HighlightParent and HighlightParent.Value) or Part1
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
