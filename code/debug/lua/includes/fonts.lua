local function loadINI(f)
	local file = io.open("C:/Quake3/baseq3/" .. f, "r")
	if(file != nil) then
		local lines = 0
		local content = ""
		for line in file:lines() do
			content = content .. line .. "\n"
		end
		file:close()
		return content
	else
		error("File not found: '" .. f .. "'.")
		return 
	end
	local txt = packRead(f)
	if(txt != nil) then
		error("File not found: '" .. f .. "'.")
		return txt
	end
	return 
end

local FontT = {}

function FontT:DrawChar(x,y,ch,w,h)
	local t = string.ToTable(ch)
	if(t[1]) then
		local b = string.byte(t[1])+1
		self.sprite:SetFrame(b-1)
		x = x + (self.spacings[b]+self.kern)*(w/40)
		self.sprite:SetPos(x,y+(h/1.25))
		self.sprite:SetSize(w,h)
		self.sprite:DrawAnim()
		x = x + (self.spacings[b]+self.kern)*(w/40)
		return x
	else
		return 0
	end
end

function FontT:Draw(x,y,str,w,h)
	for k,v in pairs(string.ToTable(str)) do
		local b = string.byte(v)+1
		self.sprite:SetFrame(b-1)
		x = x + (self.spacings[b]+self.kern)*(w/40)
		self.sprite:SetPos(x,y+(h/1.25))
		self.sprite:SetSize(w,h)
		self.sprite:DrawAnim()
		x = x + (self.spacings[b]+self.kern)*(w/40)
	end
	return x
end

function FontT:GetWidth(str,w)
	local x = 0
	for k,v in pairs(string.ToTable(str)) do
		local b = string.byte(v)+1
		x = x + ((self.spacings[b]+self.kern)*(w/40))*2
	end
	return x
end

function FontT:SetKern(k)
	self.kern = tonumber(k)
end

function FontT:GetSpacings()
	return self.spacings
end

function FontT:GetTitle()
	return self.title
end

function FontT.__index(str)
	print(str .. "\n")
end

function FontT.__call(self,...)
	if(type(arg[1]) == "number") then
		self:Draw(unpack(arg))
	else
		print("call: " .. arg[1] .. "\n")
	end
end

function LoadFont(ini,shadefunc)
	local f = loadINI(ini)
	if(!f) then f = loadINI(ini .. ".ini") end
	if(!f) then return nil end
	local texture = string.sub(ini,0,string.len(ini) - 3) .. "tga"
	util.ClearImage(texture)
	local data = 
	[[{
		{
			map ]] .. texture .. [[
			blendFunc blend
			rgbGen vertex
			alphaGen vertex
		}
	}]]
	if(shadefunc and type(shadefunc) == "function") then
		local b,e = pcall(shadefunc,texture)
		if(b) then
			if(e ~= nil) then
				data = tostring(e)
			end
		end
	end
	
	local tab = string.Explode("\n",f)
	local shader = CreateShader("f",data)
	local title = tab[1]
	local sprite = AnimSprite(shader,16,16,30,0)
	local spacings = {}
	for k,v in pairs(tab) do
		if(k > 1) then
			local eq = string.find(v,"=")
			if(eq) then
				local index = string.sub(v,0,eq-1)
				local value = string.sub(v,eq+1,string.len(v))
				spacings[tonumber(index)+1] = tonumber(value)
			end
		end
	end
	tab = nil
	
	local o = {}
	
	setmetatable(o,FontT)
	FontT.__index = FontT
	
	o.spacings = spacings
	o.title = title
	o.shader = shader
	o.sprite = sprite
	o.kern = 5
	
	return o
end