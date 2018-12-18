local character = "sorlag"
local legs,torso,head = LoadCharacter(character)
local anims = loadPlayerAnimations(character)

MOVE_SPEED = 4

local lx = 0
local speed = MOVE_SPEED

local lanim = anims["LEGS_RUN"]
	lanim:SetRef(legs)
	lanim:SetType(ANIM_ACT_LOOP_LERP)
	lanim:Play()
	
local lanim_idle = anims["LEGS_IDLE"]
	lanim_idle:SetRef(legs)
	lanim_idle:SetType(ANIM_ACT_LOOP_LERP)
	lanim_idle:Stop()

local tanim = anims["TORSO_STAND2"]
	tanim:SetRef(torso)
	tanim:SetType(ANIM_ACT_LOOP)
	tanim:Play()

local location = PlayerTrace().endpos

local function trDown(pos)
	local endpos = vAdd(pos,Vector(0,0,-2000))
	local res = TraceLine(pos,endpos,nil,1)
	return res.endpos
end

local function canMove(lp,forward)
	local pos = lp + forward*MOVE_SPEED
	local endpos = vAdd(pos,Vector(0,0,-100))
	local res = TraceLine(pos,endpos,nil,1)
	return (res.fraction != 1)
end

local function skipGap(lp,forward)
	local pos = lp + forward*25
	local endpos = vAdd(pos,Vector(0,0,-100))
	local res = TraceLine(pos,endpos,nil,1)
	if(res.fraction != 1) then
		return pos
	else
		return lp
	end
end

local lp = Vectorv(location)
local lt = lt or LevelTime()
local ang = Vector()

local function d3d()
	local d = LocalPlayer():GetPos() - lp
	local forward = VectorNormalize(d)
	local dist = VectorLength(d)
	local look = math.sin(LevelTime()/400)*20
	local look2 = math.cos(LevelTime()/200)*10
	local nang = VectorToAngles(forward)
	local p = nang.p
	local p2 = -getDeltaAngle(p,0)
	local dt = (LevelTime() - lt)/10
	forward = AngleVectors(ang)

	lp.z = trDown(lp).z
	lp.z = lp.z + 25

	forward.z = 0
	
	local forward2 = AngleVectors(nang)
	forward2.z = 0

	if(canMove(lp,forward)) then
		lp = lp + forward*speed
	else
		if(canMove(lp,forward2)) then
			lp = lp + forward2*speed
		else
			local np = skipGap(lp,forward2)
			lp = np
			dist = 0
		end	
	end
	
	if(dist < 100) then
		lanim:Stop()
		lanim_idle:Play()
		speed = 0
	else
		ang = ang + getDeltaAngle3(nang,ang)*.1
		speed = dt--MOVE_SPEED
		lanim:Play()
		lanim_idle:Stop()
	end
	
	--LEGS------------------------------------------------------------------------------------
	legs:SetPos(lp)
	
	--Scaling works relative so set angles to reset scale
	legs:SetAngles(Vector(0,ang.y,0))
	legs:Render()
	
	--TORSO------------------------------------------------------------------------------------
	torso:SetAngles(Vector())
	torso:PositionOnTag(legs,"tag_torso")
	
	local g = torso:GetAngles()
	torso:SetAngles(Vector(p2/2,ang.y,g.r))
	torso:Render()
	
	--HEAD-----------------------------------------------------------------------------------
	head:SetAngles(Vector())
	head:PositionOnTag(torso,"tag_head")
	head:SetAngles(Vector(p2,ang.y,ang.r))
	
	--head:Scale(Vector(1,1,1))
	head:Render()
	
	--ANIMATION--------------------------------------------------------------------------------
	for k,v in pairs(anims) do
		v:Animate()
	end
	lt = LevelTime()
end
hook.add("Draw3D","cl_init",d3d)