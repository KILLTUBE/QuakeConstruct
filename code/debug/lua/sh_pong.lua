ClearNetworkedTable(211)
ClearNetworkedTable(212)
ClearNetworkedTable(213)

local player1 = CreateNetworkedTable(211)
local player2 = CreateNetworkedTable(212)
local game = CreateNetworkedTable(213)

local function def(var,value)
	return var or value
end

local function calcball(ball)
	local x = 0
	local y = 0
	if(ball.started == 1) then
		local t = ball.btime
		if(t == nil) then return 0,0 end
		
		x = ball.bx + (ball.vx/1000) * (LevelTime() - t)
		y = ball.by + (ball.vy/1000) * (LevelTime() - t)
	end
	return x,y
end

function PlayerMove(pm,walk,forward,right)
	//__DL_BLOCK
	if(SERVER) then
		local f,r,u = pm:GetMove()
		local index = pm:EntIndex()
		local entity = nil
		
		for k,v in pairs(GetAllPlayers()) do
			if(v:EntIndex() == index) then entity = v end
		end
		if(entity == nil) then return end
		
		local ready = 0
		if(u == 127) then ready = 1 end
		if(index == 0) then
			player1.paddle_y = f
			if(ready != 0 and game.started == 0) then player1.ready = ready end
		else
			player2.paddle_y = f
			if(ready != 0 and game.started == 0) then player2.ready = ready end
		end
	end
	//__DL_UNBLOCK
	return true
end
hook.add("PlayerMove","sh_pong",PlayerMove)

if(SERVER) then
//__DL_BLOCK
	downloader.add("lua/sh_pong.lua")
	
	local ball_vx = 0.6
	local ball_vy = 0.65
	local function initGame()
		game.hit = 0
		game.started = 0
		game.bx = 0
		game.by = 0
		game.vx = math.cos(math.random(360)/57.3)*0.65
		game.vy = math.sin(math.random(360)/57.3)*0.65
		game.bsize = .04
		game.btime = LevelTime()
	end
	
	local function initPlayer(pl,client)
		pl.paddle_y = 0
		pl.paddle_size = .2
		pl.score = 0
		pl.client = client
		pl.ready = 0
	end
	
	local function initAllPlayers()
		initPlayer(player1,0)
		initPlayer(player2,1)
		--player2.paddle_size = .06
	end
	
	initAllPlayers()
	initGame()
	
	local function startGame()
		game.btime = LevelTime()
	end
	
	local function playerScored(pl)
		pl.score = pl.score + 1
		initGame()
		player1.ready = 0
		player2.ready = 0
	end
	
	local function bump_paddle(x,y)
		game.vx = game.vx * -1.15
		game.vy = game.vy + (math.random(-10,10)*.03)
		if(game.vy > 2) then game.vy = 2 end
		if(game.vy < -2) then game.vy = -2 end
		game.bx = x
		game.by = y
		game.btime = LevelTime()-20
		game.hit = 0
		game.hit = 1	
	end
	
	local lastx,lasty = 0,0
	local function frame()
		if(game.started == 0) then 
			if(player1.ready == 1 and player2.ready == 1) then
				game.btime = LevelTime()
				game.started = 1
			end
			lastx = nil
			lasty = nil
			return 
		end
		local x,y = calcball(game)
		local s = game.bsize
		local p1y = player1.paddle_y / 127
		local p2y = player2.paddle_y / 127
		local p1s = player1.paddle_size
		local p2s = player2.paddle_size
		
		lastx = lastx or x
		lasty = lasty or y
		
		if(y+s >= 1 or y-s <= -1) then
			game.vy = game.vy * -1
			game.bx = x
			game.by = y
			game.btime = LevelTime()-20
			game.hit = 0
			game.hit = 1
		end
		
		if(x < -.85 and lastx > -.85 and y < p1y + p1s and y > p1y - p1s) then
			bump_paddle(x,y)
			return
		end
		
		if(x > .85 and lastx < .85 and y < p2y + p2s and y > p2y - p2s) then
			bump_paddle(x,y)
			return
		end
		
		if(x-s <= -2) then
			playerScored(player2)
		end
		
		if(x+s >= 2) then
			playerScored(player1)
		end
		lastx = x
		lasty = y
	end
	hook.add("Think","sh_pong",frame)
	
	local function ready(str,v)
		if(str == "ReadyForPong") then
			print("Ready\n")
			Timer(.5,function()
				print("VarSet1\n")
				game:SendVars(v)
			end)
			Timer(1,function()
				print("VarSet2\n")
				player1:SendVars(v)
			end)
			Timer(1.5,function()
				print("VarSet3\n")
				player2:SendVars(v)
			end)
		end
	end
	hook.add("MessageReceived","sh_pong",ready)
	
	for k,v in pairs(GetAllPlayers()) do
		--ready("ReadyForPong",v)
		--game:SendVars(v)
		--player1:SendVars(v)
		--player2:SendVars(v)
	end
