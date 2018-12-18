print("Loaded Init\n")

downloader.add("lua/entities/testentity/cl_init.lua")

local function writeVector(msg,v)
	message.WriteFloat(msg,v.x)
	message.WriteFloat(msg,v.y)
	message.WriteFloat(msg,v.z)
end

function ENT:Initialized()
	print("Ent Init\n")
	self.Entity:SetNextThink(LevelTime() + 1000)
	self.hp = 100
	self.nextheal = 0
	
	self.Entity:SetMins(Vector(-15,-15,-15))
	self.Entity:SetMaxs(Vector(15,15,15))
	self.Entity:SetClip(1)
	self.Entity:SetTakeDamage(true)
	self.Entity:SetHealth(1000)
	self.Entity:SetBounce(.7)
end

function ENT:Removed()
	print("Ent Removed\n")
end

function ENT:Pain(other,b,take)
	print("Ow!\n")
	self.Entity:SetHealth(1000)
	local pos = self.Entity:GetPos()
	local dir = VectorNormalize(other:GetPos() - pos)
	self.Entity:SetVelocity((dir*-700) + Vector(0,0,100))
	self.net.hitTime = LevelTime()
end

function ENT:SendSparks(p1,p2)
	local msg = Message()
	message.WriteString(msg,"testentity")
	writeVector(msg,p1)
	writeVector(msg,(p2 - p1) * 30)
	message.WriteLong(msg,1)
	
	for k,v in pairs(GetEntitiesByClass("player")) do
		SendDataMessage(msg,v,"itempickup")
	end
end

function ENT:Think()
	self.hp = 35
	
	self:SendSparks(self.Entity:GetPos(),self.Entity:GetPos())
	
	self.nextheal = 0
end

function ENT:Touch(other,trace)
	if(other != nil and other:IsPlayer() and self.nextheal < LevelTime()) then
		print("Ent Touched\n")
		if(self.hp > 0) then
			local hp = other:GetHealth()
			if(hp < 300) then
				other:SetHealth(hp + 1)
				self.hp = self.hp - 1
				self.nextheal = LevelTime() + 50
				self:SendSparks(self.Entity:GetPos(),other:GetPos())
			end
			if(self.hp <= 0) then
				self.Entity:SetNextThink(LevelTime() + 100)
			end
		end
		--self.Entity:Remove()
	end
	--BounceEntity(self.Entity,trace,.8)
end