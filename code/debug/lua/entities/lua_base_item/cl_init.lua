local flaretex = CreateShader("f",[[
{
	{
		map gfx/misc/flare.tga
		blendFunc add
		rgbGen entity
		alphaGen entity
	}
}
]])

local white = CreateShader("f",[[
{
	{
		map $whiteimage
		blendFunc add
		rgbGen entity
		alphaGen entity
	}
}
]])

local data = 
[[{
	{
		blendfunc add
		map $whiteimage
		alphaGen vertex
		rgbGen vertex
	}
}]]
local trailfx1 = CreateShader("f",data)

print("YO!!\n")

function ENT:GetColor(a)
	a = a or 1
	local col = self.net.color
	local r,g,b = 0*a,.2*a,.8*a
	if(col) then
		r,g,b = LongToColor(col)
	end
	return r,g,b,a
end

function ENT:PassTrail(trail) 
	--Pass the trail over to a local entity so the engine can render it out.
	local trail = self.trail
	if(trail == nil) then return end
	local le = LocalEntity()
	le:SetPos(trail:GetPos())
	le:SetRefEntity(trail)
	le:SetVelocity(Vector(0,0,0))
	le:SetStartTime(LevelTime())
	le:SetEndTime(LevelTime() + 4000)
	
	
	local r,g,b,a = trail:GetColor()
	le:SetColor(r,g,b,1)
	le:SetRadius(trail:GetRadius())
	le:SetType(LE_FRAGMENT)
	le:SetTrType(TR_STATIONARY)
	
	le:SetCallback(LOCALENTITY_CALLBACK_THINK,function(le)
		local r = le:GetRefEntity()
		r:SetPos(r:GetPos())
		le:SetRefEntity(r)
		le:SetNextThink(LevelTime() + 40)
	end)
end

function ENT:Removed()
	self:PassTrail()
end

function ENT:GetScale()
	local rem = self.net.remove
	local fade = self.net.fadetime
	self.start = self.start or LevelTime()
	local scale = 1
	local scalet = 0
	
	if(self.net.fadetime == 0) then
		return scale,scalet
	end
	
	if(self.start != nil and fade != nil) then
		scale = (LevelTime() - self.start) / (fade/2)
		if(scale > 1) then scale = 1 end
	else
		scale = 1
	end
	
	if(rem != nil and rem > LevelTime() and fade != nil) then
		scale = (rem - LevelTime()) / fade
		if(scale < 0) then scale = 0 end
		scalet = 1
	end
	return scale,scalet
end

function ENT:DrawFadeSprite(pos)
	local scale,scalet = self:GetScale()
	
	local flare = RefEntity()
	flare:SetType(RT_SPRITE)
	flare:SetPos(pos)
	flare:SetShader(flaretex)
	
	local r,g,b,a = self:GetColor()
	
	if(scale < 1) then
		flare:SetRadius(200 * scale*(1-scale))
		flare:SetColor(scale,scale*.8,scale*.1,1)
		if(scalet == 0) then
			flare:SetColor((1-scale)*r,(1-scale)*g,(1-scale)*b,1)
			flare:SetRadius(100 * (scale*(scale)))
		end
		flare:Render()
		
		flare:SetColor(scale,scale,scale*.5,1)
		flare:SetRadius(150 * scale*(1-scale))
		if(scalet == 0) then
			flare:SetColor(1-scale,1-scale,(1-scale)*.5,1)
			flare:SetRadius(100 * (scale*(scale)))
		end
		
		flare:Render()
	end
	
	local rate = 1000
	local t = (self.start + LevelTime()) % rate
	local a = 1 - (t/rate)
	a = (a * 2) - 1
	if(a < 0) then a = 0 end
	
	local r,g,b = self:GetColor()
	
	flare:SetColor(r*a,g*a,b*a,1)
	flare:SetRadius(30 * scale)
	flare:Render()
	
	flare:SetRadius(40 * scale)
	flare:Render()
end

function ENT:DrawTrail(pos)
	if(self.trail == nil) then
		local r,g,b = self:GetColor()
		local trail = RefEntity()
		trail:SetType(RT_TRAIL)
		trail:SetColor(r,g,b,1)
		trail:SetRadius(2)
		trail:SetShader(trailfx1)
		trail:SetTrailLength(36)
		trail:SetTrailFade(FT_COLOR)
		self.trail = trail
	end
	self.trail:SetPos(pos)
	self.trail:Render()
end

function ENT:DLight(pos)
	local scale,scalet = self:GetScale()
	local r,g,b,a = self:GetColor()
	--r = r + .2
	--g = g + .2
	--b = b + .2
	if(r > 1) then r = 1 end
	if(g > 1) then g = 1 end
	if(b > 1) then b = 1 end
	render.DLight(pos,r,g,b,(50 + math.cos(LevelTime()/200)*10)*scale)
	render.DLight(pos,1,1,1,(30 + math.cos(LevelTime()/200)*2)*scale)
end

function ENT:DrawModel(active)
	local pos = self.Entity:GetPos()
	local scale,scalet = self:GetScale()
	
	if(self.net.type == nil) then return end
	local model = util.GetItemModel(self.net.type)
	local mins,maxs = render.ModelBounds(model)
	
	--pos = pos + Vector(0,0,math.cos(LevelTime()/200)*4)
	
	pos = pos - Vector(0,0,mins.z * scale)
	--pos = pos + Vector(0,0,100)
	
	--if(scalet == 0) then scale = 1 end
	
	self.ref = RefEntity()
	self.ref:SetModel(model or self.CustomModel)
	self.ref:SetAngles(Vector(0,LevelTime()/6,0))
	self.ref:Scale(Vector(scale))
	
	local mins,maxs = render.ModelBounds(self.ref:GetModel())
	
	pos.z = pos.z + ((maxs.z - mins.z)/2) * (1 - scale)
	
	self.ref:SetPos(pos)
	
	if(active == false) then
		self.ref:SetColor(.1,.1,.1,1)
		self.ref:SetShader(white)
	end
	self.ref:Render()
	
	maxs.z = maxs.z / 2
	pos = pos + (maxs + mins) * scale
	
	if(active) then
		self:DLight(pos)
		self:DrawFadeSprite(pos)
		self:DrawTrail(pos)
	end
end

function ENT:Draw()
	if(self.net.draw == 1) then
		if(self.wasgone) then
			print("SCALE UP!\n")
			self.start = LevelTime()
			self.wasgone = nil
		end
		self:DrawModel(true)
	else
		--print("Draw Non-Active\n")
		self:DrawModel(false)
		self.wasgone = true
	end
end