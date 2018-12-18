WEAPON.Base = "base_weapon"
WEAPON.baseModel = "models/weapons2/bfg/bfg.md3"
WEAPON.printName = "BFG 10k"
WEAPON.slot = 10

if(CLIENT) then
	WEAPON.vm_pos = Vector(18,-5,-4)
else
	downloader.add("lua/weapons/weapon_bfg/shared.lua")
end