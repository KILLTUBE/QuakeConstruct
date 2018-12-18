if(CLIENT) then
	local ind = {}
	local bubble = LoadShader('waterBubble')
	local function r() return math.random(-100,100) end
	local function rvec() return Vector(r(),r(),r())/100 end
	
	local function waterLevel(pos,pl)
		local level = 0
		local pos = pos or pl:GetPos()
		local mask = CONTENTS_WATER
		local res = TraceLine(pos + Vector(0,0,28),pos,pl,mask)
		if(res.fraction < .5) then level = 1 end
		if(res.fraction < .35) then level = 2 end
		if(res.fraction <= 0) then level = 3 end
		return level
	end
	
	local function makeBubble(pl,sub)
		sub = sub or Vector()
		for i=1,5 do
			Timer((math.random(1,100)/300),function()
				local pos = (pl:GetPos() + Vector(0,0,32)) - sub
				local le,ref = QuickParticle(pos + rvec()*10,math.random(1000,4000),bubble)
				ref:SetRotation(math.random(0,360))
				ref:SetRadius(math.random(220,450)/100)
				le:SetRefEntity(ref)
				le:SetVelocity(Vector(0,0,math.random(50,100)) + (rvec()*10))
				
				le:SetCallback(LOCALENTITY_CALLBACK_THINK,function(le)
					if(waterLevel(le:GetPos()) == 0) then
						le:SetColor(0,0,0,0)
						le:SetStartTime(-1000)
						le:SetEndTime(0)
					end
					le:SetVelocity(le:GetVelocity() + (rvec()*4))
					le:SetNextThink(LevelTime() + 20)
				end)
				
			end)
		end
	end
	
	local function Think()
		local players = GetAllPlayers()
		table.insert(players,LocalPlayer())
		for k,v in pairs(players) do
			if(waterLevel(nil,v) >= 3) then
				local index = v:EntIndex()
				ind[index] = ind[index] or {}
				ind[index].btime = ind[index].btime or LevelTime()
				ind[index].cnt = ind[index].cnt or 20
				if(ind[index].btime < LevelTime()) then
					local sub = Vector()
					if(v:GetInfo().health > 0) then
						ind[index].btime = LevelTime() + math.random(500,1000)
						ind[index].cnt = 6
						sub.z = 0
					else
						ind[index].btime = LevelTime() + math.random(40,100)
						ind[index].cnt = ind[index].cnt - 1
						sub.z = 30
					end
					if(ind[index].cnt > 0) then
						makeBubble(v,sub)
					end
				end
			end
		end
	end
	hook.add("Think","cl_bubbles",Think)
	
	local function damaged(v)
		if(waterLevel(nil,v) >= 3) then
			makeBubble(v)
			makeBubble(v)
			makeBubble(v)
		end
	end
	hook.add("PlayerDamaged","cl_bubbles",damaged)
end