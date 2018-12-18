local matrix = require("includes/matrix")
local function identity()
	return matrix {{1,0,0},{0,1,0},{0,0,1}}
end

local function identityx(x,y,z)
	return matrix {{x},
				   {y},
				   {z}}
end
local rotation = identity()
local camera = identityx(0,0,0)

local function m_projection(e,d,out)
	out[1][1] = (d.x - e.x) * (e.z/d.z)
	out[2][1] = (d.y - e.y) * (e.z/d.z)
	return out
end

local function r() return math.random(-100,100) end
function VectorRandom() return Vector(r(),r(),r())/100 end

function vAdd(v1,v2)
	return v1 + v2
end

function vSub(v1,v2)
	return v1 - v2
end

function vMul(v1,v2)
	return v1 * v2
end

function vAbs(v)
	local out = Vector()
	out.x = math.abs(v.x)
	out.y = math.abs(v.y)
	out.z = math.abs(v.z)
	return out
end

function RotateEntity(ent,ang)
	local f,r,u = ent:GetAxis()
	
	r = RotatePointAroundVector(u,r,ang.y)
	f = CrossProduct(r,u)
	
	u = RotatePointAroundVector(r,u,ang.p)
	f = CrossProduct(r,u)
	
	local tu = u
	r = RotatePointAroundVector(f,r,ang.z)
	u = RotatePointAroundVector(f,tu,ang.z)
	
	ent:SetAxis(f,r,u)
end

function RotatePointAroundAxis(f,r,u,vec,ang)
	r = RotatePointAroundVector(u,r,ang.y)
	f = CrossProduct(r,u)
	
	u = RotatePointAroundVector(r,u,ang.p)
	f = CrossProduct(r,u)
	
	local tu = u
	r = RotatePointAroundVector(f,r,ang.z)
	u = RotatePointAroundVector(f,tu,ang.z)
	
	vec = vec * f
	vec = vec * r
	vec = vec * u
	return vec
end

if(CLIENT) then
	local w,h = 320,240
	function VectorToScreen(vec,refdef)
		if(vec == nil) then return end
		local out;
		if(refdef == nil) then
			out = render.ToScreen(vec);
		else
			out = render.ToScreen(refdef,vec);
		end
		out.z = -(1 - out.z)
		return out,(out.z <= 0)
		--[[local mat = identityx(vec.x,vec.y,vec.z)
		local out = Vector()
		
		local o = pos or _CG.viewOrigin
		local f = _CG.refdef.forward
		local r = _CG.refdef.right
		local u = _CG.refdef.up
		local fov = _CG.refdef.fov_x/2
		
		if(in_fov == 0) then
			fov = 0
		else
			if(in_fov) then fov = in_fov/2 end
			fov = ((3.58 - (fov/25.2))*5) - (3.58 + 1.79 + 1.79)
		end
		
		if(ang != nil) then
			f,r,u = AngleVectors(ang)
		end
		
		--local fov = 90
		--fov = fov / 2
		--fov = 1/math.tan(fov/2)
		
		camera = identityx(o.x,o.y,o.z)
		rotation = matrix {{-r.x,-r.y,-r.z},
						   {-u.x,-u.y,-u.z},
						   {-f.x,-f.y,-f.z},}
		
		if(mat ~= nil) then
			local mt = mat
			mt = (rotation * (mt - camera))
				
			if(fov ~= 0) then
				local d = {x=mt[1][1],y=mt[2][1],z=mt[3][1]}
				local e = {x=0,y=0,z=fov}
				mt = m_projection(e,d,mt)

				mt[1][1] = mt[1][1] * -1.12
				mt[2][1] = mt[2][1] * -1.5
				
				mt[1][1] = mt[1][1] + 1
				mt[2][1] = mt[2][1] + 1
				
				out.x = mt[1][1] * (w/2) + w/2
				out.y = mt[2][1] * (h/2) + h/2
			else
				out.x = mt[1][1]
				out.y = mt[2][1]
			end
			
			out.z = mt[3][1]
			
			mt = nil
		end
		
		local draw = true
		if(out.z > 0) then draw = false end
		
		return out,draw]]
	end
end

--[[function Vector(x,y,z)
	x = x or 0
	y = y or 0
	z = z or 0
	return {x=x,y=y,z=z}
end]]

function IsVector(v)
	local s,r = pcall(function()
		if(type(v) ~= "userdata") then return end
		if(v.x == nil) then return end
		return true
	end)
	if(r == true) then return true end
	return false
end

function XYZ(v)
	return v.x, v.y, v.z
end

function Vectorv(tab)
	return Vector(tab.x,tab.y,tab.z) --{x=tab.x,y=tab.y,z=tab.z}
end