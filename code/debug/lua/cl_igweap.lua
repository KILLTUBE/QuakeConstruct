local tp = Vector()
local lightning = LoadShader("lightningBoltNew")
local pdown = 0
local smoke = LoadShader("smokePuff")
local lastflpos = Vector()

local firedata = {}
local firetime = 0
local fireduration = 1000
local firemid = 900

local intervals = {2,-1.6,2,3}

local function postpone_ex()
	examinetime = 0
	extimer = (LevelTime() + exduration) + math.random(5000,8000)
end

local function railgun(ref,state,wtime)
	local f = wtime / 1500
	local s = .2
	if(f <= 0) then s = 1 end
	if(f > 1) then f = 1 end
	local r,g,b = hsv(LevelTime()/10,s,1-f)
	local af,ar,au = ref:GetAxis()
	
	ref:SetColor(r,g,b,1)
	if(pdown > .1) then ref:SetAngles(ref:GetAngles() + Vector(pdown*2,pdown*-2,pdown)) end
	ref:SetPos(ref:GetPos() + (au * (pdown*-2)))
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
	le:SetStartColor(rc*.7,rc*.8,rc,.1)
	le:SetEndColor(.8,.8,.8,0)
	le:SetStartRadius(math.random(3,6))
	le:SetEndRadius(math.random(3,6)*4)
end

local function fire()
	local a1 = Vector(0,0,0)
	local a2 = Vector(-80,10,5)
	local a3 = Vector(35,-10,22)
	local a4 = Vector(-8,0,0)
	
	local pt = (fireduration - (firetime - LevelTime()))
	print(pt .. "\n")
	
	firedata = {a1,a2,a3,a4,a1,a1}
	if(pt < firemid) then
		firetime = LevelTime() + firemid
		return
	end
	
	firetime = LevelTime() + fireduration
end

local function doSplines(ref)
	local ang = Vector()
	local pos = Vector()
	
	local t2 = (firetime - LevelTime()) / fireduration
	if(t2 > 0) then
		local angle = VectorSpline(firedata,1-t2)
		local f,r,u = ref:GetAxis()
		local back = angle.y
		angle.y = 0
	
		ang = ang + angle
		pos = pos + f*(angle.p/5)
		pos = pos - f*back
		pos = pos - u*back
	else
		return
	end
	
	ref:SetAngles(ref:GetAngles() + ang)
	ref:SetPos(ref:GetPos() + pos)
end

local muzzlePos = Vector()
function GetAltMuzzleLocation()
	return muzzlePos
end

local function d3d()
	local hand = util.Hand()
	local pl = LocalPlayer()
	local id = pl:GetInfo().weapon
	
	if(id == WP_NONE) then return end
	if(id != WP_RAILGUN) then return end
	
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
	ref:SetPos(ref:GetPos() + f*8)
	ref:SetPos(ref:GetPos() + u*-8)
	ref:SetPos(ref:GetPos() + r*-3)
	--ref:SetAngles(ref:GetAngles() + Vector(math.cos(LevelTime()/400),0,math.sin(LevelTime()/800)*2))
	doSplines(ref)

	railgun(ref,wpstate,wptime)
	
	ref:SetPos(ref:GetPos() + Vector(0,0,math.sin(LevelTime()/400)/6))
	
	ref:Scale(Vector(1,2,2))
	ref:Render()

	if(inf.flashModel != 0) then
		local flash = RefEntity()
		flash:SetModel(inf.flashModel)
		flash:PositionOnTag(ref,"tag_flash")
		
		if(wpstate == WEAPON_FIRING) then
			local fv = (lastflpos - flash:GetPos())
			smokeParticles(flash,fv*-2)
		end
		
		lastflpos = flash:GetPos()
		
		--if(firing == 0) then
			if((LevelTime() - fltime) > 10) then return end
		--end
		
		fire()
		flash:Render()
		
		muzzlePos = flash:GetPos()
	end
end
hook.add("Draw3D","cl_igweap",d3d)

local function ShouldDraw(str)
	if(str == "HUD_DRAWGUN") then
		return false
	end
end
hook.add("ShouldDraw","cl_igweap",ShouldDraw)