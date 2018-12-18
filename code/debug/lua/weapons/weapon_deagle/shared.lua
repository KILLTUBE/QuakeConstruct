WEAPON.Base = "base_weapon"
WEAPON.baseModel = "models/weapons2/deagle/deagle.md3"
WEAPON.printName = "Desert Eagle"

if(CLIENT) then
	WEAPON.vm_pos = Vector(18,-5,-4)
else
	downloader.add("lua/weapons/weapon_deagle/shared.lua")
end