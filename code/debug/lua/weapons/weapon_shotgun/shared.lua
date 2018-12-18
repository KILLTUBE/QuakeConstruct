WEAPON.Base = "base_weapon"
WEAPON.baseModel = "models/weapons2/shotgun/shotgun.md3"
WEAPON.printName = "Shotgun"
WEAPON.slot = 2

if(CLIENT) then
	WEAPON.vm_pos = Vector(18,-5,-4)
else
	downloader.add("lua/weapons/weapon_shotgun/shared.lua")
end