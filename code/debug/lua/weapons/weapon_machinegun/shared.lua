WEAPON.Base = "base_weapon"
WEAPON.Firerate = 100
WEAPON.baseModel = "models/weapons2/machinegun/machinegun.md3"
WEAPON.printName = "Machine Gun"

if(CLIENT) then
else
	downloader.add("lua/weapons/weapon_machinegun/shared.lua")
end