local scoreGrabTimer = LevelTime()

local data = 
[[{
	nopicmip
	{
		map "gfx/grad_1_alpha.tga"
		blendfunc blend
		tcMod scale .95 1
	}
}]]
local gradient = CreateShader("gradient",data)

local MAX_SCOREEVENT_TIME = 6000
local msg = scoreboard_messages

local playerIcons = {}
local score_events = {}

local function cachedIcon(ico)
	if(playerIcons[ico] == nil) then
		playerIcons[ico] = LoadShader(ico)	
	end
	return playerIcons[ico]
end

local teamColors = {
	[TEAM_FREE] = {1,1,.2},
	[TEAM_RED] = {1,.2,.2},
	[TEAM_BLUE] = {.2,.2,1},
	[TEAM_SPECTATOR] = {.7,.7,.7},
}

local placeColors = {
	{0,0,.7},
	{.7,0,0},
	{.5,.5,0},
}

local teamNames = {
	[TEAM_FREE] = "Free for all",
	[TEAM_RED] = "Red Team",
	[TEAM_BLUE] = "Blue Team",
	[TEAM_SPECTATOR] = "Spectators",
}

local defer = LoadShader("gfx/2d/defer.tga")
local function drawIcon(x,y,w,h,info)
	local skin = info.skinName
	if(info.team == TEAM_RED) then skin = "red" end
	if(info.team == TEAM_BLUE) then skin = "blue" end
	local path = "models/players/" .. info.modelName .. "/icon_" .. skin .. ".tga"
	local shd = cachedIcon(path)
	if(shd == 0) then shd = defer end
	draw.Rect(x,y,w,h,shd)
end

local function teamCount(team,scores)
	local i = 0
	for k,v in pairs(scores) do
		if(v.team == team) then i = i + 1 end
	end
	return i
end

local function drawPlayerRow(sm,pl,score,info,columns)
	for k,v in pairs(columns) do
		local val = ""
		if(v[3] == "i") then val = info[v[2]] end
		if(v[3] == "s") then val = score[v[2]] end
		draw.Text2(v[4],sm.y,"" .. val,1)
	end
	
	sm.y = sm.y - 10
	drawIcon(sm.x,sm.y,40,40,info)
	sm.y = sm.y + 50
end

