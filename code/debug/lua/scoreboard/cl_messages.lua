scoreboard_messages = {}

local function weapIco(str) return LoadModel("models/weapons2/" .. str .. "/" .. str .. ".md3") end
local skull = LoadModel("models/gibs/skull.md3")
local blood = LoadShader("viewBloodBlend");
local notes = {}
local icons = {
	[MOD_SHOTGUN] = weapIco("shotgun"),
	[MOD_GAUNTLET] = {weapIco("gauntlet"),Vector(0,-20,0)},
	[MOD_MACHINEGUN] = {weapIco("machinegun"),Vector(0,-5,0)},
	[MOD_GRENADE] = weapIco("grenadel"),
	[MOD_GRENADE_SPLASH] = weapIco("grenadel"),
	[MOD_ROCKET] = weapIco("rocketl"),
	[MOD_ROCKET_SPLASH] = weapIco("rocketl"),
	[MOD_PLASMA] = weapIco("plasma"),
	[MOD_PLASMA_SPLASH] = weapIco("plasma"),
	[MOD_RAILGUN] = {weapIco("railgun"),Vector(0,-6,0)},
	[MOD_LIGHTNING] = weapIco("lightning"),
	[MOD_BFG] = weapIco("bfg"),
	[MOD_BFG_SPLASH] = weapIco("bfg"),
}
local messages = {
	[MOD_SHOTGUN] = "%a ripped %s a new one with %ga1 shotty.",
	[MOD_GAUNTLET] = "%s was cut down by %a's gauntlet.",
	[MOD_MACHINEGUN] = "%a perforated %s with his machinegun.",
	[MOD_GRENADE] = "%s couldn't dodge %a's grenade onslaught.",
	[MOD_ROCKET] = "%s was blown to bits by %a's rocket.",
	[MOD_PLASMA] = "%s was liquified by %a's hot plasma",
	[MOD_RAILGUN] = "%s was stabbed by %a's rail beam",
	[MOD_LIGHTNING] = "%s was shocked by %a's 1.21 gigawatts!",
	[MOD_BFG] = "%s didn't see %a's BFG blast.",
	[MOD_WATER] = "%s forgot %gs2 didn't have gils.",
	[MOD_SLIME] = "%s swam in the nasty stuff.",
	[MOD_LAVA] = "turns out %s can't survive lava.",
	[MOD_CRUSH] = "%s got too close to the moving parts.",
	[MOD_TELEFRAG] = "%s was in %a's personal space.",
	[MOD_FALLING] = "%s became flat as a pancake.",
	[MOD_SUICIDE] = "%s became bored with life.",
	[MOD_TARGET_LASER] = "%s: wait, there are lasers in this game?",
	[MOD_TRIGGER_HURT] = "%s stood too close to the edge.",
}
messages[MOD_GRENADE_SPLASH] = messages[MOD_GRENADE]
messages[MOD_ROCKET_SPLASH] = messages[MOD_ROCKET]
messages[MOD_PLASMA_SPLASH] = messages[MOD_PLASMA]
messages[MOD_BFG_SPLASH] = messages[MOD_BFG]

local messages_self = {
	[MOD_GRENADE_SPLASH] = "%s forgot to put the pin back in.",
	[MOD_ROCKET_SPLASH] = "%s blew %gs3 up.",
	[MOD_PLASMA_SPLASH] = "%s melted %gs3.",
	[MOD_BFG_SPLASH] = "%s should has used a smaller gun."
}

local genders = {
	[GENDER_NEUTER] = {"its","it","itself"},
	[GENDER_MALE] = {"his","he","himself"},
	[GENDER_FEMALE] = {"her","she","herself"}
}

scoreboard_messages.renderIcon = function(x,y,w,h,ico)
	draw.SetColor(1,1,1,1)
	draw.Rect(x-20,y,w+40,h,blood)
	
	render.CreateScene()
	
	local offset = Vector()
	ico = icons[ico]
	if(type(ico) == "table") then
		offset = ico[2]
		ico = ico[1]
	end
	if(ico == nil) then
		ico = skull
		offset.y = -10
	end
	local r = RefEntity()
	local dist = GetModelSize(ico)
	local size = GetModelSize3(ico)
	local off = Vector(dist*2,size.y/2,0) + offset
	r:SetAngles(Vector(0 + math.sin(LevelTime()/600)*5,-90 + math.cos(LevelTime()/400)*10,0))
	r:SetModel(ico)
	r:SetPos(GetModelCenter(ico) + off)
	r:Render()
	
	local refdef = {}
	refdef.origin = Vector(size.x-5,0,0)
	refdef.x = x
	refdef.y = y
	refdef.width = w
	refdef.height = h
	refdef.flags = 1
	render.RenderScene(refdef)
end

local function token(str,torepl,with) return string.Replace(str,torepl,with) end

scoreboard_messages.deathMessage = function(self,attacker,sg,ag,means,maxs)
	local str = messages[means]
	if(attacker == "") then str = messages_self[means] or str end
	if(str) then
		str = token(str,"%s",self)
		str = token(str,"%a",attacker)
		for i=1, 3 do 
			str = token(str,"%gs" .. i,genders[sg][i]) 
			str = token(str,"%ga" .. i,genders[ag][i]) 
		end
		local tw = maxs / string.len(str)
		return str,tw,tw*string.len(str)
	else
		str = self .. " died."
		local tw = maxs / string.len(str)
		return str,tw,tw*string.len(str)
	end
end