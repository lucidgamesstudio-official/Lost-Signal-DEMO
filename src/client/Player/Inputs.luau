-- Object
local Inputs = {}
Inputs.__index = Inputs

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Utility = require(ReplicatedStorage.Shared.Utility)
local InputActions = require(ReplicatedStorage.Shared.Utils.InputActions)

-- Types
export type InputsType = {
    -- Public

    -- Private
    CONTEXTS: { [string]: number },
    ACTIONS: { [string]: number },
}

-- Constantes
Inputs.CONTEXTS = {
    NORMAL = "NORMAL",
    CINEMATIC = "CINEMATIC",
    DEAD = "DEAD"
}

Inputs.ACTIONS = {
    SPRINT = "SPRINT",
    CROUCH = "CROUCH",
    ACTION = "ACTION"
}

local REMOTE_EVENT_FOLDER = Utility.CreateFolder("RemoteEvents")
local START_SPRINT_REMOTE = Utility.CreateRemoteEvent("startSprint", REMOTE_EVENT_FOLDER)
local STOP_SPRINT_REMOTE = Utility.CreateRemoteEvent("stopSprint", REMOTE_EVENT_FOLDER)
local START_CROUCH_REMOTE = Utility.CreateRemoteEvent("startCrouch", REMOTE_EVENT_FOLDER)
local STOP_CROUCH_REMOTE = Utility.CreateRemoteEvent("stopCrouch", REMOTE_EVENT_FOLDER)
local ACTION_REMOTE = Utility.CreateRemoteEvent("action", REMOTE_EVENT_FOLDER)
local SEND_CONN_REMOTE = Utility.CreateRemoteEvent("addConnections", REMOTE_EVENT_FOLDER)

-- Variables
local connections: { RBXScriptConnection | thread} = {}

--=========================================
-- HELPERS
--=========================================


--=========================================
-- Actions
--=========================================

-- SPRINT
local sprint: InputActions.Action = InputActions.GetAction(Inputs.CONTEXTS.NORMAL, Inputs.ACTIONS.SPRINT)
sprint.KeyboardBinding.KeyCode = Enum.KeyCode.LeftShift

local startSprintConn: RBXScriptConnection = sprint.Pressed:Connect(function ()
    if Players.LocalPlayer.Character then
        START_SPRINT_REMOTE:FireServer()
    end
end)
table.insert(connections, startSprintConn)

local stopSprintConn: RBXScriptConnection = sprint.Released:Connect(function ()
    if Players.LocalPlayer.Character then
        STOP_SPRINT_REMOTE:FireServer()
    end
end)
table.insert(connections, stopSprintConn)

-- CROUCH
local crouch: InputActions.Action = InputActions.GetAction(Inputs.CONTEXTS.NORMAL, Inputs.ACTIONS.CROUCH)
crouch.KeyboardBinding.KeyCode = Enum.KeyCode.C

local startCrouchConn: RBXScriptConnection = crouch.Pressed:Connect(function ()
    if Players.LocalPlayer.Character then
        START_CROUCH_REMOTE:FireServer()
    end
end)
table.insert(connections, startCrouchConn)

local stopCrouchConn: RBXScriptConnection = crouch.Released:Connect(function ()
    if Players.LocalPlayer.Character then
        STOP_CROUCH_REMOTE:FireServer()
    end
end)
table.insert(connections, stopCrouchConn)

-- ACTION
local action: InputActions.Action = InputActions.GetAction(Inputs.CONTEXTS.NORMAL, Inputs.ACTIONS.ACTION)
action.KeyboardBinding.KeyCode = Enum.KeyCode.MouseLeftButton

local actionConn: RBXScriptConnection = crouch.Pressed:Connect(function ()
    if Players.LocalPlayer.Character then
        ACTION_REMOTE:FireServer()
    end
end)
table.insert(connections, actionConn)

-- Send connections to player
SEND_CONN_REMOTE:FireServer(connections)

return Inputs