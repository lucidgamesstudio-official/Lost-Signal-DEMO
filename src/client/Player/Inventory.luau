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

-- Typing
export type ItemSlot = CanvasGroup & {
    ViewportFrame: ViewportFrame,
    BG: ImageLabel
}

export type PlayerInventoryType = {
    -- Public properties
    Screen: ScreenGui,
    SlotContainer: CanvasGroup,
    PlaceHolderFolder: Folder,
    PlaceHolder: ItemSlot,

    -- Private properties
    canInteract: boolean,

    -- Public methods
    new: (player: Player) -> PlayerInventoryType,
    AddItem: (self: PlayerInventoryType, tool: Tool) -> (),
    RemoveItem: (self: PlayerInventoryType, tool: Tool) -> (),
    ShowInventory: (self: PlayerInventoryType, hideDelay: number) -> (),
    HideInventory: (self: PlayerInventoryType) -> (),
}

-- Constructor
function PlayerInventory.new(player: Player): PlayerInventoryType
    local self = {} :: PlayerInventoryType
    self = setmetatable(self, PlayerInventory)
    
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
    self:HideInventory()

    return self
end

function PlayerInventory.AddItem(self: PlayerInventoryType, tool: Tool)
    local newSlot: ItemSlot = self.PlaceHolder:Clone()
    local toolRepresentation: Tool = TOOL_REPRESENTATION_FOLDER:FindFirstChild(tool.Name):Clone()
    if not toolRepresentation then
        Utility.Warn("Warn: No toolRepresentation found in: " .. TOOL_REPRESENTATION_FOLDER.Name, script.Name)
        return
    end
    toolRepresentation.Parent = newSlot.ViewportFrame:FindFirstChildOfClass("WorldModel")
    newSlot.Name = tool.Name
    newSlot.Parent = self.SlotContainer
    newSlot.Visible = true
    self:ShowInventory(2)
end

function PlayerInventory.RemoveItem(self: PlayerInventoryType, tool: Tool)
    local slot: ItemSlot = self.SlotContainer:FindFirstChild(tool.Name) :: ItemSlot
    if not slot then
        Utility.Warn("Warn: slot not found in: " .. tostring(self.SlotContainer), script.Name)
        return
    end
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

return PlayerInventory