local flare = LoadShader("flareShader")
local blood3 = LoadShader("viewBloodFilter_HQ")

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

local explodeSound = LoadSound("sound/player/gibsplt1.wav")
local impact = {}
impact[1] = LoadSound("sound/player/gibimp1.wav")
impact[2] = LoadSound("sound/player/gibimp2.wav")
impact[3] = LoadSound("sound/player/gibimp3.wav")

local lengths = {}
for k,v in pairs(gibs) do
	local mins,maxs = render.ModelBounds(v)
	lengths[v] = VectorLength(maxs-mins)
end

local blood = {}
for i=1,5 do
	--table.insert(blood,LoadShader("BloodMarkN" .. i))
end
table.insert(blood,LoadShader('bloodMark'))

blood3 = LoadShader('bloodTrail')

local function rvel(a)
	return Vector(
	math.random(-a,a),
	math.random(-a,a),
	math.random(-a,a))
end

local mdl = LoadModel("models/misc/spinnything.md3")
local ref = RefEntity()
	ref:SetColor(1,1,1,1)
	ref:SetType(RT_SPRITE)
	ref:SetShader(blood3)
	
local data = 
[[{
	{
		map models/misc/thingie_texmap.tga
		blendfunc blend
		rgbGen entity
		alphaGen entity
	}
}]]
local thingmap = CreateShader("f",data)
	
local function newParticle1(pos,indir,freeze,parent,len,model)
	scale = scale or 1

	local mins,maxs = render.ModelBounds(model)
	local radius = 15 --VectorLength(maxs-mins)
	
	local pmodel = parent:GetRefEntity():GetModel()
	local le = LocalEntity()
	le:SetPos(pos)
	le:SetRefEntity(ref)
	le:SetRadius(radius)
	le:SetStartTime(LevelTime())
	le:SetEndTime(LevelTime() + (400))
	le:SetType(LE_FRAGMENT)
	le:SetColor(math.random(160,255)/255,1,1,.8)
	le:SetEndColor(1,0,0,1)
	le:SetEndRadius(radius/2)
	--le:SetTrType(TR_LINEAR)
	
	if(parent) then
		le:SetParent(parent,attach)
	end
	
	le:Emitter(LevelTime(), LevelTime() + len, 10, function(em,t)
		ref:SetRotation(math.random(360))
		em:SetRefEntity(ref)
		if(parent) then
			local pa = parent:GetRefEntity():GetAngles()
			pa = VectorForward(pa)*-1
			local pv = pa * math.random(200,400)
			pv = pv + (VectorRandom()*20)
			em:SetVelocity(pv*(1-(t*t)))
			em:SetRadius(radius * (1-(t*t)))
			em:SetEndRadius(0)
			--em:SetVelocity(parent:GetVelocity()*(math.random(1,100)/100))
		end
		em:SetCallback(LOCALENTITY_CALLBACK_TOUCH,function(le2,tr)
			--em:Remove()
		end)
	end)
	return le
end

--function newParticle(pos,dir,model,scale,skin,head)
local function newParticle(pos,indir,modelList,scale,skins,head)

	--ref:SetRotation(math.random(360))
	--ref:SetModel(mdl)
	local id = 1
	local le = LocalEntity()
	le:SetPos(pos)
	le:SetRadius(20)
	le:SetStartTime(LevelTime())
	le:SetType(LE_FRAGMENT)
	le:SetColor(1,.6,0,0)
	le:SetEndColor(1,0,0,0)
	le:SetEndRadius(0)
	--le:SetTrType(TR_LINEAR)
	le:Emitter(LevelTime(),LevelTime()+1000,0,function(em)
		local rv = rvel(200)
		local t = (5800) + math.random(300,1000)
		if(head) then t = t + 16000 end
		rv.z = rv.z * 1.5
		em:SetVelocity(rv)
		em:SetAngleVelocity(rvel(600))
		em:SetEndTime(LevelTime() + t)
		em:SetBounceFactor(.7)
		em:SetPos(LocalPlayer():GetPos())
		
		local mdl = 0
		local ref2 = RefEntity()
		if(type(modelList) == "table") then
			mdl = modelList[id]
		else
			mdl = modelList
		end
		ref2:SetModel(mdl)
		if(type(skins) == "table") then
			ref2:SetSkin(skins[id])
		else
			ref2:SetSkin(skins)
		end
		ref2:Scale(Vector(1,1,1)*scale)
		em:SetRefEntity(ref2)
		
		local p3 = newParticle1(pos,Vector(),false,em,6000,mdl)
		
		em:SetCallback(LOCALENTITY_CALLBACK_TOUCH,function(le2,tr)
			util.CreateMark(blood[math.random(1,#blood)],tr.endpos,tr.normal,math.random(360),math.random(150,255)/255,1,1,1,math.random(15,35),true,0)
			if(em:GetTable() and em:GetTable().stopped) then return end
			em:SetAngleVelocity(rvel(600))
		end)
		em:SetCallback(LOCALENTITY_CALLBACK_STOPPED,function(le2)
			em:SetAngleVelocity(Vector())
			--if(p3 != nil) then 
				--p3:Remove()
				--p3 = nil
			--end
			em:GetTable().stopped = true
		end)
		em:SetCallback(LOCALENTITY_CALLBACK_DIE,function(le2)
			--if(p3 != nil) then 
				--p3:Remove()
				--p3 = nil
			--end		
		end)
		print("Emitted: " .. id .. "\n")
		id = id + 1
	end)
	if(type(modelList) == "table") then
		print("ModelList == table: #" .. #modelList .. "\n")
		for i=0, #modelList/2 do
			le:Emit()	
		end
	else
		le:Emit()
	end
	le:Remove()
end

local function particleTest()
	local entity = LocalPlayer()
	local pos = PlayerTrace().endpos
	local list = getGibModels(entity)
	local skins = getGibSkins(entity)
	
	newParticle(pos + Vector(0,0,30),Vector(0,0,1),list,1.5,skins)
	
	local mdl = entity:GetInfo().headModel
	local skin = entity:GetInfo().headSkin
		
	newParticle(pos,Vector(0,0,.8),mdl,1.4,skin,true)
	
end
concommand.add("ptest",particleTest)

local function event(entity,event,pos,dir)
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
		
		newParticle(pos,Vector(0,0,.8) + vel,mdl,1.4,skin,true)
		if(math.random(0,1) == 1) then
			--newParticle(pos+Vector(0,0,20) + vel,Vector(0,0,.2),torso,1,torsoskin,false)
		else
			--newParticle(pos,Vector(0,0,.2) + vel,legs,1,legsskin,false)
		end
		--for x=1, 2 do
			local list = getGibModels(entity)
			local skins = getGibSkins(entity)
			print("Gib Created\n")
			newParticle(pos,Vector(0,0,.5) + vel,list,1.5,skins)
		--end
		return true
	end
end
hook.add("EventReceived","cl_newgibs",event)