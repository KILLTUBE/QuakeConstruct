local l = false
DROWNING_ENABLED = false

local function PrePlayerDamaged(self,inflictor,attacker,damage,mod)
	if(l == true) then return damage end
	if(mod == MOD_WATER) then return 0 end
end
hook.add("PlayerDamaged","water",PrePlayerDamaged)

local clients = {}

local function goUnder(cl,id)
	clients[id].waterTime = LevelTime() + 12000
	clients[id].amt = 2
end

local function comeUp(cl,id)
	clients[id].regenTime = LevelTime() + 1200
	clients[id].amt = 4
end

local function clientthink(cl)
	local id = cl:EntIndex()
	if(clients[id] == nil) then
		clients[id] = {}
		clients[id].isAboveWater = true
		clients[id].loss = 0
		clients[id].amt = 0
		clients[id].regenTime = 0
		clients[id].waterTime = 0
		clients[id].lastHp = cl:GetHealth()
	end
	local hp = cl:GetHealth()
	
	if(hp > clients[id].lastHp) then
		local d = hp - clients[id].lastHp
		if(clients[id].loss > 0) then
			clients[id].loss = clients[id].loss - d
		end
		clients[id].lastHp = hp
	end
	
	local clx = clients[id]
	if(clx ~= nil) then
		local lv = entityWaterLevel(cl)
		if(lv > 2) then
			if(clients[id].isAboveWater == true) then
				clients[id].isAboveWater = false
				goUnder(cl,id)
			end
			
			local dwt = clients[id].waterTime - LevelTime()
			if(dwt <= 0 and hp > 0) then
				l = true
				local amt = clients[id].amt
				amt = math.ceil(amt)
				cl:SetPainDebounce(LevelTime() + 200)
				cl:Damage(nil,nil,amt,MOD_WATER,DAMAGE_NO_ARMOR)
				clients[id].loss = clients[id].loss + amt
				clients[id].amt = amt * 1.25
				if(clients[id].amt > 20) then
					clients[id].amt = 20
				end
				l = false
				
				if(math.random() > .5) then
					cl:PlaySound("sound/player/gurp1.wav",CHAN_VOICE)
				else
					cl:PlaySound("sound/player/gurp2.wav",CHAN_VOICE)
				end
				
				clients[id].waterTime = LevelTime() + 1000 - (clients[id].amt*20)
			end
		elseif(hp > 0) then
			if(clients[id].isAboveWater == false) then
				clients[id].isAboveWater = true
				comeUp(cl,id)
			end
			
			if(clients[id].loss > 0 and clients[id].regenTime < LevelTime()) then
				local regen = math.ceil(clients[id].amt)
				local prev = cl:GetHealth()
				if(clients[id].loss > regen) then
					clients[id].loss = clients[id].loss - regen
					clients[id].regenTime = LevelTime() + 850 - regen*3
					clients[id].amt = clients[id].amt + 1.25
					cl:SetHealth(prev + regen)
				else
					cl:SetHealth(prev + clients[id].loss)
					clients[id].loss = 0
				end
				if(prev < 100 and cl:GetHealth() > 100) then
					cl:SetHealth(100)
					clients[id].loss = 0
				end
			end
		end
	end
	clients[id].lastHp = cl:GetHealth()
end
hook.add("ClientThink","water",clientthink)