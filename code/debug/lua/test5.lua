util.ClearImage("gfx/trailbanner.tga")
util.ClearImage("gfx/trailstreaks.tga")

local data = 
[[{
	{
		blendfunc add
		map gfx/trailstreaks.tga //$whiteimage
		//tcMod scroll 0  0.7
		alphaGen vertex
		rgbGen vertex
		//tcGen environment
	}
}]]
local trailfx1 = CreateShader("f",data)

local data = 
[[{
	{
		blendfunc blend
		map gfx/trailstreaks.tga //$whiteimage
		alphaGen vertex
		rgbGen vertex
		//tcGen environment
	}
}]]
local trailfx2 = CreateShader("f",data)

local data = 
[[{
	{
		map gfx/misc/railcorethin_mono.tga
		blendfunc add
		alphaGen vertex
		rgbGen vertex
		//tcGen environment
	}
}]]
local trailfx3 = CreateShader("f",data)

local data = 
[[{
	{
		map gfx/misc/dissolve2.tga
		blendfunc add
		alphaFunc LT128
		alphaGen oneMinusVertex
		rgbGen vertex
		tcMod scale 2 1
		tcMod scroll .3 -.2
	}
	{
		map gfx/misc/dissolve2.tga
		blendfunc add
		alphaFunc LT128
		alphaGen oneMinusVertex
		rgbGen vertex
		tcMod scale 2 1
		tcMod scroll -.2 .1
	}
}]]

local data2 =
[[{
	sort portal
	{
		map gfx/misc/dissolve2.tga
		blendfunc gl_zero gl_one
		alphaFunc LT128
		alphaGen oneMinusVertex
		depthwrite
	}
}]]
local trailfx4 = CreateShader("f",data)


local data =
[[{
	{
        map gfx/damage/blood8x.tga
		blendFunc blend
		rgbGen		vertex
		alphaGen	vertex
	}
}]]
local blood = CreateShader("f",data)

local trailCache = {}
local posCache = {}
local healthCache = {}
local dtimers = {}

local function passTrail(trail) 
	--Pass the trail over to a local entity so the engine can render it out.
	local le = LocalEntity()
	le:SetPos(trail:GetPos())
	le:SetRefEntity(trail)
	le:SetVelocity(Vector(0,0,0))
	le:SetStartTime(LevelTime())
	le:SetEndTime(LevelTime() + 8000)
	
	
	local r,g,b,a = trail:GetColor()
	le:SetColor(r,g,b,1)
	le:SetRadius(trail:GetRadius())
	le:SetType(LE_FRAGMENT)
	le:SetTrType(TR_STATIONARY)
	
	le:SetCallback(LOCALENTITY_CALLBACK_THINK,function(le)
		local r = le:GetRefEntity()
		r:SetPos(r:GetPos())
		le:SetRefEntity(r)
		le:SetNextThink(LevelTime() + 40)
	end)
end

local function makeTrail(i,cr,cg,cb,ca)
	local r,g,b = hsv(math.random(360),1,.5)
	local trail = RefEntity()
	trail:SetType(RT_TRAIL)
	trail:SetColor(cr or r,cg or g,cb or b,ca or .5)
	trail:SetRadius(4)
	trail:SetShader(trailfx4)
	trail:SetTrailLength(256)
	trail:SetTrailFade(FT_ALPHA)
	trail:SetTrailStaticMap(true)
	trail:SetTrailMapLength(300)
	trailCache[i] = trail
end

