-- Object
local PlayerInventory = {}
PlayerInventory.__index = PlayerInventory

-- Services
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Modules
local Utility = require(ReplicatedStorage.Shared.Utility)

-- Constantes
local TOOL_REPRESENTATION_FOLDER = ReplicatedStorage:FindFirstChild("ItemsRepresentation")
local GUI: ScreenGui = ReplicatedFirst:FindFirstChild("Guis"):FindFirstChild("InventoryScreen")
local REMOTE_EVENT_FOLDER = Utility.CreateFolder("RemoteEvents")
local EQUIP_TOOL_REMOTE = Utility.CreateRemoteEvent("EquipTool", REMOTE_EVENT_FOLDER)
local UNEQUIP_TOOL_REMOTE = Utility.CreateRemoteEvent("UnequipTool", REMOTE_EVENT_FOLDER)

-- Typing
export type ItemSlot = ImageButton & {
    -- Childs
    ViewportFrame: ViewportFrame,
    BG: ImageLabel
}

export type PlayerInventoryType = {
    -- Public properties
    Player: Player,
    Character: Model,
    Screen: ScreenGui,
    SlotContainer: CanvasGroup,
    PlaceHolderFolder: Folder,
    PlaceHolder: ItemSlot,

    -- Private properties
    canInteract: boolean,
    nextId: number,
    _slotConns: { [number]: RBXScriptConnection },

    -- Public methods
    new: (player: Player) -> PlayerInventoryType,
    AddItem: (self: PlayerInventoryType, tool: Tool) -> (),
    RemoveItem: (self: PlayerInventoryType, tool: Tool) -> (),
    ShowInventory: (self: PlayerInventoryType, hideDelay: number) -> (),
    HideInventory: (self: PlayerInventoryType) -> (),

    -- Private method
    _nextId: (self: PlayerInventoryType) -> number,
}

-- Constructor
function PlayerInventory.new(player: Player): PlayerInventoryType
    local self = {} :: PlayerInventoryType
    self = setmetatable(self, PlayerInventory)
    
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
    self.nextId = 0
    self._slotConns = {}
    self:HideInventory()

    return self
end

-- Public methods

function PlayerInventory.AddItem(self: PlayerInventoryType, tool: Tool)
    local newSlot: ItemSlot = self.PlaceHolder:Clone()
    local toolRepresentation: Tool = TOOL_REPRESENTATION_FOLDER:FindFirstChild(tool.Name):Clone()
    if not toolRepresentation then
        Utility.Warn("Warn: No toolRepresentation found in: " .. TOOL_REPRESENTATION_FOLDER.Name, script.Name)
        return
    end
    toolRepresentation.Parent = newSlot.ViewportFrame:FindFirstChildOfClass("WorldModel")
    local newSlotId = self:_nextId()
    newSlot.Name = tool.Name
    newSlot.Parent = self.SlotContainer
    newSlot.Visible = true
    newSlot:SetAttribute("SlotId", newSlotId)
    local newSlotConn: RBXScriptConnection = newSlot.Activated:Connect(function ()
        local clone: Tool = tool:Clone()
        if Utility.GetToolFromCharacter(self.Character, clone.Name) then
            UNEQUIP_TOOL_REMOTE:FireServer()
        else
            EQUIP_TOOL_REMOTE:FireServer(clone.Name)
        end
    end)
    self._slotConns[newSlotId] = newSlotConn
    self:ShowInventory(2)
end

function PlayerInventory.RemoveItem(self: PlayerInventoryType, tool: Tool)
    local slot: ItemSlot = self.SlotContainer:FindFirstChild(tool.Name) :: ItemSlot
    if not slot then
        Utility.Warn("Warn: slot not found in: " .. tostring(self.SlotContainer), script.Name)
        return
    end
    local worldModel: WorldModel = slot.ViewportFrame:FindFirstChildOfClass("WorldModel") :: WorldModel
    local toolRepresentation: Tool? = worldModel:FindFirstChildOfClass("Tool")
    if toolRepresentation then
        toolRepresentation:Destroy()
    end
    local slotConn: RBXScriptConnection? = slot:GetAttribute("SlotId") and self._slotConns[slot:GetAttribute("SlotId") :: number] or nil
    if not slotConn then
        Utility.Warn("Warn: No connection found for the slot: " .. tostring(slot:GetDebugId()), script.Name)
        return
    end
    slotConn:Disconnect()
    self._slotConns[slot:GetAttribute("SlotId") :: number] = nil
    slot:Destroy()
end

function PlayerInventory.ShowInventory(self: PlayerInventoryType, hideDelay: number?)
    if not self.canInteract then return end
    local TI: TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine)
    local goal = {
        AnchorPoint = Vector2.new(.5, 1)
    }
    local Tween: Tween = TweenService:Create(self.SlotContainer, TI, goal)
    Tween:Play()
    self.canInteract = false
    Tween.Completed:Once(function ()
        self.canInteract = true
        if hideDelay then
            task.delay(hideDelay, function()
                self:HideInventory()
            end)
        end
    end)
end

function PlayerInventory.HideInventory(self: PlayerInventoryType)
    if not self.canInteract then return end
    local TI: TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine)
    local goal = {
        AnchorPoint = Vector2.new(.5, 0)
    }
    local Tween: Tween = TweenService:Create(self.SlotContainer, TI, goal)
    Tween:Play()
    self.canInteract = false
    Tween.Completed:Once(function ()
        self.canInteract = true
    end)
end

-- Private methods

function PlayerInventory:_nextId()
    self.nextId += 1
    return self.nextId
end

return PlayerInventory