WEAPON.Base = "base_weapon"
WEAPON.baseModel = "models/weapons2/railgun/railgun.md3"
WEAPON.printName = "Railgun"
WEAPON.slot = 4

if(CLIENT) then
	WEAPON.vm_pos = Vector(18,-5,-4)
else
	downloader.add("lua/weapons/weapon_railgun/shared.lua")
end