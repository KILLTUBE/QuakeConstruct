game_entities = {}

local function addEnt(ent)
	for k,v in pairs(game_entities) do
		if(v:EntIndex() == ent:EntIndex()) then
			return false
		end
	end
	table.insert(game_entities,ent)
	return true
	--table.sort(game_entities,function(a,b) return a:Classname() < b:Classname() end)
end

local function removeEnt(ent)
	for k,v in pairs(game_entities) do
		if(v:EntIndex() == ent:EntIndex()) then
			table.remove(game_entities,k)
		end
	end
end
	
function GetAllEntities()
	return game_entities
end

function GetEntitiesByType(t)
	if(t < ET_GENERAL or t > ET_LUA) then return end
	local out = {}
	for k,v in pairs(GetAllEntities()) do
		if(type(v) == "userdata") then
			if(type(t) == "number") then
				if(v:GetType() == t) then
					table.insert(out,v)
				end
			elseif(type(t) == "table") then
				for _,c in pairs(t) do
					if(v:GetType() == c) then
						table.insert(out,v)
					end
				end
			end
		end
	end
	return out
end

function GetEntitiesByClass(class)
	local out = {}
	for k,v in pairs(GetAllEntities()) do
		if(type(v) == "userdata") then
			if(type(class) == "string") then
				if(v:Classname() == class) then
					table.insert(out,v)
				end
			elseif(type(class) == "table") then
				for _,cname in pairs(class) do
					if(v:Classname() == cname) then
						table.insert(out,v)
					end
				end
			end
		end
	end
	return out
end

function GetAllPlayers()
	return GetEntitiesByClass("player")
end

function GetOwner()
	for k,v in pairs(GetEntitiesByClass("player")) do
		if(v:IsAdmin()) then return v end
	end
	return nil
end

if(SERVER) then
	function GetPlayerByIndex(id)
		for _,v in pairs(GetEntitiesByClass("player")) do
			if(v:EntIndex() == id) then return v end
		end
	end

	function GetEntityByIndex(id)
		for _,v in pairs(GetAllEntities()) do
			if(v:EntIndex() == id) then return v end
		end
	end
	
	hook.add("ItemRegistered","_RegisterItem",function(itemid)
		for k,v in pairs(GetAllPlayers()) do
			v:SendString("__RegisterItems")
		end
		print("^2SV_RegisterItems\n")
	end)
else
	hook.add("MessageReceived","_RegisterItem",function(str)
		if(str == "__RegisterItems") then
			print("^2CL_RegisterItems\n")
			util.UpdateItems()
		end
	end)
end

function FindEntityTargets(ent)
	local targets = {}
	for k,v in pairs(GetAllEntities()) do
		if(v:GetTargetName() == ent:GetTarget()) then
			table.insert(targets,v)
		elseif(v:EntIndex() == ent:GetTargetEnt():EntIndex()) then
			table.insert(targets,v)
		end
	end
	return targets
end

function FindEntities(func,value,...)
	if(type(func) != "string") then return end
	func = Entity[func]
	if(func == nil) then return end
	
	local tab = {}
	for k,v in pairs(GetAllEntities()) do
		local b,e = pcall(func,v,unpack(arg))
		if(!b) then
			print("^1FIND ERROR: " .. e .. "\n")
			return tab
		else
			if(e == value) then
				table.insert(tab,v)
			end
		end
	end
	return tab
end

local function UnlinkEntity(ent)
	if(ent == nil) then return end
	if(string.find(ent:Classname(),"func_")) then return end
	if(string.find(ent:Classname(),"mover")) then return end
	local index = ent:EntIndex()
	if(ent:IsPlayer() == false) then
		removeEnt(ent)
		if(ent:Classname() != nil) then
			debugprint("^2QLUA Entity Unlinked: " .. index .. " | " .. ent:Classname() .. "\n")
		else
			debugprint("^2QLUA Entity Unlinked: " .. index .. "\n")
		end
	else
		if(ent:Classname() != nil) then
			debugprint("Entity Unlinked: " .. index .. " | " .. ent:Classname() .. "\n")
		else
			debugprint("Entity Unlinked: " .. index .. "\n")
		end
	end
	if(CLIENT) then
		removeEnt(ent)
	end
	debugprint("NumLinks: " .. #game_entities .. "\n")
end

local function UnlinkPlayer(ent)
	if(ent == nil) then return end
	local index = ent:EntIndex()
	if(ent:IsPlayer() == true) then
		removeEnt(ent)
		if(ent:Classname() != nil) then
			debugprint("^2QLUA Entity Unlinked: " .. index .. " | " .. ent:Classname() .. "\n")
		else
			debugprint("^2QLUA Entity Unlinked: " .. index .. "\n")
		end
	end
end

local function LinkEntity(ent)
	if(ent == nil) then return end
	--if(string.find(ent:Classname(),"target_")) then return end
	--if(string.find(ent:Classname(),"func_")) then return end
	if(string.find(ent:Classname(),"mover")) then return end
	local index = ent:EntIndex()
	if(!addEnt(ent)) then return end
	if(ent:Classname() != nil) then
		debugprint("^2QLUA Entity Linked: " .. index .. " | " .. ent:Classname() .. "\n")
	else
		debugprint("^2QLUA Entity Linked: " .. index .. "\n")
	end
	debugprint("NumLinks: " .. #game_entities .. "\n")
end

function GetEntityTable(ent)
	if(ent != nil) then
		--print("^3'GetEntityTable' is depricated. Use Entity:GetTable() instead.\n")
		return ent:GetTable()
	end
end


hook.add("EntityLinked","_LinkToLua",LinkEntity,999)
hook.add("EntityUnlinked","_UnlinkFromLua",UnlinkEntity,999)
hook.add("PlayerDisconnected","_UnlinkFromLua",UnlinkPlayer,999)
hook.add("PlayerJoined","_LinkToLua",function(ent) LinkEntity(ent) end,999)
hook.add("PlayerSpawned","_LinkToLua",function(ent) LinkEntity(ent) end,999)
--hook.add("ClientReady","_LinkToLua",function(ent) LinkEntity(ent) end,999)
--Delay player linking so that other entities can link up first

debugprint("^3Entity code loaded.\n")