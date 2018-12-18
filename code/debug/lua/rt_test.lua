render.SetupRenderTarget(1,512,512)

local data = 
[[{
	//sort nearest
	//cull disable
	{
		blendfunc blend
		//alphaFunc LT128
		map $rendertarget 1
		alphaGen vertex
		rgbGen vertex
		tcMod transform 1 0 0 -1 0 0
		//tcGen environment
	}
}]]
local renderTarget = CreateShader("f",data)

local data = 
[[{
	//sort nearest
	//cull disable
	{
		blendfunc blend
		//alphaFunc LT128
		map $rendertarget 1
		alphaGen vertex
		rgbGen vertex
		tcMod transform 1 0 0 -1 0 0
		//tcGen environment
	}
}]]
local renderTarget2 = CreateShader("f",data)

local data = 
[[{
	{
		blendfunc filter
		map $whiteimage
		alphaGen vertex
		rgbGen vertex
	}
}]]
local white = CreateShader("f",data)

local blood = LoadShader("dissolve")

local function riter(s,t)
	draw.Rect(-s,0,640,480,t)
	draw.Rect(s,0,640,480,t)
	draw.Rect(0,-s,640,480,t)
	draw.Rect(0,s,640,480,t)
	draw.Rect(s,s,640,480,t)
	draw.Rect(-s,-s,640,480,t)
	draw.Rect(-s,s,640,480,t)
	draw.Rect(s,-s,640,480,t)
end

function d2d()
	draw.SetColor(1,1,1,.3)
	draw.Rect(0,0,640,480,renderTarget2)

	draw.SetColor(1,1,1,.5)
	riter(1,renderTarget2)
	
	draw.SetColor(1,1,1,.3)
	riter(2,renderTarget2)
	
	draw.SetColor(1,1,1,.1)
	riter(3,renderTarget2)
	
	--riter(7)
	--riter(10)
	
	
	--[[draw.Rect(0,0,1,1)
	draw.Text(0,200,"YO",10,10)
	draw.Text(0,210,"YO",10,10)]]
end
hook.add("Draw2D","test8",d2d)


local mdl = LoadModel("*0")

local poly = Poly(renderTarget)

poly:AddVertex(Vector(-10,-10,-0),1,1,{1,1,1,1})
poly:AddVertex(Vector(-10,10,0),0,1,{1,1,1,1})
poly:AddVertex(Vector(10,10,0),0,0,{1,1,1,1})
poly:AddVertex(Vector(10,-10,0),1,0,{1,1,1,1})

poly:Split()

local reftest = poly:ToRef(false)

local function draw2D()
	render.CreateScene()

	--[[local ref = RefEntity()
	ref:AlwaysRender(true)
	ref:SetModel(mdl)
	ref:SetColor(1,1,1,1)
	ref:Scale(Vector(1,1,1))
	ref:Render()
	ref:SetShader(0)]]
	
	render.AddPacketEntities()
	render.AddLocalEntities()
	render.AddMarks()
	
	--local rh = util.Hand()
	--util.PlayerWeapon(LocalPlayer(),rh)
	
	local ang = VectorToAngles(_CG.refdef.angles)
	local ang2 = ang - Vector(90,0,0)
	local f,r,u = AngleVectors(ang)
	local org = _CG.refdef.origin + (f*20)
	
	--_CG.refdef.origin
	
	reftest:SetAngles(ang2)
	reftest:Scale(Vector(1.5,2,5))
	
	--[[reftest:SetColor(1,1,1,.92)
	reftest:SetShader(renderTarget)
	reftest:SetPos(org)
	reftest:Render()]]
	
	--[[reftest:SetPos(org + u/2)
	reftest:Render()
	reftest:SetPos(org - u/2)
	reftest:Render()
	reftest:SetPos(org + r/2)
	reftest:Render()
	reftest:SetPos(org - r/2)
	reftest:Render()]]
	
	local refdef = {}
	refdef.x = 0
	refdef.y = 0
	refdef.fov_x = _CG.refdef.fov_x
	refdef.fov_y = _CG.refdef.fov_y
	refdef.width = 640
	refdef.height = 480
	refdef.origin = _CG.refdef.origin
	refdef.angles = VectorToAngles(_CG.refdef.angles)
	refdef.flags = 0
	refdef.renderTarget = 1
	refdef.isRenderTarget = true
	render.RenderScene(refdef)
end
hook.add("DrawRT","test8",draw2D)