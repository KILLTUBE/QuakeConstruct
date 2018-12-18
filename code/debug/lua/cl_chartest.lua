
local charmap = LoadShader("gfx/2d/bigchars")
local flare = LoadShader("flareShader")

local poly = Poly(charmap)
local off = Vector(672,1872,22)

local v1 = Vector(-1,-1,0) * 10
local v2 = Vector(1,-1,0) * 10
local v3 = Vector(1,1,0) * 10
local v4 = Vector(-1,1,0) * 10

poly:AddVertex(v1,0,0,{1,1,1,1})
poly:AddVertex(v2,1,0,{1,1,1,1})
poly:AddVertex(v3,1,1,{1,1,1,1})
poly:AddVertex(v4,0,1,{1,1,1,1})

poly:Split()

local function rpoint(pos)
	local s = RefEntity()
	s:SetType(RT_SPRITE)
	s:SetPos(pos)
	s:SetColor(1,1,1,1)
	s:SetRadius(8)
	s:SetShader(flare)
	return s
end

local function drawChar(verts,ch,pos,u,r,w,h)
	local v1 = verts[1]
	local v2 = verts[2]
	local v3 = verts[3]
	local v4 = verts[4]
	
	--pos.z = pos.y
	pos = pos * -1
	
	local row,col,s = util.CharData(ch)
	v1[2].u = col
	v1[2].v = row
	
	v2[2].u = col + s
	v2[2].v = row
	
	v3[2].u = col + s
	v3[2].v = row + s
	
	v4[2].u = col
	v4[2].v = row + s
	
	v1[1] = pos
	v2[1] = pos - ((r * w))
	v3[1] = pos - ((r * w) + (u * h))
	v4[1] = pos - (u * h)
	
	poly:Render(true)
end

local function clamp(v,b,t) 
	if(v > t) then v = t end
	if(v < b) then v = b end
	return v
end

function drawString(str,pos,ang,w,h,halign,valign,kern)
	if(str == nil or str == "" or type(str) != "string") then return end
	if(string.find(str,"\n")) then
		for _,ch in pairs(string.Explode( "\n", str )) do
			drawString(ch,pos,ang,w,h,halign,valign,kern)
			pos = pos - Vector(0,0,h)
		end
		return
	end
	kern = kern or 0
	halign = clamp(halign or 0,0,2)
	valign = clamp(valign or 0,0,2)
	poly:SetOffset(pos)
	local f,r,u = AngleVectors(ang)
	local verts = poly:GetVerts()
	local p = (r * -(string.len(str)*(((w + (kern/1.5))/2) * halign)))
	p = p - (u * ((h/2) * valign))
	w = w + kern
	
	for k,ch in pairs(string.ToTable(str)) do
		if(ch == "\n") then
			return
		else
			w = w - kern
			drawChar(verts,ch,p,u,r,w,h)
			w = w + kern
			p = p + (r * w)
		end
	end
end

function draw3d()
	local ang = Vector(0,0,0)
	local vang = VectorToAngles(_CG.viewAngle)
	
	ang.y = vang.y + 180

	local tab = GetEntitiesByClass("player")
	for k,v in pairs(tab) do
		local name = v:GetInfo().name
		if(name != nil) then
			local pos = v:GetPos()
			local hp = v:GetInfo().health
			if(hp > 0) then
				pos = pos + Vector(0,0,50)
			else
				name = name .. "\n<dead>"
			end
			if(hp > -39) then
				drawString(name,pos,ang,5,8,1,1)
				--[[for _,ch in pairs(string.Explode( "\n", name )) do
					drawString(ch,pos,ang,5,8,1,1)
					pos = pos - Vector(0,0,8)
				end]]
			end
		end
	end
	
	
	
	rpoint(Vector(64,64,64)):Render()
end
hook.add("Draw3D","cl_chartest",draw3d)

function draw2d()
	--draw.Rect(0,0,200,200,charmap,fcol,frow,fcol+size,frow+size)
end
hook.add("Draw2D","cl_chartest",draw2d)