local function JetPak()
	for k,v in pairs(GetAllEntities()) do
		if(v:IsPlayer() and v:GetInfo()["health"] > 0 and v:IsBot() == false) then
			local tab = GetEntityTable(v)
			if(tab.fly) then
				local vec = VectorForward(v:GetAimAngles())
				
				local pvel = v:GetVelocity()
				
				local normal = VectorNormalize(pvel)
				normal = vAdd(normal,vMul(vSub(vec,normal),0.6))
				
				pvel = vMul(normal,440)
				
				v:SetVelocity(pvel)
			end
		end
	end
end

local function FlyTime()
	for k,v in pairs(GetAllPlayers()) do
		if(v:IsPlayer() and v:GetInfo()["health"] > 0 and v:IsBot() == false) then
			local bits = v:GetInfo()["buttons"];
			local tab = GetEntityTable(v)
			
			local filter = bitAnd(bits,16)
			if(filter != 0) then 
				if(tab.wasup) then
					if(tab.fly == nil) then tab.fly = false end
					tab.fly = !tab.fly
					tab.wasup = false
				end
			else
				tab.wasup = true
			end
			
			if(tab.fly) then
				v:SetPowerup(PW_FLIGHT,POWERUP_FOREVER)
			else
				v:SetPowerup(PW_FLIGHT,-1)
			end
		end
	end
end

--hook.add("Think","JetPackStuff",JetPak)
hook.add("Think","JetPackStuff",FlyTime)