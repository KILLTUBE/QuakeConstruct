local tp = Vector()
local skull = LoadModel("models/gibs/skull.md3")
local weap = LoadModel("models/weapons2/rocketl/rocketl.md3")
local lightning = LoadShader("lightningBoltNew")
local rotspeed = 0
local rot = 0
local spintime = LevelTime()
local pdown = 0
local smoke = LoadShader("smokePuff")
local lastflpos = Vector()

local firedata = {}
local firetime = 0
local fireduration = 1000
local firemid = 900

local examinedata = {}
local examinetime = 0
local extimer = LevelTime()
local exduration = 7000
local intervals = {2,-1.6,2,3}

local data = 
[[{
	{
		blendfunc add
		map $whiteimage
		alphaGen vertex
		rgbGen vertex
		//tcGen environment
	}
}]]
local trailfx1 = CreateShader("f",data)

local function lerpVec(v1,v2,t)
	return v1 + (v2 - v1) * t
end

local function bezier(c1,c2,c3,c4,t)
	local c5 = lerpVec(c2,c1,t)
	local c6 = lerpVec(c3,c2,t)
	local c7 = lerpVec(c4,c3,t)
	
	local c8 = lerpVec(c6,c5,t)
	local c9 = lerpVec(c7,c6,t)
	return lerpVec(c9,c8,t)
end

local function postpone_ex()
	examinetime = 0
	extimer = (LevelTime() + exduration) + math.random(5000,8000)
end

local function pr(i)
	if(i >= 0) then return 1 end
	if(i < 0) then return -1 end
end

local function railgun(ref,state,wtime)
	local f = wtime / 1500
	local s = .2
	if(f <= 0) then s = 1 end
	if(f > 1) then f = 1 end
	local r,g,b = hsv(LevelTime()/10,s,1-f)
	ref:SetColor(r,g,b,1)
	--ref:SetAngles(ref:GetAngles() + Vector(pdown*-50,pdown*-15,pdown*-20))
end

local function smokeParticles(ref,partvel)
	pos = ref:GetPos()
	pos = pos + (VectorRandom()*2)
	local le,ref = QuickParticle(pos,2200,smoke)
	ref:SetRotation(math.random(360))
	ref:SetRadius(math.random(3,6))
	le:SetType(LE_FADE_TWEEN)
	le:SetRefEntity(ref)
	le:SetVelocity(partvel + (vAbs(VectorRandom())*Vector(0,0,20)) + VectorRandom()*5)
	
	local rc = math.random(5,8)/10
	le:SetStartColor(rc,rc,rc,.1)
	le:SetEndColor(.8,.8,.8,0)
	le:SetStartRadius(math.random(3,6))
	le:SetEndRadius(math.random(3,6)*4)
end

local function fire()
	local a1 = Vector(0,0,0)
	local a2 = Vector(-40,0,5)
	local a3 = Vector(35,0,22)
	local a4 = Vector(-8,0,-20)
	
	local pt = (fireduration - (firetime - LevelTime()))
	print(pt .. "\n")
	
	firedata = {a1,a2,a3,a4,a1,a1}
	if(pt < firemid) then
		firetime = LevelTime() + firemid
		return
	end
	
	firetime = LevelTime() + fireduration
end

local function examine()
	postpone_ex()
	local a1 = Vector()
	local a2 = Vector(-10,50,90)
	local a3 = Vector(-20,-40,-80)
	local a4 = Vector()
	
	examinedata = {a1,a2,a2,a3,a3,a3,a4}
	examinetime = LevelTime() + exduration
end
--examine()

local function doSplines(ref)
	local ang = Vector()
	local pos = Vector()
	local t = (examinetime - LevelTime()) / exduration
	if(t > 0) then
		local t1,t2,t3,t4 = unpack(intervals)
		if(t*2 < .5) then
			examinetime = examinetime - 20
		else
			examinetime = examinetime - bezier(t1,t2,t3,t4,(t*2)-1)*10
		end
		
		local angle = VectorSpline(examinedata,1-t)
		local f,r,u = ref:GetAxis()
	
		ang = ang + angle
		pos = pos + f*-(angle.p/4)
	end
	
	local t2 = (firetime - LevelTime()) / fireduration
	if(t2 > 0) then
		local angle = VectorSpline(firedata,1-t2)
		local f,r,u = ref:GetAxis()
	
		ang = ang + angle
		pos = pos + f*(angle.p/5)
	end
	
	ref:SetAngles(ref:GetAngles() + ang)
	ref:SetPos(ref:GetPos() + pos)
