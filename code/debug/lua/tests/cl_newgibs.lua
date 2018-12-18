require "tests/cl_gibchooser"

local gibs = {
	LoadModel("models/gibs/abdomen.md3"),
	LoadModel("models/gibs/arm.md3"),
	LoadModel("models/gibs/arm.md3"),
	LoadModel("models/gibs/chest.md3"),
	LoadModel("models/gibs/fist.md3"),
	LoadModel("models/gibs/fist.md3"),
	LoadModel("models/gibs/foot.md3"),
	LoadModel("models/gibs/forearm.md3"),
	LoadModel("models/gibs/intestine.md3"),
	LoadModel("models/gibs/leg.md3"),
	LoadModel("models/gibs/leg.md3"),
	LoadModel("models/gibs/brain.md3"),
}

local function makeBloodExplosionShader(i)
	local data = 
	[[{
		nopicmip
		polygonoffset
		{
			map gfx/blood]] .. i .. [[_a.tga
			rgbGen vertex
			blendFunc blend
			alphaGen vertex
		}
	}]]
	return CreateShader("f",data)
end

local bexplosion = {
	makeBloodExplosionShader(2),
	makeBloodExplosionShader(3),
}

local function trDir(pos,dir,limit)
	limit = limit or 1000
	dir = dir or Vector(0,0,-1)
	local endpos = vAdd(pos,dir*limit)
	local res = TraceLine(pos,endpos,nil,1)
	return res
end

local explodeSound = LoadSound("sound/player/gibsplt1.wav")
local skull = LoadModel("models/gibs/skull.md3")
local inviso = LoadShader("teleporteffect2")
local flare = LoadShader("flareShader")
local bullet = LoadShader("bulletExplosion")
local blood1 = LoadShader("BloodMark") --viewBloodFilter_HQ
local blood2 = LoadShader("BloodMarkN2")
local blood3 = LoadShader("viewBloodFilter_HQ")
local gore = LoadShader("deadGore")
local i=0
local rpos = Vector(670,500,30)
local lastPos = Vector()
local bob = 0
local nxt = 0

local impact = {}
impact[1] = LoadSound("sound/player/gibimp1.wav")
impact[2] = LoadSound("sound/player/gibimp2.wav")
impact[3] = LoadSound("sound/player/gibimp3.wav")

local blood = {}
for i=1,5 do
	table.insert(blood,LoadShader("BloodMarkN" .. i))
end

local function rvel(a)
	return Vector(
	math.random(-a,a),
	math.random(-a,a),
	math.random(-a,a))
end

