downloader.add("lua/weapons/base_weapon/cl_init.lua")
downloader.add("lua/weapons/base_weapon/shared.lua")

function WEAPON:Fire(player,muzzle,angles)
	G_FireBullet(player,250,20)
	local f,r,u = AngleVectors(angles)
	--player:SetVelocity(player:GetVelocity() - f * 200)
end

function WEAPON:Pickup(player)
	player:PlaySound(self.pickupSound)
end

function WEAPON:Drop(player)
	print("CHECK DROP WEAPON\n")
	
	if not(self.canDrop) then return end
	local ammo = self:GetAmmo(player)
	
	print(self._id .. ": AMMO: " .. ammo .. "\n")
	
	if(ammo > 0) then
		print("DROP WEAPON\n")
		
		local e = CreateLuaEntity(self._classname)
		e.Entity:SetPos(player:GetPos() + Vector(0,0,20))
		e.Entity:SetTrType(TR_GRAVITY)
		e.respawnTime = 0
		e.Quantity = ammo
		e.dropped = true
	end
end