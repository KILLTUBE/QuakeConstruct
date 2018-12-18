WEAPON.Base = "base_weapon"
WEAPON.Firerate = 600
WEAPON.ammoClass = "ammo_rockets"
WEAPON.printName = "Rocket Launcher"
WEAPON.slot = 2

if(SERVER) then
	downloader.add("lua/weapons/weapon_rocketlauncher/shared.lua")
	
	function WEAPON:Fire(player,muzzle,angles)
		--__FireDefault(player,5)
		local f,r,u = AngleVectors(angles)
		local e = CreateLuaEntity("projectile")
		e.Entity:SetPos(muzzle)
		e.Entity:SetVelocity(f * 800)
		e.Entity:SetAngles(angles)
		e:SetOwner(player)
		e:SetDamage(100)
		e:SetRadius(120)
		e:SetMod(MOD_ROCKET_SPLASH)
	end

else
	function WEAPON:GetHandModel()
		return LoadModel("models/weapons2/rocketl/rocketl_hand.md3")
	end

	function WEAPON:Register()
		self.BaseClass.Register(self)
		self.fire = LoadSound("sound/weapons/rocket/rocklf1a.wav")
		self.flash = LoadModel("models/weapons2/rocketl/rocketl_flash.md3")
		self.flashRef = RefEntity()
		self.flashRef:SetModel(self.flash)
	end
end