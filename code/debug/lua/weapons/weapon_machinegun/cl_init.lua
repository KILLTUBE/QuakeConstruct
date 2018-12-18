function WEAPON:Register()
	self.BaseClass.Register(self)
	self.fire = LoadSound("sound/weapons/machinegun/machgf1b.wav")
	self.deploy = LoadSound("sound/world/1shot_gong.wav")
	self.flash = LoadModel("models/weapons2/machinegun/machinegun_flash.md3")
	self.flashRef:SetModel(self.flash)
	self.barrelModel = LoadModel("models/weapons2/machinegun/machinegun_barrel.md3")
	self.barrelRef = RefEntity()
	self.barrelRef:SetModel(self.barrelModel)
end

function WEAPON:GetHandModel()
	return LoadModel("models/weapons2/machinegun/machinegun_hand.md3")
end

function WEAPON:ItemOverride(ITEM)
	function ITEM:Draw()
		local ref = self.BaseClass.Draw(self)
		if(ref == nil) then return end
		self.WEAP.barrelRef:SetAngles(Vector(0,0,0))
		self.WEAP.barrelRef:PositionOnTag(ref,"tag_barrel")
		self.WEAP.barrelRef:SetRenderFx(0)
		self.WEAP.barrelRef:SetLightingOrigin(ref:GetPos())
		self:ItemFX(self.WEAP.barrelRef)
	end
end

function WEAPON:Draw(parent,player,team,firstperson)
	if not (self.registered) then return end
	local renderFx = parent:GetRenderFx()
	self.ref:SetRenderFx(renderFx)
	self.ref:SetAngles(Vector(0,0,0))
	self.ref:PositionOnTag(parent,"tag_weapon")
	self.ref:SetLightingOrigin(parent:GetPos())
	self:RenderModel(player,self.ref)
	
	local pl = self:CheckPL(player)
	local flash = pl.flashTime or 0
	pl.rotate = pl.rotate or 0
	pl.rspeed = pl.rspeed or 0
	pl.rspeed = pl.rspeed - .05 * Lag()
	if(pl.rspeed < 0) then pl.rspeed = 0 end
	
	pl.rotate = pl.rotate + pl.rspeed * Lag()
	
	self.barrelRef:SetShader(0)
	self.barrelRef:SetAngles(Vector(0,0,pl.rotate))
	self.barrelRef:PositionOnTag(self.ref,"tag_barrel")
	self.barrelRef:SetRenderFx(renderFx)
	self.barrelRef:SetLightingOrigin(self.ref:GetPos())
	self:RenderModel(player,self.barrelRef)
	
	if(flash > LevelTime()) then
		self.flashRef:SetAngles(Vector(0,0,0))
		self.flashRef:PositionOnTag(self.ref,"tag_flash")
		self.flashRef:SetRenderFx(parent:GetRenderFx())
		self.flashRef:Render()
	end
end

function WEAPON:Fire(player,muzzle,angles)
	if not (self.registered) then return end
	self.BaseClass.Fire(self,player,muzzle,angles)
	local pl = self:CheckPL(player)
	pl.rspeed = pl.rspeed or 0
	pl.rspeed = pl.rspeed + 3
	if(pl.rspeed > 10) then pl.rspeed = 10 end
end