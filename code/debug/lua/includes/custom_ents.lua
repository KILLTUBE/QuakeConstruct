local META = {}
local ENTS = {}
local active = {}
local FCF = FindCustomFiles

--[[function META:Think() end
function META:Initialized() end
function META:Removed() end
function META:MessageReceived() end
function META:VariableChanged() end

if(SERVER) then
	function META:Touch(other,trace) end
	function META:Pain(a,b,take) end
	function META:Die(a,b,take) end
	function META:Use(other) end
	function META:Blocked(other) end
	function META:Reached(other) end
	function META:ClientReady(ent) end
else
	function META:Draw() end
	function META:UserCommand() end
end]]

local function WriteEntityFunctions(cent) --Write internal entity functions into the meta table, these can be overwritten.
	for k,v in pairs(_G["Entity"]) do
		if(type(v) == "function") then
			if(cent[k] == nil) then
				cent[k] = function(self,...)
					local entity = self["Entity"]
					local b,e = pcall(entity[k],entity,unpack(arg))
					if(!b) then
						print("^1Error: [Entity:" .. k .. "] ^2" .. e .. "\n")
						return nil
					else
						return e
					end
				end
			end
		end
	end
end

local function metaCall(tab,func,...)
	if(tab[func] != nil) then
		local b,e = pcall(tab[func],tab,unpack(arg))
		if(!b) then
			print("^1Entity Error[" .. tab._classname .. "]: ^2" .. e .. "\n")
		else
			return true
		end
	end
	return false
end

function ExecuteEntity(v)
	ENT = {}
	ENT._classname = string.lower(v[2])
	
	setmetatable(ENT,META)
	META.__index = META
	
	Execute(v[1])
	
	if(!ENT.Base) then
		WriteEntityFunctions(ENT)
	end
	
	ENTS[ENT._classname] = ENT
	table.insert(_CUSTOM,{data=ENT,type="entity"})
end

function ExecuteEntitySub(v)
	print("^1EXECUTE ENTITY SUB! [" .. v[2] .. "]\n")
	local class = string.lower(v[2])
	local current = ENTS[class]
	if(current != nil) then
		ENT = {}
		Execute(v[1])
		
		--ENTS[class] = table.Inherit( ENT, ENTS[class] )
		table.Update(ENTS[class],ENT)
		
		for k,v in pairs(active) do
			if(active[k]._classname == class) then
				--active[k] = table.Inherit(ENTS[class], active[k])
				table.Update(active[k],ENT)
				metaCall(active[k],"ReInitialize")
			end
		end
	else
		ExecuteEntity(v)
	end
end

function RegisterEntityClass(class,ENT)
	if(type(ENT) ~= "table") then print("^1Argument 2 is not Entity Table\n") return end
	class = string.lower(class)
	
	local current = ENTS[class]
	if(current != nil) then
		table.Update(ENTS[class],ENT)
		
		for k,v in pairs(active) do
			if(active[k]._classname == class) then
				table.Update(active[k],ENT)
				metaCall(active[k],"ReInitialize")
			end
		end
	else
		setmetatable(ENT,META)
		META.__index = META

		ENT._classname = class
		if(!ENT.Base) then
			WriteEntityFunctions(ENT)
		end
		
		ENTS[ENT._classname] = ENT
		table.insert(_CUSTOM,{data=ENT,type="entity"})		
	end
	print("Registered Entity Class: " .. class .. "\n")
end

function __GEntityOverride(classname)
	return ENTS[classname] ~= nil
end

local function InheritEntities()
	local finished = false
	local nl = true
	local maxiter = 100
	local i = 0
	local lc = 0
	while(nl == true and i < maxiter) do
		nl = false
		for k,v in pairs(ENTS) do
			if(!v.__inherit) then
				local base = v.Base
				local name = v._classname
				--if(base == nil) then base = "panel" end
				if(type(base) == "string" and ENTS[base] and base != name) then
					if(ENTS[base].__inherit == true) then
						ENTS[name] = table.Inherit( ENTS[name], ENTS[base] )
						--print("^3Entity Inherited: " .. name .. " -> " .. base .. "\n")
						lc = lc + 1
						v.__inherit = true
					else
						nl = true
					end
				else
					lc = lc + 1
					v.__inherit = true
				end
			end
		end
		i = i + 1
	end
	print("Loaded " .. lc .. " entities with " .. i .. " iterations.\n")
