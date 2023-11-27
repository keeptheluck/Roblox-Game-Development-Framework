local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Scripts = script.Parent.Parent.Scripts

local framework = require(ReplicatedStorage:WaitForChild("Framework"))

framework.Start(Scripts)