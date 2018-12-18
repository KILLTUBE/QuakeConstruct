--[[for k,v in pairs(GetAllEntities()) do
	print(v:Classname() .. "\n")
	if(string.find(v:Classname(),"func_door")) then
		print("Door\n")
		v:Fire()
	end
end]]

local tab = FindEntities("Classname","trigger_multiple")
for k,v in pairs(tab) do
	local tn = v:GetTarget()
	if(tn != nil) then
		print("target " .. tn .. "\n")
	else
		print("target\n")
	end
end

for k,v in pairs(GetAllEntities()) do
	local tn = v:GetTargetName()
	if(tn) then
		print("[" .. v:Classname() .. "] " .. tn .. "\n")
	end
end

local t = 0
for k,v in pairs(GetAllEntities()) do
	local tn = v:Classname()
	if(tn and tn == "func_door") then
		v:SetCallback(ENTITY_CALLBACK_USE,function(door,other,activator)
			--print("Other: " .. other:Classname() .. "\n")
			if(activator:IsPlayer()) then
				local pp = activator:GetPos()
				local dp = door:GetPos()
				local delta = Vector(0,0,10)
				
				--print(tostring(dp) .. "\n")
				
				--activator:GetVelocity() + 
				door:GetTable().t = door:GetTable().t or 0
				if(door:GetTable().t < LevelTime()) then
					activator:SetHealth(activator:GetHealth() + 1)
					if(activator:GetHealth() > 200) then
						activator:SetHealth(200)
					end
					activator:SendMessage("DOOR #" .. k .. " HEALS YOU TO: " .. activator:GetHealth(),true)
					door:GetTable().t = LevelTime() + 80
				end
				
				--activator:Damage(nil,nil,2,12)
			end
		end)
		print("[" .. v:Classname() .. "] " .. tn .. "\n")
	end
end

local function fire(p,c,a)
	if(type(a[1]) != "string") then return end
	local tab = FindEntities("GetTargetName",a[1])
	for k,v in pairs(tab) do
		v:Fire()
		print("Fired: " .. v:Classname() .. "\n")
	end
end
concommand.add("efire",fire)