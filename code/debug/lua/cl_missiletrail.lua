local fx = LoadShader("railCore")
local flareshd = LoadShader("flareShader")

local function attachBeam(ent)

end

local etab = {}
local splodes = LinkedList()
local function makeTrail(cr,cg,cb,ca,size,ft)
	local r,g,b = hsv(math.random(360),1,.5)
	local trail = RefEntity()
	trail:SetType(RT_TRAIL)
	trail:SetColor(cr or r,cg or g,cb or b,ca or .5)
	trail:SetRadius(size)
	trail:SetShader(fx)
	trail:SetTrailLength(100)
	trail:SetTrailFade(ft or FT_RADIUS)
	trail:SetTrailStaticMap(true)
	trail:SetTrailMapLength(300)
	return trail
end

local function makeFlare(r,g,b,size,tex)
	local flare = RefEntity()
	flare:SetType(RT_SPRITE)
	flare:SetColor(r,g,b,1)
	flare:SetRadius(size or 12)
	flare:SetShader(tex or flareshd)
	return flare
end

local function d3d()
	local tab = GetEntitiesByClass("missile")
	local leveltime = LevelTime()

	for k,v in pairs(tab) do
		local id = v:EntIndex()
		local vx = etab[id]
		if(vx ~= nil) then
			v:CustomDraw(true)
			if(vx.trail ~= nil) then
				
				local pos = v:GetPos()
				local t = leveltime - vx.start
				local dir = VectorNormalize(v:GetTrajectory():GetDelta())
				local a = VectorToAngles(dir)
				local f,r,u = AngleVectors(a)
				local o = r*vx.rad*math.sin(t/vx.speed)
				o = o + u*vx.rad*math.cos(t/vx.speed)
			
				vx.trail:SetPos(pos + o)
				vx.trail2:SetPos(pos)
				if(vx.flare ~= nil) then
					vx.flare:SetPos(pos)
					vx.flare:Render()
				end
				if(vx.flare2 ~= nil) then
					vx.flare2:SetPos(pos)
					vx.flare2:Render()
				end
				vx.lt = leveltime
				vx.die = vx.lt
			end
		end
	end
	for k,v in pairs(etab) do
		if(v.trail ~= nil and v.trail2 ~= nil) then
			v.trail:Render()
			v.trail2:Render()
			
			--[[local h = (leveltime - v.start*1.4)/5
			local r,g,b = hsv(h,1,1)
			
			if(v.flare ~= nil and v.flare2 ~= nil) then
				v.flare:SetColor(r,g,b,1)
				v.flare2:SetColor(r,g,b,1)
			end
			v.trail:SetColor(r,g,b,1)
			v.trail2:SetColor(r,g,b,1)]]
			if(v.lt < leveltime - 60) then
				v.trail:SetPos(v.trail:GetPos())
				v.trail2:SetPos(v.trail2:GetPos())
			end
			if(v.die < leveltime - 1500) then
				v.trail = nil
				v.trail2 = nil
			end
		end
	end
	splodes:Iter(function(v)
		if(v.trail) then
			for i=0, 1 do v.trail:SetPos(v.trail:GetPos()) end
			v.trail:Render()
			if(v.start < LevelTime() - 1000) then
				v.trail = nil
				splodes:Remove()
			end
		end
	end)
end
hook.add("Draw3D","cl_missiletrail",d3d)

local function splode(pos,ptr,dir)
	if(ptr == nil) then return end
	local r,g,b,a = ptr:GetColor()
	local tr = makeTrail(r,g,b,a,ptr:GetRadius()*2)
	
	tr:SetPos(pos)
	for i=0,40 do
		tr:SetPos(tr:GetPos() + dir*2 + VectorRandom()*(4+i/10))
	end
	
	splodes:Add({trail=tr,start=LevelTime(),pos=pos})
end

local function LinkEntity(e)
	if(e == nil) then return end
	if(e:Classname() == "missile") then
		local id = e:EntIndex()	
		etab[id] = {}
		local r = 1
		local g = 0.5
		local b = 0.1
		local rad = 2
		local size = 8
		local speed = 20
		local ir = 1
		local ig = 0.4
		local ib = 0
		
		if(e:GetWeapon() == WP_BFG) then
			r = 0.4
			g = 1
			b = 0.3
			ir = 0
			ig = 1
			ib = 0
			rad = 10
			size = 18
		end
		if(e:GetWeapon() == WP_PLASMAGUN) then
			r = 0.7
			g = 0.5
			b = 1
			ir = 0.5
			ig = 0.4
			ib = 1
			rad = 6
			speed = 15
		end
		if(e:GetWeapon() == WP_GRENADE_LAUNCHER) then
			g = g - 0.1
			b = b + 0.2
			ir = 1
			ig = 0
			ib = 0
			rad = 1
		end
		
		local t = makeTrail(r,g,b,1,size,FT_COLOR)
		local t2 = makeTrail(ir/2,ig/2,ib/2,1,size*5,FT_COLOR)
		local f = makeFlare(r,g,b,size*4)
		etab[id].flare = f
		etab[id].flare2 = makeFlare(1,1,1,size*2)
		etab[id].trail = t
		etab[id].trail2 = t2
		etab[id].start = LevelTime()
		etab[id].rad = rad
		etab[id].speed = speed
	end
end
hook.add("EntityLinked","cl_coolrockets",LinkEntity)

local function event(entity,event,pos,dir)
	if(event == EV_MISSILE_MISS or event == EV_MISSILE_HIT or event == EV_MISSILE_MISS_METAL) then
		local id = entity:EntIndex()
		local vx = etab[id]
		if(vx ~= nil) then
			splode(entity:GetPos(),vx.trail,dir)
			vx.flare = nil
			vx.flare2 = nil
		end
	end
	if(event == EV_GRENADE_BOUNCE) then
		local id = entity:EntIndex()
		local vx = etab[id]
		if(vx ~= nil) then
			dir = VectorNormalize(entity:GetTrajectory():GetDelta()) * .6
			splode(entity:GetPos(),vx.trail,dir)
			splode(entity:GetPos(),vx.trail,dir*-1)
		end	
	end
end
hook.add("EventReceived","cl_missiletrail",event)