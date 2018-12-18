local gibs = {
	LoadModel("models/presents/present1.md3"),
	LoadModel("models/presents/present2.md3"),
	LoadModel("models/presents/present3.md3"),
	LoadModel("models/presents/ribbon1.md3")
}
local confetti = {
	LoadShader("confetti1"),
	LoadShader("confetti2")
}

local explodeSound = LoadSound("sound/player/kapop.wav")

local i=0
local rpos = Vector(670,500,30)
local lastPos = Vector()

local function rvel(a)
	return Vector(
	math.random(-a,a),
	math.random(-a,a),
	math.random(-a,a))
end

local particles = {}
local localents = {}

function makeConfetti(le,scale)
	if(VectorLength(le:GetVelocity()) > 100) then
		le:SetNextThink(LevelTime() + 170)
		local le2 = LocalEntity()
		le2:SetPos(le:GetPos())
		local ref = le:GetRefEntity()
		ref:SetRotation(math.random(360))
		ref:SetColor(1,1,1,1)
		ref:SetType(RT_SPRITE)
		ref:SetShader(confetti[math.random(1,#confetti)])
		ref:SetRadius(25*scale)
		le2:SetRadius(25*scale)
		le2:SetRefEntity(ref)
		le2:SetStartTime(LevelTime())
		le2:SetEndTime(LevelTime() + 1000)
		le2:SetType(LE_FADE_RGB) --LE_FRAGMENT
		le2:SetColor(1,1,1,1)
		le2:SetTrType(TR_STATIONARY)
	end
end

function newParticle(pos,dir,model,scale)
	scale = scale or 1
	local r = RefEntity()
	r:SetModel(model)
	r:SetColor(1,1,1,1)
	r:SetRadius(20*scale)
	r:SetRotation(math.random(360))
	r:SetPos(pos)
	r:SetPos2(pos)
	r:SetAngles(Vector(math.random(360),math.random(360),math.random(360)))
	r:Scale(Vector(scale,scale,scale))
	r:AddRenderFx(RF_LIGHTING_ORIGIN)
	r:AddRenderFx(RF_MINLIGHT)
	
	dir = vAdd(dir,vMul(rvel(10),.08))
	dir = vMul(dir,math.random(60,120)/60)

	local le = LocalEntity()
	le:SetAngleVelocity(Vector(math.random(-360,360),math.random(-360,360),math.random(-360,360)))
	le:SetPos(pos)
	le:SetRefEntity(r)
	le:SetVelocity(vMul(dir,300))
	le:SetStartTime(LevelTime())
	le:SetEndTime(LevelTime() + (8000) + math.random(1000,4000))
	le:SetType(LE_FRAGMENT)
	le:SetColor(1,1,1,1)
	le:SetRadius(r:GetRadius())
	le:SetCallback(LOCALENTITY_CALLBACK_TOUCH,function(le)
		if(!le:GetTable().stopped) then
			local ref = le:GetRefEntity()
			ref:Scale(Vector(scale,scale,scale))
			le:SetRefEntity(ref)
			le:SetAngleVelocity(Vector(math.random(-360,360),math.random(-360,360),math.random(-360,360)))
		end
	end)
	le:SetCallback(LOCALENTITY_CALLBACK_THINK,function(le)
		makeConfetti(le,scale)
	end)
	le:SetCallback(LOCALENTITY_CALLBACK_STOPPED,function(le)
		le:GetTable().stopped = true
		le:SetAngleVelocity(Vector(0,0,0))
	end)
	
	local re = le:GetRefEntity()
end

local function event(entity,event,pos,dir)
	if(event == EV_BULLET_HIT_WALL) then
		--PlaySound(explodeSound)
		--newParticle(pos,entity:GetByteDir(),gibs[math.random(1,#gibs)],.5)
	end
	if(event == EV_GIB_PLAYER) then
		PlaySound(explodeSound)
		for i=0, 10 do
			local origin = pos
			origin.x = origin.x + math.random(-10,10)
			origin.y = origin.y + math.random(-10,10)
			origin.z = origin.z + math.random(0,5)
			newParticle(pos,Vector(0,0,1),gibs[math.random(1,#gibs)],.4)
		end
		return true --Returning True Overrides
	end
end
hook.add("EventReceived","cl_suprise",event)