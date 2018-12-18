function WEAPON:Register()
	self.gun = LoadModel(self.baseModel)
	self.ref = RefEntity()
	self.ref:SetModel(self.gun)
	self.fire = LoadSound("sound/weapons/deagle/fire.wav")
	self.deploy = LoadSound("sound/weapons/deagle/deploy.wav")
	self.holster = LoadSound("sound/weapons/deagle/holster.wav")
	self.flash = LoadModel("models/weapons2/deagle/deagle_flash.md3")
	self.flashRef = RefEntity()
	self.flashRef:SetModel(self.flash)
	self.registered = true
	self.deployTime = 0
end

function WEAPON:Deploy()
	PlaySound(self.deploy)
	self.deployTime = LevelTime()
end

function WEAPON:Holster()
	PlaySound(self.holster)
end

function WEAPON:CheckPL(pl)
	local id = pl:EntIndex()
	self.players[id] = self.players[id] or {}
	return self.players[id]
end

function WEAPON:Init()
	self.flashTime = 0
	self.players = {}
end

function WEAPON:RenderModel(player,ref)
	local copy = RefEntity(ref)
	local s,e = CallHook("DrawGunModel",copy,player,0,player:GetInfo().team,true)
	if(s == false) then
		copy:Render()
	else
		ref:Render()
	end
end

WEAPON.vm_pos = Vector() --  18,-5,-4
WEAPON.vm_angles = Vector()

function WEAPON:AdjustHand(hand,player,firstperson)
	if(firstperson) then
		local pos = hand:GetPos()
	
		local f,r,u = hand:GetAxis()
		pos = pos + f * self.vm_pos.x
		pos = pos + r * self.vm_pos.y
		pos = pos + u * self.vm_pos.z
		
		RotateEntity(hand,self.vm_angles)
		hand:SetPos(pos)
	end
end

function WEAPON:Draw(parent,player,team,firstperson)
	if not (self.registered) then return end
	
	self.deployTime = self.deployTime or 0
	
	self.ref:SetAngles(Vector(0,0,0))
	self.ref:PositionOnTag(parent,"tag_weapon")
	self.ref:SetRenderFx(parent:GetRenderFx())
	self.ref:SetLightingOrigin(parent:GetPos())
	
	local angle = Vector()
	local pl = self:CheckPL(player)
	local flash = pl.flashTime or 0

	self:RenderModel(player,self.ref)
	
	if(flash > LevelTime()) then
		self.flashRef:SetAngles(Vector(0,0,0))
		self.flashRef:PositionOnTag(self.ref,"tag_flash")
		self.flashRef:SetRenderFx(parent:GetRenderFx())
		self.flashRef:Render()
	end
end

function WEAPON:Fire(player,muzzle,angles)
	if not (self.registered) then return end
	PlaySound(player, self.fire)
	local pl = self:CheckPL(player)
	pl.flashTime = LevelTime() + 50
end