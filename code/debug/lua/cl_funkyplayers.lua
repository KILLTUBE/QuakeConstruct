local flare = LoadShader("flareShader")

local function trDown(pos)
	local endpos = vAdd(pos,Vector(0,0,-1000))
	local res = TraceLine(pos,endpos,nil,1)
	return res.endpos
end

local identity = Vector(1,1,1)

local function r()
	local rx = math.random(0,3)
	if(rx == 1) then
		return 1
	else
		return 0
	end
end

local function RefFlare(pos)
	local fl = RefEntity()
	fl:SetShader(flare)
	fl:SetColor(r(),r(),r(),1)
	fl:SetRadius(math.random(32,64))	
	fl:SetPos(pos)
	fl:SetType(RT_SPRITE)
	fl:Render()
end

local function drawPlayer(v)
	local pos = v:GetPos()
	local ang = v:GetAngles()
	local vlen = VectorLength(v:GetTrajectory():GetDelta())
	
	local head = RefEntity()
	local torso = RefEntity()
	local legs = RefEntity()

	util.AnimatePlayer(v,legs,torso)
	util.AnglePlayer(v,legs,torso,head)
	
	pos.z = pos.z - 2
	
	--legs:SetAngles(ang)
	legs:SetPos(pos) --Vector(652,1872,24)
	legs:SetColor(1,1,1,1)
	legs:SetModel(v:GetInfo().legsModel)
	legs:SetSkin(v:GetInfo().legsSkin)
	legs:Scale(Vector(1,1,1))
	
	torso:SetModel(v:GetInfo().torsoModel)
	torso:SetSkin(v:GetInfo().torsoSkin)
	
	head:SetModel(v:GetInfo().headModel)
	head:SetSkin(v:GetInfo().headSkin)

	--local f,r,u = AngleVectors(torso:GetAngles())
	torso:Scale(Vector(4,4,4))
	torso:PositionOnTag(legs,"tag_torso")
	
	--head:Scale(Vector(2,2,1.5))
	head:Scale(Vector(.5,.5,.5))
	head:PositionOnTag(torso,"tag_torso")

	legs:Render()
	--torso:Render()
	head:Render()
	
	RefFlare(torso:GetPos())
	--[[for i=0, 1 do
		local f,r,u = head:GetAngles()
		local dp = vMul(u,12)
		head:SetPos(vAdd(head:GetPos(),dp))
		head:Scale(Vector(1.1,1.1,1.1))
		head:Render()
		RefFlare(head:GetPos())
	end]]	
end

local legs = nil
local torso = nil
local refNull = RefEntity()
fpdata = fpdata or {}
local function PlayerPart(re,ent,part,team)
	if(part == 0) then return false end
	local id = ent:EntIndex()
	local lt = LevelTime()
	local hp = ent:GetInfo().health
	local epos = ent:GetPos()
	if(fpdata[id] == nil) then
		fpdata[id] = {}
		fpdata[id].die = lt
		print("ALLOC: " .. id .. "\n")
		if(id>=64) then
			fpdata[id].body = true
			fpdata[id].die = lt + 1000
		else
			fpdata[id].body = false
		end
		fpdata[id].alive = (hp > 0)
	end
	if(fpdata[id].body and fpdata[id].lastPos ~= epos.x + epos.y) then
		fpdata[id].die = lt + 1000
	end
	fpdata[id].lastPos = epos.x + epos.y
	
	if(hp <= 0 and fpdata[id].alive) then
		fpdata[id].die = lt
		fpdata[id].alive = false
		if(fpdata[id].body == true) then
			fpdata[id].die = lt
			print("RE: " .. id .. "\n")
		end
	elseif(hp > 0 and fpdata[id].alive == false) then
		if(fpdata[id].body == false) then
			fpdata[id].die = 0
			fpdata[id].alive = true
		end
	end
	
	local dtx = 1 - ((lt - fpdata[id].die) / 12000)
	local dt = (lt - fpdata[id].die) / 5000
	local dt2 = dt * 2
	if(dtx > 1) then dtx = 1 end
	if(dt > 1) then dt = 1 end
	if(dt2 > 1) then dt2 = 1 end
	dt = dt - dtx/4
	dt2 = dt2 - dtx/4
	if(dt > 1) then dt = 1 end
	if(dt2 > 1) then dt2 = 1 end
	dt = 1 - dt
	dt2 = 1 - dt2
	
	if(part == 1) then
		local cl = dt2 * 1
		if(cl > 1) then cl = 1 end
		local pos = re:GetPos()
		
		local p = GetTag(re,"tag_torso")
		if(fpdata[id].body == false) then
			local ang = math.sin(lt/120)*20*dt*dt + (cl * 30)
			local a2 = math.cos(lt/140)*10*dt2
			RotateEntity(re,Vector(0,ang*2,ang-a2*8)/3)
		else
			local ang = math.sin(lt/500)*5*dt*dt
			RotateEntity(re,Vector(0,0,ang))
		end
		local p2 = GetTag(re,"tag_torso")
		
		local delta = pos-p2
		local n = pos + (delta)
		
		n = n + (p-pos)
		
		re:SetPos(n)
		re:Scale(Vector(1))
		re:Render()
	elseif(part == 2) then
		if(fpdata[id].body == false) then
			local cl = dt2 * 4
			if(cl > 1) then cl = 1 end
		
			local ang = math.sin(lt/100)*20*dt*dt + (cl * 30)
			local a2 = math.sin(lt/80)*10*dt2
			RotateEntity(re,Vector(ang*2,a2*3,a2-ang)/3)
		else
			local ang = math.sin(lt/500)*5*dt*dt
			RotateEntity(re,Vector(ang,0,0))
		end
		
		re:Render()
	elseif(part == 3) then
		if(fpdata[id].body == false) then
			local cl = dt2 * 4
			if(cl > 1) then cl = 1 end
			local ang = math.cos(lt/80)*20*dt*dt + (cl * 30)
			local a2 = math.cos(lt/60)*10*dt2
			RotateEntity(re,Vector(-ang + ((1-dt)*30),-a2,0))
		else
			local ang = math.sin(lt/500)*5*dt*dt
			RotateEntity(re,Vector(ang,0,0))
		end
		re:Render()
	end
	return true,re
end
hook.add("DrawPlayerModel","cl_funkyplayers",PlayerPart)

local function d3d()
	--[[local tab = GetEntitiesByClass("player")
	for k,v in pairs(tab) do
		v:CustomDraw(true)
		drawPlayer(v)
	end]]
end
hook.add("Draw3D","cl_funkyplayers",d3d)