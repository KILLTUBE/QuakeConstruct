local bulletbounce = MessagePrototype("bulletbounce"):Vector():Vector():Short():E()

//__DL_BLOCK
if(SERVER) then
downloader.add("lua/bouncybullets.lua")

local MASK_SHOT = gOR(CONTENTS_SOLID,CONTENTS_BODY,CONTENTS_CORPSE)

local function crand()
	return 2 * (math.random() - 0.5)
end

local function sendline(s,e,t,p)
	--local msg = Message()
	local ttype = bitShift(t,-8)
	local t = bitOr(ttype,p)
	--message.WriteVector(msg,s)
	--message.WriteVector(msg,e)
	--message.WriteShort(msg,t)
	--SendDataMessageToAll(msg,"bulletbounce")
	bulletbounce:Send(XYZ(s),XYZ(e),t)
end

local function bullet(i,start,angle,pl,spread,damage,mod)
	local forward,right,up = AngleVectors(angle)

	local r = math.random() * math.pi * 2
	local u = math.sin(r) * crand() * spread * 16
	local bounced = false
	r = math.cos(r) * crand() * spread * 16
	
	local vend = start + forward * 8192*16
	vend = vend + right * r
	vend = vend + up * u
	
	local ignore = pl:EntIndex()
	if(i > 0) then ignore = nil end
	local tr = TraceLine(start,vend,ignore,MASK_SHOT)
	
	if(tr.hit) then
		if(bitAnd(tr.surfaceflags, SURF_NOIMPACT) ~= 0) then
			if(i ~= -1) then sendline(start,vend,mod,i) end
			return
		end
		
		local ent = tr.entity
		local tent = nil
		if(ent ~= nil and ent:IsPlayer()) then
			tent = CreateTempEntity(tr.endpos,EV_BULLET_HIT_FLESH)
			tent:SetEventParm(ent:EntIndex())
		else
			tent = CreateTempEntity(tr.endpos,EV_BULLET_HIT_WALL)
			tent:SetEventParm(DirToByte(tr.normal))
		end
		tent:SetOtherEntity(pl)
		
		if(ent ~= nil) then
			ent:Damage(pl,pl,damage,mod,forward,tr.endpos)
		else
			if(i < 3) then
				local dot = DotProduct( forward, tr.normal );
				--if(i == 0) then print(dot .. "\n") end
				if(dot > -.6) then
					local reflect = VectorNormalize(vAdd(forward,vMul(tr.normal,-2*dot)))
					local angle = VectorToAngles(reflect)
					bounced = true
					Timer(.06,function()
						bullet(i+1,tr.endpos,angle,pl,spread/2,damage*2,mod)
					end)
				end
			end
		end
		if(i ~= -1 and (i > 0 or bounced)) then sendline(start,tr.endpos,mod,i) end
	else
		if(i ~= -1 and (i > 0 or bounced)) then sendline(start,vend,mod,i) end
	end
end

function FireBullet(start,angle,pl,spread,damage,mod)
	bullet(0,start,angle,pl,spread,damage,mod)
end

local function fired(clientnum,weapon,t,muzzle,forward)
	local pl = GetPlayerByIndex(clientnum)
	if(pl == nil) then return end

	if(weapon == WP_MACHINEGUN) then
		FireBullet(muzzle,forward,pl,200,7,MOD_MACHINEGUN)
		return true
	elseif(weapon == WP_SHOTGUN) then
		for i=0, 7 do
			FireBullet(muzzle,forward,pl,1200,15,MOD_SHOTGUN)
		end
		return true
	end
end
hook.add("SVFiredWeapon","bullets.lua",fired)
return
end
//__DL_UNBLOCK

local mark = LoadShader("gfx/damage/hole_lg_mrk")
local flare = LoadShader("flareShader")
local fx = LoadShader("railCore")

local function getBeamRef(v1,v2,r,g,b,size)
	local st1 = RefEntity()
	st1:SetType(RT_RAIL_CORE)
	st1:SetPos(v1)
	st1:SetPos2(v2)
	st1:SetColor(r,g,b,1)
	st1:SetRadius(size or 12)
	st1:SetShader(fx)
	return st1
end

local function rpoint(pos,size)
	local s = RefEntity()
	s:SetType(RT_SPRITE)
	s:SetPos(pos)
	s:SetColor(1,1,1,1)
	s:SetRadius(size or 8)
	s:SetShader(flare)
	return s
end

local function qbeam(v1,v2,r,g,b,size,np,delay,stdelay)
	local ref = getBeamRef(v1,v2,r,g,b,size)
	
	for i=1,3 do
		if(!np or i==3) then
			local le = LocalEntity()
			le:SetPos(v1)
			
			le:SetRefEntity(ref)
			if(i == 1) then le:SetRefEntity(rpoint(v1,size*i)) end
			if(i == 2) then le:SetRefEntity(rpoint(v2,size*i)) end
			le:SetRadius(ref:GetRadius())
			le:SetStartTime(LevelTime() + (stdelay or 0))
			le:SetEndTime(LevelTime() + (delay or 500))
			le:SetType(LE_FADE_RGB)
			--if(point) then le:SetType(LE_FRAGMENT) end --LE_FRAGMENT
			le:SetColor(r,g,b,1)
			le:SetTrType(TR_STATIONARY)
		end
	end
end

function bulletbounce:Recv(data)
	local s = Vector(data[1],data[2],data[3])
	local e = Vector(data[4],data[5],data[6])
	local t = data[7]
	
	local d = VectorNormalize(e-s)
	local tr = TraceLine(s,e+d*1000)
	--ParticleEffect("Spark",e,tr.normal)
	
	--[[for k,v in pairs(tr) do
		print(k .. " = " .. tostring(v) .. "\n")
	end]]
	
	local ttype = bitShift(t,8)
	local power = bitAnd(t,255)
	
	local r,g,b = 1,.7,.4
	local size = 1
	local c = .3 + power/5
	
	if(ttype == MOD_SHOTGUN) then
		size = size + 3
		r = 0.8 + math.random()*.2
		g = 0.3 + math.random()*.4
	end
	
	size = size * (power+0.5)
	
	r = r * c
	g = g * c
	b = b * c
	qbeam(s,e,r,g,b,size,false,800)
end

--[[local function HandleMessage(msgid)
	if(msgid == "bulletbounce") then
		local s = message.ReadVector()
		local e = message.ReadVector()
		local t = message.ReadShort()
		
		local d = VectorNormalize(e-s)
		local tr = TraceLine(s,e+d*1000)
		--ParticleEffect("Spark",e,tr.normal)
		
		--[[for k,v in pairs(tr) do
			print(k .. " = " .. tostring(v) .. "\n")
		end]]
		
		local ttype = bitShift(t,8)
		local power = bitAnd(t,255)
		
		local r,g,b = 1,.7,.4
		local size = 1
		local c = .3 + power/5
		
		if(ttype == MOD_SHOTGUN) then
			size = size + 3
			r = 0.8 + math.random()*.2
			g = 0.3 + math.random()*.4
		end
		
		size = size * (power+0.5)
		
		r = r * c
		g = g * c
		b = b * c
		qbeam(s,e,r,g,b,size,false,800)
	end
end
hook.add("HandleMessage","cl_instagib",HandleMessage)]]