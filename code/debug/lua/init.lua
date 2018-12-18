--includesimple("sctest")

--require "sh_notify"

--message.Precache("itempickup")
--message.Precache("playerdamage")
--message.Precache("playerrespawn")
include("lua/shared.lua")

--[[
local function Fuse(v)
	if(v == nil) then return end
	if(v:Classname() != "grenade") then return end
	v:SetNextThink(LevelTime() + 500)
end
hook.add("EntityLinked","super",Fuse)
]]

print("^2CURRENT GAME: " .. GetCvar("g_luagame") .. "\n")

--[[local function writeVector(msg,v)
	message.WriteFloat(msg,v.x)
	message.WriteFloat(msg,v.y)
	message.WriteFloat(msg,v.z)
end]]

--[[local function ItemPickup(item, other, trace, itemid)
	if(item and other and itemid) then
		local vec = item:GetPos()
		local vec2 = other:GetVelocity()
		
		local msg = Message()
		message.WriteString(msg,item:Classname())
		writeVector(msg,vec)
		writeVector(msg,vec2)
		message.WriteLong(msg,itemid)
		
		for k,v in pairs(GetEntitiesByClass("player")) do
			SendDataMessage(msg,v,"itempickup")
		end
	end
	--return false
end
hook.add("ItemPickup","init",ItemPickup)

local function PlayerDamaged(self,inflictor,attacker,damage,meansOfDeath,asave,dir,pos)
	for k,v in pairs(GetEntitiesByClass("player")) do
		local db = DirToByte(Vector(0,0,-1))
		if(dir != nil) then db = DirToByte(dir) end
		local msg = Message(v,"playerdamage")
		message.WriteShort(msg,damage)
		message.WriteShort(msg,meansOfDeath)
		message.WriteShort(msg,self:EntIndex())
		message.WriteShort(msg,self:GetHealth())
		message.WriteVector(msg,pos or Vector(0,0,0))
		message.WriteShort(msg,db)
		--message.WriteVector(msg,dir or Vector(0,0,0))
		if(attacker) then
			message.WriteShort(msg,attacker:EntIndex() or -1)
		else
			message.WriteShort(msg,-1)
		end
		SendDataMessage(msg)
	end
end

hook.add("PostPlayerDamaged","init",PlayerDamaged)

local function PlayerSpawned(pl)
	for k,v in pairs(GetEntitiesByClass("player")) do
		local msg = Message(v,"playerrespawn")
		message.WriteShort(msg,pl:EntIndex())
		SendDataMessage(msg)
	end
end
hook.add("PlayerSpawned","init",PlayerSpawned)
]]

local function makeEnt(p,c,a)
	if(a[1] == nil) then return end
	local tr = PlayerTrace(p)
	local ent = CreateEntity(a[1])
	if(a[2] == "drop") then
		ent:SetPos(tr.endpos)
	else
		ent:SetPos(tr.endpos + Vector(0,0,20))
	end
	--ent:SetWait(1)
	--ent:SetTrType(TR_STATIONARY)
	--ent:SetSpawnFlags(1)
end
concommand.add("entity",makeEnt)

local function makeEnt(p,c,a)
	local r = 0
	if(a[1] == nil) then return end
	a[1] = tostring(a[1])
	if(string.len(a[1]) < 1) then return end
	local ents = {}
	local tmp = table.Copy(GetAllEntities())
	for k,v in pairs(tmp) do
		local class = v:Classname()
		if(string.find(class,a[1])) then
			table.insert(ents,class)
			v:Remove()
			r = r + 1
		end
	end
	print("Removed " .. r .. " entities:\n")
	for k,v in pairs(ents) do
		print("   " .. v .. "\n")
	end
end
concommand.add("remove",makeEnt,true)

local function kill(p,c,a)
	if(p:GetHealth() <= 0) then return end
	p:Damage(nil,nil,p:GetHealth(),MOD_FALLING,DAMAGE_NO_ARMOR)
end
concommand.add("suicide",kill,false)

local function makeEnt(p,c,a)
	local tr = PlayerTrace(p)
	local ent = CreateMissile("grenade",p)
	ent:SetPos(tr.endpos + Vector(0,0,20))
	ent:SetVelocity(Vector(0,0,20))
	--[[print(ET_MISSILE .. "\n")
	ent:SetType(ET_MISSILE)
	ent:SetFlags(EF_BOUNCE_HALF)
	ent:SetSvFlags(SVF_USE_CURRENT_ORIGIN)
	ent:SetWeapon(WP_GRENADE_LAUNCHER)
	ent:SetOwner(p)
	ent:Spawn()]]
end
concommand.add("grenade",makeEnt,true)