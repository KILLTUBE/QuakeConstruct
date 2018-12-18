function DropArmor(pl)

end

local function ArmorChanged(self,before,after)
	print(self:GetInfo().name .. "'s armor level changed " .. before .. "->" .. after .. "\n")
end

local function isArmor(str)
	return (string.find(str,"armor") != nil)
end

local function ItemPickup(item, self, trace, itemid)
	if(self != nil and self:IsPlayer() and isArmor(item:Classname())) then
		local before = self:GetArmor()
		Timer(.01,function()
			ArmorChanged(self,before,self:GetArmor())
		end)
	end
	--return false
end
hook.add("ItemPickup","armordrop",ItemPickup)

local function pldamage(self,inflictor,attacker,damage,MOD)
	if(self != nil and self:IsPlayer()) then
		local before = self:GetArmor()
		Timer(.01,function()
			ArmorChanged(self,before,self:GetArmor())
		end)
	end
end
hook.add("PlayerDamaged","armordrop",pldamage)