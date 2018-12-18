function teleporterCallbackTest(teleporter)
	local touch = function(ent,other,trace)
		if(ent and other) then
			local entName = "Unknown"
			local otherName = "Unknown"
			if(ent:Classname()) then entName = ent:Classname() end
			if(other:Classname()) then otherName = other:Classname() end
			
			if(ent:GetTarget()) then
				local targ = ent:GetTarget()
				local angles = AngleVectors(targ:GetAngles())
				
				if(otherName == "rocket" or otherName == "grenade" or otherName == "bfg" or otherName == "plasma") then
					local len = VectorLength(other:GetVelocity())
					
					CreateTempEntity(vAdd(other:GetPos(),Vector(0,0,-5)),EV_PLAYER_TELEPORT_IN)
					
					other:SetPos(targ:GetPos())
					other:SetVelocity(vMul(angles,len))
					
					CreateTempEntity(vAdd(other:GetPos(),Vector(0,0,-5)),EV_PLAYER_TELEPORT_OUT)
				end
			end
		end
	end
	teleporter:SetCallback(ENTITY_CALLBACK_TOUCH, touch)
end

function jumpPadCallbackTest(teleporter)
	local touch = function(ent,other,trace)
		if(ent and other) then
			local entName = "Unknown"
			local otherName = "Unknown"
			if(ent:Classname()) then entName = ent:Classname() end
			if(other:Classname()) then otherName = other:Classname() end
			
			if(ent:GetTarget()) then
				local targ = ent:GetTarget()
				local angles = vSub(targ:GetPos(), other:GetPos())
				local normal, len = VectorNormalize(angles)
				
				len = len * 1.5
				
				if(otherName == "rocket" or otherName == "grenade" or otherName == "bfg" or otherName == "plasma") then
					local rlen = VectorLength(other:GetVelocity())
					if(len < rlen) then len = rlen end
					
					other:SetVelocity(vMul(normal,len))
				end
			end
		end
	end
	teleporter:SetCallback(ENTITY_CALLBACK_TOUCH, touch)
end

for k,v in pairs(GetEntitiesByClass({"trigger_teleport"})) do
	print("^5" .. v:Classname() .. "\n")
	teleporterCallbackTest(v)
end

for k,v in pairs(GetEntitiesByClass({"trigger_push"})) do
	print("^5" .. v:Classname() .. "\n")
	jumpPadCallbackTest(v)
end