//__DL_UNBLOCK
else
	local fire = {
		LoadSound("sound/weapons/machinegun/machgf1b.wav"),
		LoadSound("sound/weapons/machinegun/machgf2b.wav"),
		LoadSound("sound/weapons/machinegun/machgf3b.wav"),
		LoadSound("sound/weapons/machinegun/machgf4b.wav"),
	}

	local mx = 0
	local my = 0
	local active = true
	local function paddleInfo(scale)
		local p1y = def(player1.paddle_y,0) / 127
		local p2y = def(player2.paddle_y,0) / 127
		local p1size = def(player1.paddle_size,4)
		local p2size = def(player2.paddle_size,4)
		if(scale) then
			p1size = p1size * 480
			p2size = p2size * 480
			p1y = (p1y * 240) + 240
			p2y = (p2y * 240) + 240
		end
		return p1y,p2y,p1size,p2size
	end
	
	local function drawPlayers()
		local p1y,p2y,p1size,p2size = paddleInfo(true)
		local cl1 = def(player1.client,-1)
		local cl2 = def(player2.client,-1)
		draw.SetColor(1,0,0,1)
		draw.Rect(20,p1y-p1size/2,20,p1size)
		draw.SetColor(0,0,1,1)
		draw.Rect(600,p2y-p2size/2,20,p2size)
		
		if(cl1 != -1) then
			local ptxt = GetEntityByIndex(cl1):GetInfo().name .. ": " .. player1.score
			draw.SetColor(1,0,0,1)
			draw.Text(20,10,ptxt,20,20)
			if(player1.ready == 1) then
				draw.SetColor(1,1,1,1)
				draw.Text(20,30,"Ready",20,20)
			else
				draw.SetColor(1,1,1,math.abs(math.sin(LevelTime()/500)))
				draw.Text(20,30,"Press Space",20,20)
			end
		end

		if(cl2 != -1) then
			local ptxt = GetEntityByIndex(cl2):GetInfo().name .. ": " .. player2.score
			draw.SetColor(0,0,1,1)
			draw.Text(620-string.len(ptxt)*20,10,ptxt,20,20)
			if(player2.ready == 1) then
				draw.SetColor(1,1,1,1)
				draw.Text(620-string.len("Ready")*20,30,"Ready",20,20)
			else
				draw.SetColor(1,1,1,math.abs(math.sin(LevelTime()/500)))
				draw.Text(620-string.len("Press Space")*20,30,"Press Space",20,20)
			end
		end
	end
	
	local lastx,lasty = 0,0
	local function drawPong(border)
		draw.SetColor(1,1,1,border)
		draw.Rect(0,0,4,480)
		draw.Rect(0,0,640,4)
		draw.Rect(640-4,0,4,480)
		draw.Rect(0,480-4,640,4)
	
		local p1y,p2y,p1s,p2s = paddleInfo(false)
		local cx,cy = calcball(game)
		if(cx < -.85 and lastx > -.85 and cy < p1y + p1s and cy > p1y - p1s) then cx = -.85 end
		if(cx > .85 and lastx < .85 and cy < p2y + p2s and cy > p2y - p2s) then cx = .85 end
		if(cy > (1 - game.bsize)) then cy = (1 - game.bsize) end
		if(cy < (-1 + game.bsize)) then cy = (-1 + game.bsize) end
		lastx = cx
		lasty = cy
		
		local ball_x = (cx * 320) + 320
		local ball_y = (cy * 240) + 240
		local ball_sizex = def(game.bsize,.01)*640
		local ball_sizey = def(game.bsize,.01)*480
		
		
		if(game.hit == 1) then
			PlaySound(fire[math.random(1,#fire)])
			game.hit = 0
		end
		
		local r,g,b = hsv(LevelTime()/2,1,1)
		draw.SetColor(r,g,b,1)
		draw.Rect(mx-1,my-1,2,2)
		draw.Rect(ball_x-ball_sizex/2,ball_y-ball_sizey/2,ball_sizex,ball_sizey)
		drawPlayers()
	end

	local rlvl = 10
	local dist = 0
	local rrx = 0
	local rry = 0
	local trail = RefEntity()
	
	local data = 
	[[{
		cull back
		deformVertexes wave 10000 sin 1 1 0 0
		polygonoffset
		{
			map $whiteimage
			rgbGen entity
			alphaGen entity
		}
	}]]
	local cullfx = CreateShader("f",data)
	
	local data = 
	[[{
		{
			blendfunc add
			map $whiteimage
			//tcMod scroll 0  0.7
			alphaGen vertex
			rgbGen vertex
			//tcGen environment
		}
	}]]
	local trailfx1 = CreateShader("f",data)
	
	trail:SetType(RT_TRAIL)
	trail:SetTrailLength(10)
	trail:SetRadius(.4)
	trail:SetShader(trailfx1)
	trail:SetColor(1,1,1,1)
	trail:SetTrailFade(FT_COLOR)
	
	local function renderOutline(ref)
		ref:Render()
		ref:SetColor(1,1,1,1)
		ref:SetShader(cullfx)
		ref:Render()	
	end
	
	local function drawPlayer(cid,pos,s)
		local pl = GetEntityByIndex(cid)
		if(pl == nil) then return end
		local legs,torso,head = LoadPlayerModels(pl)
		legs:SetPos(pos)
		
		util.AnimatePlayer(pl,legs,torso)

		if(cid == 0) then
			legs:SetAngles(Vector(0,-90,0))
		else
			legs:SetAngles(Vector(0,90,0))
		end
		legs:Scale(Vector(s,s,s))
		
		torso:SetAngles(Vector(0,0,0))
		torso:PositionOnTag(legs,"tag_torso")
		head:PositionOnTag(torso,"tag_head")
		
		renderOutline(legs)
		renderOutline(torso)
		renderOutline(head)
	end
	
	local function d3d()
		if(active) then
			util.LockMouse(true)
			draw.SetColor(0,0,0,.5)
			draw.Rect(0,0,640,480)
			
			local ballVec = Vector()
			local p1p = Vector()
			local p2p = Vector()
			--drawPong()
			
			if(KeyIsDown(K_ENTER)) then --enterquit
				active = false
			end
			local cx,cy = calcball(game)
			local rx = cx--(mx/320) - 1
			local ry = cy--(my/240) - 1
			rrx = rrx + (rx - rrx) * .05
			rry = rry + (ry - rry) * .05
			
			local ang = Vector(rry*rlvl,rrx*rlvl,.5)
			
			local forward,right,up = AngleVectors(ang)
			right.y = right.y * -1
			
			forward = _CG.refdef.forward
			
			if(game.started == 1) then
				dist = dist + (6-dist) * .04
			else
				dist = dist + (0-dist) * .04
			end
			
			local pos = (_CG.refdef.origin + forward*(13.2 + dist)) - up*10
			pos = pos + right * (rrx * rlvl/2)
			pos = pos + up * (rry * rlvl/2)
			
			local v1 = (pos - right*13.4)
			local v2 = (pos + right*13.4)
			local v3 = (v2 + up*20)
			local v4 = (v1 + up*20)
			
			render.Quad(v1,v2,v3,v4,nil,0,0,0,0)
			draw.Start3D(v3,v4,v2,forward)
			
			drawPong(dist/6)
			
			local p1y,p2y,p1s,p2s = paddleInfo(true)
			local pld = (1.2) + .4 * (1 - (dist/6))
			
			ballVec = draw.Get3DCoord((lastx * 320) + 320,(lasty * 240) + 240)
			p1p = draw.Get3DCoord(((-pld)*320) + 320,p1y)
			p2p = draw.Get3DCoord(((pld)*320) + 320,p2y)
			draw.End3D()
			
			local r,g,b = hsv(LevelTime()/2,1,1)
			trail:SetColor(r,g,b,1)
			trail:SetPos(ballVec)
			if(math.abs(game.vx) > 4) then
				trail:SetTrailLength(10)
			else
				trail:SetTrailLength(5)
			end
			if(math.abs(game.vx) > 2) then
				trail:Render()
			end
			
			drawPlayer(0,p1p,.08)
			drawPlayer(1,p2p,.08)
		else
			util.LockMouse(false)
		end
	end
	hook.add("Draw3D","sh_pong",d3d)
	hook.add("AllowGameSound","sh_pong",function(sound) return !active end)

	function view(pos,ang,fovx,fovy)
		ApplyView(pos,Vector(rry*rlvl,rrx*rlvl,0),fovx,fovy)
	end
	hook.add("CalcView","sh_pong",view)
	
	local function moused(x,y)
		mx = mx + x
		my = my + y
		
		if(mx > 640) then mx = 640 end
		if(mx < 0) then mx = 0 end
		
		if(my > 480) then my = 480 end
		if(my < 0) then my = 0 end
	end
	hook.add("MouseEvent","sh_pong",moused)
	
	local function UserCmd(pl,angle,fm,rm,um,buttons,weapon)
		if(active) then
			fm = ((my/480) * 254)-127
			rm = LocalPlayer():EntIndex()
			SetUserCommand(Vector(0,0,0),fm,0,um,buttons,0)
			--print(fm .. "\n")
		end
	end
	hook.add("UserCommand","sh_pong",UserCmd)

	local function noNuthin(str)
		if(!active) then return true end
		if(str == "WORLD") then return false end
		if(str == "ENTITIES") then return false end
		--if(str == "HUD") then return false end
		if(str == "HUD_DRAWGUN") then return false end
	end
	hook.add("ShouldDraw","sh_pong",noNuthin);
	SendString("ReadyForPong")
end