include("lua/guidedrockets.lua")
include("lua/regen.lua")

ROCKET_GUIDESTRENGTH = 0.08
ROCKET_VELOCITY = 800

for k,v in pairs(GetAllEntities()) do
	if(string.find(v:Classname(),"weapon")) then v:Remove() end
	if(string.find(v:Classname(),"item")) then v:Remove() end
	if(string.find(v:Classname(),"ammo")) then v:Remove() end
end

function ClientThink(cl)
	cl:RemoveWeapons()
	cl:GiveWeapon(WP_ROCKET_LAUNCHER)
	cl:SetWeapon(WP_ROCKET_LAUNCHER)
	cl:SetAmmo(WP_ROCKET_LAUNCHER,-1)
	if(cl:IsBot()) then
		cl:SetAmmo(WP_ROCKET_LAUNCHER,999)
	end
	cl:SetPowerup(PW_QUAD,9999999)
	cl:SetSpeed(1.3)
end
hook.add("ClientThink","weapness.lua",ClientThink)

local function PlayerDamaged(self,inflictor,attacker,damage,means)
	if(attacker != nil) then 
		if(means == MOD_ROCKET) then
			for k,v in pairs(GetAllPlayers()) do
				attacker:SetInfo(PLAYERINFO_SCORE,attacker:GetInfo().score + 2)
				Timer(.2,function()
					v:SendMessage(attacker:GetInfo().name .. " Got a direct hit!\n2 points!.\n",true)
				end)
			end
		end
	end
	if(means == MOD_FALLING) then return 0 end
end
hook.add("PlayerDamaged","weapness.lua",PlayerDamaged)
hook.add("ShouldDropItem","weapness.lua",function() return false end)

hook.add("PrePlayerDamaged","weapness.lua",function(self,i,attacker) 
	if(attacker == self) then return 35 end --Reduce Spash Damage
end)

hook.add("SVFiredWeapon","weapness.lua",function(client,weap,delay,muzzle,dir) 
	local pl = GetPlayerByIndex(client)
	if(pl ~= nil and pl:IsBot() == false) then
		local v = pl:GetVelocity()
		local f,r,u = AngleVectors(dir)
		f.z = f.z/2.8
		f.z = f.z - .2
		pl:SetVelocity(v + f*-300)
	end
	return delay/2 
end)