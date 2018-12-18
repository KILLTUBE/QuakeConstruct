WEAPON.Base = "base_weapon"
WEAPON.baseModel = "models/weapons2/plasma/plasma.md3"
WEAPON.printName = "Plasma Gun"
WEAPON.slot = 3

if(CLIENT) then
	WEAPON.vm_pos = Vector(18,-5,-4)
else
	downloader.add("lua/weapons/weapon_plasmagun/shared.lua")
end