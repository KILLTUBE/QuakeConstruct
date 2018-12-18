local function trDown(pos)
	local endpos = vAdd(pos,Vector(0,0,-10000))
	local res = TraceLine(pos,endpos,nil,1)
	return res.endpos
end

if(SERVER) then
//__DL_BLOCK
	downloader.add("lua/sh_spawner.lua")
	
	message.Precache("limbo_status")

	local restrict = {
		[MOD_WATER] = false,
		[MOD_SLIME] = false,
		[MOD_LAVA] = false,
		[MOD_CRUSH] = true,
		[MOD_TELEFRAG] = false,
		[MOD_FALLING] = false,
		[MOD_SUICIDE] = false,
		[MOD_TARGET_LASER] = true,
		[MOD_TRIGGER_HURT] = true,	
	}
	
	--[[local function linker(pl)
		LinkEntity(pl)
	end
	hook.add("ClientThink","sh_spawner",linker)]]
	
	local function sendLimbo(pl,bool)
		local msg = Message()
		message.WriteShort(msg,pl:EntIndex())
		message.WriteShort(msg,boolToInt(bool))
		SendDataMessageToAll(msg,"limbo_status")
	end

	function plspawn(v)
		if(v:GetHealth() > 0 and v:GetTeam() != TEAM_SPECTATOR) then
			v:AddEvent(EV_TAUNT)
			v:SetAnim(TORSO_GESTURE,ANIM_TORSO,2500)
			v:SetAnim(LEGS_JUMP,ANIM_LEGS,0)
			v:SetVelocity(v:GetVelocity() + Vector(0,0,350))
		end
	end
	hook.add("PlayerSpawned","sh_spawner",plspawn)

	local function rdeath()
		local a = math.random(1,3)
		print(a .. "\n")
		if(a == 1) then return BOTH_DEATH1 end
		if(a == 2) then return BOTH_DEATH2 end
		if(a == 3) then return BOTH_DEATH3 end
		return BOTH_DEATH1
	end

	local function Killed(pl,inflictor,attacker,damage,means)
		--if(pl:IsBot()) then return end
		--if(true) then return end
		if(restrict[means]) then return end
		if(pl and pl:IsBot()) then return end
		local team = pl:GetTeam()
		local aim = pl:GetAimAngles()
		pl:GetTable().dpos = pl:GetPos()
		Timer(1,function()
			local pos = pl:GetPos()--pl:GetTable().dpos
			pl:GetTable().spawnlock = true
			pl:SetTeam(TEAM_SPECTATOR)
			pl:GetTable().body = pl:Respawn()
			LinkEntity(pl)
			if(pl:GetTable().body) then
				pl:GetTable().body:SetNextThink(LevelTime() + 10000)
			end
			pl:SetPos(pos)
			pl:SetAimAngles(aim)
			sendLimbo(pl,true)
			--pl:SetAnim(BOTH_DEATH1,ANIM_LEGS,6000)
			--pl:SetAnim(BOTH_DEATH1,ANIM_TORSO,6000)
		end)
		Timer(10,function()
			local aimx = pl:GetAimAngles()
			local pos = trDown(pl:GetPos())
			local vel = pl:GetVelocity()
			local body = pl:GetTable().body
			if(body != nil) then
				CreateTempEntity(vAdd(body:GetPos(),Vector(0,0,-5)),EV_PLAYER_TELEPORT_OUT)
				body:Remove()
				--pos = pl:GetTable().body:GetPos()
			end
			if(pl:GetSpectatorType() == SPECTATOR_FOLLOW) then
				pl:SetSpectatorType(SPECTATOR_FREE)
				pos = nil
			end
			pl:GetTable().spawnlock = false
			pl:SetTeam(team)
			pl:Respawn()
			UnlinkEntity(pl)
			sendLimbo(pl,false)
			pl:SetAimAngles(aimx)
			if(pos != nil) then
				pl:SetPos(pos + Vector(0,0,25))
			end
			pl:SetVelocity(pl:GetVelocity() + vel)
			CreateTempEntity(vAdd(pl:GetPos(),Vector(0,0,-5)),EV_PLAYER_TELEPORT_IN)
		end)
	end
	hook.add("PlayerKilled","sh_spawner",Killed)

	local function deny(pl,team)
		if(team == TEAM_SPECTATOR) then
			return true
		elseif(pl:GetTable().spawnlock) then
			pl:SendMessage("You gotta wait man.",true)
			return false
		end
	end
	hook.add("PlayerTeamChanged","sh_spawner",deny)
//__DL_UNBLOCK
else
	local states = {}
	local function HandleMessage(msgid)
		if(msgid == "limbo_status") then
			local pl = message.ReadShort()
			local state = intToBool(message.ReadShort())
			if(state == true) then print("Limbo On\n") end
			if(state == false) then print("Limbo Off\n") end
			if(pl != nil) then
				states[pl] = state
			end
		end
	end
	hook.add("HandleMessage","sh_spawner",HandleMessage)

	local function dfade(pos)
		local maxlen = 200
		local d = VectorLength(pos - LocalPlayer():GetPos()) / maxlen
		if(d > 1) then d = 1 end
		return d
	end
	
	local fire = LoadShader("fireSphere")
	function d3d()
		local tab = GetEntitiesByClass("player")
		table.insert(tab,LocalPlayer())
		for k,v in pairs(tab) do
			if(states[v:EntIndex()]) then
				v:CustomDraw(true)
				local legs,torso,head = LoadPlayerModels(v)
				legs:SetPos(trDown(v:GetPos()) + Vector(0,0,24))
				
				util.AnimatePlayer(v,legs,torso)
				util.AnglePlayer(v,legs,torso,head)
				
				torso:PositionOnTag(legs,"tag_torso")
				head:PositionOnTag(torso,"tag_head")
				
				local d = dfade(legs:GetPos())
				
				legs:SetColor(.5*d,.3*d,1*d,1)
				torso:SetColor(.5*d,.3*d,1*d,1)
				head:SetColor(.5*d,.3*d,1*d,1)
				
				legs:SetShader(fire)
				torso:SetShader(fire)
				head:SetShader(fire)
				
				legs:Render()
				torso:Render()
				head:Render()
			else
				v:CustomDraw(false)
			end
		end
	end
	hook.add("Draw3D","sh_spawner",d3d)
end