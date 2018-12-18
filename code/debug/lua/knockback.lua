local weaponKnockback = {
	[WP_GAUNTLET] = 0,
	[WP_MACHINEGUN] = 100,
	[WP_SHOTGUN] = 400,
	[WP_GRENADE_LAUNCHER] = 500,
	[WP_ROCKET_LAUNCHER] = 600,
	[WP_LIGHTNING] = 60,
	[WP_RAILGUN] = 800,
	[WP_PLASMAGUN] = 80,
	[WP_BFG] = 700,
}

local function FiredWeapon(player,weapon,delay,pos,angle)
	if(!player:IsBot()) then
		local angle = VectorForward(angle)
		local vec = player:GetVelocity()
		local knock = weaponKnockback[weapon]*.4
		
		if(knock) then
			vec = vec + (angle * -knock)
		end
		
		player:SetVelocity(vec)
	end
end
hook.add("FiredWeapon","Knockback",FiredWeapon)