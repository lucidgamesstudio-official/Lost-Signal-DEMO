local module = {}

-- Services
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Utility = require(ReplicatedStorage.Shared.Utility)

-- Lighting Default Settings
-- local DefaultSettings = {
--     Brightness = 2,
--     ColorShift_Bottom = Color3.new(0, 0, 0),
--     ColorShift_Top = Color3.new(0, 0, 0),
--     ClockTime = 14.5,
--     ExposureCompensation = 0,
-- }

-- Lighting Want Settings
local WantSettings = {
    Brightness = 2,
    ColorShift_Bottom = Color3.new(0, 0, 0),
    ColorShift_Top = Color3.new(0, 0, 0),
    ClockTime = 0,
    ExposureCompensation = -.5,
}

function module:Init()
    for setting, value in WantSettings do
        Lighting[setting] = value
    end
    local GameSetting: Folder = Lighting:FindFirstChild("GameSetting")
    if not GameSetting then
        Utility.Warn("Not found Game Setting", script.Name)
        return
    end
    for _, effect in Lighting:GetChildren() do
        if effect:IsA("PostEffect") or effect:IsA("Sky") or effect:IsA("Atmosphere") and not effect:IsA("Folder") then
            effect:Destroy()
        end
    end
    for _, child in GameSetting:GetChildren() do
        if child:IsA("PostEffect") then
            child.Enabled = true
        end
        child.Parent = Lighting
    end
end

return module