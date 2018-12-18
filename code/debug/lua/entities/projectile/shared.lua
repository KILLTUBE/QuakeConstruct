if(SERVER) then downloader.add("lua/entities/projectile/shared.lua") end

local explosionProto = MessagePrototype("p_explode"):Vector():E()

if(SERVER) then
//__DL_BLOCK
	function ENT:Initialized()
		self.Entity:SetMins(Vector(-1,-1,-1))
		self.Entity:SetMaxs(Vector(1,1,1))
		self.Entity:SetClip(1)
		self.Entity:SetContents(CONTENTS_TRIGGER)
		self.Entity:SetBounce(0)
		self.Entity:SetTrType(TR_LINEAR)
		self.Entity:SetSvFlags(SVF_BROADCAST)
		
		self.Entity:SetNextThink(LevelTime() + 10000)

		self.owner = self.Entity
		self.damage = 0
		self.radius = 0
		self.touch = false
		
		self.net.draw = 1
	end
	
	function ENT:SetOwner(owner)
		self.owner = owner
	end
	
	function ENT:GetOwner()
		return self.owner
	end
	
	function ENT:SetDamage(d)
		self.damage = d
	end
	
	function ENT:SetRadius(r)
		self.radius = r
	end
	
	function ENT:SetMod(m)
		self.mod = m
	end
	
	function ENT:Think()
		self.Entity:Remove()
	end
	
	function ENT:Touch(other,trace)
		if(other ~= nil and other:IsPlayer() == false) then return end
		if(other ~= nil and other == self.owner) then return end
		if(self.touch == true) then return end
		print("TOUCHED\n")
		G_RadiusDamage(self.Entity:GetPos(),
			self.owner,
			self.damage,
			self.radius,
			self.Entity,
			self.mod)
			
		self.Entity:PlaySound("sound/weapons/rocket/rocklx1a.wav")

		--local msg = Message(pl,"_projectile")
		--message.WriteVector(msg,self.Entity:GetPos())
		--SendDataMessageToAll(msg)
		
		for k,pl in pairs(GetAllPlayers()) do
			explosionProto:Send(pl,self.Entity:GetPos())
		end
		
		self.touch = true
		
		self.Entity:Remove()
	end

//__DL_UNBLOCK
else
	function ENT:Init()
		self.rocket = LoadModel("models/ammo/rocket/rocket.md3")
		self.ref = RefEntity()
		self.ref:SetModel(self.rocket)
		self.smoke = LoadShader("shotgunSmokePuff")
		self.nextTrail = LevelTime()
	end
	function ENT:Draw()
		if(self.ref == nil) then return end
		self.ref:SetPos(self.Entity:GetPos())
		self.ref:SetAngles(self.Entity:GetAngles())
		self.ref:Render()
		
		if(self.nextTrail < LevelTime()) then
			local le,r = QuickParticle(self.Entity:GetPos(),800,self.smoke)
			
			r:SetRotation(math.random(360))
			r:SetRadius(16)
			le:SetRefEntity(r)
			le:SetColor(.5,.5,.5,1)
			self.nextTrail = LevelTime() + 25
		end
		
	end
	
	local Explosions = {}
	local exRef = RefEntity()
	exRef:SetType(RT_SPRITE)
	exRef:SetShader(LoadShader("rocketExplosion"))
	function d3d()
		local lt = LevelTime()
		for k,v in pairs(Explosions) do
			local dt = (lt - v[2]) / 950
			if(dt > 1) then v[3] = true end
			dt = CLAMP(dt+.2,0,1)
			exRef:SetTime(v[2]) -- - dt * 400
			exRef:SetPos(v[1])
			exRef:SetColor(1-dt,(1-dt)/2,0,1)
			exRef:SetRadius(25 + dt * 25)
			exRef:Render()
		end
		
		for k,v in pairs(Explosions) do
			if(v[3]) then table.remove(Explosions,k) end
		end
	end
	hook.add("Draw3D","projectile",d3d)

	function explosionProto:Recv(data)
		print("GOT: " .. tostring(data[1]) .. " - " .. type(data[1]) .. "\n")
		table.insert(Explosions,{data[1],LevelTime()})
	end
	--[[function pmessage(msgid)
		if(msgid == "_projectile") then
			local pos = message.ReadVector()
			table.insert(Explosions,{pos,LevelTime()})
		end
	end
	hook.add("HandleMessage","projectile",pmessage)]]
end