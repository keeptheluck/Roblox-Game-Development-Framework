--//Services
local module = {}
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--//Variables
local functionSet = {}
local remoteSet = {}
local remoteStorage = {}
local replicatedSet = {}

--//ProcessCall
function ProcessCall(sName, index, indexType, args)
	local outcome = nil
	local thisTimeout = 60

	if RunService:IsServer() then
		local player = args[1]

		if player and (typeof(player) == "table" or (typeof(player)=="Instance" and Players:IsAncestorOf(player)))
			and not string.find(indexType, "All")
		then
			table.remove(args,1)
		end

		--//Client remote
		if indexType == "FireAll" then
			script.RemoteEvent:FireAllClients(sName, index, args)

		elseif indexType == "Fire" then
			if typeof(player)=="table" then
				for i,v in pairs (player) do
					if not v:IsA("Player") then
						continue
					end

					script.RemoteEvent:FireClient(v, sName, index, args)
				end
			elseif player:IsA("Player") then
				script.RemoteEvent:FireClient(player, sName, index, args)
			end

		elseif indexType == "Invoke" then
			local intialTick = os.clock()
			task.spawn(function()
				outcome = table.pack(script.RemoteFunction:InvokeClient(player, sName, index, args))
			end)

			repeat task.wait() until (os.clock() - intialTick >= thisTimeout or outcome)
		end

	else
		--//Server remote
		if indexType=="Fire" then
			script.RemoteEvent:FireServer(sName, index, args)

		elseif indexType=="Invoke" then
			outcome = table.pack(script.RemoteFunction:InvokeServer(sName, index, args))

		end
	end

	return table.unpack(outcome or {})
end

--//Framework
local framework = {}
local modules = {}

--//:Get() (For getting functions within same directory)
function framework:Get(sName)
	if functionSet[sName] == nil then
		warn("No module with the name: "..sName.." in the "..(RunService:IsServer() and "server" or "client").." was found." .. debug.traceback())
	end
	return functionSet[sName]
end

--//:Fetch() (Getting functions between server and client)
function framework:Fetch(sName, timeout, sendMetatable)
	--print("Fetch script:"..sName)

	local main = remoteStorage[sName] and remoteStorage[sName][1]
	local remoteFramework = remoteStorage[sName] and remoteStorage[sName][2]

	if main == nil or remoteFramework == nil then
		main = {}
		remoteFramework = {}

		remoteFramework.__index = function(_,index)

			return setmetatable({}, {
				__index = function(_, indexType)
					return function(_, ...)
						local args = {...}

						return ProcessCall(sName, index, indexType, args) 
					end
				end;
			})

		end;

		remoteStorage[sName] = {main, remoteFramework}
	end

	if sendMetatable == true then
		return main, remoteFramework
	else
		return setmetatable(main, remoteFramework)
	end
end

--//:IsTemporaryServer
function framework:IsTemporaryServer()
	return module:IsTemporaryServer()
end

--//Locking framework
framework.__index = error
framework.__newindex = error
framework.__metatable = "Locked"

modules.__index = modules

function setupFramework(internal, scriptName)
	internal.framework = framework
	internal.modules = setmetatable({}, modules)

	--//Custom functions go here
	function internal:Warn(output, ...)
		warn(string.format("[%s] Error: "..output, scriptName, ...))
	end
end

function IncludeScripts(parent, set)
	local scriptsRequiring = 0
	local allScripts = parent
	if typeof(parent) == "Instance" then
		allScripts = parent:GetDescendants()
	end

	for _,_script in pairs (allScripts) do
		local validParent = typeof(parent) == "table" or (_script.Parent == parent or (_script.Parent.Parent == parent and _script.Parent:IsA("Folder"))) 
		if _script and _script:IsA("ModuleScript") and validParent then
			task.spawn(function()
				scriptsRequiring += 1

				debug.setmemorycategory(string.format("%s_Framework_", _script.Name))
				local success, err = pcall(function()
					set[_script.Name] = require(_script)
				end)

				if success == false then
					if err then
						task.spawn(function()
							warn(string.format("Error while loading module %s", _script.Name))
							error(err)
						end)
					end

					set[_script.Name] = {}
					scriptsRequiring -= 1
					return
				end

				setupFramework(set[_script.Name], _script.Name)

				if RunService:IsServer() then
					remoteSet[_script.Name] = functionSet[_script.Name]["Client"]
				else
					remoteSet[_script.Name] = functionSet[_script.Name]["Server"]
				end

				scriptsRequiring -= 1
			end)
		end
	end

	while scriptsRequiring > 0 do
		task.wait()
	end

	table.sort(set,function(a,b)
		local priorityA = (a.settings and a.settings.Priority)
		local priorityB = (b.settings and b.settings.Priority)
		return (priorityA or 0) >= (priorityB or 0)
	end)
end

