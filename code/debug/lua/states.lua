local S = "sv"
if(CLIENT) then S = "cl" end

local US = string.upper(S)

_ACTIVESCRIPTS = {}

local function SAVE(slot)
	local AS = table.Copy(_ACTIVESCRIPTS)

	AS["lua/init.lua"] = nil
	AS["lua/cl_init.lua"] = nil
	AS["lua/states.lua"] = nil
	AS["lua/shared.lua"] = nil
	for k,v in pairs(AS) do
		if(string.StartsWith(k,"lua/includes")) then AS[k] = nil end
		if(string.StartsWith(k,"lua/downloads")) then AS[k] = nil end
		if(string.StartsWith(k,"persistance")) then AS[k] = nil end
	end
	
	local tab = persist.Load("lstate")
	local slots = tab["states"] or {}
	slots[S .. "_state" .. slot] = AS
	
	persist.Start("lstate")
	persist.Write("states",slots)
	for k,v in pairs(tab) do
		if(k ~= "states") then persist.Write(k,v) end
	end
	print(US .. ": Saved Lua State[" .. slot .. "].\n")
	persist.Close()
end

local function LOAD(slot)
	local tab = persist.Load("lstate")
	if(tab["states"] == nil) then tab["states"] = {} end
	
	local t_slot = tab["states"][S .. "_state" .. slot]
	if(t_slot == nil) then print(string.upper(S) .. "_State[" .. slot .. "] does not exist.\n") return end
	
	for k,v in pairs(t_slot) do
		print("Loaded: " .. k .. "\n")
		if(v == 1) then 
			include(k)
			_ACTIVESCRIPTS[k] = 1
		end
	end
	print(US .. ": Loaded Lua State[" .. slot .. "].\n")
end

local function CLEAR(slot)
	local tab = persist.Load("lstate")
	local slots = tab["states"] or {}
	slots[S .. "_state" .. slot] = nil
	
	persist.Start("lstate")
	persist.Write("states",slots)
	for k,v in pairs(tab) do
		if(k ~= "states") then persist.Write(k,v) end
	end
	print(US .. ": Cleared Lua State[" .. slot .. "].\n")
	persist.Close()
end

_SCRIPT_STATE_CALLS = {}

local function getScriptStates()
	local scriptstates = persist.Load("lstate")
	return scriptstates[S.."_scriptstates"] or {}
end

local function putScriptStates(data)
	print("-----------------------------\n")
	print("-----------------------------\n")
	print("-----------" .. US .. "_SAVING---------\n")
	print("-----------------------------\n")
	print("-----------------------------\n")
	local errors = {}
	for k,v in pairs(_SCRIPT_STATE_CALLS) do
		print(US.."STATE_CALL: " .. k .. " " .. tostring(v) .. "\n")
		local b,e = pcall(v)
		if not (b) then
			errors[k] = e
		else
			data[k] = e
			print(US.."CALL SUCCESS:\n")
			for k,v in pairs(e) do
				print(US.."SAVE " .. k .. " = " .. v .. "\n")
			end
		end
	end
	persist.Write(S.."_errors",errors)
end

hook.add("Shutdown","_statemanagement",function(script)
	local tab = persist.Load("lstate")
	persist.Start("lstate")
	tab[S.."_scriptstates"] = tab[S.."_scriptstates"] or {}
	for k,v in pairs(tab) do
		if(k == S.."_scriptstates") then tab[k] = putScriptStates(v) end
		if(k ~= S.."_shutdowntime" and k ~= S.."_errors") then persist.Write(k,v) end
	end
	persist.Write(S.."_shutdowntime",LevelTime())
	persist.Close()
	SAVE("_auto")
end)

local IGNORE = nil

hook.add("PreScriptLoaded","_statemanagement",function(script)
	--print("PRE_SCRIPT: " .. script .. "\n")
	_SaveState = nil
	_LoadState = function() return getScriptStates()[script] or {} end
	if(IGNORE == nil) then IGNORE = script end
end)

hook.add("ScriptLoadError","_statemanagement",function(script)
	--print("PRE_SCRIPT: " .. script .. "\n")
	if(script == IGNORE) then IGNORE = nil end
end)

hook.add("ScriptLoaded","_statemanagement",function(script)
	if(IGNORE == nil or IGNORE == script) then 
		_ACTIVESCRIPTS[script] = 1
		IGNORE = nil
	else
		--print("^5IGNORING: " .. script .. "\n")
	end
	if(type(_SaveState) == "function") then
		_SCRIPT_STATE_CALLS[script] = _SaveState
		print("^3Put SaveState Function: " .. tostring(_SaveState) .. "\n")
	end
	_LoadState = nil
	_SaveState = nil
	--print("POST_SCRIPT: " .. script .. "\n")
end)

if(RESTARTED) then
	LOAD("_auto")
else
	SAVE("_auto")
end

concommand.add("savestate",function(p,c,a) SAVE(a[1]) end,true,true)
concommand.add("loadstate",function(p,c,a) LOAD(a[1]) end,true,true)
concommand.add("noauto",function(p,c,a) 
	CLEAR("_auto")
	_ACTIVESCRIPTS = {}
end,true,true)