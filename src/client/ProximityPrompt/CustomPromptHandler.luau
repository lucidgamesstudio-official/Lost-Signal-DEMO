-- Objects
local CustomPromptHandler = {}

-- Services
local PromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Player & Character
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
player.CharacterAdded:Connect(function(char)
	character = char
end)


--  Modules
local Utility = require(ReplicatedStorage.Shared.Utility)
local PromptEffect = require(script.Parent.Modules.PromptEffect)
local PromptFolder = script.Parent.Prompts

-- Active Modules Dictionary
local activeModules = {}

local function isCustom(prompt)
	if prompt.Style == Enum.ProximityPromptStyle.Custom then
		local conf = prompt:FindFirstChild("CustomPromptConf")
		if conf and conf:FindFirstChild("CustomPrompt") then
			local flag = conf.CustomPrompt
			return flag:IsA("BoolValue") and flag.Value == true
		end
	end
	return false
end

-- Core handler
local function handle(prompt, methodName, inputType)
	if not isCustom(prompt) then return end

	local moduleName = prompt.CustomPromptConf.CustomPrompt.PromptName.Value
	local moduleScript = PromptFolder:FindFirstChild(moduleName)
	if not moduleScript then warn("[CustomPrompt Handler] Prompt module not found:", moduleName); return end

	local module = activeModules[moduleName]
	if not module then
		module = require(moduleScript)
		activeModules[moduleName] = module
	end

	if module[methodName] then
		module[methodName](module, prompt, inputType, player)
	end
end

-- Prompt SHOWN
PromptService.PromptShown:Connect(function(prompt, inputType)
	if isCustom(prompt) then
		if prompt.CustomPromptConf.Beam.Value then
			PromptEffect:CreateBeam(prompt.Parent, character:FindFirstChild("HumanoidRootPart"), prompt.CustomPromptConf)
		end
		if prompt.CustomPromptConf.Highlight.Value then
			PromptEffect:CreateHighlight(prompt.Parent, prompt.CustomPromptConf)
		end
	end
	handle(prompt, "onShown", inputType)
end)

-- Prompt HIDDEN
PromptService.PromptHidden:Connect(function(prompt, inputType)
	if isCustom(prompt) then
		if prompt.CustomPromptConf.Beam.Value then
			PromptEffect:DestroyBeam(prompt.Parent, character:FindFirstChild("HumanoidRootPart"))
		end
		if prompt.CustomPromptConf.Highlight.Value then
			PromptEffect:DestroyHighlight(prompt.Parent)
		end
	end
	handle(prompt, "onHidden", inputType)
end)

-- Other events
PromptService.PromptTriggered:Connect(function(prompt, inputType)
	handle(prompt, "onTriggered", inputType)
end)

PromptService.PromptButtonHoldBegan:Connect(function(prompt, inputType)
	handle(prompt, "onHoldStart", inputType)
end)

PromptService.PromptButtonHoldEnded:Connect(function(prompt, inputType)
	handle(prompt, "onHoldEnd", inputType)
end)


Utility.Warn("[CustomPrompt Handler] Custom Proximity Prompt System  Made by:Madrian622 ", script.Name) -- You can delete it if you want, it won't bother me


local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CustomPrompts"
ScreenGui.Parent = player.PlayerGui

return CustomPromptHandler