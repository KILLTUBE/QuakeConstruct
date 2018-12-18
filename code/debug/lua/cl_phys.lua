require "tests/cl_gibchooser"

local data = [[{
	//deformVertexes wave 1000 sin 22 0 0 0
	{
		map gfx/charged_blue2.jpg
		blendFunc add
		rgbGen entity
		alphaGen entity
	}
}]]
local plaincolor = CreateShader("f",data)

local boxmodel = LoadModel("models/geom/box.MD3")
local conemodel = LoadModel("models/geom/cone16.MD3")
local rocketl = LoadModel("models/weapons2/rocketl/rocketl.MD3")
local flag = LoadModel("models/players/sorlag/head.MD3")

local NID = 0
if(PHYS_OBJECTS ~= nil) then
	for k,v in pairs(PHYS_OBJECTS) do
		if(v.native ~= nil) then
			phys.RemoveRigidBody(v.native)
			v.native = nil
		end
	end
end
PHYS_OBJECTS = {}

phys.SetWorldScale(0.1)
local MASS_SCALE = 2

local function removePhysObject(body)
	for k,v in pairs(PHYS_OBJECTS) do
		if(v.id == body.id) then
			if(v.native ~= nil) then
				phys.RemoveRigidBody(v.native)
				v.native = nil
			end
			table.remove(PHYS_OBJECTS,k)
			return
		end
	end
end

local function addPhysBox(size,pos,mass,model)
	mass = mass * MASS_SCALE
	local body = phys.NewBoxRigidBody(size,mass)
	if(body ~= nil) then
		phys.SetPos(body, pos)
		--phys.SetRestitution(body, .01)
	end
	local tab = {
		native = body, 
		scale = size*2, 
		mass = mass, 
		mdl = (model or boxmodel), 
		id=NID}
		
	table.insert(PHYS_OBJECTS,tab)
	NID = NID + 1
	return body,tab
end

local function addPhysModel(model,pos,mass,scale,center,skin)
	mass = mass * MASS_SCALE
	model = model or boxmodel
	scale = scale or Vector(1,1,1)
	center = center or Vector(0,0,0)
	local body = phys.NewModelRigidBody(model,mass,scale,center)
	if(body ~= nil) then
		phys.SetPos(body, pos)
		--phys.SetRestitution(body, .01)
	end
	local tab = {
		native = body, 
		scale = scale, 
		mass = mass, 
		mdl = (model or boxmodel), 
		center = center, 
		skin = skin, 
		id=NID}
	
	table.insert(PHYS_OBJECTS,tab)
	NID = NID + 1
	return body,tab
end

--local box = addPhysBox(Vector(280,280,5),Vector(0,0,7),0)
--[[local cone = addPhysModel(conemodel,Vector(0,0,20),10,Vector(15,15,15))
phys.SetAngles(cone,Vector(0,90,0))
]]
--phys.SetAngles(box,Vector(0,0,0))

--addPhysModel(nil,Vector(0,0,0),10,Vector(20,40,5))
--addPhysModel(conemodel,Vector(0,0,10),10,Vector(3,3,15))

local plBox = addPhysBox(Vector(10,10,20),Vector(0,0,0),0)
--[[for i=0, 10 do
	local b = addPhysBox(Vector(10,10,10),Vector(0,0,100 + i*10),10)
	phys.SetAngles(b,Vector(42,i*2,0))
end]]

for i=0, 3 do
	local rl = addPhysModel(rocketl,Vector(50,0,102 + i*10),10,Vector(1,1,1),Vector(20,0,0))
	phys.SetAngles(rl,Vector(0,i*10,0))
end

local fl = addPhysModel(flag,Vector(100,0,50),10,Vector(2),Vector(3,0,0))

