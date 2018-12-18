IG_RELOADTIME = 2000
IG_BOUNCES = 2

STAT_SHOTS = 1
STAT_HITS = 2
STAT_DEATHS = 4
STAT_LONGSHOT = 5

RELOAD = RELOAD or false

local let = {
	[MOD_UNKNOWN] = 1,
	[MOD_WATER] = 1,
	[MOD_SLIME] = 1,
	[MOD_LAVA] = 1,
	[MOD_CRUSH] = 1,
	[MOD_TELEFRAG] = 1,
	[MOD_SUICIDE] = 1,
	[MOD_TARGET_LASER] = 1,
	[MOD_TRIGGER_HURT] = 1,
	--Hazards respawn the player
}

local tr_flags = 1
tr_flags = bitOr(tr_flags,33554432)
tr_flags = bitOr(tr_flags,67108864)

message.Precache("igrailfire")
message.Precache("igstat")
--message.Precache("igbeam")
message.Precache("igdeath")

local function fullHealth(self) 
	--Simple function set's player's health to full and set's a timer to do so after damage
	self:SetHealth(100)
	Timer(.001,self.SetHealth,self,100)
end

local function removePickups()
	print("Removing Entities\n")
	for k,v in pairs(GetAllEntities()) do --Loop through all the entities
		print(v:Classname() .. "\n")
		if(string.find(v:Classname(),"weapon")) then
			v:Remove() --If an entity's name contains 'weapon', remove it
		end
		if(string.find(v:Classname(),"ammo")) then
			v:Remove() --If an entity's name contains 'ammo', remove it
		end
		if(string.find(v:Classname(),"armor")) then
			v:Remove() --If an entity's name contains 'armor', then remove it
		end
		if(string.find(v:Classname(),"health")) then
			v:Remove() --If an entity's name contains 'health', then remove it
		end
		if(string.find(v:Classname(),"item")) then
			v:Remove() --If an entity's name contains 'item', then remove it
		end
	end
end
removePickups()

local function sendStat(pl,s)
	local msg = Message()
	message.WriteShort(msg,s)
	message.WriteShort(msg,pl:GetTable().stats[s])
	SendDataMessage(msg,pl,"igstat")
end

local function sendBeam(pl,s,e,color)
	local msg = Message()
	message.WriteVector(msg,s)
	message.WriteVector(msg,e)
	message.WriteShort(msg,color)
	SendDataMessageToAll(msg,"igbeam")
end

local function setStat(pl,s,i)
	pl:GetTable().stats = pl:GetTable().stats or {}
	pl:GetTable().stats[s] = i
	sendStat(pl,s)
end

local function addStat(pl,s,i)
	pl:GetTable().stats = pl:GetTable().stats or {}
	pl:GetTable().stats[s] = pl:GetTable().stats[s] or 0
	pl:GetTable().stats[s] = pl:GetTable().stats[s] + i
	sendStat(pl,s)
end

local function getStat(pl,s)
	return pl:GetTable().stats[s]
end

local function setupPlayer(pl)
	fullHealth(pl)
	pl:RemoveWeapons() --Remove all of the player's weapons
	local function go()
		pl:GiveWeapon(WP_RAILGUN) --Give the player a railgun
		pl:SetAmmo(WP_RAILGUN,-1) -- -1 will make the ammo numbers go away :)
		pl:SetWeapon(WP_RAILGUN) --Set the railgun as the active weapon
	end
	if(!pl:IsBot()) then pl:SetSpeed(1.2) end
	if(pl:IsBot()) then pl:SetAmmo(WP_RAILGUN,999) end --Bots need full ammo or they won't shoot
	pl:SetPowerup(PW_INVIS,3000)
	pl:GetTable().gi_invistime = LevelTime() + 3000
	Timer(2.5,go)
end

local function PreDamage(self,inflictor,attacker,damage,dtype) 
	--PreDamage is called BEFORE the player is damaged, and the returned value is the amount of damage the player will take
	self:GetTable().gi_invistime = self:GetTable().gi_invistime or 0
	if(attacker) then
		if(attacker:GetInfo().weapon == WP_RAILGUN) then
			if(self:GetTable().gi_invistime > LevelTime()) then
				fullHealth(self)
				return 0; --No damage to invisibles
			end
			--If the player was hit with a railgun
			addStat(attacker,STAT_HITS,1)
			addStat(self,STAT_DEATHS,1)
			local d = VectorLength(attacker:GetPos() - self:GetPos())
			setStat(attacker,STAT_LONGSHOT,d)
			
			local msg = Message()
			message.WriteShort(msg,self:EntIndex())
			SendDataMessageToAll(msg,"igdeath")
			
			return 200 --Just gib the player (loads of damage)
		end
	end
	if(let[dtype] == nil) then
		fullHealth(self)
		return 0 --If we don't have an exception (aka hazard) then don't damage the player
		--This makes it so that the player doesn't take falling damage
	else
		fullHealth(self)
		self:Respawn()
		return 0
	end
