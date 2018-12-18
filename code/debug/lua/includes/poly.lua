local PolyT = {}

function PolyT:Init()
	self.set = {}
	self.verts = {}
	self.flipped = {}
	self.offset = Vector()
	self.shd = nil
	self.splitted = false
end

function PolyT:Fuse(savemap)
	local ids = {}
	local buffer = {}
	for i=1, #self.set do
		for v=1, #self.set[i][1] do
			table.insert(buffer,self.set[i][1][v])
			ids[#buffer] = {i,v,1}
			
			--table.insert(buffer,self.set[i][2][v])
			--ids[#buffer] = {i,v,2}
		end
	end

	--save = table.Copy(buffer)
	
	buffer = table.Fuse(buffer,function(a,b) return a[1] == b[1] end)
	
	for k,v in pairs(buffer) do
		local id = ids[k]
		local set = id[1]
		local vert = id[2]
		local fl = id[3]
		
		--local vert = self.set[set][fl][vert]
		self.set[set][fl][vert] = v
	end
	
	--table.Flip(self.verts)
end

function PolyT:VClamp(v)
	if(v > 1) then v = 1 end
	if(v < 0) then v = 0 end
	return v
end

function PolyT:ColorCheck(c)
	c = self:VClamp(c)
	return c * 255
end

function PolyT:AddVertex(pos,u,v,color)
	r = color.r or color[1]
	g = color.g or color[2]
	b = color.b or color[3]
	a = color.a or color[4]

	u = self:VClamp(u)
	v = self:VClamp(v)
	
	r = self:ColorCheck(r)
	g = self:ColorCheck(g)
	b = self:ColorCheck(b)
	a = self:ColorCheck(a)
	
	table.insert(self.verts,{pos,Vector(u,v),r,g,b,a})
	if(#self.verts > 1) then
		self.flipped = table.Flip(self.verts)
	else
		self.flipped = self.verts
	end
	self.splitted = false
end

function PolyT:Split()
	table.insert(self.set,{self.verts,self.flipped})
	self.verts = {}
	self.flipped = {}
	self.splitted = true
end

function PolyT:GetVerts()
	local buffer = {}
	for i=1, #self.set do
		for v=1, #self.set[i][1] do
			table.insert(buffer,self.set[i][1][v])
		end
	end
	
	return buffer
end

function PolyT:ClearVerts()
	self.set = {}
	self.verts = {}
	self.flipped = {}
	self.splitted = false
end

function PolyT:Copy()
	local ids = {}
	local buffer = {}
	for i=1, #self.set do
		for v=1, #self.set[i][1] do
			table.insert(buffer,self.set[i][1][v])
			ids[#buffer] = {i,v,1}
		end
	end

	local cp = table.Copy(self)

	for k,v in pairs(buffer) do
		local id = ids[k]
		local set = id[1]
		local vert = id[2]
		local fl = id[3]
		
		local nv = {Vectorv(v[1]),Vectorv(v[2]),v[3],v[4],v[5],v[6]}
		
		--local vert = self.set[set][fl][vert]
		cp.set[set][fl][vert] = nv
	end	
	
	return cp
end

function PolyT:SetOffset(o)
	self.offset = o
end

function PolyT:SetShader(s)
	if(s == nil or type(s) == "number") then
		self.shd = s
	end
end

function PolyT:GetShader()
	return self.shd
end

function PolyT:Render(flipped)
	if(!self.splitted) then
		self:Split()
	end

	for i=1, #self.set do
		local s = self.set[i]
		if(type(s) == "table") then
			if(#s[1] >= 3) then
				render.DrawPoly(s[1],self.shd,self.offset)
				if(flipped) then
					render.DrawPoly(s[2],self.shd,self.offset)
				end
			else
				error("Not enough vertices in set[" .. i .. "], " .. #s .. ".\n")
			end
		end
	end
end

function PolyT:ToRef(flip)
	for i=1, #self.set do
		local s = self.set[i]
		if(type(s) == "table") then
			if(#s[1] >= 3) then
				local ref = RefEntity()
				ref:SetType(RT_POLY)
				if(!flip) then
					render.PolyRef(s[1],ref)
				else
					render.PolyRef(s[2],ref)
				end
				return ref
			else
				error("Not enough vertices in set[" .. i .. "], " .. #s .. ".\n")
			end
		end
	end
end

function Poly(tex)
	local o = {}

	setmetatable(o,PolyT)
	PolyT.__index = PolyT
	
	o:Init()
	o:SetShader(tex)
	o.Init = nil
	
	return o;
end