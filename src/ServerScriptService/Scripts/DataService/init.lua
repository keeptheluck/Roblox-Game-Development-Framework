local service = {Priority = 10}

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local SocialService = game:GetService("SocialService")

local ProfileService = require(script:WaitForChild("ProfileService"))
local ProfileTemplate = require(script:WaitForChild("Template"))

local Profiles = {}
local ProcessingPlayers = {}

local key = 'PlayerDataProdV1'
local profileKey = "Player_"
local ProfileStore = ProfileService.GetProfileStore(
	key,
	ProfileTemplate
)

function service.Init()
	service.Data = {}
	service.MockProfile = true
	
	service.DayReset = Instance.new("BindableEvent")
end

--//Side functions
function service.GetProfileStore()
	return ProfileStore
end

function service.GetProfile(player: Player)
	return Profiles[player]
end

function service.IsActive(player: Player)
	return Profiles[player]:IsActive()
end

function service.ViewProfile(id: number)
	return ProfileStore:ViewProfileAsync(profileKey .. id)
end

function service.SendGlobalUpdate(id: number, sendData: {string: any})
	return ProfileStore:GlobalUpdateProfileAsync(
		(profileKey .. id),
		function(globalUpdates)
			globalUpdates:AddActiveUpdate(sendData)
		end
	)
end

--//Main
function service.UpdateLeaderstats(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local data = service.Data[player]
	if not (data and leaderstats) then
		return
	end

	
end

function service.DataSetup(player: Player, profile: any) --//Extra setup if needed
	local data = profile.Data

	--//Leaderstats
	local leaderstats = Instance.new("Folder", player)
	leaderstats.Name = "leaderstats"

	local DPSValue = Instance.new("IntValue")
	DPSValue.Name = "DPS"
	DPSValue.Value = data.DPS
	DPSValue.Parent = leaderstats

	DPSValue.Changed:Connect(function(value)
		data.DPS = value
	end)

	local yenValue = Instance.new("StringValue")
	yenValue.Name = "Yen"
	yenValue.Value = data.Yen
	yenValue.Parent = player

	yenValue.Changed:Connect(function(value)
		data.Yen = tostring(value)
	end)
end

function service.PlayerSetup(player)
	print(player.Name.." joined!")

	while ProfileService.ServiceLocked do
		task.wait()
	end
	
	if Profiles[player] then
		return
    end
		
	local profile = nil
	if RunService:IsStudio() and service.MockProfile == true then
		profile = ProfileStore.Mock:LoadProfileAsync(profileKey .. player.UserId)
	else
		profile = ProfileStore:LoadProfileAsync(profileKey .. player.UserId)
	end
	
	if profile then
		profile:AddUserId(player.UserId) -- GDPR compliance
		profile:Reconcile() -- Fill in missing variables from ProfileTemplate (optional)
		profile:ListenToRelease(function()
			Profiles[player] = nil
			service.Data[player] = nil
			
			player:Kick("1 | Profile could not be loaded!")
		end)
		
		if not player:IsDescendantOf(Players) then
			profile:Release()
			return
		end

		Profiles[player] = profile
		service.Data[player] = profile.Data
		
		local serverType = workspace:GetAttribute("ServerType")
		if not (service.framework:IsTemporaryServer() and serverType == "AFKWorld") then
			service.DataSetup(player, profile)
		end

		print("Data loaded for "..player.Name)
		player:SetAttribute("Loaded", true)
	else
		player:Kick("2 | Profile could not be loaded!")
	end
end

function service.PlayerAdded(player)
	local profile = service.GetProfile(player)
	local data = service.Data[player]
	
	if not (profile and data and not service.framework:IsTemporaryServer()) then
		return
	end
end

function service.PlayerRemoving(player: Player)
	local profile = Profiles[player]
	
	if profile then
		profile.Data.LastLeft = workspace:GetServerTimeNow()
		warn(profile.Data)
		profile:Release()
	end
end

return service