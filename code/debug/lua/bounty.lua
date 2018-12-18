local function makeHP(target,pos,amt)
		local health = CreateLuaEntity("lua_base_item")
		health:SetPos(pos)
		health.ShouldPickup = function(self,other)
			return (other:IsPlayer() and other != target and other:GetHealth() < 200)
		end
		health.Affect = function(self,other)
			other:SetHealth(other:GetHealth() + amt)
			if(other:GetHealth() > 200) then
				other:SetHealth(200)
			end
		end
		health:SetColor(.2,1,.2)
		health:SetType("item_health_small")
		health:SetVelocity(Vector(0,0,300) + VectorNormalize(VectorRandom())*100)
		LinkEntity(health.Entity)
end

local function makeArmor(target,pos,amt)
		local armor = CreateLuaEntity("lua_base_item")
		armor:SetPos(pos)
		armor.ShouldPickup = function(self,other)
			return (other:IsPlayer() and other != target and other:GetArmor() < 200)
		end
		armor.Affect = function(self,other)
			other:SetArmor(other:GetArmor() + amt)
			if(other:GetArmor() > 200) then
				other:SetArmor(200)
			end
		end
		armor:SetColor(1,.8,.1)
		armor:SetType("item_armor_shard")
		armor:SetVelocity(Vector(0,0,300) + VectorNormalize(VectorRandom())*100)
		LinkEntity(armor.Entity)
end

function playerDamage(target,inflictor,attacker,damage,method,asave)
	damage = damage - asave
	--local tpos = target:GetPos() + Vector(0,0,20)
	if(attacker == nil or !attacker:IsPlayer()) then return end
	if(damage >= 10) then
		print("^3DAMAGE: " .. damage .. "\n")
		damage = math.ceil(damage/10)
		print("^3COUNT: " .. damage .. "\n")
		for i=0,damage do
			Timer(i*.2,function()
				local tpos = target:GetPos() + Vector(0,0,20)
				makeHP(target,tpos,5) 
			end)
		end
	end
	if(asave >= 20) then
		print("^2SAVE: " .. asave .. "\n")
		asave = math.ceil(asave/20)
		print("^2COUNT: " .. asave .. "\n")
		for i=0,asave do
			Timer(i*.2,function() 
				local tpos = target:GetPos() + Vector(0,0,20)
				makeArmor(target,tpos,10) 
			end)
		end
	end
end
hook.add("PostPlayerDamaged","bounty.lua",playerDamage)