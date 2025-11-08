local Dialogues = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Utility = require(ReplicatedStorage.Shared.Utility)

-- Folders
local RemoteEventsFolder: Folder = Utility.CreateFolder("RemoteEvents")

-- Remotes
local SendDialoguesRemote: RemoteEvent = Utility.CreateRemoteEvent("SendDialogues", RemoteEventsFolder)

-- Typing
export type DialoguesDict = {
	title: string?,
	lines: { string }?,
	speaker: string?,
	portrait: string?,
	style: number?,
}

-----------------------------------------------------------
-- Functions
-----------------------------------------------------------

function Dialogues.SendDialogue(player: Player, dialogues: DialoguesDict): boolean
	if not player:IsA("Player") then
		Utility.Warn(`Player: {player} not exist`, script.Name)
		return false
	end
	if typeof(dialogues) ~= "table" then
		Utility.Warn("Invalid dialogue payload", script.Name)
		return false
	end
	if dialogues.lines and #dialogues.lines == 0 then
		Utility.Warn("Dialogue has no lines", script.Name)
		return false
	end

	SendDialoguesRemote:FireClient(player, dialogues)

	return true
end

return Dialogues
