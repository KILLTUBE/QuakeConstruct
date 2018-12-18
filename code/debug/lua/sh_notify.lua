if(SERVER) then
	//__DL_BLOCK
	--a
	--SendScript("lua/sh_notify.lua")
	downloader.add("lua/sh_notify.lua")
	message.Precache("deathnotify")
	local function death(self,inflictor,attacker,damage,means)
		if(self == nil) then return end
		local msg = Message()
		message.WriteShort(msg,self:EntIndex())
		if(attacker != nil and attacker:IsPlayer()) then
			message.WriteShort(msg,attacker:EntIndex())
		else
			message.WriteShort(msg,-1)
		end
		message.WriteShort(msg,means)
		SendDataMessageToAll(msg,"deathnotify")
	end
	hook.add("PlayerKilled","sh_notify",death)
	//__DL_UNBLOCK
else
	
	print("NOTIFY LOADED!\n")
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
	
	local noteTime = 10000
	local lmeans = -1
	
	local function HandleMessage(msgid)
		if(msgid == "deathnotify") then
			local self = GetEntityByIndex(message.ReadShort())
			local attacker = message.ReadShort()
			local means = message.ReadShort()
			lmeans = means
			if(attacker != -1) then attacker = GetEntityByIndex(attacker) end
			
			table.insert(notes,{self,attacker,means,LevelTime()})
			print("Dispatched Note!\n")
		end
	end
	hook.add("HandleMessage","sh_notify",HandleMessage)
	
	local function renderIcon(x,y,w,h,ico)
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
	
	local function shadowText(x,y,txt,r,g,b,tw,th)
		draw.SetColor(0,0,0,1)
		draw.Text(x-1,y-1,txt,tw,th)
		draw.Text(x+1,y-1,txt,tw,th)
		draw.Text(x-1,y+1,txt,tw,th)
		draw.Text(x+1,y+1,txt,tw,th)
		draw.SetColor(r,g,b,1)
		draw.Text(x,y,txt,tw,th)	
	end
	
	local function tc(team)
		if(team == TEAM_BLUE) then return .2,.2,1 end
		if(team == TEAM_RED) then return 1,.2,.2 end
		if(team == TEAM_SPECTATOR) then return .5,.6,.7 end
		if(team == TEAM_FREE) then return 1,1,1 end
	end
	
	local function token(str,torepl,with) return string.Replace(str,torepl,with) end
	
	local function deathMessage(self,attacker,sg,ag,means,maxs)
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
	
	local function drawNotes()
		--renderIcon(50,50,100,100,lmeans)
		local th = 18
		local y = th
		for k,v in pairs(notes) do
			v.nx = v.nx or 1200
			v.ny = v.ny or y
			local s_team = v[1]:GetInfo().team
			local a_team = 0
			local s_g = v[1]:GetInfo().gender
			local a_g = GENDER_NEUTER
			local s_name = v[1]:GetInfo().name
			local a_name = ""
			if(v[2] != -1) then a_name = v[2]:GetInfo().name end
			if(v[2] != -1) then a_team = v[2]:GetInfo().team end
			if(v[2] != -1) then a_g = v[2]:GetInfo().gender end
			s_name = fixcolorstring(s_name)
			a_name = fixcolorstring(a_name)
			local means = v[3]
			local t = v[4]
			local dt = (LevelTime() - t) / noteTime
			if(v[2] != nil and v[2] != -1) then
				if(v[1]:EntIndex() == v[2]:EntIndex()) then a_name = "" end
			end
			local el = string.len(s_name)*(th*.8)
			local sl = string.len(a_name)*(th*.8)
			local spl = (th*.8)*6
			
			v.ny = v.ny + (y - v.ny)*.2
			
			if(dt >= 1) then dt = 1 end
			if(dt < .5) then
				v.nx = v.nx + (620 - v.nx)*.2 
			else
				if(dt < .52) then
					v.nx = v.nx + (550 - v.nx)*.1
				else
					v.nx = v.nx + (1200 - v.nx)*.05
				end
			end
			
			local vx = el
			local r,g,b = tc(s_team)
			shadowText(v.nx - vx,v.ny,s_name,r,g,b,th*.8,th)
			renderIcon((v.nx - vx)-80,(v.ny-40)+8,80,80,means)
			vx = vx + spl + sl
			r,g,b = tc(a_team)
			shadowText(v.nx - vx,v.ny,a_name,r,g,b,th*.8,th)
			local size = el + spl + sl
			if(size > 0) then
				local dm,dms,maxs = deathMessage(s_name,a_name,s_g,a_g,means,size)
				shadowText(v.nx - maxs,v.ny+th,dm,1,1,1,dms,th/2)
			end
			
			if(dt > .5 and v.nx > 1000) then v.rmv = true end
			
			y = y + (th+10)
		end
		for k,v in pairs(table.Copy(notes)) do
			if(v.rmv) then
				table.remove(notes,k)
			end
		end
	end
	hook.add("Draw2D","sh_notify",drawNotes)
end