local function d3d()
	local players = GetAllPlayers()
	table.insert(players, LocalPlayer())
	for k,v in pairs(players) do
		local i = v:EntIndex()
		local trail = trailCache[i]
		
		local forward = VectorForward(v:GetLerpAngles())
		local pos = v:GetPos() + Vector(0,0,25)
		local ep = pos + forward * 3000
		local tr = TraceLine(pos,ep,v,1)
		
		
		--posCache[i] = posCache[i] or Vector()
		--posCache[i] = posCache[i] + ((tr.endpos + Vector(0,0,15)) - posCache[i])*.5
		local plpos = (v:GetPos() - Vector(0,0,10))
		local health = v:GetInfo().health
		if(health > 0) then
			if(trail == nil) then
				makeTrail(i)
			else
				if(posCache[i] != nil) then
					if(VectorLength(posCache[i] - plpos) > 300) then
						passTrail(trail)
						makeTrail(i,trail:GetColor())
						trail = trailCache[i]
						posCache[i] = plpos
					end
				end
				if(healthCache[i] != nil and (healthCache[i] - health) > 1) then
					dtimers[i] = 10
				end
				if(dtimers[i] and dtimers[i] > 0) then
					local r,g,b,a = trail:GetColor()
					local trad = trail:GetRadius()
					local shd = trail:GetShader()
					trail:SetColor(dtimers[i]/10,0,0,1)
					trail:SetRadius(trad*8)
					trail:SetShader(trailfx3)
					trail:Render()
					trail:SetColor(r,g,b,a)
					trail:SetRadius(trad)
					trail:SetShader(shd)
					dtimers[i] = dtimers[i] - 1
				end
				trail:SetPos(plpos)
				trail:Render()
				posCache[i] = plpos
			end
		else
			if(trailCache[i] != nil) then
				local trail = trailCache[i]
				local r,g,b,a = trail:GetColor()
				trail:SetTrailLength(128)
				trail:SetRadius(trail:GetRadius() * 2)
				trail:SetShader(trailfx2)
				trail:SetTrailFade(FT_ALPHA)
				trail:SetColor(r/4,g/4,b/4,a/4)
				passTrail(trail)
				trailCache[i] = nil
			end
		end
		healthCache[i] = health
	end
end
hook.add("Draw3D","test5",d3d)
//__DL_BLOCK

local function createEmitter()
	local ref = RefEntity()
	ref:SetColor(1,1,0,1)
	ref:SetType(RT_TRAIL)
	ref:SetShader(blood)
	ref:SetRadius(1)
	ref:SetTrailLength(10)
	ref:SetTrailFade(FT_ALPHA)
	
	local le = LocalEntity()
	le:SetRefEntity(ref)
	le:SetStartTime(LevelTime())
	le:SetEndTime(LevelTime() + 100)
	le:SetType(LE_FRAGMENT)
	le:SetEndColor(0,0,0,0)
	le:Emitter(LevelTime(), LevelTime()+100, 1000)
	return le
end

local emitter = createEmitter()

local function pldamage(self2,attacker,pos,dmg,death,self,suicide,hp,id,pos,dir)
	if(self2 != nil and self2:IsPlayer()) then
		local le = createEmitter()
		le:SetPos(pos)
	
		for i=1,8 do
			local le2 = le:Emit()
			if(le2 != nil) then
				dir = Vector(0,0,0)
				dir.x = dir.x + (math.random(-10,10)/10)
				dir.y = dir.y + (math.random(-10,10)/10)
				dir.z = dir.z + (math.random(-10,10)/10)
						
				dir = dir * math.random(60,300)
				le2:SetVelocity(dir + self2:GetTrajectory():GetDelta()/2)
				le2:SetRadius(math.random(1,5))
				le2:SetEndRadius(.5)
				le2:SetStartTime(LevelTime())
				le2:SetEndTime(LevelTime() + math.random(800,2000))
				
				le2:SetCallback(LOCALENTITY_CALLBACK_THINK,function(le)
					local r = le:GetRefEntity()
					r:SetPos(r:GetPos())
					le:SetRefEntity(r)
					le:SetNextThink(LevelTime() + 20)
				end)
				
				
				--if(math.random(0,1) == 1) then
					le2:SetStartColor(.4,0,0,1)
				--else
					--le2:SetStartColor(1,1,1,1)
				--end
			end
		end
	end
end
hook.add("PlayerDamaged","test5",pldamage)

local function event(entity,event,pos,dir)
	if(event == EV_BULLET_HIT_FLESH) then

	end
end
hook.add("EventReceived","vecdefine",event)
//__DL_UNBLOCK