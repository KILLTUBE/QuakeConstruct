print("Loaded Init\n")

downloader.add("lua/entities/lua_gpanel/cl_init.lua")

local function writeVector(msg,v)
	message.WriteFloat(msg,v.x)
	message.WriteFloat(msg,v.y)
	message.WriteFloat(msg,v.z)
end

function ENT:Initialized()
	print("Ent Init\n")
	local lock = G_SpawnString("locked","0")
	
	self.Entity:SetNextThink(LevelTime() + 1000)
	self.hp = 100
	self.nextheal = 0
	self.net.message = G_SpawnString("message","Open Door")
	if(lock == "1") then
		self.net.locked = 1
	else
		self.net.locked = 0
	end
	
	--print("SPAWN ANGLE: " .. self.Entity:GetSpawnAngle() .. "\n")
	--print("SPAWN ANGLE2: " .. tostring(self.Entity:GetAngles()) .. "\n")
	--print("SPAWN MESSAGE: " .. tostring(self.net.message) .. "\n")
	
	self.Entity:SetClip(CONTENTS_PLAYERCLIP)
	self.Entity:SetMins(Vector(-5,-5,-5))
	self.Entity:SetMaxs(Vector(5,5,5))
	--self.Entity:SetAngles(Vector(0,self.Entity:GetSpawnAngle(),0))
end

function GPanelMessage(self,str,client)
	--"panelfired " .. self.Entity:EntIndex() .. " " .. 1
	local args = string.Explode(" ",str)
	
	if(args[1] != "panelfired") then return end
	if(tonumber(args[2]) != self.Entity:EntIndex()) then return end
	local func = tonumber(args[3])

	for k,v in pairs(GetAllEntities()) do
		if(v:GetTargetName() == self.Entity:GetTarget()) then
			v:Fire()
		elseif(v:EntIndex() == self.Entity:GetTargetEnt():EntIndex()) then
			v:Fire()
		end
	end
end

function ENT:MessageReceived(str,client)
	
	GPanelMessage(self,str,client)

end

function ENT:Use(other)
	print("Panel Used!\n")
	if(self.net.locked == 0) then
		self.net.locked = 1
	else
		self.net.locked = 0
	end
end

function ENT:Removed()

end

function ENT:Pain(other,b,take)

end

function ENT:Think()

end

function ENT:Touch(other,trace)

end