end

local list = FindCustomFiles("lua/entities")
for k,v in pairs(list) do
	ExecuteEntity(v)
end
InheritEntities()
print("Loading custom entities\n")

local function FindEntity(name)
	return ENTS[string.lower(name)]
end

function FindCustomEntityClass(name)
	return FindEntity(name)
end

local function SetCallbacks(ent,tab)
	if(SERVER) then
		ent:SetCallback(ENTITY_CALLBACK_THINK,function(ent) metaCall(tab,"Think") end)
		ent:SetCallback(ENTITY_CALLBACK_DIE,function(ent,a,b,take) metaCall(tab,"Die",a,b,take) end)
		ent:SetCallback(ENTITY_CALLBACK_PAIN,function(ent,a,b,take) metaCall(tab,"Pain",a,b,take) end)
		ent:SetCallback(ENTITY_CALLBACK_TOUCH,function(ent,other,trace) metaCall(tab,"Touch",other,trace) end)
		ent:SetCallback(ENTITY_CALLBACK_USE,function(ent,other) metaCall(tab,"Use",other) end)
		--ent:SetCallback(ENTITY_CALLBACK_BLOCKED,function(ent,other) metaCall(tab,"Blocked",other) end)
		--ent:SetCallback(ENTITY_CALLBACK_REACHED,function(ent,other) metaCall(tab,"Reached",other) end)
	end
end

local function LinkEntity(ent)
	if(ent == nil) then return end
	local name = ent:Classname()
	local found = FindEntity(name)

	if(found != nil) then
		local id = ent:EntIndex()
		if(id == 0) then return end
		if(active[id] != nil) then return active[id] end
		local cent = {}--table.Copy(found)
		setmetatable(cent,found)
		found.__index = found
		
		cent.entity = ent
		cent.Entity = ent --Because I'm like that
		cent.net = CreateEntityNetworkedTable(ent:EntIndex() or -1)
		function cent.net:VariableChanged(...)
			--active[id].net = CreateNetworkedTable(ent:EntIndex() or -1)
			metaCall(cent,"VariableChanged",unpack(arg))
		end
		metaCall(cent,"Initialized")
		metaCall(cent,"Initialize")
		metaCall(cent,"Init")
		active[id] = cent
		SetCallbacks(ent,cent)
		
		return cent
		--cent.__index = function(self,str) return active[self.Entity:EntIndex()][str] end
		--cent.__newindex = function(self,str,val) active[self.Entity:EntIndex()][str] = val end
	end
	
	--local str = "Entity Linked: " .. name .. "\n"
	--if(SERVER) then str = "SV: " .. str else str = "CL: " .. str end
	--print(str)
end
hook.add("EntityLinked","checkcustom",LinkEntity)

local function UnlinkEntity(ent)
	local id = ent:EntIndex()
	local cent = active[id]
	if(cent != nil) then
		metaCall(cent,"Removed")
	end
	if(id == 0) then return end
	ClearEntityNetworkedTable(id)
	active[id] = nil
	
	--local str = "Entity Unlinked: " .. ent:Classname() .. "\n"
	--if(SERVER) then str = "SV: " .. str else str = "CL: " .. str end
	--print(str)
end
hook.add("EntityUnlinked","checkcustom",UnlinkEntity)

local function reloadEnts()
	--ENTS
	local list = FCF("lua/entities")
	for k,v in pairs(list) do
		ExecuteEntitySub(v)
	end
	InheritEntities()
end
if(SERVER) then
	concommand.add("reloadEnts",reloadEnts)
else
	concommand.add("reloadEnts_cl",reloadEnts)
