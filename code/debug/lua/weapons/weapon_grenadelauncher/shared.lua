WEAPON.Base = "base_weapon"
WEAPON.baseModel = "models/weapons2/grenadel/grenadel.md3"
WEAPON.printName = "Grenade Launcher"
WEAPON.slot = 2

if(CLIENT) then
	WEAPON.vm_pos = Vector(18,-5,-4)
else
	downloader.add("lua/weapons/weapon_grenadelauncher/shared.lua")
end