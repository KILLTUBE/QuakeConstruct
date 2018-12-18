if(!hook) then
	hook = {}
	hook.events = {}
	hook.debugflags = {}
	hook.locked = {}
	hook.reserved = {}
end

H = {}

HOOKS = {}
HOOKS.SV = {
	"ClientShutdownLua",
	"ClientThink",
	"FlagCaptured",
	"FlagDropped",
	"FlagStatus",
	"FiredWeapon",
	"ItemPickup",
	"ItemPickupQuantity",
	"MessageReceived",
	"PlayerDamaged",
	"PlayerDisconnected",
	"PlayerJoined",
	"PlayerKilled",
	"PlayerSpawned",
	"PlayerTeamChanged",
	"PostPlayerDamaged",
	"PrePlayerDamaged",
	"ShouldDropItem",
	"TeamScored",
}

HOOKS.SHARED = {
	"Think",
	"EntityLinked",
	"EntityUnLinked",
	"PlayerMove",
	"Shutdown",
	"ScriptLoaded",
}

HOOKS.CL = {
	"AllowGameSound",
	"ClientInfoLoaded",
	"ClientInfoChanged",
	"DemoStarted",
	"Draw2D",
	"Draw3D",
	"DrawCustomEntity",
	"DrawInfo",
	"DrawPlayerModel",
	"EventReceived",
	"HandleMessage",
	"InitialSnapshot",
	"ItemPickup",
	"KeyEvent",
	"Loaded",
	"MessageReceived",
	"ModelLoaded",
	"MouseEvent",
	"ShaderLoaded",
	"ShouldDraw",
	"SoundLoaded",
	"UserCommand",
}

function hook.sort(event)
	table.sort(hook.events[event],function(a,b) return a.priority > b.priority end)
end

function hook.replacehook(tab,event)
	if(hook.events[event] == nil) then return end
	for k,v in pairs(hook.events[event]) do
		if(v.name == tab.name) then 
			hook.events[event][k] = tab
			hook.sort(event)
			return true
		end
	end
	hook.sort(event)
	return false
end

function hook.removeAllByName(name)
	for _,e in pairs(hook.events) do
		for k,v in pairs(e) do
			if(v.name == name) then 
				table.remove(e,k)
			end
		end
	end
end

function hook.remove(event,name)
	if(hook.reserved[name]) then error("Unable to remove hook: " .. name .. ". -reserved\n") return end
	if(hook.events[event] == nil) then error("Unable to remove hook: " .. event .. ". -locked\n") return end
	for k,v in pairs(hook.events[event]) do
		if(v.name == name) then 
			table.remove(hook.events[event],k)
		end
	end
	hook.sort(event)
end

function hook.add(event,name,func,priority)
	if(hook.reserved[name]) then error("Unable to add hook: " .. name .. ". -reserved\n") return end
	if(hook.locked[event]) then error("Unable to add hook: " .. event .. ". -locked\n") return end
	priority = priority or 0
	if(event != nil and name != nil and func != nil) then
		local tab = {func=func,name=name,priority=priority}
		hook.events[event] = hook.events[event] or {}
		if not (hook.replacehook(tab,event)) then
			table.insert(hook.events[event],tab)
		end
	else
		event = tostring(event) or "Unknown Event"
		error("Unable to add hook: " .. event .. ".\n")
	end
	hook.sort(event)
end
hook.Add = hook.add

function hook.reserve(name)
	hook.reserved[name] = true
end

function hook.lock(event)
	hook.locked[event] = true
end

function hook.debug(event,b)
	print("Debug Set: " .. event .. " | " .. tostring(b) .. "\n")
	hook.debugflags[event] = b
end

local function funcname(func)
	for k,v in pairs(_G) do
		if(v == func) then return k end
	end
	return ""
end

local ispost = false

local function printhooks()
	for k,_ in pairs(hook.events) do
		print(k .. "\n")
		if(type(hook.events[k]) == "table") then
			for _,v in pairs(hook.events[k]) do 
				print("  -" .. v.name .. "\n")
			end
		end
	end
end
if(SERVER) then concommand.Add("PrintHooks_SV",printhooks) end
if(CLIENT) then concommand.Add("PrintHooks_CL",printhooks) end

function onHookCall(event,...)

end

function CallHookArgTForm(event,tform,...)
	--For overriding arguments
	local __print = print
	print = function(str) __print(str) LOG(str) end
	for k,v in pairs(arg) do
		if(type(v) == "vector3") then
			arg[k] = Vectorv(v)
		end
	end
	if(hook.events[event] == nil) then print = __print return end
	local retVal = nil
	for k,v in pairs(hook.events[event]) do
		local fname = v.name
		if (hook.debugflags[event] == true) then debugprint("Calling Function: " .. fname .. "\n") end
		
		onHookCall(event,unpack(arg))
		if(tform ~= nil and type(tform) == "function") then
			--print("TFORM\n")
			local b,e = pcall(tform,unpack(arg))
			if not b then
				print("^1HOOK TFORM ERROR[" .. event .. "]: " .. e .. "\n")
			elseif(e ~= nil and type(e) == "table") then
				if(#e == #arg) then
					arg = e
				else
					print("^1HOOK TFORM ERROR[" .. event .. "]: bad tform arg count[" .. #e .. "] != " .. #arg .. "\n")
				end
			end
		end
		
		local b,e,x,y,z = pcall(v.func,unpack(arg))
		if not b then
			print("^1HOOK ERROR[" .. event .. "]: " .. e .. "\n")
		else
			if not (e == nil) then
				if (hook.debugflags[event] == true) then 
					debugprint("Returned Value ")
					if(e == false) then
						debugprint("False.\n")
					elseif(e == true) then
						debugprint("True.\n")
					else
						debugprint(tostring(e) .. ".\n")
					end
				end
				retVal = retVal or {}
				retVal[1] = e
				if(x ~= nil) then retVal[2] = x end
				if(y ~= nil) then retVal[3] = y end
				if(z ~= nil) then retVal[4] = z end
			end
		end
	end
	if(retVal != nil) then print = __print return unpack(retVal) end
	print = __print
end

function CallHook(event,...)
	return CallHookArgTForm(event,nil,unpack(arg))
end

hook.add("ScriptLoaded","_scriptloadhooks",function(script)
	script = string.sub(script,5)
	script = string.sub(script,0,string.len(script)-4)

	if(H.clear) then
		hook.removeAllByName(script)
	end
	
	for k,v in pairs(H) do
		if(type(v) == "function") then
			hook.add(k,script,v)
		end
	end
	
	H = {}
end)

debugprint("^3Hook code loaded.\n")