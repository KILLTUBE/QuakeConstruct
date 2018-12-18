downloader.add("lua/configurator/cl_init.lua")

configurator_vars = configurator_vars or {}
local vars = configurator_vars

local function getValue(var,def)
	if(vars[var] == nil) then vars[var] = def end
	return vars[var]
end

if(ITEM_POSITIONS == nil) then
	ITEM_POSITIONS = {}
	for k,v in pairs(GetAllEntities()) do
		local index = v:ItemIndex()
		if(index ~= nil) then
			local flags = v:GetSpawnFlags()
			table.insert(ITEM_POSITIONS,{entity=v,class=v:Classname(),pos=v:GetPos(),item=v:ItemIndex(),wait=v:GetWait(),flags=flags})
		end
	end
end

local function replaceItem(item,with)
	local inf = util.ItemInfo(with)
	if(inf == nil) then return end
	local class = inf.classname
	
	for k,v in pairs(ITEM_POSITIONS) do
		if(v.item == item) then
			if(v.entity ~= nil) then
				v.entity:Remove()
				v.entity = CreateEntity(class)
				v.entity:SetSpawnFlags(v.flags)
				v.entity:SetWait(0)
				v.entity:SetPos(v.pos)
			end
		end
	end
end

local function message(str,pl)
	local args = string.Explode(" ",str)
	if(args[1] == "cnfvar") then
		local var = ""
		if(string.sub(args[2],0,1) != "-") then
			var = args[2]
			val = tonumber(args[3])
			vars[var] = val
			if(string.sub(var,0,7) == "replace") then
				var = tonumber(string.sub(var,8,string.len(var)))
				print("replace " .. var .. " | " .. val .. "\n")
				replaceItem(var,val)
				pl:SendString("replace " .. var .. " " .. val)
			else
				print("var " .. var .. "\n")
				if(var == "g_maxhp") then for k,v in pairs(GetAllPlayers()) do v:SetMaxHealth(val) end end
			end
		else
			var = string.sub(args[2],2,string.len(args[2]))
			val = args[3]
			SetCvar(var,val)
			print("cvar " .. var .. "\n")
			if(var == "g_speed") then for k,v in pairs(GetAllPlayers()) do v:SetSpeed(1) end end
		end
		
		for k,v in pairs(GetAllPlayers()) do
			v:SendMessage(var .. " = " .. val,true)
		end
	elseif(args[1] == "gcnfvar") then
		if(string.sub(args[2],0,1) != "-") then
			var = args[2]
			local val = tostring(vars[var]) or ""
			if(val == "") then return end
			pl:SendString("rcnfvar " .. args[2] .. " " .. val)
		else
			var = string.sub(args[2],2,string.len(args[2]))
			pl:SendString("rcnfvar " .. args[2] .. " " .. GetCvar(var))
		end		
	end
end
hook.add("MessageReceived","configurator",message)

local function PlayerSpawned(player)
	player:SetHealth(getValue("g_starthp",125))
	player:SetMaxHealth(getValue("g_maxhp",100))
end
hook.add("PlayerSpawned","configurator",PlayerSpawned)

local function getVPercent(var)
	local v = getValue(var,100)
	if(v > 0) then
		v = v / 100
	else
		v = 0
	end
	return v
end

local function weapFire(player,wp,delay,pos,angle)
	local ndelay = delay * getVPercent("wp_delay")
	ndelay = ndelay * getVPercent("wp_cw" .. wp .. "_delay")
	return ndelay
end
hook.add("FiredWeapon","configurator",weapFire)

local dmg_str = "hz_damage_"
local damagestrings = {
	"water",
	"slime",
	"lava",
	"crush",
	"telefrag",
	"falling",
}

local pTab = {}
local function ClientThink(cl)
	local id = cl:EntIndex()
	local tab = pTab[id] or {}
	local lt = LevelTime()
	local hp = cl:GetHealth()
	
	tab.nextHeal = tab.nextHeal or 0
	if(tab.nextHeal < lt) then
		local amt = getValue("g_regen_amt",0)
		if(hp < 100 and hp > 0) then
			hp = hp + amt
			if(hp > 100) then hp = 100 end
			cl:SetHealth(hp)
		end
		tab.nextHeal = lt + getValue("g_regen_rate",1) * 1000
	end
	if(hp >= 100) then
		tab.nextHeal = lt + getValue("g_regen_rate",1) * 1000
	end
	
	pTab[id] = tab
end
hook.add("ClientThink","configurator",ClientThink)

local function ClientPickup(item,player,quantity,itype,itag)
	itype = EnumToString(itemType_t,itype)
	itype = string.sub(itype,string.len("IT_")+1,string.len(itype))
	itype = string.lower(itype)
	local old = quantity
	local new = old
	local v = getValue("pk_multiplier",1) * getValue("pk_mult_" .. itype,1)
	if(v != 1) then
		new = math.ceil(quantity * v)
		if(new < 1) then new = 1 end
	end
	
	print("Item Quantity " .. itype .. " - " .. old .. " => " .. new .. "\n")
	
	return new
end
hook.add("ItemPickupQuantity","configurator",ClientPickup)

local function ItemRespawnTime(item,respawn)
	local itype = util.ItemInfo(item:ItemIndex()).type
	itype = EnumToString(itemType_t,itype)
	itype = string.sub(itype,string.len("IT_")+1,string.len(itype))
	itype = string.lower(itype)
	local old = respawn
	local new = old
	local v = getValue("pk_wait",1) * getValue("pk_wait_" .. itype,1)
	if(v != 1) then
		new = math.ceil(respawn * v)
		if(new < 1) then new = 1 end
	end
	
	print("Item Respawn " .. itype .. " - " .. old .. " => " .. new .. "\n")
	
	return new
end
hook.add("ItemPickupRespawn","configurator",ItemRespawnTime)

local function PreDamage(self,inflictor,attacker,damage,dtype) 
	if(dtype <= MOD_BFG_SPLASH) then
		local wp = MethodOfDeathToWeapon(dtype)
		local ndamage = damage * getVPercent("wp_damage")
		ndamage = ndamage * getVPercent("wp_cw" .. wp .. "_damage")
		return ndamage 
	end
	local dt2 = (dtype - MOD_BFG_SPLASH)
	if(dt2 > 0 and dt2 <= #damagestrings) then
		damage = damage * getVPercent(dmg_str .. damagestrings[dt2])
		return damage
	end
end
hook.add("PrePlayerDamaged","configurator",PreDamage)

concommand.add("configreset",function() 
	configurator_vars = {}; 
	vars = {};
	print("^2Reset Configurator Variables\n")
end,true)