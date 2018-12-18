if(SERVER) then
	downloader.add("lua/flytest.lua")
	local function PlayerDamaged(self,inflictor,attacker,damage,meansOfDeath,dir,pos)
		if(self:GetHealth() <= 0 and self:GetHealth() > -50) then
			self:Damage(attacker,attacker,1000)
		end
	end
	hook.add("PostPlayerDamaged","pmove.lua",PlayerDamaged)
	
	local function FiredWeapon(player,weapon,delay,pos,angle)
		player:SetAmmo(player:GetInfo().weapon,-1)
		return delay / 2
	end
	hook.add("FiredWeapon","pmove.lua",FiredWeapon)
else
	local function maxvel(v)
		return math.min(math.max(v,-320),320)/320;
	end
		
	local function weapIco(str) return LoadModel("models/weapons2/" .. str .. "/" .. str .. ".md3") end
	local weapmodels = {}
	weapmodels[WP_GAUNTLET] = weapIco("gauntlet")
	weapmodels[WP_MACHINEGUN] = weapIco("machinegun")
	weapmodels[WP_SHOTGUN] = weapIco("shotgun")
	weapmodels[WP_GRENADE_LAUNCHER] = weapIco("grenadel")
	weapmodels[WP_ROCKET_LAUNCHER] = weapIco("rocketl")
	weapmodels[WP_LIGHTNING] = weapIco("lightning")
	weapmodels[WP_RAILGUN] = weapIco("railgun")
	weapmodels[WP_PLASMAGUN] = weapIco("plasma")
	weapmodels[WP_BFG] = weapIco("bfg")

	local tang = Vector()
	local smoothvel = 0
	local smoothpos = Vector()
	local lpos = Vector()
	local function bobview(pos,ang,fovx,fovy)
		if(!_CG) then return end
		if(_CG.stats[STAT_HEALTH] <= 0) then return end
		local crd = _CG.refdef.right
		local cup = _CG.refdef.up
		local vel = LocalPlayer():GetTrajectory():GetDelta()
		local rvel = maxvel(DotProduct(vel,crd))*-15
		local dpos = (pos - lpos)
		dpos = Vector(0,DotProduct(dpos,crd),DotProduct(dpos,cup)*2)*2
		
		smoothvel = smoothvel + (rvel - smoothvel)*.2
		smoothpos = smoothpos + (dpos - smoothpos)*.3
		
		lpos = pos
		local vp = smoothpos
		pos = pos + crd*(vp.y)
		pos = pos + cup*(vp.z)
		
		pos = pos - Vector(0,0,16)
		pos = pos - (VectorForward(ang)*60)
		
		ang.z = smoothvel
		tang = ang
		tang.z = -tang.z
		
		
		ApplyView(pos,ang)
	end
	hook.add("CalcView","pmove.lua",bobview)
	
	local function pldraw()
		local tab = GetEntitiesByClass("player")
		table.insert(tab,LocalPlayer())
		for k,v in pairs(tab) do
			v:CustomDraw(true)
			if(v:GetInfo().health > 0) then
				local weap = weapmodels[v:GetInfo().weapon]
				local legs,torso,head = LoadPlayerModels(v)
				local ang = v:GetLerpAngles()
				head:SetAngles(ang)
				if(v != LocalPlayer()) then
					head:Scale(Vector(4,4,4))
				end
				head:SetPos(v:GetPos() + Vector(0,0,10))
				head:Render()
				local f,r,u = AngleVectors(ang)
				
				if(weap != nil) then
					local w = RefEntity()
					w:SetAngles(ang)
					if(v != LocalPlayer()) then
						w:Scale(Vector(4,4,4))
					end
					w:SetModel(weap)
					
					w:SetPos(v:GetPos() - r*10)
					w:Render()
					
					w:SetPos(v:GetPos() + r*10)
					w:Render()
				end
			end
		end	
	end
	hook.add("Draw3D","pmove.lua",pldraw)
end

function PlayerMove(pm,walk,forward,right)
	--PM_Accelerate(Vector(0,0,1),4,10)
	--[[if(pm:WaterLevel() > 1) then
		PM_WaterMove()
	elseif(walk) then
		PM_WalkMove()
	else
		PM_AirMove()
	end]]
	--PM_FlyMove()
	--PM_AirMove()
	
	local prv = pm:GetVelocity()
	local f,r,u = pm:GetMove()
	local v = (forward*f)
	v = v + (right*r)
	v = v + (Vector(0,0,1)*u)
	v = v * pm:GetScale()
	v = v / 4
	v = v + prv/1.2
	
	pm:SetVelocity(v)
	PM_StepSlideMove(false)
	
	--pm:SetVelocity(pm:GetVelocity() / 1.2)
	
	
	if(SERVER) then
		--print(scale .. "\n")
	end
	
	return true
end
hook.add("PlayerMove","pmove.lua",PlayerMove)

--[[if(SERVER) then
	function ClientThink(pl)
		pl:SetVelocity(pl:GetVelocity() + Vector(0,0,-50))
	end
	hook.add("ClientThink","pmove.lua",ClientThink)
end]]