local selectbody = nil
local ref = RefEntity()
local function ptraceline()
	selectbody = nil
	local start = _CG.refdef.origin
	if(start == nil) then return end
	local en = start + _CG.refdef.forward * 1000
	
	local pos,normal,body = phys.TraceLine(start,en)
	normal = VectorToAngles(normal)
	
	if(body ~= nil) then
		selectbody = body
		phys.ApplyImpulse(body,_CG.refdef.forward*100)
		phys.ApplyTorque(body,Vector(0,0,50))
	end
	
	ref:SetPos(pos)
	ref:SetAngles(normal)
	ref:Render()
end

local first = true
local lt = 0
local function d3d()
	local ref = RefEntity()
	ref:AlwaysRender(true)

	if(plBox ~= nil) then
		local pos = LocalPlayer():GetPos() - Vector(0,0,10)
		phys.SetPos(plBox,pos)
		phys.SetAngles(plBox,Vector(0,0,0))
	end
	
	for k,v in pairs(PHYS_OBJECTS) do
		ref:SetShader(0)
		if(v.native == nil) then error("No Native Handle For Physics Object\n") return end
		local pos = phys.GetPos(v.native)
		local f,r,u = phys.GetAngles(v.native)
		
		ref:SetAxis(f,r,u)
		
		ref:SetModel(0)
		ref:SetPos(pos)
		--ref:Render()
		
		if(v.center) then
			pos = pos - f * (v.center.x * v.scale.x)
			pos = pos - r * (v.center.y * v.scale.y)
			pos = pos - u * (v.center.z * v.scale.z)
		end
		
		--ang = VectorToAngles(ang)
		--ref:SetAngles(ang)
		--ref:SetAngles(Vector(0,0,0))
		ref:SetPos(pos)
		ref:Scale(v.scale)
		ref:SetModel(v.mdl)
		ref:SetColor(.2,.2,.2,1)
		
		if(v.skin ~= nil) then
			ref:SetSkin(v.skin)
		else
			ref:SetSkin(0)
		end
		
		if(v.mass ~= 0) then
			ref:SetColor(.2,0,.2,1)
		end
		if(v.native ~= plBox) then
			ref:Render()
		end
		
		if(selectbody == v.native) then
			ref:SetShader(plaincolor)
			ref:Render()
		end
		
		if(v.gib) then
			if(v.bt < LevelTime()) then
			ParticleEffect("BloodSplash",ref:GetPos())
			ParticleEffect("BloodCloud",ref:GetPos())
			v.bt = LevelTime() + math.random(20,60)*10
			end
		end
	end
	
	--ptraceline()
end
hook.add("Draw3D","cl_phys",d3d)


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

concommand.add("spawn",function()
	--local b = addPhysBox(Vector(20,20,20),_CG.refdef.origin,10)
	local start = _CG.refdef.origin
	if(start == nil) then return end
	local en = start + _CG.refdef.forward * 1000
	
	local pos,normal,body = phys.TraceLine(start,en)
	
	local list = getGibModels(LocalPlayer())
	local skins = getGibSkins(LocalPlayer())
	for i=1, #list do
		local v = VectorRandom()*300
		v.z = v.z + 300
		v.z = v.z * 2
		v = v / 3
		local gib = list[i]
		local skin = skins[i]
		if(skin == -1) then skin = nil end
		local b,tab = addPhysModel(gib,Vector(100,0,50),5,Vector(1),Vector(0,0,0),skin)
		phys.SetPos(b,pos+Vector(0,0,10)+VectorRandom()*10)
		phys.ApplyImpulse(b,v)
		phys.ApplyTorque(b,VectorRandom()*2000)
		phys.SetRestitution(b, .45)
		
		tab.gib = true
		tab.bt = LevelTime() + 30
		
		Timer(8+math.random()*3,function()
			removePhysObject(tab)
		end)
	end
	ParticleEffect("BigBloodExplosion",pos)
end)

--[[hook.add("Think","cl_phys",function()
	if(first == true) then
		lt = LevelTime()
		first = false
	end
	local dt = LevelTime() - lt
	phys.Simulate(dt/1000)
	lt = LevelTime()
end)]]