local particles = {}
local localents = {}
local tgtime = 0
function newParticle(pos,dir,model,scale,skin,head)
	--if(!flesh) then return end
	local ex = 5000
	if(head) then ex = 60000 end
	scale = scale or 1
	local r = RefEntity()
	r:SetModel(model)
	if(skin and skin != -1) then r:SetSkin(skin) end
	r:SetColor(1,1,1,1)
	--r:SetType() --RT_RAIL_CORE
	--r:SetType(RT_SPRITE)
	r:SetRadius(20*scale)
	r:SetRotation(math.random(360))
	--r:SetShader(gore)
	r:SetPos(pos)
	r:SetPos2(pos)
	r:SetAngles(Vector(math.random(360),math.random(360),math.random(360)))
	r:Scale(Vector(scale,scale,scale))
	
	dir.x = dir.x + (math.random(-10,10)/30)
	dir.y = dir.y + (math.random(-10,10)/30)
	dir.z = dir.z + (math.random(-10,10)/30)
	
	dir = vMul(dir,math.random(60,120)/60)

	local le = LocalEntity()
	le:SetBounceFactor((math.random(1,100)/300) + .4)
	le:SetPos(pos)
	le:SetRefEntity(r)
	le:SetVelocity(vMul(dir,300))
	le:SetStartTime(LevelTime())
	le:SetEndTime(LevelTime() + (5000 + ex) + math.random(1000,4000))
	le:SetType(LE_FRAGMENT)
	le:SetStartColor(1,.5,.3,1)
	le:SetEndColor(1,1,1,0)
	le:SetRadius(r:GetRadius())
	le:SetAngleVelocity(Vector(math.random(-360,360),math.random(-360,360),math.random(-360,360)))
	le:SetCallback(LOCALENTITY_CALLBACK_TOUCH,function(le,tr)
		if(le:GetTable()) then
			le:GetTable().lgtime = le:GetTable().lgtime or LevelTime()
			if(le:GetTable().lgtime <= LevelTime() and tgtime < LevelTime()) then
				PlaySound(le:GetPos(),impact[math.random(1,3)])
				le:GetTable().lgtime = LevelTime() + math.random(800,1200)
				tgtime = LevelTime() + math.random(100,400)
			end
		end
		if(VectorLength(le:GetVelocity()) > 10 or math.random(0,2) == 1) then
			util.CreateMark(blood[math.random(1,#blood)],tr.endpos,tr.normal,math.random(360),1,1,1,1,math.random(18,25),true,math.random(8000,10000)/30)
		end
		if(!le:GetTable().stopped) then
		local ref = le:GetRefEntity()
			--ref:SetAngles(ref:GetAngles()) --Vector(math.random(360),math.random(360),math.random(360))
			--ref:Scale(Vector(scale,scale,scale))
			le:SetRefEntity(ref)
			le:SetAngleVelocity(Vector(math.random(-360,360),math.random(-360,360),math.random(-360,360)))
		end
	end)
	le:SetCallback(LOCALENTITY_CALLBACK_THINK,function(le)
		if(VectorLength(le:GetVelocity()) > 3) then
			local ref = le:GetRefEntity()
			ref:SetAngles(ref:GetAngles())
			ref:Scale(Vector(scale,scale,scale))
			local f,r,u = ref:GetAxis()
			
			le:SetNextThink(LevelTime() + 60)
			local le2 = LocalEntity()
			le2:SetPos(le:GetPos())
			local ref = le:GetRefEntity()
			ref:SetRotation(math.random(360))
			le:SetRefEntity(ref)
			ref:SetColor(1,1,1,1)
			ref:SetType(RT_SPRITE)
			ref:SetShader(blood3)
			le2:SetBounceFactor(0)
			le2:SetRefEntity(ref)
			
			local vel = (f*-math.random(50,100)) + VectorRandom()*10
			
			le2:SetVelocity(vel + Vector(0,0,20))
			le2:SetStartRadius(12 + math.random(0,5))
			le2:SetEndRadius(25)
			le2:SetStartTime(LevelTime())
			le2:SetEndTime(LevelTime() + 400)
			le2:SetType(LE_FRAGMENT) --LE_FRAGMENT
			--.5 + (math.random(0,5)/8)
			le2:SetStartColor(1,math.random(0,3)/10,0,.8)
			le2:SetEndColor(1,0,0,.4)
			--le2:SetTrType(TR_LINEAR)
		end
		--le2:SetTrType(TR_STATIONARY)
		--end
	end)
	
	le:SetCallback(LOCALENTITY_CALLBACK_STOPPED,function(le)
		le:GetTable().stopped = true
		le:SetAngleVelocity(Vector(0,0,0))
		if(head) then
			print("LE_STOPPED\n")
			local ref = le:GetRefEntity()
			local tr = trDir(le:GetPos())
			ref:SetAngles(Vector(math.random(-40,40),math.random(-60,60),math.random(-60,60)))
			ref:Scale(Vector(scale,scale,scale))
			le:SetRefEntity(ref)
			for i=0, 2 do
				util.CreateMark(blood[math.random(1,#blood)],tr.endpos,tr.normal,math.random(360),1,1,1,1,math.random(10,20),true,65000)
			end
		end
	end)
	
	if(head) then
		NG_HEADGIB = le
	end
	
	--local re = le:GetRefEntity()
	--AddLocalEntity(le);
	--table.insert(localents,le)
end

local function makeMark(pos)
	local res = trDir(pos,nil,100)
	if(res.hit) then
		local id = math.random(1,#bexplosion)
		local tex = bexplosion[id]
		util.CreateMark(
			tex,
			res.endpos,
			res.normal,
			math.random(360),
			.4,0,0,1,
			math.random(80,120),
			true,3000)
	end
end

local function event(entity,event,pos,dir)
	if(event == EV_BULLET_HIT_WALL) then
		--[[PlaySound(pos,explodeSound)
		local list = getGibModels(LocalPlayer())
		local skins = getGibSkins(LocalPlayer())
		for i=1, #list do
			local mdl = list[i]
			local skin = skins[i]
			-- + ((math.random(1,6))/20)
			newParticle(pos,Vector(0,0,0.75),mdl,1,skin)
		end
		makeMark(pos)]]
		--local mdl = entity:GetInfo().headModel or skull
		--local skin = entity:GetInfo().headSkin
		--newParticle(pos,Vector(0,0,.8),mdl,1.4,skin,true)
	end
	if(event == EV_BULLET_HIT_FLESH) then
		--newParticle(pos,vMul(entity:GetByteDir(),.2),gibs[5])
	end
	if(event == EV_GIB_PLAYER) then
		local vel = entity:GetTrajectory():GetDelta()/1000
		if(vel.z < 0) then vel.z = vel.z * -1 end
		PlaySound(entity,explodeSound)
		
		local mdl = entity:GetInfo().headModel or skull
		local skin = entity:GetInfo().headSkin
		
		local torso = entity:GetInfo().torsoModel or skull
		local torsoskin = entity:GetInfo().torsoSkin
		
		local legs = entity:GetInfo().legsModel or skull
		local legsskin = entity:GetInfo().legsSkin
		
		makeMark(pos)
		
		newParticle(pos,Vector(0,0,.8) + vel,mdl,1.4,skin,true)
		if(math.random(0,1) == 1) then
			--newParticle(pos+Vector(0,0,20) + vel,Vector(0,0,.2),torso,1,torsoskin,false)
		else
			--newParticle(pos,Vector(0,0,.2) + vel,legs,1,legsskin,false)
		end
		--for x=1, 2 do
			local list = getGibModels(entity)
			local skins = getGibSkins(entity)
			for i=1, #list do
				local mdl = list[i]
				local skin = skins[i]
				-- + ((math.random(1,6))/20)
				newParticle(pos,Vector(0,0,.5) + vel,mdl,1.5,skin)
			end
		--end
		--util.CreateMark(bexplosion[math.random(1,#bexplosion)],pos,normal,r,.2,0,0,1,tscale*.7,true,5000)
		return true
	end
end
hook.add("EventReceived","cl_newgibs",event)