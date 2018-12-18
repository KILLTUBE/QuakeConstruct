local function trDown(pos)
	local endpos = vAdd(pos,Vector(0,0,-10000))
	local res = TraceLine(pos,endpos,nil,1)
	return res.endpos
end

local stayTime = 10000
local fadeTime = 2000

if(SERVER) then
//__DL_BLOCK
	--A
	message.Precache("bodydissolve")
	
	downloader.add("lua/longbodies.lua")
	
	local function Respawn(pl,body)
		if(body) then
			body:GetTable().start = LevelTime()
			body:SetNextThink(LevelTime() + stayTime)
			body:GetTable().finish = false
			body:GetTable().sent = false
		end
	end
	hook.add("PlayerSpawned","longbodies",Respawn)

	local function Think()
		for _,body in pairs(GetEntitiesByClass("bodyque")) do
			if(body:GetTable().finish == false) then
				local dtx = (stayTime - fadeTime)
				if((LevelTime() - dtx) > body:GetTable().start) then
					if(body:GetTable().sent == false) then
						
						local msg = Message()
						message.WriteShort(msg,body:EntIndex())
						SendDataMessageToAll(msg,"bodydissolve")
						body:GetTable().sent = true
					end
				end
				if((LevelTime() - (stayTime - 100)) > body:GetTable().start) then
					body:SetPos(body:GetPos() - Vector(0,0,500))
				end
				if((LevelTime() - stayTime) > body:GetTable().start) then
					body:SetPos(body:GetPos() - Vector(0,0,1000))
					body:GetTable().finish = true
					UnlinkEntity(body)
				end
			end
		end
	end
	hook.add("Think","longbodies",Think)	
//__DL_UNBLOCK
else
	local d_ents = {}
	local d_hues = {}
	local function HandleMessage(msgid)
		if(msgid == "bodydissolve") then
			local ent = message.ReadShort()
			d_ents[ent] = LevelTime()
			d_hues[ent] = math.random(1,360)
		end
	end
	hook.add("HandleMessage","longbodies",HandleMessage)
	
	local fire = LoadShader("dissolve2") --LoadShader("fireSphere")
	function d3d()
		local tab = GetEntitiesByClass("player")
		table.insert(tab,LocalPlayer())
		for k,v in pairs(tab) do
			local index = v:EntIndex()
			local tx = d_ents[index]
			local h = d_hues[index] or 0
			local team = v:GetInfo().team
			h = h + 1
			if(h > 360) then h = 1 end
			d_hues[index] = h
			local hr,hg,hb = hsv(h,1,1)
			if(tx) then
				if(LevelTime() - stayTime < tx) then
					v:CustomDraw(true)
					local dt = (tx - (LevelTime() - fadeTime))/fadeTime
					if(dt >= 0 and dt <= 1) then
						local legs,torso,head = LoadPlayerModels(v)
						legs:SetPos(v:GetPos()) --trDown(v:GetPos()) + Vector(0,0,24)
						
						util.AnimatePlayer(v,legs,torso)
						util.AnglePlayer(v,legs,torso,head)
						
						torso:PositionOnTag(legs,"tag_torso")
						head:PositionOnTag(torso,"tag_head")

						local dtx = (1-(dt*.7))
						local dtz = dt/1.4
						local c = {hr*dtz,hg*dtz,hb*dtz,1*dtx}
						
						if(team == TEAM_RED) then
							c = {1*dtz,.1*dtz,.1*dtz,1*dtx}
						elseif(team == TEAM_BLUE) then
							c = {.1*dtz,.1*dtz,1*dtz,1*dtx}
						end
						
						legs:SetColor(unpack(c))
						torso:SetColor(unpack(c))
						head:SetColor(unpack(c))
						
						legs:SetShader(fire)
						torso:SetShader(fire)
						head:SetShader(fire)
						
						for i=0,2 do
							legs:Render()
							torso:Render()
							head:Render()
						end
					end
				end
			else
				v:CustomDraw(false)
			end
		end
	end
	hook.add("Draw3D","sh_spawner",d3d)
end