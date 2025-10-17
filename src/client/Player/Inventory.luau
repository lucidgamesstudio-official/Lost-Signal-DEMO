--[[
	- Inventory
	- Alienduck
	- 16/10/2025
	- v1.0
]]

-- Object
local PlayerInventory = {}
PlayerInventory.__index = PlayerInventory

-- Services
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Modules
local Utility = require(ReplicatedStorage.Shared.Utility)

-- Constants
local TOOL_REPRESENTATION_FOLDER = ReplicatedStorage:FindFirstChild("ItemsRepresentation")
local GUI: ScreenGui = ReplicatedFirst:FindFirstChild("Guis"):FindFirstChild("InventoryScreen")
local REMOTE_EVENT_FOLDER = Utility.CreateFolder("RemoteEvents")
local EQUIP_TOOL_REMOTE = Utility.CreateRemoteEvent("EquipTool", REMOTE_EVENT_FOLDER)
local UNEQUIP_TOOL_REMOTE = Utility.CreateRemoteEvent("UnequipTool", REMOTE_EVENT_FOLDER)

-- Typing
export type ItemSlot = ImageButton & {
	ViewportFrame: ViewportFrame,
	BG: ImageLabel,
}

export type PlayerInventoryType = {
	Player: Player,
	Character: Model,
	Screen: ScreenGui,
	SlotContainer: CanvasGroup,
	PlaceHolderFolder: Folder,
	PlaceHolder: ItemSlot,

	canInteract: boolean,
	isVisible: boolean,
	nextId: number,
	_slotConns: { [number]: RBXScriptConnection },

	new: (player: Player) -> PlayerInventoryType,
	AddItem: (self: PlayerInventoryType, tool: Tool) -> (),
	RemoveItem: (self: PlayerInventoryType, tool: Tool) -> (),
	ShowInventory: (self: PlayerInventoryType, hideDelay: number?) -> (),
	HideInventory: (self: PlayerInventoryType) -> (),
	GetSlotByIndex: (self: PlayerInventoryType, index: number?) -> ItemSlot?,
	_nextId: (self: PlayerInventoryType) -> number,
}

-- Constructor
function PlayerInventory.new(player: Player): PlayerInventoryType
	local self = setmetatable({}, PlayerInventory)

	self.Player = player
	self.Character = player.Character or player.CharacterAdded:Wait()
	self.Screen = GUI:Clone() :: ScreenGui
	if not self.Screen then
		Utility.Error("Error: no InventoryScreen found in: " .. tostring(player.PlayerGui), script.Name)
		return self
	end

	self.Screen.Parent = player.PlayerGui
	self.SlotContainer = self.Screen:FindFirstChild("SlotContainer")
	self.PlaceHolderFolder = self.SlotContainer:FindFirstChild("PlaceHolder")
	self.PlaceHolder = self.PlaceHolderFolder:FindFirstChild("PlaceHolder")
	self.canInteract = true
	self.isVisible = false
	self.nextId = 0
	self._slotConns = {}

	self:HideInventory()
	return self
end

-- Methods

function PlayerInventory:AddItem(tool: Tool)
	local newSlot: ItemSlot = self.PlaceHolder:Clone()
	local toolRepresentation: Tool = TOOL_REPRESENTATION_FOLDER:FindFirstChild(tool.Name)

	if not toolRepresentation then
		Utility.Warn("Warn: No toolRepresentation found in: " .. TOOL_REPRESENTATION_FOLDER.Name, script.Name)
		return
	end

	local clonedRepresentation = toolRepresentation:Clone()
	clonedRepresentation.Parent = newSlot.ViewportFrame:FindFirstChildOfClass("WorldModel")

	local newSlotId = self:_nextId()
	newSlot.Name = tool.Name
	newSlot.LayoutOrder = #Utility.GetChildrenOfClass(self.SlotContainer, "ImageButton") + 1
	newSlot.Parent = self.SlotContainer
	newSlot.Visible = true
	newSlot:SetAttribute("SlotId", newSlotId)

	local newSlotConn = newSlot.Activated:Connect(function()
		local clone = tool:Clone()
		if Utility.GetToolFromCharacter(self.Character, clone.Name) then
			UNEQUIP_TOOL_REMOTE:FireServer()
		else
			EQUIP_TOOL_REMOTE:FireServer(clone.Name)
		end
	end)

	self._slotConns[newSlotId] = newSlotConn
	self:ShowInventory(2)
end

function PlayerInventory:RemoveItem(tool: Tool)
	local slot: ItemSlot = self.SlotContainer:FindFirstChild(tool.Name)
	if not slot then
		Utility.Warn("Warn: slot not found in: " .. tostring(self.SlotContainer), script.Name)
		return
	end

	-- Cleanup content
	local worldModel = slot.ViewportFrame:FindFirstChildOfClass("WorldModel")
	local toolRepresentation = worldModel and worldModel:FindFirstChildOfClass("Tool")
	if toolRepresentation then
		toolRepresentation:Destroy()
	end

	-- Disconnect
	local slotId = slot:GetAttribute("SlotId")
	if slotId and self._slotConns[slotId] then
		self._slotConns[slotId]:Disconnect()
		self._slotConns[slotId] = nil
	end

	slot:Destroy()

	-- Reorder LayoutOrders
	local index = 1
	for _, child in ipairs(self.SlotContainer:GetChildren()) do
		if child:IsA("ImageButton") then
			child.LayoutOrder = index
			index += 1
		end
	end
end

function PlayerInventory:ShowInventory(hideDelay: number?)
	if not self.canInteract then
		return
	end

	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine)
	local tween = TweenService:Create(self.SlotContainer, tweenInfo, { AnchorPoint = Vector2.new(0.5, 1) })

	self.canInteract = false
	self.isVisible = true
	tween:Play()

	tween.Completed:Once(function()
		self.canInteract = true
		if hideDelay then
			task.delay(hideDelay, function()
				self:HideInventory()
			end)
		end
	end)
end

function PlayerInventory:HideInventory()
	if not self.canInteract then
		return
	end

	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine)
	local tween = TweenService:Create(self.SlotContainer, tweenInfo, { AnchorPoint = Vector2.new(0.5, 0) })

	self.canInteract = false
	self.isVisible = false
	tween:Play()

	tween.Completed:Once(function()
		self.canInteract = true
	end)
end

function PlayerInventory:GetSlotByIndex(index: number?): ItemSlot?
	index = index or 0
	for _, slot in ipairs(self.SlotContainer:GetChildren()) do
		if slot:IsA("ImageButton") and slot.LayoutOrder == index then
			return slot
		end
	end
	return nil
end

-- Private Methods

function PlayerInventory:_nextId(): number
	self.nextId += 1
	return self.nextId
end

return PlayerInventory
