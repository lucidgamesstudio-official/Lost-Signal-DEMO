-- Services
local Players: Players = game:GetService("Players")
local TweenService: TweenService = game:GetService("TweenService")
local ReplicatedFirst: ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContentProvider: ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Disable default GUI
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

-- Modules
local Utility = require(ReplicatedStorage:WaitForChild("Shared").Utility)

ReplicatedFirst:RemoveDefaultLoadingScreen()

-- Classe
local LoadingModule = {}
LoadingModule.__index = LoadingModule

-- Constantes
local GUI_FOLDER: Folder = ReplicatedFirst:FindFirstChild("Guis") :: Folder
if not GUI_FOLDER then
	return Utility.Warn("Warn: Fail to find GUIS folder", script.Name)
end
local ASSETS: { Instance } = game:GetDescendants()
local REMOTE_EVENT_FOLDER = Utility.CreateFolder("RemoteEvents")

-- Variables

-- Manual Typage
export type LoadingModuleType = {
	-- Public Properties
	Screen: ScreenGui,
	Container: CanvasGroup,
	BarBase: Frame,
	BarLoading: Frame,
	AssetLoading: TextLabel,

	Player: Player,

	-- Private Properties

	-- Connections/Threads

	-- Functions/Methods
	new: (screenGui: ScreenGui) -> LoadingModuleType,
	Init: (self: LoadingModuleType) -> (),
}

-- Constructor
function LoadingModule.new(): LoadingModuleType?
	local self = {} :: LoadingModuleType
	self = setmetatable(self, LoadingModule)

	-- Find the GUI
	local screenGui: ScreenGui = GUI_FOLDER:FindFirstChild("LoadingScreen") :: ScreenGui
	if not screenGui then
		Utility.Error("Error: No loading screen found", script.Name)
		return nil
	end

	-- Public Properties
	self.Screen = screenGui
	self.Container = screenGui:WaitForChild("Container") :: CanvasGroup
	self.BarBase = self.Container:WaitForChild("BarBase") :: Frame
	self.BarLoading = self.BarBase:WaitForChild("BarLoading") :: Frame
	self.AssetLoading = self.Container:WaitForChild("AssetLoading") :: TextLabel

	self.Player = Players.LocalPlayer

	-- Private Properties

	-- Connections/Threads

	return self
end

------------------------------------------------------------------------------
-- HELPERS
------------------------------------------------------------------------------

local function fadeIn(canvas: CanvasGroup, doWait: boolean)
	canvas.GroupTransparency = 1
	canvas.Visible = true
	local TI: TweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local Tween: Tween = TweenService:Create(canvas, TI, { GroupTransparency = 0 })
	Tween:Play()
	if doWait then
		Tween.Completed:Wait()
	end
end

local function fadeOut(canvas: CanvasGroup, doWait: boolean)
	canvas.GroupTransparency = 0
	canvas.Visible = true
	local TI: TweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local Tween: Tween = TweenService:Create(canvas, TI, { GroupTransparency = 1 })
	Tween:Play()
	if doWait then
		Tween.Completed:Wait()
	end
end

------------------------------------------------------------------------------
-- METHODS
------------------------------------------------------------------------------

function LoadingModule.Init(self: LoadingModuleType)
	for _, content in ipairs(self.Screen:GetDescendants()) do
		ContentProvider:PreloadAsync({ content })
	end
	self.Screen.Enabled = true
	self.Container.Visible = true
	self.Screen.Parent = self.Player:WaitForChild("PlayerGui")
	self.BarLoading.AnchorPoint = Vector2.new(1, .5)
	self.BarLoading.Position = UDim2.fromScale(1, .5)
	self.BarLoading.Size = UDim2.fromScale(1, 1)
	fadeIn(self.Container, true)
	for index, element in ipairs(ASSETS) do
		self.AssetLoading.Text = "Loading: " .. element.Name .. "..."
		ContentProvider:PreloadAsync({ element })

		local progress = index / #ASSETS
		-- ancienne version : grandit la barre
		-- self.BarLoading.Size = UDim2.new(progress, 0, self.BarLoading.Size.Y.Scale, 0)

		-- nouvelle version : rétrécit la barre
		self.BarLoading.Size = UDim2.new(1 - progress, 0, self.BarLoading.Size.Y.Scale, 0)
	end

	Utility.CreateRemoteEvent("spawnPlayer", REMOTE_EVENT_FOLDER):FireServer()
	Players.LocalPlayer.CharacterAdded:Wait()
	fadeOut(self.Container, true)
	self.Screen:Destroy()
end

-- Return
return LoadingModule
