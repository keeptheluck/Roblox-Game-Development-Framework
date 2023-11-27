local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Scripts = script.Parent.Parent:WaitForChild("Scripts")

local Player = Players.LocalPlayer

-- This is set after data is loaded.
while not Player:GetAttribute("Loaded") do
	task.wait()
end

framework.Start(Scripts)