--Remove Some Of The Items From The Map

local function RemoveStuff()
	local tab = table.Copy(GetAllEntities())
	for k,v in pairs(tab) do
		local class = v:Classname()
		if(string.find(class,"weapon") or string.find(class,"ammo") or string.find(class,"item")) then
			if not (string.find(class,"item_health")) then v:Remove() end
		end
	end
end
RemoveStuff()


local function Think()
	local tab = GetAllEntities()
	for k,v in pairs(tab) do
		if(v:IsPlayer() and v:GetInfo()["connected"]) then
			local weap = v:GetInfo()["weapon"]
			local vtab = v:GetTable()
			local hp = v:GetInfo()["health"]
			
			if(v:IsBot()) then
				pcall(v.SetAmmo,v,weap,100) --Bots need ammo or else they go to gauntlet
			end
			
			if(vtab.dtime and vtab.dtime < CurTime()) then
				--Gib The Player
				v:Damage(nil,nil,(hp/2) + 5,12)
				vtab.dtime = nil
			end
			
			if(vtab.adtime) then
				if(vtab.adtime < CurTime()) then
					--Gib The Player
					v:Damage(nil,nil,(hp/2) + 5,12)
					v:SetInfo(PLAYERINFO_SCORE,v:GetInfo()["score"]+1)
					vtab.adtime = nil
				else
					--Tell The Player He's Gonna Be Gibbed
					local sec = math.ceil(vtab.adtime - CurTime())
					v:SendMessage("You have accended to the top.\nYou will die in " .. sec .. " seconds.\n",true)
				end
			end
		end
	end
end

local function SetNextWeap(cl)
	local vtab = cl:GetTable()
	vtab.currWeap = vtab.nextWeap
	if not (vtab.currWeap == WP_BFG) then
		vtab.nextWeap = vtab.currWeap+1
	end
end

--Ammo And Weapons Blah Blah Blah Etc.
local function ApplyNextWeap(cl)
	local tab = cl:GetTable()
	cl:RemoveWeapons()
	
	if(tab.currWeap == WP_PLASMAGUN and tab.nextWeap == WP_BFG) then
		tab.adtime = CurTime() + 10
		cl:SetPowerup(PW_QUAD,10000)
		cl:SetPowerup(PW_BATTLESUIT,10000)
		--Set Us Up For Gibbing
		--And Give Us Powerups!
	end
	
	cl:GiveWeapon(WP_GAUNTLET)
	cl:SetAmmo(WP_GAUNTLET,-1)
	
	cl:GiveWeapon(tab.nextWeap)
	cl:SetWeapon(tab.nextWeap)
	cl:SetAmmo(tab.nextWeap,-1)
	
	SetNextWeap(cl)
	if(tab.nextWeap == WP_GRENADE_LAUNCHER) then
		SetNextWeap(cl)
	end
end

--Player Spawned, Clean Player.
local function PlayerSpawned(cl)
	local tab = cl:GetTable()
	tab.nextWeap = 1
	tab.dtime = nil
	SetNextWeap(cl)
	ApplyNextWeap(cl)
	cl:SetInfo(PLAYERINFO_HEALTH,100)
end

local function PlayerKilled(self,inflictor,attacker,damage,meansOfDeath)
	if(attacker != nil) then
		local weap = attacker:GetInfo()["weapon"]
		if(attacker:IsPlayer()) then ApplyNextWeap(attacker) end
	end
	
	self:GetTable().dtime = CurTime() + 1
end

local function PlayerDamaged(self,inflictor,attacker,damage,meansOfDeath)
	if(attacker != nil) then 
		local hp = attacker:GetInfo(attacker)["health"]
		if(hp) then
			if(hp < 200) then
				attacker:SetInfo(PLAYERINFO_HEALTH,hp + math.ceil(damage/5))
				hp = attacker:GetInfo()["health"]
			end
			if(hp > 200) then
				attacker:SetInfo(PLAYERINFO_HEALTH,200)
			end
		end
	end
	if(self:GetInfo()["health"] <= 0) then
		damage = 0
	else
		--[[if(damage > self:GetInfo()["health"]) then
			damage = self:GetInfo()["health"]
			return damage
		end]]
	end
	damage = damage * 2
	return damage
end

hook.add("PlayerSpawned","Accention",PlayerSpawned)
hook.add("PlayerJoined","Accention",PlayerSpawned)
hook.add("PlayerDamaged","Accention",PlayerDamaged)
hook.add("PlayerKilled","Accention",PlayerKilled)
hook.add("ShouldDropItem","Accention",function() return false end)
hook.add("Think","Accention",Think)

for k,v in pairs(GetAllPlayers()) do
	PlayerSpawned(v)
end