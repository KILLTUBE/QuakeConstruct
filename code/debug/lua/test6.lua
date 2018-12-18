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

local function makeRef(r,g,b)
	local ref = RefEntity()
	ref:SetColor(r,g,b,1)
	ref:SetType(RT_TRAIL)
	ref:SetShader(trailfx1)
	ref:SetRadius(1)
	ref:SetTrailLength(150)
	ref:SetTrailFade(FT_COLOR)
	return ref
end

local w = 110
local h = 90
local minx = -w/2
local maxx = w/2

local miny = -h/2
local maxy = h/2
local cx = minx
local ref = makeRef(0,1,0)
local oldref = nil
local ty = 0
local cy = 0
local cy2 = 0
local lasthp = 0
local dm = 0
local brt = 1

local function getHP()
	local hp = _CG.stats[STAT_HEALTH]
	local hc = (hp / LocalPlayer():GetInfo().handicap) * 100
	return hc
end

local function d2d()
	local hp = getHP()/100
	
	if(hp > 1) then hp = 1 end
	if(hp < 0) then hp = 0 end
	
	local hue = hp*100
	local cr,cg,cb = hsv(hue*1.1,1,1)
	if(hp < 0) then hp = 0 end
	for i=1,6 do
		if(cy < ty) then
			cy = cy + 1
		elseif(cy > ty) then
			cy = cy - 1
		end
	end
	cx = cx + 1.5
	if(cx > maxx*2) then 
		cx = minx*2
		oldref = ref
		ref = makeRef(cr,cg,cb)
	end
	
	if(lasthp > hp) then
		ref:SetColor(cr,cg,cb)
		dm = math.random(-40,40)
	elseif(lasthp < hp) then
		ref:SetColor(cr,cg,cb)
	end
	
	local f = ((cx - minx) / (maxx*2)) % (.7 - (.4*(1-hp)))
	if(f > .28 and f < .34) then
		ty = -20
		brt = .4
	elseif(f > .4 and f < .46) then
		ty = 30
	elseif(f > .5 and f < .55) then
		ty = -30
	elseif(f > .6 and f < .65) then
		ty = 10
	else
		ty = 0
	end
	
	cy2 = cy2 + (cy - cy2)*.7
	dm = dm + (0 - dm)*.2
	brt = brt + (0 - brt)*.1
	
	draw.SetColor(cr*brt,cg*brt,cb*brt,.6)
	draw.Rect(10,10,200,100)

	render.CreateScene()
	
	local r,g,b = ref:GetColor()
	ref:SetRadius(1)
	ref:SetPos(Vector(.1,cx/2,((-cy2*hp)*1.5) + dm))
	ref:Render()
	
	ref:SetColor(r/2,g/2,b/2)
	ref:SetRadius(2)
	ref:Render()
	ref:SetColor(r,g,b)
	
	if(oldref != nil) then
		oldref:SetRadius(1)
		oldref:SetPos(oldref:GetPos())
		oldref:Render()
		
		local r,g,b = oldref:GetColor()
		
		oldref:SetColor(r/2,g/2,b/2)
		oldref:SetRadius(2)
		oldref:Render()
		oldref:SetColor(r,g,b)
	end
	
	local refdef = {}
	refdef.x = 10
	refdef.y = 10
	refdef.fov_y = 25
	refdef.width = 200
	refdef.height = 100
	refdef.flags = 1
	refdef.angles = Vector(0,180,0)
	refdef.origin = Vector(200,0,0)
	
	refdef.zNear = 0
	refdef.zFar = 1000

	render.RenderScene(refdef)
	lasthp = hp
end
hook.add("Draw2D","test6",d2d)