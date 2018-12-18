WEAPON.Base = "base_weapon"
WEAPON.baseModel = "models/weapons2/lightning/lightning.md3"
WEAPON.printName = "Lightning Gun"
WEAPON.slot = 3

if(CLIENT) then
	WEAPON.vm_pos = Vector(18,-5,-4)
else
	downloader.add("lua/weapons/weapon_lightninggun/shared.lua")
end