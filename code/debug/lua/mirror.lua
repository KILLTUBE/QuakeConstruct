render.SetupRenderTarget(1,512,512)
render.SetupRenderTarget(0,512,512)

local portal1 = {}
local portal2 = {}

portal1.pair = portal2
portal2.pair = portal1

local nxtPortal = 0

local data = 
[[{
	sort nearest
	cull disable
	{
		map $rendertarget 0
		tcMod transform 1 0 0 -1 0 0
	}
}]]
local rt_0 = CreateShader("rendertarget1",data)

local data = 
[[{
	sort nearest
	cull disable
	{
		map $rendertarget 1
		tcMod transform 1 0 0 -1 0 0
	}
}]]
local rt_1 = CreateShader("rendertarget2",data)

local data = 
[[{
	sort nearest
	cull disable
	{
		map $whiteimage
	}
}]]
local noportal = CreateShader("noportal",data)


local poly = Poly(rt_1)

poly:AddVertex(Vector(-10,-10,-0),1,1,{1,1,1,1})
poly:AddVertex(Vector(-10,10,0),0,1,{1,1,1,1})
poly:AddVertex(Vector(10,10,0),0,0,{1,1,1,1})
poly:AddVertex(Vector(10,-10,0),1,0,{1,1,1,1})

poly:Split()

local reftest = poly:ToRef(false)

local function drawPortal(portal)
	if(portal.on) then
		reftest:SetAngles(VectorToAngles(portal.normal) - Vector(90,0,180))
		reftest:SetPos(portal.pos + portal.normal)
		reftest:Scale(Vector(3,3,3))
		reftest:SetShader(noportal)
		
		if(portal.pair and portal.pair.on) then
			reftest:SetShader(portal.rtshader)
		end
		
		reftest:SetColor(1,1,1,1)
		reftest:Render()
	end
end

function d3d()
	drawPortal(portal1)
	drawPortal(portal2)
end
hook.add("Draw3D","mirror",d3d)

local mdl = LoadModel("*0")

local function drawPlayer(pl)
	local legs,torso,head = LoadPlayerModels(pl)
	legs:SetPos(pl:GetPos())
	
	util.AnimatePlayer(pl,legs,torso)
	util.AnglePlayer(pl,legs,torso,head)

	--torso:Scale(Vector(1.2,1.2,1.2))
	
	torso:PositionOnTag(legs,"tag_torso")
	head:PositionOnTag(torso,"tag_head")
	
	
	--head:Scale(Vector(2,2,2))
	
	legs:Render()
	torso:Render()
	head:Render()

	util.PlayerWeapon(pl,torso)
end

local function drawMirrorRT(index,mirror_pos,mirror_normal)
	render.CreateScene()

	local ref = RefEntity()
	ref:AlwaysRender(true)
	ref:SetModel(mdl)
	ref:SetColor(1,1,1,1)
	ref:Scale(Vector(1,1,1))
	ref:Render()
	ref:SetShader(0)
	
	drawPlayer(LocalPlayer())
	
	render.AddPacketEntities()
	render.AddLocalEntities()
	render.AddMarks()
	
	if(portal1.rt == index) then
		drawPortal(portal1)
	end
	
	if(portal2.rt == index) then
		drawPortal(portal2)
	end
	
	local ang = VectorToAngles(mirror_normal)
	local mpos = mirror_pos + mirror_normal

	local refdef = {}
	refdef.x = 0
	refdef.y = 0
	refdef.fov_x = 90
	refdef.fov_y = 90
	refdef.width = 512
	refdef.height = 512
	refdef.origin = mpos
	refdef.angles = ang
	refdef.flags = 1
	refdef.renderTarget = index
	refdef.isRenderTarget = true
	render.RenderScene(refdef)
end

local function use(s)
	local pt = PlayerTrace()
	local mirpos = pt.endpos
	local mirnormal = pt.normal
	
	if(!s) then return end
		
	if(nxtPortal == 0) then
		portal1.on = true
		portal1.pos = mirpos
		portal1.normal = mirnormal
		portal1.rt = 0
		portal1.rtshader = rt_0
		nxtPortal = 1
	elseif(nxtPortal == 1) then
		portal2.on = true
		portal2.pos = mirpos
		portal2.normal = mirnormal
		portal2.rt = 1
		portal2.rtshader = rt_1
		nxtPortal = 0
	end
end
hook.add("Use","mirror",use)

local function draw2D()
	if(portal1.on and portal1.pair and portal1.pair.on) then
		drawMirrorRT(portal1.rt,portal1.pair.pos,portal1.pair.normal)
	end
	if(portal2.on and portal2.pair and portal2.pair.on) then
		drawMirrorRT(portal2.rt,portal2.pair.pos,portal2.pair.normal)
	end
end
hook.add("DrawRT","mirror",draw2D)