//__DL_BLOCK
if(SERVER) then
	downloader.add("lua/sidescroller.lua")
	local function BlockAdjust(pl)
		return false
	end
	hook.add("ShouldAdjustAngle","sidescroller",BlockAdjust)
	
	local function NoFallDamage(self,inflictor,attacker,damage,meansOfDeath)
		if(meansOfDeath == MOD_FALLING) then
			--return 0
		end
	end
	hook.add("PlayerDamaged","RemoveFallDamage",NoFallDamage)
	
	local function spawn(cl)
		local wp = WP_GRENADE_LAUNCHER
		--cl:GiveWeapon(wp)
		--cl:SetWeapon(wp)
		--cl:SetAmmo(wp,-1)	
	end
	hook.add("PlayerSpawned","sidescroller",spawn)
end
//__DL_UNBLOCK

local contents = gOR(CONTENTS_SOLID,CONTENTS_PLAYERCLIP)
local ind = {}
local jump = nil
local smoker = nil
--
if(CLIENT) then
	jump = LoadSound("sound/world/jumppad.wav")
	local flare = LoadShader("smokePuff")
	
	smoker = function(pos,vel)
		local le2 = LocalEntity()
		le2:SetVelocity(Vector(0,0,100))
		local ref = RefEntity()
		ref:SetRotation(math.random(360))
		ref:SetType(RT_SPRITE)
		ref:SetShader(flare)
		ref:SetRadius(15 + math.random(0,10))
		ref:SetPos(pos)

		le2:SetRefEntity(ref)
		le2:SetStartTime(LevelTime())
		le2:SetEndTime(LevelTime() + 600)
		le2:SetType(LE_FADE_RGB)
		le2:SetColor(1,1,1,1)
		le2:SetPos(pos)
		le2:SetVelocity(vel * .36)
		le2:SetTrType(TR_LINEAR)	
	end
end

local function OnGround(pm,mask)
	local start = pm:GetPos()
	local tr = TraceLine(start,start - Vector(0,0,1),nil,mask,pm:GetMins(),pm:GetMaxs())
	return tr.fraction != 1
end

local function CheckDoubleJump(pm,mask)
	local mx,my,mz = pm:GetMove()
	local pl = pm:EntIndex()
	local pos = pm:GetPos()
	
	ind[pl] = ind[pl] or {}
	ind[pl].last_up = ind[pl].last_up or 0
	ind[pl].canJump = false
	ind[pl].jumpcount = ind[pl].jumpcount or 0
	ind[pl].jumptimer = ind[pl].jumptimer or 0
	ind[pl].range = ind[pl].range or 0
	if(ind[pl].last_up != 127 and mz == 127) then
		ind[pl].canJump = true
	end
	ind[pl].last_up = mz
	
	if(mz == -127) then 
		local v = pm:GetVelocity()
		local range = ind[pl].range
		
		if(range < 500 and v.z < -range) then
			v.z = -range
			
			pm:SetVelocity(v)
			
			if(!OnGround(pm,mask)) then
				ind[pl].smtime = ind[pl].smtime or LevelTime()
				if(ind[pl].smtime < LevelTime()) then
					if(smoker) then smoker(pos - Vector(0,0,30),v) end
					ind[pl].range = ind[pl].range + (ind[pl].range/2)
					ind[pl].smtime = LevelTime() + (ind[pl].range)
				end
			end
		end
	end
	
	if(ind[pl].canJump and ind[pl].jumptimer < LevelTime() and ind[pl].jumpcount < 2) then
		local v = pm:GetVelocity()
		if(v.z < 0) then
			pm:SetVelocity(Vector(v.x,v.y,450))
		else
			pm:SetVelocity(Vector(v.x,v.y,v.z + 450))
		end
		ind[pl].jumptimer = LevelTime() + 300
		ind[pl].jumpcount = ind[pl].jumpcount + 1
		PM_AddEvent(EV_JUMP)
		if(CLIENT) then
			local ent = GetEntityByIndex(pl)
			if(ent != nil) then
				if(smoker) then smoker(pos - Vector(0,0,30),v) end
			end
		end
	end
	
	if(OnGround(pm,mask)) then
		ind[pl].jumptimer = LevelTime() + 250
		ind[pl].jumpcount = 0
		ind[pl].range = 30
	end
end