local function drawTeamScores(sm,team,scores,columns)
	if(teamCount(team,scores) == 0) then return end

	local me = LocalPlayer():EntIndex()
	
	local r,g,b = unpack(teamColors[team])
	local tstr = teamNames[team]
	
	if(team == TEAM_BLUE or team == TEAM_RED) then
		tstr = tstr .. ": " .. _CG.teamScores[team]
	end
	
	local ns = string.len(tstr)*10
	draw.SetColor(r,g,b,1)
	draw.Rect(sm.x,sm.y,sm.width-sm.inset*2,15,gradient)
	draw.SetColor(0,0,0,1)
	draw.Text((sm.center_x - ns/2)-1,sm.y+2,tstr,10,10)
	draw.SetColor(0,0,0,1)
	draw.Text((sm.center_x - ns/2)+1,sm.y+2,tstr,10,10)
	draw.SetColor(0,0,0,1)
	draw.Text((sm.center_x - ns/2)-1,sm.y+4,tstr,10,10)
	draw.SetColor(0,0,0,1)
	draw.Text((sm.center_x - ns/2)+1,sm.y+4,tstr,10,10)
	draw.SetColor(1,1,1,1)
	draw.Text((sm.center_x - ns/2),sm.y+3,tstr,10,10)
	sm.y = sm.y + 15

	local k2 = 1
	for k,v in pairs(scores) do
		local info = util.GetClientInfo(v.client)
		if(info != nil) then	
			if(info.connected and info.team == team) then
			
				if(v.client == me) then
					draw.SetColor(.5,.5,.5,1)
					draw.Rect(sm.x,sm.y+4,sm.width/2,20,gradient)
				end
			
				if(info.team == TEAM_FREE) then
					local place = k2
					if(k != 1 and scores[k-1].score == v.score) then
						place = place - 1
					end
					if(v.client == me and place <= #placeColors and place > 0) then
						local r,g,b = unpack(placeColors[place])
						draw.SetColor(r,g,b,1)
						draw.Rect(sm.x,sm.y+7,sm.width/1.5,14,gradient)
					end
				end
				
				draw.SetColor(1,1,1,1)
				drawPlayerRow(sm,pl,v,info,columns)
				k2 = k2 + 1
			end
		end
	end
end

local function inEvent()
	local mt = MAX_SCOREEVENT_TIME
	if(#score_events == 0) then return false end
	if(#score_events > 2) then
		mt = mt * .75
	end
	for i=1, #score_events do
		if((LevelTime() - score_events[i][4]) < mt) then return true end
	end
	return false
end

local function drawScoreEvents(sm)
	if(#score_events > 4) then
		table.remove(score_events,1)
	end
	local event_height = 100
	local count = #score_events
	local sy = sm.center_y - (event_height*count)/2
	local ex = sm.end_x
	local y = sy
	for i=1, #score_events do
		local x = sm.x
		local atname = ""
		local atg = GENDER_NEUTER
		local ev = score_events[i]
		local self = util.GetClientInfo(ev[1])
		local attacker = nil
		local t = ev[4]
		local urgent = ev[6]
		local cr,cg,cb = unpack(teamColors[self.team])
		if(ev[2] != -1) then
			attacker = util.GetClientInfo(ev[2])
			atname = attacker.name
			atg = attacker.gender
		end
		local means = ev[3]
		draw.SetColor(cr,cg,cb,1 - math.min((LevelTime() - t) / 500,1))
		if(urgent) then
			draw.SetColor(cr,cg,cb,1 - math.min(((LevelTime() - t) % 500) / 500,1))
		end
		draw.Rect(x,y,sm.width,event_height)
		
		draw.SetColor(1,1,1,1)
		
		if(attacker) then
			drawIcon(x,y,event_height,event_height,attacker)
			x = x + event_height
			draw.Text(x,y,atname,20,event_height/2)
		end
		
		if(self) then
			drawIcon(ex-event_height,y,event_height,event_height,self)
			draw.Text((ex-event_height) - (20*string.len(self.name)),y,self.name,20,event_height/2)
		end

		local message,tw,ts = msg.deathMessage(self.name,atname,self.gender,atg,ev[3],400)
		if(ev[5]) then
			message = ev[5]
			tw = 400 / string.len(ev[5])
			ts = string.len(ev[5])*tw
		end
		if(message) then
			draw.SetColor(1,1,1,1)
			draw.Text(sm.center_x-(ts/2),y+(event_height/2),message,tw,event_height/2)
		end
		
		y = y + event_height
	end
end

local function drawScoreBoard()
	local columns = {}
	local scores = _CG.scores
	local teamScores = _CG.teamScores
	local sm = {}
	sm.width = 640/1.1
	sm.height = 480
	sm.center_x = 320
	sm.center_y = 240
	sm.start_x = sm.center_x - (sm.width/2)
	sm.start_y = sm.center_y - (sm.height/2)	
	sm.end_x = sm.center_x + (sm.width/2)
	sm.end_y = sm.center_y + (sm.height/2)
	sm.inset = 5
	sm.x = sm.start_x + sm.inset
	sm.y = sm.start_y + sm.inset
	
	draw.SetColor(0,0,0,.2)
	draw.Rect(sm.start_x,sm.start_y,sm.width,sm.height)
	
	if(inEvent()) then
		drawScoreEvents(sm)
		return
	else
		score_events = {}
	end
	
	table.insert(columns,{"player","name","i",sm.x + 40})
	table.insert(columns,{"time","time","s",sm.end_x-100})
	table.insert(columns,{"score","score","s",sm.end_x-200})
	
	for k,v in pairs(columns) do
		draw.SetColor(1,1,1,.7)
		draw.Text2(v[4],sm.y + 20,v[1],.6)
	end

	sm.y = sm.y + 40
	
	if(teamScores[TEAM_RED] > teamScores[TEAM_BLUE]) then
		drawTeamScores(sm,TEAM_RED,scores,columns)
		drawTeamScores(sm,TEAM_BLUE,scores,columns)
	else
		drawTeamScores(sm,TEAM_BLUE,scores,columns)
		drawTeamScores(sm,TEAM_RED,scores,columns)	
	end
	drawTeamScores(sm,TEAM_FREE,scores,columns)
	drawTeamScores(sm,TEAM_SPECTATOR,scores,columns)
end

local mdl = LoadModel("models/misc/scoreboard.MD3")

local function doScoreboard(pos,yaw,scale)
	local ref = RefEntity()
	ref:SetAngles(Vector(0,yaw or 90,math.sin(LevelTime()/1200)*5))
	ref:SetPos(pos)
	ref:SetModel(mdl)
	ref:Scale(Vector(scale))
	ref:Render()
	
	local pos = GetTag(ref,"tag_origin")
	local right = GetTag(ref,"tag_right")
	local down = GetTag(ref,"tag_down")
	
	draw.Start3D(pos,right,down,Vector(0,0,0))
	
	drawScoreBoard()
	
	draw.End3D()
end

local svinfo = GetConfigString(CS_SERVERINFO)
local mapName = CS_ValueForKey(svinfo,"mapname")

local function d3d()

	if(mapName != nil) then
		local boards = scoreboard_mapdef[string.lower(mapName)]
		if(boards != nil) then
			for k,v in pairs(boards) do
				doScoreboard(v[1],v[2],v[3])
			end
		end
	end
	--Vector(-550,65,400)
	--doScoreboard(Vector(315,290 + 2400,800),0,1.5)
	--doScoreboard(Vector(315,290 - 2400,800),180,1.5)
	--doScoreboard(Vector(-850,65 - 1200,800),130,1.5)

end
hook.add("Draw3D","cl_scores",d3d)

local function draw2d()
	--drawScoreBoard()
	
	if(scoreGrabTimer < LevelTime()) then
		util.GetScores()
		scoreGrabTimer = LevelTime() + 500
	end
end
hook.add("Draw2D","cl_scores",draw2d)

local function eventTest(p,c,a)
	table.insert(score_events,{0,-1,MOD_GRENADE_SPLASH,LevelTime(),"Hxrmn is totally awesome!",true})
	print("EventTest!\n")
end
concommand.Add("testevent",eventTest)

local flagMessages = {
	" Returned ",
	" Took ",
	" Captured "
}

local teamFlags = {
	"The ^1Red Flag",
	"The ^4Blue Flag"
}

local function otherTeam(team)
	if(team == TEAM_RED) then return TEAM_BLUE end
	if(team == TEAM_BLUE) then return TEAM_RED end
	return TEAM_FREE
end

local function HandleMessage(msgid)
	if(msgid == "deathnotify") then
		local self = message.ReadShort()
		local ci = util.GetClientInfo(self)
		local attacker = message.ReadShort()
		local means = message.ReadShort()
		lmeans = means
		
		if(ci.team != TEAM_FREE) then
			return
		end
		
		if(attacker == self) then attacker = -1 end
		
		table.insert(score_events,{self,attacker,means,LevelTime()})
	end
	
	if(msgid == "flagnotify") then
		local ev = message.ReadShort()
		local self = message.ReadShort()
		local ci = util.GetClientInfo(self)
		local name = ci.name
		local team = ci.team
		
		if(ev != 0) then team = otherTeam(team) end
		
		local msg = name .. flagMessages[ev+1] .. teamFlags[team] .. "."
		
		table.insert(score_events,{self,-1,means,LevelTime(),msg,(ev != 0)})
	end
end
hook.add("HandleMessage","cl_scores",HandleMessage)