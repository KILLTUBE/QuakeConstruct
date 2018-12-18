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
	cull disable
	{
		map $whiteimage
		blendFunc add
		rgbGen entity
		alphaGen entity
	}
}
]])

local jshd = CreateShader("f",[[{
     nomipmaps
     cull disable
     {
		map models/mapobjects/jets/jet_1.tga
                blendFunc add
                tcmod scale  .7  .7
                tcmod scroll 6 0
                rgbGen entity
	 }
}]])

local regen = LoadSound("sound/items/regen.wav")
local restock = LoadSound("sound/items/wearoff.wav")

function ENT:Initialized()
	self.model = LoadModel("models/mapobjects/jets/jets01.md3")
	self.model2 = LoadModel("models/powerups/health/large_cross.md3")
	self.planemodel = LoadModel("models/geom/plane.md3")
	self.scaletime = 0
	self.resettime = 0
	self.rstart = 0
end

function ENT:Scale()
	local s = .05
	if(self.scaletime > LevelTime()) then
		local dt = (self.scaletime - LevelTime()) / 200
		s = s + (1 - s)*dt
	end
	return s
end

function ENT:ResetDT()
	if(self.resettime < LevelTime()) then return 1 end
	return 1 - (self.resettime - LevelTime()) / self.net.delay
end

function ENT:RestockDT()
	return (LevelTime() - self.rstart) / self.net.restock
end

function ENT:Restocking()
	if(self.restocking) then return true end
end

function ENT:Color()
	local r = 1
	local g = 1
	local b = 1
	
	if(self.resettime > LevelTime()) then
		local dt = self:ResetDT()
		r = 0
		g = dt/2
		b = dt
	else
		local rem = (self.net.remain/self.net.hp)
		b = rem
		g = g - (1 - math.sqrt(rem))
		r = 0.2
		r = 1 - rem
	end
	
	if(self:Restocking()) then 
		r = .5
		b = 0
		g = 0
	end

	return r,g,b,1
end

function ENT:DrawModel(active)
	local pos = self.Entity:GetPos() + Vector(0,0,10)
	local rdt = 1 - self:ResetDT()
	local rotate = LevelTime()/6
	
	local eye = _CG.viewOrigin
	if(eye ~= nil) then	
		local dv = VectorNormalize(eye - pos)
		local angles = VectorToAngles(dv)
		
		rotate = angles.y
	end
	
	self.ref = RefEntity()
	self.ref:SetShader(jshd)
	self.ref:SetColor(.1*rdt,1 * rdt,.8*rdt)
	self.ref:SetPos(pos)
	self.ref:SetModel(self.model)
	self.ref:SetAngles(Vector(0,rotate+90,0))
	self.ref:Scale(Vector(1,1,self:Scale()))
	
	self.ref:Render()
	
	self.ref:SetColor(self:Color())
	
	local s = .2 + self:Scale()/2.5
	
	self.ref:Render()
	
	self.ref:Scale(Vector(1.4,1.4,-.8))
	self.ref:SetPos(pos-Vector(0,0,5))
	self.ref:Render()
	
	self.ref:Scale(Vector(.5,.5,1 + s))
	self.ref:Render()
	
	self.ref:Scale(Vector(.5,.5,1 + s))
	self.ref:Render()
	
	local r,g,b,a = self:Color()
	local brt = .7 + math.cos(LevelTime()/100)/4
	r = r * brt
	g = g * brt
	b = b * brt

	local scl = 1
	local rem = self.net.remain/self.net.hp
	if(self:Restocking()) then 
		rem = self:RestockDT()
		r = .8
		b = 0
		g = 0
		scl = .4
	end
	
	local imdl,iscale,irotate = self:GetIconModel()
	
	local vrotate = Vector(90,rotate,0)
	self.ref:SetColor(r,g,b,a)
	self.ref:SetPos(pos+Vector(0,0,20))
	self.ref:SetAngles(vrotate + irotate)
	self.ref:SetModel(imdl)
	self.ref:SetShader(white)
	self.ref:Scale(iscale*scl)
	--[[self.ref:Scale(Vector(20,8,1)*scl)
	self.ref:Render()
	self.ref:SetAngles(vrotate)
	self.ref:Scale(Vector(8,20,1)*scl)]]
	self.ref:Render()
	
	self.ref:SetModel(self.planemodel)
	self.ref:SetPos(pos+Vector(0,0,40))
	self.ref:SetAngles(vrotate)
	self.ref:Scale(Vector(2,20*rem,1))
	self.ref:Render()

	self.ref:SetColor(.2,.2,.2)
	self.ref:SetAngles(vrotate)
	self.ref:Scale(Vector(2.8,20.8,1))
	self.ref:Render()
end

function ENT:GetIconModel()
	return self.model2, Vector(.01,1,1), Vector(-90,0,0)
end

function ENT:Draw()
	self:DrawModel(true)
end

function ENT:OnEvent(id)
	if(id == 2) then
		self.restocking = true
		self.rstart = LevelTime()
		return
	end
	
	if(id == 3) then
		self.restocking = false
		PlaySound(self.Entity,restock)
		--return
	else
		PlaySound(self.Entity,regen)
	end

	self.scaletime = LevelTime() + 200
	self.resettime = LevelTime() + self.net.delay
	
	local pos = self.Entity:GetPos()
	for i=0, 50 do
		local le,ref = QuickParticle(pos,200 + math.random(100,600),flaretex) -- model,angle,scale
		local vr = VectorRandom()*300
		vr.z = vr.z + 150
		le:SetVelocity(vr)
		le:SetColor(0.2,.5 + (math.random(0,10)/20),1)
		le:SetType(LE_FRAGMENT)
		le:SetTrType(TR_GRAVITY)
		le:SetRadius(math.random(2,30)/2)
		le:SetEndRadius(0)
	end
end