--H.clear = true
local deadClients = {}
local GAME_DURATION = 1.5 --minutes
local startTime = LevelTime()

local function GameMinutes()
	return GAME_DURATION*1000*60
end

local freezePlayers = true

function FiredWeapon()
	if(freezePlayers) then return -1 end
end
hook.add("FiredWeapon","sh_lastman",FiredWeapon)

function PlayerMove()
	if(freezePlayers) then return true end
end
hook.add("PlayerMove","sh_lastman",PlayerMove)


if(SERVER) then
//__DL_BLOCK
	downloader.add("lua/sh_lastman.lua")

	message.Precache("lastman_update")
	
	team.CustomScores(true)
	
	local lastKill = 0
	local surviveTimer = nil
	
	local function respawnItems()
		local it = GetEntitiesByType(ET_ITEM)
		for k,v in pairs(it) do
			if(bitAnd(v:GetFlags(),FL_DROPPED_ITEM) == 0) then
				print("^2Respawn: ^3" .. v:Classname() .. "\n")
				v:Respawn()
			else
				print("^1Must Remove: ^3" .. v:Classname() .. "\n")
				v:Remove()
			end
		end
	end
	
	local function sendFreeze()
		local msg = Message()
		message.WriteShort(msg,4)
		SendDataMessageToAll(msg,"lastman_update")
	end
	
	local function sendPLOut(pl)
		local msg = Message()
		message.WriteShort(msg,1)
		message.WriteShort(msg,pl:EntIndex())
		SendDataMessageToAll(msg,"lastman_update")
	end
	
	local function sendReset()
		startTime = LevelTime()
		local msg = Message()
		message.WriteShort(msg,2)
		SendDataMessageToAll(msg,"lastman_update")
	end

	local function sendMessage(str,pl)
		local msg = Message()
		message.WriteShort(msg,3)
		message.WriteString(msg,str)
		if(pl ~= nil) then
			SendDataMessage(msg,pl,"lastman_update")
		else
			SendDataMessageToAll(msg,"lastman_update")
		end
	end
	
	function testStrMessage()
		sendMessage("Line #1\nLine #2")
	end
	
	local function PlayerKilled(pl,inflictor,attacker,damage,means)
		lastKill = LevelTime()
		print("Hook " .. tostring(pl) .. " | " .. tostring(inflictor) .. " | " .. tostring(attacker) .. " | " .. tostring(damage) .. " | " .. tostring(means) .. "\n")
		if(pl == nil) then return end
		table.insert(deadClients,pl)
		print("Player Killed\n")
		sendMessage(pl:GetInfo().name .. " is out!");
		sendPLOut(pl)
		Timer(1,function()
			local t = LevelTime() + 6000000
			pl:SetRespawnTime(t)
			print("Set RespawnTime: " .. t .. "\n")
			
			if(surviveTimer ~= nil) then
				StopTimer(surviveTimer)
			end
			
			surviveTimer = Timer(1,function()
				checkAndPrintSurvivor()
			end)

			if(pl and pl:GetTable() and pl:GetTable().body) then
				pl:GetTable().body:SetNextThink(t)
			end
			--pl:SetAnim(BOTH_DEATH1,ANIM_LEGS,6000)
			--pl:SetAnim(BOTH_DEATH1,ANIM_TORSO,6000)
		end)
	end
	hook.add("PlayerKilled","sh_lastman",PlayerKilled)

	local function countLivePlayers()
		local c = 0
		local last = ""
		for k,v in pairs(GetAllPlayers()) do
			if(v:GetInfo().team ~= TEAM_SPECTATOR) then
				if(v:GetHealth() > 0) then
					c = c + 1
					last = v
				end
			end
		end
		return c,last
	end

	local waitingReset = false
	function checkAndPrintSurvivor()
		local live,last = countLivePlayers()
		if(live <= 1) then
			if(waitingReset == true) then return end
			if(live == 0) then
				sendMessage("Nobody Survived!");
			else
				sendMessage(last:GetInfo().name .. " is the last survivor!\n 1 Point")
				last:SetInfo(PLAYERINFO_SCORE,last:GetInfo().score + 1)
			end
			freezePlayers = true
			sendFreeze()
			waitingReset = true
		end
	end

	local function reset()
		waitingReset = false
		deadClients = {}
		sendReset()
		for k,v in pairs(GetAllPlayers()) do
			local body = v:Respawn()
			if(body ~= nil) then
				body:Remove()
			end
		end
		respawnItems()
		freezePlayers = true
		Timer(3,function() freezePlayers = false end)
	end
	reset()
	
	local function Think()
		if(startTime + GameMinutes() < LevelTime() and waitingReset ~= true) then
			sendMessage("Time's Up, Restarting...")
			startTime = LevelTime()
			reset()
			return
		end
		if(lastKill < LevelTime() - 5000) then
			local live,last = countLivePlayers()
			if(live <= 1 and #deadClients > 0) then
				reset()
			end
		end
	end
	hook.add("Think","sh_lastman",Think)
	

	local function PlayerDamaged(self,inflictor,attacker,damage,meansOfDeath)
		if(self == nil) then return end
		local hp = self:GetInfo()["health"]
		if(hp <= 0) then
			damage = 0
		else
			if((hp - damage) < -40) then
				damage = hp+1
			end
		end
		return damage
	end
	hook.add("PlayerDamaged","sh_lastman",PlayerDamaged)

//__DL_UNBLOCK
else
	local svmessage = ""
	local svmessageTime = 0
	
	local MESSAGE_DURATION = 3000
	
	local function Think()
		util.EnableCenterPrint(false)
	end
	hook.add("Think","sh_lastman",Think)
	
	local function drawTimer()
		local m = GameMinutes()
		local t = m - ((LevelTime() - startTime))
		if(t < 0) then t = 0 else t = t / 1000 end
		local s = math.floor(t % 60)
		if(s < 10) then s = "0" .. s end
		local tstr = math.floor(t/60) .. ":" .. s
		local w = draw.Text2Width(tstr)
		draw.SetColor(1,1,1,1)
		draw.Text2(320 - (w/2), 10, tstr, .8, false)
	end
	
	local function Draw2D()
		local y = 200
		draw.Text(10,y,"^2Players:",10,10)
		local tab = _CG.scores
		for k,v in pairs(tab) do
			local info = util.GetClientInfo(v.client)
			if(info != nil) then	
				if(info.connected and info.team ~= TEAM_SPECTATOR) then
					y = y + 10
					local name = fixcolorstring(info.name)
					draw.SetColor(1,1,1,1)
					if(deadClients[v.client] == true) then
						draw.SetColor(.6,0,0,1)
						name = name .. "[OUT]"
					end
					draw.Text(10,y,name,10,10)
				end
			end
		end
		if(svmessageTime > LevelTime() - MESSAGE_DURATION) then
			local msgC = string.Explode("\n",svmessage)
			local d = (svmessageTime - (LevelTime() - MESSAGE_DURATION)) / MESSAGE_DURATION
			local s = (d/2 + .5)
			local h = 26 * s
			local y = 300
			if(_CG.stats[STAT_HEALTH] <= 0) then
				y = 380
			end
			
			y = y - (h * #msgC) / 2
			for k,v in pairs(msgC) do
				local w = draw.Text2Width(v) * s
				local x = 320 - (w/2)
				draw.SetColor(1,1,1,d)
				draw.Text2(x,y,v,s,false)
				y = y + h
			end
		end
		drawTimer()
		if(_CG.stats[STAT_HEALTH] <= 0) then
			draw.SetColor(0,0,0,.7)
			draw.Rect(0,415,640,60)
			local tstr = "You Are Dead!"
			local s = math.sin(LevelTime()/100)*.06
			local w = draw.Text2Width(tstr) * (.8 + s)
			draw.SetColor(.8,0,0,1)
			draw.Text2(320 - (w/2), 425, tstr, (.8 + s), false)
			tstr = "Wait For The Round To Finish"
			local w = draw.Text2Width(tstr) * .6
			draw.SetColor(1,1,1,.7)
			draw.Text2(320 - (w/2), 450, tstr, .6, false)
		end
	end
	hook.add("Draw2D","sh_lastman",Draw2D)
	
	local dtime = LevelTime()
	function deadview(pos,ang,fovx,fovy)
		if(_CG.stats[STAT_HEALTH] <= 0) then
		local pl = LocalPlayer()
		local legs,torso,head = LoadPlayerModels(pl)
		legs:SetPos(pl:GetPos())
		util.AnimatePlayer(pl,legs,torso)
		util.AnglePlayer(pl,legs,torso,head)
		torso:PositionOnTag(legs,"tag_torso")
		head:PositionOnTag(torso,"tag_head")
		
		local tx = (LevelTime() - dtime)/15000
		if(tx > 1) then tx = 1 end
		tx = 1.0 - tx
		tx = tx * tx
		pos = head:GetPos() + Vector(0,0,70 + tx*-30)
		local normal = VectorNormalize(pos - torso:GetPos())
		local ax = VectorToAngles(normal)
		ang.p = ax.p*-1
		ang.y = ax.y+180
		ang.z = 0
		
		ApplyView(pos,ang)
				legs:Render()
				torso:Render()
				head:Render()

		else
			dtime = LevelTime()
		end
	end
	hook.add("CalcView","sh_lastman",deadview)
	
	local function shouldDraw(str)
		if(_CG.stats[STAT_HEALTH] <= 0) then
			if(str == "HUD_SCOREBOARD") then return false end
			if(str == "HUD_TWOSCORE") then return false end
		end
	end
	hook.add("ShouldDraw","sh_lastman",shouldDraw)
	
	local function HandleMessage(msgid)
		if(msgid == "lastman_update") then
			local t = message.ReadShort()
			if(t == 1) then
				local pl = message.ReadShort()
				deadClients[pl] = true
			elseif(t == 2) then
				deadClients = {}
				startTime = LevelTime()
				util.ClearMarks()
				freezePlayers = true
				Timer(3,function() freezePlayers = false end)
			elseif(t == 3) then
				local msg = message.ReadString()
				svmessage = msg
				svmessageTime = LevelTime()
			elseif(t == 4) then
				freezePlayers = true
			end
		end
	end
	hook.add("HandleMessage","sh_lastman",HandleMessage)
end