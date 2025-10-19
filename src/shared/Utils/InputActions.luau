--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = require(ReplicatedStorage.Shared.Utility)
local actionTemplate: InputAction = Instance.new("InputAction")
actionTemplate.Name = "ActionTemplate"
actionTemplate.Parent = script
actionTemplate.Type = Enum.InputActionType.Bool

local GamepadBinding: InputBinding = Instance.new("InputBinding")
GamepadBinding.Name = "GamepadBinding"
GamepadBinding.Parent = actionTemplate

local KeyboardBinding: InputBinding = Instance.new("InputBinding")
KeyboardBinding.Name = "KeyboardBinding"
KeyboardBinding.Parent = actionTemplate

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

-- module table:
local Keybind: KeybindImpl = { CurrentContext = "" } :: KeybindImpl

-- constant variables
local ACTION_TEMPLATE: Action = script.ActionTemplate
local ALWAYS_ON_STATE = "idle" -- this state will always be on

-- Private variables
local keybinds: { [string]: KeybindContext } = {}

-- Private functions

--[[
	@params: name: string \
	@return: KeybindContext \
	@description: Find context by the given name, create and return it if not found, return it if found.
]]
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

local function getEmptyAction(): Action
	return ACTION_TEMPLATE:Clone()
end

-- Global methods
function Keybind.GetAction(ctx: string, name: string): Action
	local context: KeybindContext = getContext(ctx)

	local action: Action = context.keybinds[name]
	if not action then
		local newAction = getEmptyAction()
		newAction.Name = name
		newAction.Parent = context.context

		for _, v in newAction:GetChildren() do
			local binding = v :: InputBinding
			local bindingName: string = v.Name

			binding:GetPropertyChangedSignal("KeyCode"):Connect(function()
				if binding.KeyCode == Enum.KeyCode.Unknown then
					Utility.Warn("KeyCode unknown", script.Name)
					return
				end

				-- cannot bind non-gamepad keycodes into gamepad binding
				local isGamepadBinding = (
					binding.KeyCode.Name:find("Button") ~= nil or binding.KeyCode.Name:find("DPad") ~= nil
				) and binding.KeyCode.Name:find("Mouse") == nil

				if (bindingName == "GamepadBinding") ~= isGamepadBinding then
					binding.KeyCode = Enum.KeyCode.Unknown
					Utility.Warn(
						"Invalid keybind provided. Gamepad bindings must only use gamepad buttons, and vice versa for keyboard.",
						script.Name
					)
					return
				end

				-- loop to check for duplicates
				for otherName: string, v: Action in context.keybinds do
					if (v :: any) == (newAction :: any) then
						continue
					end

					local bindingInstance: InputBinding = v:FindFirstChild(bindingName) :: InputBinding
					if bindingInstance and bindingInstance:IsA("InputBinding") then
						if bindingInstance.KeyCode == binding.KeyCode then
							Utility.Warn(`Conflicting keybinds found for {name} and {otherName}.`, script.Name)
						end
					end
				end
			end)
		end

		context.keybinds[name] = newAction
		action = newAction
	end
	return action
end

function Keybind.EnableContext(context)
	for name: string, v: KeybindContext in keybinds do
		v.context.Enabled = name == context or name == ALWAYS_ON_STATE
	end
	Keybind.CurrentContext = context
end

return Keybind :: KeybindImpl