end

local function SVFiredWeapon(player,weapon,delay,pos,angle)
	player = GetAllPlayers()[player+1]
	if(weapon == WP_RAILGUN and player != nil) then
		local color = player:GetTable().color or math.random(0,360)
		local rt = IG_RELOADTIME
		local maxv = 800
		local rv = maxv - VectorLength(player:GetVelocity())
		if(rv < 0) then rv = 0 end
		rv = rv + 800
		--rv = rv / 4
		--if(VectorLength(player:GetVelocity()) > 200) then rt = rt / 2 end
		addStat(player,STAT_SHOTS,1)
		
		local f,r,u = AngleVectors(angle)
		local mpos = pos
		mpos = mpos + f*8
		mpos = mpos + u*-8
		mpos = mpos + r*6
		local tr = TraceLine(pos,(pos+f*10000),player,tr_flags)
		
		local msg = Message()
		message.WriteShort(msg,rv)
		message.WriteVector(msg,pos)
		message.WriteVector(msg,tr.endpos)
		message.WriteShort(msg,color)
		message.WriteShort(msg,IG_BOUNCES)
		message.WriteShort(msg,player:EntIndex())
		SendDataMessageToAll(msg,"igrailfire")
		
		for i=0, IG_BOUNCES do
			if(tr and tr.hit and pos and tr.endpos) then
				--sendBeam(player,mpos,tr.endpos,color)
				local norm = VectorNormalize(tr.endpos - pos)
				if(tr.entity) then
					if(tr.entity:IsPlayer()) then
						if(tr.entity != player) then
							local vel = norm * 800
							tr.entity:SetVelocity(tr.entity:GetVelocity() + vel)
							tr.entity:Damage(player,player,1000,MOD_RAILGUN)
						else
							local vel = f * -800
							tr.entity:SetVelocity(tr.entity:GetVelocity() + vel)
						end
						break
					end
				end
				
				
				angle = VectorToAngles(norm)
				f,r,u = AngleVectors(angle)
				local dot = DotProduct( f, tr.normal );
				local ref = VectorNormalize(vAdd(f,vMul(tr.normal,-2*dot)))
				pos = tr.endpos
				tr = TraceLine(pos,(pos+ref*10000),nil,tr_flags)
				mpos = pos
			end
		end
		return rv --fire rate
	end
end

local function CLThink(pl)
	--if(pl:GetHealth() <= 0) then
		--pl:Damage(1000)
	--end
end

local function plcolor(p,c,a)
	local num = tonumber(a[1])
	if(num == nil) then
		print("useage: /mycolor [number 0-360]\n")
	else
		p:GetTable().color = num
	end
end
concommand.add("mycolor",plcolor)

local function plcolor(p,c,a)
	local num = tonumber(a[1])
	if(num == nil) then
		print("useage: /ig_bounces [number 0-100]\n")
	else
		if(num >= 0 and num <= 100) then
			IG_BOUNCES = num
		end
	end
end
concommand.add("ig_bounces",plcolor,true)

hook.add("ClientThink","instagib",CLThink)
hook.add("PlayerSpawned","instagib",setupPlayer)
hook.add("PrePlayerDamaged","instagib",PreDamage)
hook.add("SVFiredWeapon","instagib",SVFiredWeapon)
hook.add("ShouldDropItem","instagib",function() return false end) --Don't drop items (like railguns)
hook.add("PlayerKilled","instagib",function(p)  end)
--Timer(1.5,spawnPlayer,p)
--Remove pickups and outfit players
for k,v in pairs(GetAllPlayers()) do
	if(!RELOAD) then
		setupPlayer(v)
	end
	setStat(v,STAT_SHOTS,0)
	setStat(v,STAT_HITS,0)
	setStat(v,STAT_LONGSHOT,0)
end

downloader.add("lua/cl_igweap.lua")
downloader.add("lua/cl_instagib.lua")


local function reloadTime(p,c,a)
	if(a[1] == nil) then return end
	local n = tonumber(a[1])
	if(n != nil) then IG_RELOADTIME = n end
end
concommand.Add("ReloadTime",reloadTime,true)

RELOAD = true