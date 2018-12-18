print("Loaded Base_Item\n")

downloader.add("lua/entities/lua_base_item/cl_init.lua")

function ENT:Initialized()
	self.lifetime = 0
	self.respawntime = 1000
	
	self.Entity:SetMins(Vector(-25,-25,0))
	self.Entity:SetMaxs(Vector(25,25,130))
	self.Entity:SetClip(1)
	self.Entity:SetContents(CONTENTS_TRIGGER)
	self.Entity:SetBounce(.7)
	self.Entity:SetTrType(TR_GRAVITY)
	self.Entity:SetSvFlags(SVF_BROADCAST)
	
	self:SetVisible(true)
	
	self.net.fadetime = 800
	self.net.draw = 1
	self:SetType("item_armor_shard")
	
	self.thinkfunc = self.Respawn
	if(self.respawntime == 0 and self.lifetime ~= 0) then
		self.thinkfunc = self.Fadeout
		self.Entity:SetNextThink(LevelTime() + self.lifetime)
	end
	
	self.respawning = false
end

function ENT:SetType(t)
	if(type(t) == "string") then
		t = FindItemByClassname(t)
	end
	self.net.type = t
end

function ENT:Removed()

end

function ENT:SetVisible(b)
	if(b) then
		self.net.draw = 1
	else
		self.net.draw = 0
	end
end

function ENT:Respawn()
	--local dir = VectorNormalize(VectorRandom())
	--dir.z = dir.z + 1
	self:SetVisible(true)
	--self:SetVelocity(dir*320)
	self.respawning = false
end

function ENT:Fadeout()
	if(self.lifetime <= 0) then return end
	if(self.removing) then
		self.Entity:Remove()
		return
	end
	self.removing = true
	self.net.remove = LevelTime() + self.net.fadetime
	self.Entity:SetNextThink(LevelTime() + self.net.fadetime)
end

function ENT:Think()
	local b,e = pcall(self.thinkfunc,self)
	if not (b) then
		print("^1Entity Think Error[" .. self.Entity:Classname() .. "]: " .. e .. "\n")
	end
end

function ENT:ShouldPickup(other,trace)
	return other:IsPlayer() and other:GetHealth() > 0
end

function ENT:Affect(other)
	other:SetArmor(other:GetArmor() + 10)
end

function ENT:SetColor(r,g,b)
	self.net.color = ColorToLong(r,g,b)
end

function ENT:Touch(other,trace)
	if(self.respawning) then

	else
		if(other != nil and self:ShouldPickup(other,trace)) then
			AddEvent(other,EV_ITEM_PICKUP,(self.net.type or 1))
			self:Affect(other)
			
			if(self.respawntime == 0) then
				self.Entity:Remove()
			else
				self:SetVisible(false)
				self.Entity:SetNextThink(LevelTime() + self.respawntime)
				self.respawning = true
			end
		end
	end
end