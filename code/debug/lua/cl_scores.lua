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

local playerIcons = {}

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

local function drawIcon(x,y,w,h,info)
	local path = "models/players/" .. info.modelName .. "/icon_" .. info.skinName .. ".tga"
	local shd = cachedIcon(path)
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
			
				local place = k2
				if(k != 1 and scores[k-1].score == v.score) then
					place = place - 1
				end
				if(v.client == me and place <= #placeColors and place > 0) then
					local r,g,b = unpack(placeColors[place])
					draw.SetColor(r,g,b,1)
					draw.Rect(sm.x,sm.y+7,sm.width/1.5,14,gradient)
				end
				
				draw.SetColor(1,1,1,1)
				drawPlayerRow(sm,pl,v,info,columns)
				k2 = k2 + 1
			end
		end
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
	
	--[[draw.Start3D(right,pos,down + (right - pos),Vector(0,0,0))

	drawScoreBoard()
	
	draw.End3D()]]
end

local function d3d()

	--Vector(-550,65,400)
	--doScoreboard(Vector(-850,65 + 1200,800),50,1.5)
	--doScoreboard(Vector(-850,65 - 1200,800),130,1.5)
	--[[local base = _CG.refdef.origin
	local normal = _CG.refdef.forward
	local angle = VectorToAngles(normal)
	local f,r,u = AngleVectors(angle)
	
	local pos = base + (f * 20)
	
	pos = pos - (r*5)
	pos = pos + (u*5)
	
	local right = pos + (r*10)
	local down = pos - (u*10)]]
	

end
hook.add("Draw3D","cl_scores",d3d)

local function shouldDraw(d)
	if(d == "HUD_SCOREBOARD") then return false end
end
hook.add("ShouldDraw","cl_scores",shouldDraw)

local function draw2d()
	if(_CG.showScores or _CG.stats[STAT_HEALTH] <= 0) then drawScoreBoard() end
	
	if(scoreGrabTimer < LevelTime()) then
		util.GetScores()
		scoreGrabTimer = LevelTime() + 500
	end
end
hook.add("Draw2D","cl_scores",draw2d)