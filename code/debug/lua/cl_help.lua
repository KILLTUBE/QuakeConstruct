local HINT_DURATION = 35000
local HINT_TIME = LevelTime() + HINT_DURATION

hook.add("InitialSnapshot","cl_help",function() HINT_TIME = LevelTime() + HINT_DURATION end)

local function launchHelp()
	print("Help Launch.\n")
	HINT_TIME = -HINT_DURATION
	doMarkupFile("help/index.qml",true)
end

local function helpkey(key,state)
	if(key == K_F3 and !state) then
		launchHelp()
	end
end
hook.add("KeyEvent","cl_help",helpkey)

local function helpHint()
	local dt = HINT_TIME - LevelTime()
	if(dt > 0) then
		local dtx = (dt / HINT_DURATION)*10
		if(dtx > 1) then dtx = 1 end
		local wave = math.sin(dt/500)
		local size = 10
		local str = "Press F3 for help."
		local len = string.len(str)*size
		draw.SetColor(0,.1,.2,dtx)
		draw.Text(320-(len/2),20,str,size,size)
		
		draw.SetColor(1,1,1,math.abs(wave) * dtx)
		draw.Text(320-(len/2),20,str,size,size)
	end
end

local function d2d()
	helpHint()
end
hook.add("Draw2D","cl_help",d2d)