end

local trail = RefEntity()
trail:SetType(RT_TRAIL)
trail:SetShader(trailfx1)
trail:SetColor(.5,.5,.5,1)
trail:SetRadius(3)
trail:SetTrailLength(10)
trail:SetTrailFade(FT_COLOR)

local function d3d()
	local hand = util.Hand()
	local pl = LocalPlayer()
	local id = pl:GetInfo().weapon
	
	if(id == WP_NONE) then return end
	
	local inf = util.WeaponInfo(id)
	local fltime = pl:GetFlashTime()
	local firing = bitAnd(pl:GetFlags(),EF_FIRING)
	local wpstate = inf.weaponState
	local wptime = inf.weaponTime

	if(wpstate == WEAPON_FIRING) then
		pdown = pdown + (1 - pdown)*.12
	else
		pdown = pdown + (0 - pdown)*.2
	end
	
	local ref = RefEntity()
	ref:SetModel(inf.weaponModel)
	ref:PositionOnTag(hand,"tag_weapon")
	
	local f,r,u = ref:GetAxis()
	if(id != WP_GAUNTLET) then
		ref:SetPos(ref:GetPos() + f*10)
		ref:SetPos(ref:GetPos() + u*-1)
		ref:SetPos(ref:GetPos() + r*-2)
		ref:SetAngles(ref:GetAngles() + Vector(math.cos(LevelTime()/400),0,math.sin(LevelTime()/800)*2))
		doSplines(ref)
	else
		ref:SetPos(ref:GetPos() + u*-2)
	end
	if(id == WP_MACHINEGUN) then
		ref:SetPos(ref:GetPos() + r*-2)
		ref:Scale(Vector(1,.8,.8))
	end
	if(id == WP_BFG) then
		ref:SetPos(ref:GetPos() + f*-4)
	end

	if(id == WP_RAILGUN) then railgun(ref,wpstate,wptime) end
	
	ref:SetPos(ref:GetPos() + Vector(0,0,math.sin(LevelTime()/400)/6))
	
	ref:Scale(Vector(1,1.3,1.3))
	ref:Render()
	
	if(inf.barrelModel != 0) then
		local barrel = RefEntity()
		barrel:SetModel(inf.barrelModel)
		barrel:PositionOnTag(ref,"tag_barrel")
		
		local ang = barrel:GetAngles()
		ang.z = rot - ref:GetAngles().r --util.BarrelAngle(LocalPlayer()) + LevelTime()/10
		barrel:SetAngles(ang)
		barrel:Render()
		
		rot = rot + rotspeed*Lag()
	end
	
	rotspeed = rotspeed + (0-rotspeed)*(.015*Lag())
	if(math.abs(rotspeed) < .3 and spintime < LevelTime()) then
		rotspeed = -pr(rotspeed)/5
		spintime = LevelTime() + math.random(70,4000)
	end
	
	if(extimer < LevelTime()) then
		examine()
	end
	
	if(inf.flashModel != 0) then
		local flash = RefEntity()
		flash:SetModel(inf.flashModel)
		flash:PositionOnTag(ref,"tag_flash")
		
		--trail:SetPos(flash:GetPos())
		--trail:Render()
		
		if(wpstate == WEAPON_FIRING) then
			local fv = (lastflpos - flash:GetPos())
			smokeParticles(flash,fv*-2)
		end
		
		lastflpos = flash:GetPos()
		
		if(firing != 0 and (id == WP_LIGHTNING || id == WP_GAUNTLET || id == WP_GRAPPLING_HOOK)) then
			if(id == WP_LIGHTNING) then
				local tr = PlayerTrace()
				local beam = RefEntity()
				beam:SetModel(inf.flashModel)
				beam:SetType(RT_LIGHTNING)
				beam:SetPos(flash:GetPos())
				beam:SetPos2(tr.endpos)
				beam:SetShader(lightning)
				beam:Render()
			end
		else
			if((LevelTime() - fltime) > 20) then return end
		end
		
		fire()
		
		postpone_ex()
		
		rotspeed = rotspeed + 3
		if(rotspeed > 15) then rotspeed = 15 end
		flash:Render()
	end
end
hook.add("Draw3D","cl_junk",d3d)

local function ShouldDraw(str)
	if(str == "HUD_DRAWGUN") then
		return false
	end
end
hook.add("ShouldDraw","cl_junk",ShouldDraw)

local function event(entity,event,pos,dir)
	if(event == EV_BULLET_HIT_WALL) then
		tp = pos
	end
end
hook.add("EventReceived","vecdefine",event)