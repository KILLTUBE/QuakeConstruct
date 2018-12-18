local function centerText(y,str,tw,th)
	local sw = string.len(str)*tw
	draw.Text(320 - sw/2,y,str,tw,th)
	return y + th
end

local function centerText2(y,str,ts)
	local tw = 18*ts
	local sw = string.len(str)*tw
	draw.Text2(320 - sw/2,y,str,ts,0)
	return y + 25
end

local console = LoadShader("textures/sfx/console02")
local t = 0

local function togametype(gt)
	gt = tonumber(gt)
	if(gt == GT_FFA) then return "Free For All" end
	if(gt == GT_TOURNAMENT) then return "Tournament" end
	if(gt == GT_SINGLE_PLAYER) then return "Single Player" end
	if(gt == GT_TEAM) then return "Team Deathmatch" end
	if(gt == GT_CTF) then return "Capture The Flag" end
	return "Unknown Gametype"
end

local function drawRules(sysinfo,svinfo,w,h)
	local gametype = togametype(CS_ValueForKey(svinfo,"g_gametype"))
	local fraglimit = CS_ValueForKey(svinfo,"fraglimit")
	local timelimit = CS_ValueForKey(svinfo,"timelimit")
	local caplimit = CS_ValueForKey(svinfo,"capturelimit")
	local cheats = CS_ValueForKey(sysinfo,"sv_cheats")
	local pure = CS_ValueForKey(sysinfo,"sv_pure")
	pure = "1"
	if(cheats == "1") then cheats = "Cheats are enabled" else cheats = nil end
	if(pure == "1") then pure = "Pure server" else pure = nil end
	
	draw.SetColor(0,0,0,.7)
	
	w = w + 100
	h = h /2
	local y = 240-h/2
	local x = 320-w/2
	
	draw.Rect(x,y,w,h)
	
	draw.SetColor(1,1,1,1)
	x=x+2
	y=y+2
	if(gametype != "") then draw.Text(x-1,y,gametype,17,18); y=y+20 end
	if(fraglimit != "" and fraglimit != "0") then draw.Text(x,y,"Frag Limit: " .. fraglimit,12,12); y=y+14 end
	if(timelimit != "" and timelimit != "0") then draw.Text(x,y,"Time Limit: " .. timelimit,12,12); y=y+14 end
	if(caplimit != "" and caplimit != "0") then draw.Text(x,y,"Capture Limit: " .. caplimit,12,12); y=y+14 end
	if(cheats) then draw.Text(x,y,cheats,10,10); y=y+12 end
	if(pure) then draw.Text(x,y,pure,10,10); y=y+12 end
	--cheats
	
	draw.SetColor(1,1,1,1)
end

function d2d(tab)
	if(tab == nil) then tab = {} end
	draw.SetColor(0,0,0,1)
	draw.Rect(0,0,640,480)
	
	local svinfo = GetConfigString(CS_SERVERINFO)
	local sysinfo = GetConfigString(CS_SYSTEMINFO)
	
	local mapname = CS_ValueForKey(svinfo,"mapname")
	local host = CS_ValueForKey(svinfo,"sv_hostname")
	local maptext = GetConfigString(CS_MESSAGE)
	local motd = GetConfigString(CS_MOTD)
	local levelshot = LoadShader("levelshots/" .. mapname .. ".tga")
	local detail = LoadShader("levelShotDetail")
	if(levelshot == 0) then
		levelshot = LoadShader("menu/art/unknownmap")
	end
	
	local w,h = 420,300
	
	draw.SetColor(1,1,1,1)
	draw.RectRotated(600,440,60,60,console,-t*10)
	
	local y = centerText2(10,"Connecting to " .. host,1)
	y = centerText2(y+2,"Loading " .. (tab.loadString or ""),.5)
	
	draw.Rect((320-w/2)-4,(240-h/2)-4,w+8,h+8)
	draw.Rect((320-(w+100)/2)-4,(240-h/4)-4,(w+100)+8,(h/2)+8)
	
	draw.Rect(320-w/2,240-h/2,w,h,levelshot)
	draw.Rect(320-w/2,240-h/2,w,h,detail,0,0,2.5,2)
	
	centerText2((240-h/2) - 25,mapname,.75)
	
	local ny = 245+h/2
	ny = centerText2(ny,maptext,.75)
	centerText(ny,motd,10,10)
	
	drawRules(sysinfo,svinfo,w,h)
	
	local x = 0
	y = 400
	
	if(tab.playerIcons) then
		for k,v in pairs(tab.playerIcons) do
			draw.Rect(x,y,40,40,v)
			x = x + 40
		end
	end
	
	x = 0
	y = y + 40
	
	if(tab.itemIcons) then
		for k,v in pairs(tab.itemIcons) do
			draw.Rect(x,y,20,20,v)
			x = x + 22
		end
	end
	
	t = t + 2
end
hook.add("DrawInfo","cl_ginfo",d2d)
--hook.add("Draw2D","cl_ginfo",d2d)