function PlayerMove(pm,walk,forward,right)
	local strt = pm:GetPos()
	pm:SetMask(contents)
	
	
	local angles = pm:GetAngles()
	if(angles.y > 0 and angles.y < 180) then
		angles.y = 90
	else
		angles.y = -90
	end

	pm:SetAngles(angles)
	--print(tostring(pm:GetAngles()) .. "\n")
	
	if(pm:GetType() == PM_DEAD) then
		PM_Drop()
		PM_AirMove()
		
		local v = pm:GetVelocity()
		--v.x = 0
		pm:SetVelocity(v)
		
		return true
	end
	if(pm:WaterLevel() > 1) then
		PM_WaterMove()
	elseif(walk) then
		PM_WalkMove()
	else
		PM_AirMove()
	end
	
	local v = pm:GetVelocity()
	v.y = v.y - v.x
	v.x = 0
	pm:SetVelocity(v)

	local p = pm:GetPos()
	p.x = strt.x
	pm:SetPos(p)
	
	CheckDoubleJump(pm,contents)
	
	return true
end
hook.add("PlayerMove","sidescroller",PlayerMove)

if(CLIENT) then
	local aim = 0
	local flip = false
	local newbits = 0
	local realyaw = 0
	local ddist = 0
	local mdelta = {0,0}
	local vdelta = {0,0}
	local FLIP_AXIS = true
	
	local fx = LoadShader("railCore")
	local flare = LoadShader("flareShader")
	local function getBeamRef(v1,v2,r,g,b,size)
		local st1 = RefEntity()
		st1:SetType(RT_RAIL_CORE)
		st1:SetPos(v1)
		st1:SetPos2(v2)
		st1:SetColor(r,g,b,1)
		st1:SetRadius(size or 12)
		st1:SetShader(fx)
		return st1
	end
	
	local function rpoint(pos,r,g,b,size)
		local s = RefEntity()
		s:SetType(RT_SPRITE)
		s:SetPos(pos)
		s:SetColor(r,g,b,1)
		s:SetRadius(size or 8)
		s:SetShader(flare)
		return s
	end
	
	local function ShouldDraw(id)
		if(id == "HUD_DRAWGUN") then return false end
	end
	hook.add("ShouldDraw","sidescroller",ShouldDraw)
	
	local h = 1
	local function drawPlayer(pl)
		h = h + 2*Lag()
		if(h > 360) then h = 1 end
		if(pl:GetInfo().health <= -40) then return end
		local legs,torso,head = LoadPlayerModels(pl)
		legs:SetPos(pl:GetPos())
		
		util.AnimatePlayer(pl,legs,torso)
		util.AnglePlayer(pl,legs,torso,head)

		--torso:Scale(Vector(1.2,1.2,1.2))
		
		torso:PositionOnTag(legs,"tag_torso")
		head:PositionOnTag(torso,"tag_head")
		
		util.PlayerWeapon(pl,torso)
		
		--head:Scale(Vector(2,2,2))
		
		legs:Render()
		torso:Render()
		head:Render()
		
		local brt = .4
		if(LocalPlayer() != pl) then brt = .2 end
		local r,g,b = hsv(1,1,brt)
		local forward = VectorForward(pl:GetLerpAngles())
		local pos = pl:GetPos() + Vector(0,0,25)
		local ep = pos + forward * 3000
		local tr = TraceLine(pos,ep,pl,1)
		pos.z = pos.z - 2
		pos = pos + forward*30
		getBeamRef(pos,tr.endpos,r,g,b,5):Render()
		rpoint(tr.endpos,r,g,b,10):Render()
	end
	
	local function draw3d()
		local players = GetAllPlayers()
		local pl = LocalPlayer()
		table.insert(players,pl)
		for k,v in pairs(players) do
			v:CustomDraw(true)
			drawPlayer(v)
		end
	end
	hook.add("Draw3D","sidescroller",draw3d)

	local function line(x1,y1,x2,y2,size)
		local dx = x2 - x1
		local dy = y2 - y1
		local cx = x1 + dx/2
		local cy = y1 + dy/2
		local rot = math.atan2(dy,dx)*57.3
		
		draw.RectRotated(cx,cy,math.sqrt(dx*dx + dy*dy),size or 2,nil,rot)
	end
	
	local function highest(el,tab)
		local v = -99999
		for i=1, #tab do
			if(tab[i][el] > v) then v = tab[i][el] end
		end
		return v
	end

	local function lowest(el,tab)
		local v = 99999
		for i=1, #tab do
			if(tab[i][el] < v) then v = tab[i][el] end
		end
		return v
	end

	local function drawLines(tab,label,sx,sy,al)
		local min_x = highest('x',tab) + sx
		local max_x = lowest('x',tab) + sy
		local min_y = highest('y',tab) + sx
		local max_y = lowest('y',tab) + sy
		
		local col = {.8,0,0,al}
		if(string.find(string.lower(label),"health")) then col = {.3,.6,.9,al} end
		if(string.find(string.lower(label),"armor")) then col = {.3,.9,.3,al} end
		
		draw.SetColor(unpack(col))
		
		line(min_x,min_y,max_x,min_y)
		line(max_x,min_y,max_x,max_y)
		line(max_x,max_y,min_x,max_y)
		line(min_x,max_y,min_x,min_y)
		
		if(label != nil) then
			local dx = min_x - max_x
			local tl = (draw.Text2Width(label)*.4)/2
			
			local tx = (max_x + (dx/2) - tl)
			local ty = max_y-15
			
			draw.SetColor(0,0,0,al)
			draw.Text2(tx-1,ty,label,.4)
			draw.Text2(tx+1,ty,label,.4)
			draw.Text2(tx,ty-1,label,.4)
			draw.Text2(tx,ty+1,label,.4)
			
			draw.SetColor(unpack(col))
			draw.Text2(tx,ty,label,.4)
		end
	end
	
	local function BoundingBox(model,pos,angle,label,al)
		if(VectorLength(LocalPlayer():GetPos() - pos) > 250) then return end
		if(TraceLine(LocalPlayer():GetPos()+Vector(0,0,20),pos).fraction != 1) then return end
		local f,r,u = AngleVectors(angle or Vector(0,0,0))
		local mins,maxs = render.ModelBounds(model)
		local ts0 = VectorToScreen(pos)
		
		if(ts0.z > 0) then return end
		
		local ts1 = VectorToScreen(pos + (f*maxs.x) + (r*mins.y) + (u*mins.z))
		local ts2 = VectorToScreen(pos + (f*maxs.x) + (r*maxs.y) + (u*mins.z))
		local ts3 = VectorToScreen(pos + (f*mins.x) + (r*maxs.y) + (u*mins.z))
		local ts4 = VectorToScreen(pos + (f*mins.x) + (r*mins.y) + (u*mins.z))
		
		local ts5 = VectorToScreen(pos + (f*maxs.x) + (r*mins.y) + (u*maxs.z))
		local ts6 = VectorToScreen(pos + (f*maxs.x) + (r*maxs.y) + (u*maxs.z))
		local ts7 = VectorToScreen(pos + (f*mins.x) + (r*maxs.y) + (u*maxs.z))
		local ts8 = VectorToScreen(pos + (f*mins.x) + (r*mins.y) + (u*maxs.z))
		
		if(ts1.z < 0 and ts2.z < 0 and ts3.z < 0 and ts4.z < 0 and
		   ts5.z < 0 and ts6.z < 0 and ts7.z < 0 and ts8.z < 0) then
			drawLines({ts1,ts2,ts3,ts4,ts5,ts6,ts7,ts8},label,0,0,al)
		end
	end
	
	local sptimes = {}
	local function draw2d()
		draw.SetColor(1,1,1,1)
		
		--draw.Rect(vdelta[1],vdelta[2],20,20)
		
		local players = GetAllPlayers()
		local pl = LocalPlayer()
		table.insert(players,pl)
		for k,v in pairs(players) do
			local hp = v:GetInfo().health
			if(hp > 0 and v:IsPlayer()) then
				local off = false
				local p,d = VectorToScreen(v:GetPos() + Vector(0,0,50))
				if(p.y > 480) then p.y = 480 off=true end
				if(p.y < 0) then p.y = 0 off=true end				
				if(p.x > 640) then p.x = 640 off=true end
				if(p.x < 0) then p.x = 0 off=true end
				if(d) then
					if(off) then
						local dx,dy = 320 - p.x,240 - p.y
						local ang = math.atan2(dy,dx)
						local vdx,vdy = math.cos(ang),math.sin(ang)
						
						draw.SetColor(1,1,1,1)
						line(p.x,p.y,p.x + vdx*20,p.y + vdy*20)
						
						p.x = p.x + vdx*50
						p.y = p.y + vdy*30
					end
					draw.SetColor(1,1,1,1)
					local n = v:GetInfo().name
					local ny = p.y-20
					if(off) then
						ny = p.y
					end
					draw.Text(p.x-(string.len(n)*10)/2,ny,n,10,10)
					if(!off) then
						draw.Rect(p.x,p.y-10,2,10)
					end
					
					local amt = hp/5
					local amtx = amt
					if(hp > 100) then amtx = 40 end
					local r,g,b = hsv(amtx*5,1,1)
					draw.SetColor(r,g,b,1)
					draw.Rect(p.x-((string.len(n)*10)/2)-5,(ny-amt)+10,5,amt)
				end
			end
		end
		
		for k,v in pairs(GetEntitiesByClass("item")) do
			local id = v:EntIndex()
			sptimes[id] = sptimes[id] or 0
			sptimes[id] = sptimes[id] + .05
			if(sptimes[id] > 1) then sptimes[id] = 1 end
			
			local pos = v:GetPos()
			local ang = v:GetLerpAngles()
			local index = v:GetModelIndex()
			local n = util.GetItemName(index)
			local v = n or index
			
			BoundingBox(
			util.GetItemModel(index),
			pos,
			ang,
			util.GetItemName(index),sptimes[id])
		end
		
		for k,v in pairs(sptimes) do
			sptimes[k] = sptimes[k] - .01
			if(sptimes[k] < 0) then sptimes[k] = 0 end
		end
		
		--draw.Rect(vdelta[1],vdelta[2],2,2)
		--draw.Text(vdelta[1],vdelta[2],"Pos",10,10)
	end
	hook.add("Draw2D","sidescroller",draw2d)
	
	local dcam = nil
	local lastpos = Vector(0,0,0)
	local function view(pos,ang,fovx,fovy)
		local ax = -1
		if(FLIP_AXIS) then ax = 1 end
		ang = VectorToAngles(Vector(ax,0,0))
		--ang = Vector(0,90,0)
		local f,r,u = AngleVectors(ang)
		
		realyaw = ang.y
		pos = pos + f*(-400 + ddist)
		
		pos = pos + Vector(0,0,20)
		pos.z = pos.z + (ddist/8)
		
		ang.p = ang.p + 8
		ang.p = ang.p + (ddist/10)
		
		pos = pos + u * (mdelta[2]*100)
		pos = pos + r * (mdelta[1]*100)
		
		if(_CG.stats[STAT_HEALTH] <= 0) then
			mdelta[2] = mdelta[2] + (0 - mdelta[2])*.1
			mdelta[1] = mdelta[1] + (0 - mdelta[1])*.1
		end
		
		dcam = dcam or pos
		dcam = dcam + (pos - dcam) * (.02 * Lag())
		local npos = dcam
		--npos = pos
		
		
		local pl_pos = LocalPlayer():GetPos() + Vector(0,0,25)
		
		ApplyView(npos,ang,90,73.73)
		
		local def = {
			origin = npos,
			angles = ang,
			fov_x = 90,
			fov_y = 73.73,
			x = 0,
			y = 0,
			width = 640,
			height = 480,
		}
		
		local ts = VectorToScreen(pl_pos,def)
		vdelta[1] = ts.x
		vdelta[2] = ts.y
		
		
		local vel = LocalPlayer():GetTrajectory():GetDelta()
		if(VectorLength(lastpos - pl_pos) > 100 and VectorLength(vel) < 500) then
			dcam = pos
			ddist = -300
		end
		lastpos = Vectorv(pl_pos)
		
		if(LocalPlayer():GetInfo().health <= 0) then
			ddist = ddist + (300 - ddist)*(.02 * Lag())
		else
			ddist = ddist + (0 - ddist)*(.02 * Lag())
		end
	end
	hook.add("CalcView","sidescroller",view)
	
	local wasmouse = false
	local function think()
		local vx,vy = unpack(vdelta)
		local dx,dy = vx-GetXMouse(),vy-GetYMouse()
		local mx,my = GetXMouse()/640,GetYMouse()/480
		if(_CG.stats[STAT_HEALTH] > 0) then
			mdelta = {mx-.5,my-.5}
			mdelta[1] = mdelta[1] * 3
			mdelta[2] = mdelta[2] * -3
		else
			mdelta = mdelta or {mx-.5,my-.5}
		end
		
		if(FLIP_AXIS) then 
			dx = dx * -1
		end
		
		if(dx < 0) then 
			flip = true 
			dx = dx * -1
		else
			flip = false
		end
		
		aim = -math.atan2(dy,dx)*57.3
		aim = aim - 2
		
		if(aim > 90) then aim = 90 end
		if(aim < -90) then aim = -90 end
		
		
		if(MouseDown()) then
			if(!wasmouse) then
				newbits = BUTTON_ATTACK
				wasmouse = true
			end
		else
			if(wasmouse) then
				newbits = 0
				wasmouse = false
			end
		end
		
		local reset = LocalPlayer():GetInfo().health <= 0
		EnableCursor(!reset)
		if(reset) then
			flip = true
		end
	end
	hook.add("Think","sidescroller",think)
	
	local yaw = 90
	local function UserCmd(pl,angle,fm,rm,um,buttons,weapon)
		local anglex = VectorToAngles(Vector(-1,0,0))
		local qyaw = anglex.y+90
		
		if(flip) then qyaw = qyaw + 180 end
		
		local temp = rm
		rm = fm*-1
		fm = temp
		
		if(rm != 0) then
			um = rm * -1
		end
		
		
		if(FLIP_AXIS) then 
			fm = fm * -1
		end
		
		if(flip == false) then fm = fm * -1 end
		rm = 0

		buttons = bitOr(buttons,newbits)
		angle = Vector(aim,qyaw,0)
			
		--print(tostring(aim) .. "\n")
			
		SetUserCommand(angle,fm,rm,um,buttons,weapon)
	end
	hook.add("UserCommand","sidescroller",UserCmd)
end