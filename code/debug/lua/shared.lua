print("^1SHARED\n")

--include("lua/weapons.lua")
include("lua/states.lua")

local DAMAGE_PROTO_0 = MessagePrototype("_damage0"):Short():Short():Short():Short():Vector():Byte():Short():E()

if(SERVER) then
	local function PlayerDamaged(self,inflictor,attacker,damage,meansOfDeath,asave,dir,pos)
		print("PLAYER DAMAGE HOOKED\n");
		for k,v in pairs(GetEntitiesByClass("player")) do
			local db = DirToByte(Vector(0,0,-1))
			if(dir != nil) then db = DirToByte(dir) end
			local atk = -1
			if(attacker) then
				atk = attacker:EntIndex() or -1
			end
			
			DAMAGE_PROTO_0:Send(
				v,
				damage,
				meansOfDeath,
				self:EntIndex(),
				self:GetHealth(),
				pos or Vector(0,0,0),
				db,
				atk)
		end
	end
	hook.add("PostPlayerDamaged","init",PlayerDamaged)
elseif(CLIENT) then
	local lhp = 0
	function DAMAGE_PROTO_0:Recv(data)
		local attacker = nil
		local pos = Vector()
		local dmg = data[1]
		local death = data[2]
		local id = data[3]
		local self = (id == LocalPlayer():EntIndex())
		local self2 = GetEntityByIndex(id)
		local suicide = false
		local hp = data[4]
		local pos = data[5]
		local dir = ByteToDir(data[6])
		local atkid = data[7]
		local atkname = ""
		if(self) then
			_INCREMENT_COUNTER("damage_taken",dmg)
			if(lhp > 0) then
				if(hp <= 0) then
					_INCREMENT_COUNTER("deaths",1)
				end
			end
			if(lhp > -40) then
				if(hp <= -40) then
					_INCREMENT_COUNTER("gibbed",1)
				end
			end
			lhp = hp
		end
		if(atkid != -1) then
			attacker = GetEntityByIndex(atkid)
			suicide = (atkid == LocalPlayer():EntIndex())
		end
		if(attacker != nil) then
			atkname = attacker:GetInfo().name
		end
		CallHook("Damaged",atkname,pos,dmg,death,self,suicide,hp,dir,self2:GetPos())
		CallHook("PlayerDamaged",self2,atkname,pos,dmg,death,self,suicide,hp,id,pos,dir)
		CallHook("PlayerDamaged2",self2,dmg,death,pos,dir,hp)
		attacker = attacker or ""
		print("CLIENT PLAYER DAMAGE HOOKED\n");
		--print("Attacked: " .. dmg .. " " .. EnumToString(meansOfDeath_t,death) .. " " .. attacker .. "\n")
	end
end
--[[
local m_proto = MessagePrototype("test"):String():Byte():E()

if(SERVER) then
	concommand.add("prototest",function(p,c,a)
		m_proto:Send(p,"OhLook,Proto",102)
	end)
else
	function m_proto:Recv(data)
		print("PROTO SUCCESS\n")
		print(data[1] .. "\n")
		print(data[2] .. "\n")
	end
end]]


--[[
AddItem(0,false,
"ammo_laserblazer",
IT_AMMO,
WP_RESERVED0,
"icons/iconw_grapple",
"Laser Blazer Ammo",
"sound/misc/am_pkup.wav",
15,
"models/weapons2/rocketl/rocketl.md3")

AddItem(1,false,
"weapon_laserblazer",
IT_WEAPON,
WP_RESERVED0,
"icons/iconw_grapple",
"Laser Blazer",
"sound/misc/w_pkup.wav",
10,
"models/weapons2/rocketl/rocketl.md3")

--FindItemByClassname
local function ReplaceItem(item,...)
	local it = FindItemByClassname(item)
	if(it ~= -1) then
		AddItem(it,true,unpack(arg))
		print("Replaced Item: " .. it .. "\n")
	end
end

ReplaceItem("weapon_machinegun",
"weapon_machinegun",
IT_WEAPON,
WP_MACHINEGUN,
"icons/iconw_grapple",
"Desert Eagle",
"sound/weapons/deagle/deploy.wav",
18,
"models/weapons2/deagle/deagle.md3")

ReplaceItem("ammo_bullets",
"ammo_bullets",
IT_AMMO,
WP_MACHINEGUN,
"icons/iconw_grapple",
"Bullets",
"sound/weapons/deagle/deploy.wav",
18,
"models/weapons2/deagle/deagle.md3")


if(SERVER) then
	local function wfired(cl,wp,delay,muzzle,angles,weaponent)
		if(wp == WP_RESERVED0) then
			local player = GetAllPlayers()[cl+1]
			local f,r,u = AngleVectors(angles)
			player:SetVelocity(f*-800)
			
			local tr = TraceLine(muzzle,muzzle + f*1000)
			local e = CreateTempEntity(tr.endpos,EV_RAILTRAIL)
			e:SetPos2(muzzle)
		end
		if(wp == WP_MACHINEGUN) then
			G_FireBullet(weaponent,300,30)
			return true
		end
	end
	hook.add("SVFiredWeapon","shared",wfired)
	
	hook.add("PlayerSpawned","shared",function(pl) pl:SetAmmo(WP_MACHINEGUN,18) end)
else
	local function register(wp)
		if(wp == WP_MACHINEGUN) then
		local t =  {}
			t.flashSound0 = LoadSound("sound/weapons/deagle/fire.wav")
			t.flashSound1 = t.flashSound0
			t.flashSound2 = t.flashSound0
			t.flashSound3 = t.flashSound0
			return t
		end
	
		if(wp ~= WP_RESERVED0) then return end
			print("^1Registered: " .. wp .. "\n")
			local t =  {}
			t.flashSound0 = LoadSound("sound/world/jumppad.wav")
		return t
	end
	hook.add("RegisterWeapon","shared",register)
end

local function wfired(cl,wp,delay,angles)
	if(wp == WP_MACHINEGUN) then
		return 320
	end
end
hook.add("FiredWeapon","shared",wfired)
]]
if(RESTARTED) then
	if(SERVER) then
		print("^2SV_RESTARTED\n")
	else
		print("^2CL_RESTARTED\n")
	end
end