include("lua/counters.lua")
include("lua/cl_ginfo.lua")
include("lua/cl_menu2.lua")
include("lua/cl_testmenu2.lua")
--include("lua/cl_fonts.lua")
include("lua/cl_help.lua")
--include("lua/cl_emitters.lua")
include("lua/shared.lua")
--include("lua/cl_phys.lua")

local flare = LoadShader("flareShader")
local blood = LoadShader("bloodMark")
blood = LoadShader("viewBloodBlend")

local function rvel(a)
	return Vector(
	math.random(-a,a),
	math.random(-a,a),
	math.random(-a,a))
end

local ref = RefEntity()
	ref:SetColor(1,1,1,1)
	ref:SetType(RT_SPRITE)
	ref:SetShader(flare)

local function newParticle(pos,indir,freeze)
	scale = scale or 1
	
	ref:SetRotation(math.random(360))
	ref:SetPos((rvel(2000) * .01) + pos)

	local le = LocalEntity()
	le:SetPos(pos)
	le:SetRefEntity(ref)
	le:SetStartTime(LevelTime())
	le:SetType(LE_FRAGMENT)
	le:SetColor(1,1,1,1)
	le:SetEndColor(0,0,0,0)
	le:Emitter(LevelTime(), LevelTime() + 600, 1, 
	function(le2,frac)
		local dir = Vector(indir.x,indir.y,indir.z)
		dir.x = dir.x + (math.random(-10,10)/10)
		dir.y = dir.y + (math.random(-10,10)/10)
		dir.z = dir.z + (math.random(-10,10)/10)
				
		dir = dir * (math.random(100,200))	
		le2:SetVelocity(dir)
		le2:SetRadius(math.random(15,25) * (1-frac))
		le2:SetEndTime(LevelTime() + math.random(300,700) * math.random(1,4))
	end)
end

local function ItemPickup(class,pos,vel,itemid)
	--newParticle(pos + Vector(0,0,5),(vel * .002) + Vector(0,0,1),false)
	local n = VectorNormalize(vel)
	ParticleEffect("ItemPickup",pos,n,{pos=pos + Vector(0,0,40),speed=-8,friction=85,noclamp=true})
	--ParticleEffect("ItemSpawn",pos,Vector(0,0,1),{pos=pos + Vector(0,0,40),speed=-8})
	--Vector(0,0,1)
end

local function ItemThinks()
	--GetMiscTime
	local lt = LevelTime()
	for k,v in pairs(GetAllEntities()) do
		local tab = v:GetTable()
		local t = v:GetMiscTime()
		local dt = lt - t
		tab.sc = tab.sc or 0
		if(dt > 0 and dt < 1000 and tab.sc == 0) then
			local pos = v:GetPos()
			ParticleEffect("ItemSpawn",pos,Vector(0,0,1),{pos=pos + Vector(0,0,40),speed=-8})
			tab.sc = 1
		end
		if(dt < 0 or dt > 1000) then
			tab.sc = 0
		end
	end
end
hook.add("Think","cl_init",ItemThinks)

local function readVector()
	local vec = Vector()
	vec.x = message.ReadFloat()
	vec.y = message.ReadFloat()
	vec.z = message.ReadFloat()
	return vec
end

local function bool(i)
	if(i != 0) then 
		return true 
	else 
		return false 
	end
end

local lhp = 0
local function ParseDamage()
	local attacker = nil
	local pos = Vector()
	local dmg = message.ReadShort()
	local death = message.ReadShort()
	local id = message.ReadShort()
	local self = (id == LocalPlayer():EntIndex())
	local self2 = GetEntityByIndex(id)
	local suicide = false
	local hp = message.ReadShort()
	local pos = message.ReadVector()
	local dir = ByteToDir(message.ReadShort())
	local atkid = message.ReadShort()
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
	--print("Attacked: " .. dmg .. " " .. EnumToString(meansOfDeath_t,death) .. " " .. attacker .. "\n")
end

--[[
local function HandleMessage(msgid)
	if(msgid == "itempickup") then
		local class = message.ReadString()
		local pos = readVector()
		local vel = readVector()
		local itemid = message.ReadLong()
		
		ItemPickup(class,pos,vel,itemid)
		_INCREMENT_COUNTER("item_pickups",1)
	elseif(msgid == "playerdamage") then
		ParseDamage()
	elseif(msgid == "playerrespawn") then
		local id = message.ReadShort()
		local self = (id == LocalPlayer():EntIndex())
		local self2 = GetEntityByIndex(id)
		CallHook("PlayerRespawned",self2,id)
		print("^2RESPAWN!\n")
		if(self) then
			lhp = 125
			CallHook("Respawned")
			_INCREMENT_COUNTER("respawns",1)
		end
	end
end
hook.add("HandleMessage","cl_init",HandleMessage)
]]

local function makeShader(file)
	local data = [[{
	{
		map ]] .. file ..  [[
		blendFunc blend
		rgbGen vertex
		alphaGen vertex
	}
	}]]
	return CreateShader("f",data)
end

local t = LevelTime()
local shotTime = 1000
local sshader = nil
local sshot = 0
local function ss2d()

	if(sshader and t > LevelTime()) then
		local c = (t - LevelTime()) / shotTime
		draw.SetColor(1,1,1,c)
		draw.Rect(0,0,640,480,sshader)
	end

	if(sshot == 2) then
		sshader = makeShader("screenshots/lua/test.jpg")
		t = LevelTime() + shotTime
		sshot = 0
	end
	if(sshot == 1) then sshot = 2 end
end
hook.add("Draw2D","cl_init",ss2d)

--[[local function shouldDraw(str)
	if(str == "HUD" and _CG.stats[STAT_HEALTH] <= 0) then return false end
	return (sshot == 0)
end
hook.add("ShouldDraw","cl_init",shouldDraw)]]

local function takeShot()
	util.ClearImage("screenshots/lua/test.jpg") --Clear the image from the renderer's cache
	util.Screenshot(0,0,640,480,"screenshots/lua/test.jpg")
	sshot = 1
end
concommand.add("jpegshot",takeShot)

local function takeShot()
	local atkname = "player"
	local pos = Vector(0,0,0)
	local dmg = 2
	local death = MOD_FALLING
	local self = true
	local self2 = LocalPlayer()
	local suicide = true
	local hp = _CG.stats[STAT_HEALTH] - dmg
	local dir = Vector(1,0,1)
	local id = 0
	CallHook("Damaged",atkname,pos,dmg,death,self,suicide,hp,dir,self2:GetPos())
	CallHook("PlayerDamaged",self2,atkname,pos,dmg,death,self,suicide,hp,id,pos,dir)
	CallHook("PlayerDamaged2",self2,dmg,death,pos,dir,hp)
end
concommand.add("damage",takeShot)

hook.add("Respawned","cl_init",takeShot)