end

if(SERVER) then
	local function messagetest(...)
		for k,v in pairs(active) do
			if(v != nil) then
				metaCall(active[k],"MessageReceived",unpack(arg))
			end
		end
	end
	hook.add("MessageReceived","checkcustom",messagetest)
	
	local function ClientReady(...)
		for k,v in pairs(active) do
			if(v != nil) then
				metaCall(active[k],"ClientReady",unpack(arg))
			end
		end
	end
	hook.add("ClientReady","checkcustom",ClientReady)
	
	function CreateLuaEntity(class)
		if(ENTS[string.lower(class)] != nil) then
			return LinkEntity(CreateEntity(string.lower(class)))
		end
	end
else
	local function DrawEntity(ent,name)
		local index = ent:EntIndex()
		if(active[index] != nil) then
			metaCall(active[index],"Draw")
		end
	end
	hook.add("DrawCustomEntity","checkcustom",DrawEntity)
	
	local function DrawRT()
		local rtc = 0
		for k,v in pairs(active) do
			if(v != nil) then
				if(metaCall(active[k],"DrawRT")) then
					rtc = rtc + 1
				end
			end
		end
		--print("RTCalls: " .. rtc .. "\n")
	end
	hook.add("DrawRT","checkcustom",DrawRT)
	
	local function UserCommand(...)
		for k,v in pairs(active) do
			if(v != nil) then
				metaCall(active[k],"UserCommand",unpack(arg))
			end
		end
	end
	hook.add("UserCommand","checkcustom",UserCommand)
	
	--[[local function messagetest(...)
		for k,v in pairs(active) do
			if(v != nil) then
				metaCall(active[k],"MessageReceived",unpack(arg))
			end
		end
	end
	hook.add("MessageReceived","checkcustom",messagetest)]]
	
	local function Event(ent,id,pos,angle)
		for k,v in pairs(active) do
			if(v != nil and v.entity ~= nil and v.entity:EntIndex() == ent:EntIndex()) then
				if(metaCall(active[k],"EventReceived",id,pos,angle) == false) then
					if(metaCall(active[k],"OnEvent",id,pos,angle)) then
						return true
					end
				else
					return true
				end
			end
		end	
	end
	hook.add("EventReceived","checkcustom",Event,999)
	
	local function dlhook(file)
		if(string.find(file,"/lua.entities.") and
		   (string.find(file,"shared.lua") or
		   string.find(file,"cl_init.lua"))) then
			local strt = string.len("lua/downloads/lua.entities.")
			local name = string.sub(file,strt+1,string.len(file))
			local ed = string.find(name,".",0,true)
			
			--print(name .. " " .. ed .. "\n")
			if(!ed) then return false end
			name = string.sub(name,0,ed-1)
			--print(name .. "\n")
			if(string.len(name) <= 0) then return false end
			
			local class = string.lower(name)
			local current = ENTS[class]
			if(current != nil) then
				ENT = {}
				local b,e = pcall(include,file)
				if not (b) then
					print("^1Error loading entity file: " .. e .. "\n")
				end
				
				--ENT
				
				table.Update(ENTS[class], ENT)
				
				--print("REPLACING CURRENT: " .. class .. "\n")
				for k,v in pairs(active) do
					if(active[k]._classname == class) then
						--active[k] = table.Inherit(ENTS[class], active[k])
						table.Update(active[k], ENT)
						metaCall(active[k],"ReInitialize")
					end
				end
			else
				ENT = {}
				ENT._classname = string.lower(name)
				
				setmetatable(ENT,META)
				META.__index = META
			
				pcall(include,file)
				
				if(!ENT.Base) then
					WriteEntityFunctions(ENT)
				end
				
				ENTS[ENT._classname] = ENT
				table.insert(_CUSTOM,{data=ENT,type="entity"})
				InheritEntities()
			end
			--print("Downloaded Entity '" .. file .. "'\n")
			
			return true
		end
	end
	hook.add("FileDownloaded","checkcustom",dlhook)
end