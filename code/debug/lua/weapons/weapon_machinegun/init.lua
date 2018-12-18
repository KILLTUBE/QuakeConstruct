downloader.add("lua/weapons/machinegun/cl_init.lua")
downloader.add("lua/weapons/machinegun/shared.lua")

function WEAPON:Fire(player,muzzle,angles)
	G_FireBullet(player,250,5)
	local f,r,u = AngleVectors(angles)
	player:SetVelocity(player:GetVelocity() - f * 80)
end