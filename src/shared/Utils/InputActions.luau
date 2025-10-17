--!strict
--[[
	- InputActions
	- Alienduck
	- 16/10/2025
	- v1.0
	@summary Gère la création, la récupération et l’activation des contextes d’actions clavier/manette.
]]

---------------------------------------------------------------------
-- Services
---------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")

---------------------------------------------------------------------
-- Modules
---------------------------------------------------------------------

local Utility = require(ReplicatedStorage.Shared.Utility)

---------------------------------------------------------------------
-- Templates
---------------------------------------------------------------------

local actionTemplate = Instance.new("InputAction")
actionTemplate.Name = "ActionTemplate"
actionTemplate.Type = Enum.InputActionType.Bool
actionTemplate.Parent = script

local gamepadBinding = Instance.new("InputBinding")
gamepadBinding.Name = "GamepadBinding"
gamepadBinding.Parent = actionTemplate

local keyboardBinding = Instance.new("InputBinding")
keyboardBinding.Name = "KeyboardBinding"
keyboardBinding.Parent = actionTemplate

---------------------------------------------------------------------
-- Types
---------------------------------------------------------------------

export type Action = InputAction & {
	GamepadBinding: InputBinding,
	KeyboardBinding: InputBinding,
}

export type KeybindImpl = {
	CurrentContext: string,
	EnableContext: (context: string) -> (),
	GetAction: (context: string, name: string) -> Action,
}

export type KeybindContext = {
	context: InputContext,
	keybinds: { [string]: Action },
}

---------------------------------------------------------------------
-- Constantes
---------------------------------------------------------------------

local ACTION_TEMPLATE: Action = script.ActionTemplate
local ALWAYS_ON_STATE = "idle" -- contexte toujours actif

---------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------

local keybinds: { [string]: KeybindContext } = {}
local Keybind: KeybindImpl = { CurrentContext = "" } :: KeybindImpl

---------------------------------------------------------------------
-- Fonctions privées
---------------------------------------------------------------------

-- Crée ou récupère un contexte d’action
local function getContext(name: string): KeybindContext
	if not keybinds[name] then
		local context = Instance.new("InputContext")
		context.Enabled = name == ALWAYS_ON_STATE
		context.Name = name
		context.Parent = script

		keybinds[name] = {
			context = context,
			keybinds = {},
		}
	end
	return keybinds[name]
end

-- Crée une action vierge clonée depuis le template
local function getEmptyAction(): Action
	return ACTION_TEMPLATE:Clone()
end

---------------------------------------------------------------------
-- Méthodes publiques
---------------------------------------------------------------------

-- Récupère ou crée une action dans un contexte
function Keybind.GetAction(contextName: string, actionName: string): Action
	local context = getContext(contextName)
	local action = context.keybinds[actionName]

	if not action then
		local newAction = getEmptyAction()
		newAction.Name = actionName
		newAction.Parent = context.context

		for _, binding in newAction:GetChildren() do
			if not binding:IsA("InputBinding") then
				continue
			end

			local bindingName = binding.Name
			binding:GetPropertyChangedSignal("KeyCode"):Connect(function()
				if binding.KeyCode == Enum.KeyCode.Unknown then
					Utility.Warn("KeyCode unknown", script.Name)
					return
				end

				-- Vérifie si la touche correspond bien au type de binding
				local isGamepadBinding = (binding.KeyCode.Name:find("Button") or binding.KeyCode.Name:find("DPad"))
					and not binding.KeyCode.Name:find("Mouse")

				if (bindingName == "GamepadBinding") ~= isGamepadBinding then
					binding.KeyCode = Enum.KeyCode.Unknown
					Utility.Warn(
						"Invalid keybind: gamepad bindings must only use gamepad buttons, and vice versa.",
						script.Name
					)
					return
				end

				-- Vérifie les doublons
				for otherName, otherAction in context.keybinds do
					if (otherAction :: any) == newAction then
						continue
					end

					local otherBinding = otherAction:FindFirstChild(bindingName)
					if otherBinding and otherBinding:IsA("InputBinding") then
						if otherBinding.KeyCode == binding.KeyCode then
							Utility.Warn(`Conflicting keybinds found for {actionName} and {otherName}.`, script.Name)
						end
					end
				end
			end)
		end

		context.keybinds[actionName] = newAction
		action = newAction
	end

	return action
end

-- Active un contexte (désactive les autres sauf "idle")
function Keybind.EnableContext(context)
	for name, entry in keybinds do
		entry.context.Enabled = (name == context or name == ALWAYS_ON_STATE)
	end
	Keybind.CurrentContext = context
end

---------------------------------------------------------------------
-- Return
---------------------------------------------------------------------

return Keybind :: KeybindImpl
