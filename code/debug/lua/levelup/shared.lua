LVMSG_XP_ADDED = 1
LVMSG_LEVELUP = 2
LVMSG_GAMESTATE = 3

if(SERVER) then print("OPENED SHARED ON SERVER\n") end
if(CLIENT) then print("OPENED SHARED ON CLIENT\n") end

--Cost Modifier

--DAMAGE,FIRERATE,HEALTH,RESIST,SPEED,STEALTH

--G should be stealthy / speed over time
--MG should be defensive over time
--GL should be defensive over time

--RL should be offensive over time damage / firerate
--RG should be stealthy / damage / fire faster over time

--LG should be speed / damage over time
--BG should be damage over time

WP_AT_DAMAGE = 2
WP_AT_FIRERATE = 3
WP_AT_HEALTH = 4
WP_AT_RESIST = 5
WP_AT_SPEED = 6
WP_AT_STEALTH = 7

WEAPONNAMES = {}
	WEAPONNAMES[WP_GAUNTLET] = "Gauntlet"
	WEAPONNAMES[WP_MACHINEGUN] = "Machine Gun"
	WEAPONNAMES[WP_SHOTGUN] = "Shotgun"
	WEAPONNAMES[WP_GRENADE_LAUNCHER] = "Grenade Launcher"
	WEAPONNAMES[WP_ROCKET_LAUNCHER] = "Rocket Launcher"
	WEAPONNAMES[WP_RAILGUN] = "Railgun"
	WEAPONNAMES[WP_PLASMAGUN] = "Plasma Gun"
	WEAPONNAMES[WP_LIGHTNING] = "Lightning Gun"
	WEAPONNAMES[WP_BFG] = "BFG10K"
	
LVSHOP = {}
	LVSHOP[1] = {}
		LVSHOP[1][WP_GAUNTLET] = {2,1,0,0,0,2,1}
		LVSHOP[1][WP_MACHINEGUN] = {1,1,2,1,0,0,0}
		LVSHOP[1][WP_SHOTGUN] = {4,1,1,0,0,0,0}
		LVSHOP[1][WP_GRENADE_LAUNCHER] = {2,1,1,0,1,0,0}
		LVSHOP[1][WP_ROCKET_LAUNCHER] = {6,1,1,0,0,1,0}
		LVSHOP[1][WP_RAILGUN] = {4,1,1,1,0,0,1}
		LVSHOP[1][WP_PLASMAGUN] = {2,1,1,0,0,0,0}
		LVSHOP[1][WP_LIGHTNING] = {1,1,0,0,0,1,0}
		LVSHOP[1][WP_BFG] = {8,2,0,0,0,0,0}
		
	LVSHOP[2] = {}
		LVSHOP[1][WP_GAUNTLET] = {2,1,0,0,1,2,1}
		LVSHOP[1][WP_MACHINEGUN] = {1,1,2,1,2,0,0}
		LVSHOP[1][WP_SHOTGUN] = {4,1,1,0,0,0,0}
		LVSHOP[1][WP_GRENADE_LAUNCHER] = {2,1,1,0,1,0,0}
		LVSHOP[1][WP_ROCKET_LAUNCHER] = {6,2,1,0,0,2,0}
		LVSHOP[1][WP_RAILGUN] = {4,2,2,1,0,0,2}
		LVSHOP[1][WP_PLASMAGUN] = {2,2,2,0,0,0,0}
		LVSHOP[1][WP_LIGHTNING] = {1,3,0,0,0,1,0}
		LVSHOP[1][WP_BFG] = {8,4,0,0,0,0,0}
		
function LVEncodeWeapons(t)
	local str = ""
	for k,v in pairs(t) do
		str = str .. k .. "|" .. v .. "|"
	end
	return str
end

function LVDecodeWeapons(t)
	t = string.Explode("|",t)
	local key = 0
	local value = 0
	local c = 0
	local tab = {}
	for k,v in pairs(t) do
		if(c == 2) then
			tab[key] = value
			c = 0
		end
		if(c == 0) then
			key = tonumber(v)
		elseif(c == 1) then
			value = tonumber(v)
		end
		c = c + 1
	end
	return tab
end