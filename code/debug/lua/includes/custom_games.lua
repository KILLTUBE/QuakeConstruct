local META = {}
local GAMES = {}

if(SERVER) then message.Precache("__customgame") end

function META:Init() end
function META:Shutdown() end

local function dummyhook()
	print("^3You can't add hooks in custom game scripts.\nUse the built-in functions instead.")
end

local function ExecuteGame(v)
	GAME = {}
	
	setmetatable(ENT,META)
	META.__index = META
	
	local ptr = hook.add
	local ptr2 = hook.Add
	
	hook.add = dummyhook
	hook.Add = dummyhook
	
	Execute(v[1])
	
	hook.add = ptr
	hook.Add = ptr2
	
	GAME._name = string.lower(v[2])
	GAME._active = false
	GAME._exedata = v
	
	GAMES[GAME._name] = GAME
	table.insert(_CUSTOM,{data=GAME,type="game"})
end

local function FindGame(name)
	if(name == nil) then return nil end
	if(type(name) != "string") then return nil end
	return GAMES[string.lower(name)]
end

local list = FindCustomFiles("lua/games")
for k,v in pairs(list) do
	ExecuteGame(v)
end

local function CallGameHook(h,...) --This blocks players from adding hooks thustly making the game portable
	if(h == nil) then return end
	local ptr = hook.add
	local ptr2 = hook.Add
	hook.add = dummyhook
	hook.Add = dummyhook
	local b,e = pcall(h,unpack(arg))
	hook.add = ptr
	hook.Add = ptr2
	if(b and e != nil) then return e end
end

local function AddGameHook(GAME,h)
	local func = GAME[h]
	hook.add(h,"__gh_" .. GAME._name,function(...) CallGameHook(func,GAME,unpack(arg)) end)
	print("Hooked game function: " .. h .. "\n")
end

local function GetHooks()
	local list = table.Copy(HOOKS.SHARED)
	if(SERVER) then list = table.Add(list,HOOKS.SV) end
	if(CLIENT) then list = table.Add(list,HOOKS.CL) end
	return list
end

local function HookGame(GAME)
	for k,v in pairs(GetHooks()) do
		AddGameHook(GAME,v)
	end
end

local function UnHookGame(GAME)
	for k,v in pairs(GetHooks()) do
		local h = "__gh_" .. GAME._name
		hook.remove(v,h)
		print("Unhooked GHook: " .. v .. "\n")
	end
end

function ListCustomGames()
	local out = {}
	for k,v in pairs(GAMES) do
		table.insert(out,k)
	end
	return out
end

function GetCustomGameStatus(name)
	if(GAMES[name] != nil) then
		return GAMES[name]._active
	end
	return false
end

if(SERVER) then
	function NetStartGame(GAME)
		local msg = Message(v,"__customgame")
		message.WriteString(msg,GAME._name)
		message.WriteShort(msg,1)
		SendDataMessageToAll(msg)
	end
	
	function NetEndGame(GAME)
		local msg = Message(v,"__customgame")
		message.WriteString(msg,GAME._name)
		message.WriteShort(msg,0)
		SendDataMessageToAll(msg)	
	end
	
	function StartGames()
		for k,v in pairs(ListCustomGames()) do
			if(v._active) then
				StartGame(v)
			end
		end
	end
	hook.add("ClientReady","__custom_games",StartGames,9999)
end

local active = {}
function StartCustomGame(name)
	local GAME = FindGame(name)
	if(GAME == nil) then return end
	if(GAME._active) then error("Error Executing Game[" .. name .. "]:\nThis custom game is already active.\n") end
	
	if(SERVER) then NetStartGame(GAME) end
	HookGame(GAME)
	GAME._active = true
	if(GAME.init) then GAME:Init() end
end

function EndCustomGame(name)
	local GAME = FindGame(name)
	if(GAME == nil) then return end
	if(GAME._active != true) then return end
	
	if(SERVER) then NetEndGame(GAME) end
	if(GAME.Shutdown) then GAME:Shutdown() end
	GAME._active = false
	UnHookGame(GAME)
end

function ReloadCustomGame(name)
	local act = false
	local GAME = FindGame(name)
	if(GAME == nil) then return end
	if(GAME._active) then 
		act = true 
		EndCustomGame(name)
	end
	ExecuteGame(GAME._exedata)
	if(act) then StartCustomGame(name) end
end

if(CLIENT) then
	local function report(msgid)
		if(msgid != "__customgame") then return end
		local name = message.ReadString()
		local status = message.ReadShort()
		if(status == 1) then
			StartCustomGame(name)
		else
			EndCustomGame(name)
		end
	end
	hook.add("HandleMessage","__custom_games",report)
else
	concommand.Add("StartCustomGame",function(p,c,a) 
		if(type(a[1]) == "string") then
			StartCustomGame(a[1])
		end
	end,true)
	
	concommand.Add("EndCustomGame",function(p,c,a) 
		if(type(a[1]) == "string") then
			EndCustomGame(a[1])
		end
	end,true)
	
	concommand.Add("ReloadCustomGame",function(p,c,a) 
		if(type(a[1]) == "string") then
			ReloadCustomGame(a[1])
		end
	end,true)
end

function EndCustomGames()
	for k,v in pairs(ListCustomGames()) do
		EndCustomGame(v)
	end
end