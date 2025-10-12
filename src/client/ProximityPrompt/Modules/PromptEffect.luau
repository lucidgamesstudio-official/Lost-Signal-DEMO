-- // this module can create beam / highlight if the prompt is visible

local module = {}


function module:CreateBeam(Part1, Part2, Conf)
	local fromAttachment = Instance.new("Attachment")
	fromAttachment.Name = "BeamFrom"
	fromAttachment.Parent = Part1

	local toAttachment = Instance.new("Attachment")
	toAttachment.Name = "BeamTo"
	toAttachment.Parent = Part2

	local beam = Instance.new("Beam")
	beam.Attachment0 = fromAttachment
	beam.Attachment1 = toAttachment
	beam.Width0 = Conf.Beam.BeamWidth.Value
	beam.Width1 =  Conf.Beam.BeamWidth.Value
	beam.Color = ColorSequence.new( Conf.Beam.BeamColor.Value)
	beam.Transparency = NumberSequence.new(Conf.Beam.BeamTransparency.Value)
	beam.FaceCamera = true
	beam.Name = "PromptBeam"
	beam.Parent = Part1
end

function module:DestroyBeam(Part1, Part2)
	local beam = Part1:FindFirstChild("PromptBeam")
	if beam then beam:Destroy() end

	local fromAttachment = Part1:FindFirstChild("BeamFrom")
	local toAttachment = Part2:FindFirstChild("BeamTo")
	if fromAttachment then fromAttachment:Destroy() end
	if toAttachment then toAttachment:Destroy() end
end

function module:CreateHighlight(Part1, Conf)
	local Highlight = Instance.new("Highlight")
	Highlight.Name = "PromptHighlight"
	Highlight.FillTransparency = 1
	Highlight.OutlineColor = Conf.Highlight.HighlightColor.Value
	Highlight.OutlineTransparency = Conf.Highlight.HighlightTransparency.Value
	Highlight.Parent = Part1
end

function module:DestroyHighlight(Part1)
	local Highlight = Part1:FindFirstChild("PromptHighlight")
	if Highlight then Highlight:Destroy() end
end



return module
