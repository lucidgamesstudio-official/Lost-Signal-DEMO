--[[
	- CustomPromptHandler
	- Alienduck
	- 16/10/2025
	- v1.0
	@summary Gère le dispatch des modules de prompts personnalisés et les effets associés.
]]

-- Object
local CustomPromptHandler = {}
CustomPromptHandler.__index = CustomPromptHandler

-- Services
local PromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Player
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
player.CharacterAdded:Connect(function(char)
	character = char
end)

-- Modules
local Utility = require(ReplicatedStorage.Shared.Utility)
local PromptEffect = require(script.Parent.Modules.PromptEffect)
local PromptFolder = script.Parent.Prompts

-- Active modules
local activeModules = {}

---------------------------------------------------------------------
-- Private Helpers
---------------------------------------------------------------------

local function isCustom(prompt)
	if prompt.Style ~= Enum.ProximityPromptStyle.Custom then
		return false
	end

	local conf = prompt:FindFirstChild("CustomPromptConf")
	if not conf then
		return false
	end

	local customFlag = conf:FindFirstChild("CustomPrompt")
	if not customFlag or not customFlag:IsA("BoolValue") then
		return false
	end

	return customFlag.Value == true
end

local function handle(prompt, methodName, inputType)
	if not isCustom(prompt) then
		return
	end

	local conf = prompt:FindFirstChild("CustomPromptConf")
	if not conf or not conf:FindFirstChild("CustomPrompt") then
		return
	end

	local moduleName = conf.CustomPrompt.PromptName.Value
	local moduleScript = PromptFolder:FindFirstChild(moduleName)

	if not moduleScript then
		warn("[CustomPromptHandler] Module not found:", moduleName)
		return
	end

	local module = activeModules[moduleName]
	if not module then
		module = require(moduleScript)
		activeModules[moduleName] = module
	end

	if module[methodName] then
		module[methodName](module, prompt, inputType, player)
	end
end

---------------------------------------------------------------------
-- PromptService Hooks
---------------------------------------------------------------------

PromptService.PromptShown:Connect(function(prompt, inputType)
	if isCustom(prompt) then
		local conf = prompt.CustomPromptConf
		if conf.Beam.Value then
			PromptEffect:CreateBeam(prompt.Parent, character:FindFirstChild("HumanoidRootPart"), conf)
		end
		if conf.Highlight.Value then
			PromptEffect:CreateHighlight(prompt.Parent, conf)
		end
	end
	handle(prompt, "onShown", inputType)
end)

PromptService.PromptHidden:Connect(function(prompt, inputType)
	if isCustom(prompt) then
		local conf = prompt.CustomPromptConf
		if conf.Beam.Value then
			PromptEffect:DestroyBeam(prompt.Parent, character:FindFirstChild("HumanoidRootPart"))
		end
		if conf.Highlight.Value then
			PromptEffect:DestroyHighlight(prompt.Parent, conf)
		end
	end
	handle(prompt, "onHidden", inputType)
end)

PromptService.PromptTriggered:Connect(function(prompt, inputType)
	handle(prompt, "onTriggered", inputType)
end)

PromptService.PromptButtonHoldBegan:Connect(function(prompt, inputType)
	handle(prompt, "onHoldStart", inputType)
end)

PromptService.PromptButtonHoldEnded:Connect(function(prompt, inputType)
	handle(prompt, "onHoldEnd", inputType)
end)

---------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------

Utility.Warn("[CustomPromptHandler] Custom Proximity Prompt System loaded (by Madrian622)", script.Name)

local gui = Instance.new("ScreenGui")
gui.Name = "CustomPrompts"
gui.Parent = player:WaitForChild("PlayerGui")

return CustomPromptHandler