--//Main
function module.Start(folder: Folder|{any})
	if _G.framework then return end
	_G.framework = framework

	local function DefineModule(t,module)
		if module:IsA("ModuleScript") and not module:GetAttribute("Disabled") and module.Parent:IsA("Folder") then
			local index = module.Name
			if t[index] then
				warn("Module with same name found:", module.Name)
				return
			end

			local success, err = pcall(function()
				t[index] = require(module)
			end)

			if success == false and err then
				task.spawn(function()
					warn("Error while loading module: "..module.Name)
					error(err)
				end)
			end
		end
	end

	--//Setup
	local init = os.clock()

	if RunService:IsServer() then
		for i,v in pairs (game.ServerScriptService.Modules:GetDescendants()) do
			DefineModule(modules,v)
		end
	end
	for i,v in pairs (game.ReplicatedStorage.SharedModules:GetDescendants()) do
		DefineModule(modules,v)
	end

	_G.modules = modules

	--//Set up all scripts
	IncludeScripts(folder, functionSet)
	print("✅ Framework loaded ("..math.round(1000*(os.clock()-init)).." ms)")

	--//Functions
	local function Execute(sName, fName, internal, args)
		if internal and internal[fName] then
			-- local bindable = Instance.new("BindableEvent")

			-- local bindableConnection
			-- bindableConnection = bindable.Event:Connect(function() 
			-- 	internal[fName](table.unpack(args))
			-- end)

			-- bindable:Fire()
			-- bindableConnection:Disconnect()
			-- bindable:Destroy()
			task.spawn(internal[fName], table.unpack(args))
		end
	end

	local function ReplicatedExecute(sName, fName, args)
		local internal = remoteSet[sName]--_script]

		if internal and internal[fName] then
			if internal.settings and internal.settings.RunParallel == true then
				local bindable = Instance.new("BindableEvent")
				local output = nil

				task.spawn(function()
					local success, _output = pcall(internal[fName], (table.unpack(args)))
					output = (success and _output)

					bindable:Fire()
					if success == false then
						error(_output)
					end
				end)

				bindable.Event:Wait()
				bindable:Destroy()

				return output
			else
				return internal[fName](table.unpack(args))
			end
		else
			error(string.format("No remote with the name: %s in the %s script %s was found.", fName, (RunService:IsServer() and "server" or "client"), sName))
		end
	end

	--//Create callable core tasks.
	local function runTask(name, ...)
		local running = 0
		for _script,internal in pairs (functionSet) do
			local args = {...}

			if name == "Init" or name == "PlayerSetup" then
				task.spawn(function()
					running += 1

					debug.setmemorycategory(string.format("%s_Framework_", _script))
					if internal[name] then
						internal[name](table.unpack(args))
					end
					local diff = os.clock()-init

					running -= 1
				end)
			else
				task.spawn(function()
					debug.setmemorycategory(string.format("%s_Framework_", _script))
					Execute(_script, name, internal, args)
				end)
			end
		end
		while running > 0 do
			task.wait()
		end
	end

	--//Startup
	runTask("Init")
	runTask("Start")

	--//Step system
	RunService.Stepped:Connect(function(_, dt)
		runTask("Step", dt)
	end)

	if RunService:IsServer() then
		game:BindToClose(function()
			runTask("BindToClose")
		end)

	elseif RunService:IsClient() then
		RunService.RenderStepped:Connect(function()
			runTask("RenderStep")
		end)
	end

	for _script,internal in pairs (functionSet) do
		local object = internal["Loop"]
		local tasks = (typeof(object) == "table" and internal["Loop"]) 
			or (typeof(object) == "function" and {internal["Loop"]})
			or {}

		for i, loop in pairs (tasks) do
			task.spawn(function()
				while true do
					local success, err = pcall(function()
						if loop and typeof(loop)=="function" then
							loop()
						end
					end)

					if success == false and err then 
						task.spawn(function() --//Raise the error without pausing the execution 
							error(err)
						end) 
					end --

					task.wait()
				end
			end)
		end

	end

	--//Player/Character added
	local function SetupPlayer(player)
		runTask("PlayerSetup", player)
		runTask("PlayerAdded", player)

		if player.Character then
			runTask("CharacterAdded", player, player.Character)
		end

		player.CharacterAdded:Connect(function(char)
			runTask("CharacterAdded", player, char)
		end)
	end

	Players.PlayerAdded:Connect(SetupPlayer)
	for _,player in pairs (Players:GetPlayers()) do
		while player == nil do
			task.wait()
		end
		task.spawn(SetupPlayer, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		runTask("PlayerRemoving", player)
	end)

	--//Remote handling
	if RunService:IsServer() then
		local function callback(player, sName, fName, true_args)
			if true_args then
				table.insert(true_args, 1, player)
			end
			return ReplicatedExecute(sName, fName, true_args)
		end

		script.RemoteFunction.OnServerInvoke = callback
		script.RemoteEvent.OnServerEvent:Connect(callback)
	else
		local callback = ReplicatedExecute

		script.RemoteFunction.OnClientInvoke = callback
		script.RemoteEvent.OnClientEvent:Connect(callback)
	end

	--//External fetching
	script.Bindable.BindableFunction.OnInvoke = function(sName)
		return framework:Get(sName)
	end
	script.Bindable.BindableFunction2.OnInvoke = function(...)
		return framework:Fetch(...)
	end
end

function module:Get(sName)
	return script.Bindable.BindableFunction:Invoke(sName)
end

function module:Fetch(sName) 
	local main, metatable = script.Bindable.BindableFunction2:Invoke(sName, nil, true)
	return setmetatable(main, metatable)
end

function module:IsTemporaryServer()
	if RunService:IsServer() then
		return (game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0)
	else
		return workspace:GetAttribute("TemporaryServer")
	end
end

return module