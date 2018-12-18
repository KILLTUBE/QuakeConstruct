local flare = LoadShader("flareShader")
local barrel = LoadModel("models/players/skaarj/lower.md3")
local sh = [[{
	GLSL GLSL/falloff
	polygonoffset
	//deformVertexes wave 10000 sin 1 1 0.9 0
	//cull none
	sort nearest
	{
		map gfx/charged2.jpg
		blendFunc blend
		rgbGen entity
		alphaGen entity
		tcMod scale .1 .1
		tcMod turb 0 0.02 0.75 0.1
		//tcMod scroll 1 0
	}
	{
		map gfx/charged2.jpg
		blendFunc add
		rgbGen entity
		alphaGen entity
		tcMod scale .1 .1
		tcMod turb 0 0.08 0.25 0.1
		//tcMod scroll 4 0
	}
}]]
sh = CreateShader("f",sh)

local function drawShader(r,cr,cg,cb,ca)
	cr = cr or 0
	cg = cg or 0
	cb = cb or 0
	ca = ca or 1
	r:SetShader(sh)
	--r:SetColor(.2,.4,1,.2)
	r:SetColor(cr,cg,cb,ca)
	r:Render()
end

local function drawPlayer(pl)
	pl:CustomDraw(true)
	local legs,torso,head = LoadPlayerModels(pl)
	
	legs:SetPos(pl:GetPos())
	
	util.AnimatePlayer(pl,legs,torso)
	util.AnglePlayer(pl,legs,torso,head)
	
	torso:PositionOnTag(legs,"tag_torso")
	head:PositionOnTag(torso,"tag_head")
	
	legs:Render()
	torso:Render()
	head:Render()
	
	drawShader(legs)
	drawShader(torso)
	drawShader(head)
end

local tr = PlayerTrace()
local function Draw3D()
	
	local r = RefEntity()
	r:SetSkin(3)
	r:SetPos(tr.endpos)
	r:SetAngles(VectorToAngles(tr.normal))
	r:SetModel(barrel)
	r:SetColor(.2,.4,1,.6)
	r:Scale(Vector(6))
	--r:Render()
	r:SetShader(sh)
	--r:Render()
	--render.SetBaseGLSL("GLSL/rttest")
	
	--[[local tab = GetEntitiesByClass("player")
	for k,v in pairs(tab) do
		drawPlayer(v)
	end]]
end
hook.add("Draw3D","cl_glsl",Draw3D)

local function drawTeamShader(ref,team)
	if(team == TEAM_BLUE) then
		drawShader(ref,.1,.1,1,.1)
	elseif(team == TEAM_RED) then
		drawShader(ref,1,.1,.1,.1)
	else
		drawShader(ref,1,1,.1,.1)
	end
end

local function DrawModel(ref,ent,part,team)
	if(part ~= 0) then
		drawTeamShader(ref,team)
	end
	--return true
end
hook.add("DrawPlayerModel","cl_glsl",DrawModel)

local gibs = {
	LoadModel("models/gibs/abdomen.md3"),
	LoadModel("models/gibs/arm.md3"),
	LoadModel("models/gibs/chest.md3"),
	LoadModel("models/gibs/fist.md3"),
	LoadModel("models/gibs/foot.md3"),
	LoadModel("models/gibs/forearm.md3"),
	LoadModel("models/gibs/intestine.md3"),
	LoadModel("models/gibs/leg.md3"),
	--LoadModel("models/gibs/skull.md3"),
}

local skull = LoadModel("models/gibs/skull.md3")
local gibvel = 250
local function launchGib(origin, velocity, model, team, skin )
	local le = LocalEntity()
	local r = RefEntity()
	
	r:SetModel(model)
	if(skin ~= nil) then r:SetSkin(skin) end
	
	if(skin ~= nil) then
		r:Scale(Vector(2,2,2))
	end
	
	le:SetBounceFactor(0.6)
	le:SetRefEntity(r)
	le:SetPos(origin)
	le:SetVelocity(velocity)
	le:SetStartTime(LevelTime())
	le:SetEndTime(LevelTime() + 5000 + math.random(0,3000))
	le:SetType(LE_FRAGMENT)
	le:SetAsGib(true)
	
	if(skin == nil) then
	le:SetCallback(LOCALENTITY_CALLBACK_RENDER,function(le)
		local ref = le:GetRefEntity()
		drawTeamShader(ref,team)
	end)
	end
end

launchGib(tr.endpos, tr.normal*250, gibs[1], TEAM_RED)
local explodeSound = LoadSound("sound/player/gibsplt1.wav")
local function crand()
	return math.random(-100,100)/100
end
local function event(entity,event,pos,dir)
	if(event == EV_GIB_PLAYER) then
		local team = entity:GetInfo().team
		for _,v in pairs(gibs) do
			local vel = Vector()
			vel.x = crand()*gibvel
			vel.y = crand()*gibvel
			vel.z = gibvel + crand()*gibvel
			launchGib(pos,vel,v,team)
		end

		local vel = Vector()
			vel.x = crand()*gibvel/5
			vel.y = crand()*gibvel/5
			vel.z = gibvel + crand()*gibvel
		
		local mdl = entity:GetInfo().headModel or skull
		local skin = entity:GetInfo().headSkin
		PlaySound(entity,explodeSound)
		launchGib(pos,vel + Vector(0,0,gibvel/2),mdl,team,skin)
		return true
	end
end
hook.add("EventReceived","cl_glsl",event)