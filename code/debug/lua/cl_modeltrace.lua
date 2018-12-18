local size = 1/256
local v1 = Vector(size,size,size)
local v2 = Vector(size,size,size)
local data = 
[[{
	cull back
	deformVertexes wave 1000 sin 12 0 0 0
	polygonoffset
	{
		blendFunc add
		map gfx/2d/screenblur1.tga //$whiteimage
		rgbGen entity
		//tcGen environment
		//tcGen vector ( ]]..v1.x..[[ ]]..v1.y..[[ ]]..v1.z..[[ ) ( ]]..v1.x..[[ ]]..v1.y..[[ ]]..v1.z..[[ ) 
	}
}]]
local shd = "textures/base_wall/bluemetal1b_chrome"
--shd = "textures/base_wall/glass_frame"
--local outline = LoadShader(shd)--CreateShader("f",data)

data = 
[[{
	//deformVertexes wave 1000 sin 22 0 0 0
	{
		map $whiteimage
		blendFunc blend
		rgbGen entity
		alphaGen entity
	}
}]]
local plaincolor = CreateShader("f",data)

local chrome_data = 
[[{
	cull none
	//deformVertexes autosprite
	//deformVertexes wave 30 sin 22 1 0 1
	//deformVertexes bulge 12 12 1
	//deformVertexes normal 12 .2
	{
		map textures/base_wall/chrome_env2.tga
		rgbGen vertex
		alphaGen vertex
		//tcGen environment
		tcmod scale .25 .25
	}
}]]
local outline = CreateShader("f2",chrome_data)
local flare = LoadShader("flareShader")

local mdl = LoadModel("models/misc/trailtest.md3")
local t = 0
local anim = Animation(0,100,15)
local vec = PlayerTrace().endpos

anim:SetType(ANIM_ACT_LOOP_LERP)
anim:Play()

local function used(s)
	if(s) then
		vec = PlayerTrace().endpos
	end
end
hook.add("Use","cl_modeltrace",used)
	
local function newParticle(pos,indir)
	scale = scale or 1
	
	local ref = RefEntity()
	ref:SetColor(1,1,1,1)
	ref:SetType(RT_SPRITE)
	ref:SetShader(flare)
	ref:SetRotation(math.random(360))
	ref:SetPos(pos)
	ref:SetRadius(4)
	ref:Render()

	local le = LocalEntity()
	le:SetPos(pos)
	le:SetRefEntity(ref)
	le:SetStartTime(LevelTime())
	le:SetEndTime(LevelTime() + (800) + math.random(300,800))
	le:SetType(LE_FRAGMENT)
	le:SetVelocity(indir*10)
	le:SetColor(1,1,1,1)
	le:SetEndColor(0,0,0,0)
	le:SetRadius(5)
	le:SetEndRadius(0)
end

local poly = Poly(outline)

poly:AddVertex(Vector(0,0,0),0,0,{1,1,1,1})
poly:AddVertex(Vector(1,0,0),1,0,{1,1,1,1})
poly:AddVertex(Vector(1,1,0),1,1,{1,1,1,1})
poly:AddVertex(Vector(0,1,0),0,1,{1,1,1,1})

poly:Split()

poly:AddVertex(Vector(1,0,0),0,0,{1,1,1,1})
poly:AddVertex(Vector(2,0,0),1,0,{1,1,1,1})
poly:AddVertex(Vector(2,1,0),1,1,{1,1,1,1})
poly:AddVertex(Vector(1,1,0),0,1,{1,1,1,1})

poly:Fuse()

local reftest = poly:ToRef(false)

function d3d()
	
	local svec = vec.x .. " " .. vec.y .. " " .. vec.z
	local ref = RefEntity()
	local mins,maxs = render.ModelBounds(mdl)
	local vnorm = _CG.refdef.forward

	local r,g,b = hsv(LevelTime()/10,.3,1)
	ref:AlwaysRender(true)
	ref:SetModel(mdl)
	ref:SetPos(vec + Vector(0,0,10))
	ref:SetColor(1,1,1,1)
	ref:Scale(Vector(1,1,1))
	--ref:SetShader(outline)
	--ref:SetAngles(Vector(0,LevelTime()/5,0))
	
	//anim:SetRef(ref)
	//anim:Animate()
	
	reftest:AlwaysRender(true)
	reftest:SetPos(vec + Vector(0,0,10))
	reftest:SetColor(1,1,1,1)
	reftest:SetAngles(Vector(0,0,0))
	reftest:Scale(Vector(20,20,1))
	reftest:SetShader(outline)
	reftest:Render()
	
	//poly:SetOffset(vec + Vector(0,0,10))
	//poly:Render()
	
	
	--ref:Render()
	
	--local pos,_,_,f = GetTag(ref,"tag_left")
	--newParticle(pos,f*10)
	
	--local pos2,_,_,f2 = GetTag(ref,"tag_right")
	--newParticle(pos2,f2*30)
end
hook.add("Draw3D","cl_modeltrace",d3d)