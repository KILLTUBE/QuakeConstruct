local function pickspawn()
	local tab = GetEntitiesByClass("info_player_start")
	table.Add(tab,GetEntitiesByClass("info_player_deathmatch"))
	print("# of spawns: " .. #tab .. "\n")
	local point = tab[math.random(1,#tab)]
	if(point != nil) then
		return point
	end
	return nil
end

local function NoFallDamage(self,inflictor,attacker,damage,meansOfDeath)
	if(meansOfDeath == MOD_FALLING) then
		return 0
	end

	if(self) then
		if(meansOfDeath == MOD_TRIGGER_HURT) then
			local spawn = pickspawn()
			if(spawn) then
				self:SetVelocity(Vector())
				self:SetPos(spawn:GetPos())
				CreateTempEntity(vAdd(self:GetPos(),{x=0,y=0,z=10}),EV_PLAYER_TELEPORT_IN)
				local angles = spawn:GetAngles()
				if(angles) then
					self:SetAngles(angles)
				end
				
				return 0
			end
		end
	end
end
hook.add("PlayerDamaged","RemoveFallDamage",NoFallDamage)