local vorigin = Vector()
local vright = Vector()
local vdown = Vector()
local vdiag = Vector()
local vforward = Vector()
local on = false

local texture = LoadShader("gfx/anim_numbers")

local function drawIt()
	draw.SetColor(1,1,1,.5)
	
	draw.RectRotated(100,100,20,170,nil,LevelTime()/12,0,0,.2,.2)
	draw.RectRotated(100,100,20,170,texture,LevelTime()/12,0,0,.2,.2)
	
	--[[draw.Rect(10,10,620,460)
	
	draw.SetColor(1,1,1,.5)
	draw.Rect(20,20,600,420/2,texture,0,0,.2,.2)
	
	draw.Rect(20,20+460/2,600,420/2,texture)]]
end

local function d3d()
	if(!on) then return end

	--render.Quad(vorigin,vright,vdiag,vdown,nil,1,1,1,.2)
	
	draw.Start3D(vorigin,vright,vdown,vforward)
	
	--drawIt()
	
	--DrawXHUD()
	
	draw.SetColor(1,1,1,.5)
	draw.Rect(0,0,640,480)
	
	draw.SetColor(0,0,0,1)
	draw.Rect(50,50,100,100)
	
	DrawUI()
	
	draw.End3D()
end
hook.add("Draw3D","cl_3drect",d3d)

local function d2d()
	--drawIt()
end
hook.add("Draw2D","cl_3drect",d2d)

local function use(s)
	local pt = PlayerTrace()
	local pos = pt.endpos
	local normal = pt.normal
	local f,r,u = AngleVectors(VectorToAngles(normal))
	
	local w = 40
	local h = 120
	
	pos = pos + f * 10
	
	vorigin = pos + ((r*w) + (u*h))
	vright = pos - ((r*w) - (u*h))
	vdown = pos - ((u*h) - (r*w))
	vdiag = pos - ((r*w) + (u*h))
	vforward = Vector(0,0,0)
	on = true
end
hook.add("Use","cl_3drect",use)