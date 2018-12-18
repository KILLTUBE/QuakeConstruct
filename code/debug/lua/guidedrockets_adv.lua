local function r()
	return math.random(-100,100)/100
end

local function rv(v)
	local t = {}
	t.x = r()*v
	t.y = r()*v
	t.z = r()*v
	return t
end

local function RemoveStuff()
	local tab = GetAllEntities()
	for k,v in ipairs(table.Copy(tab)) do
		local class = v:Classname()
		if(string.find(class,"rocket") or string.find(class,"bfg") or string.find(class,"grenade")) then
			print("Removed: " .. class .. "\n")
			v:Remove()
		end
	end
end
--RemoveStuff()

local function PlayerSpawned(cl)
	cl:SetInfo(PLAYERINFO_HEALTH,100)
	if(!cl:IsBot()) then
		cl:GiveWeapon(WP_ROCKET_LAUNCHER)
		cl:SetWeapon(WP_ROCKET_LAUNCHER)
		cl:SetAmmo(WP_ROCKET_LAUNCHER,-1)

		cl:GiveWeapon(WP_GRENADE_LAUNCHER)
		cl:SetWeapon(WP_GRENADE_LAUNCHER)
		cl:SetAmmo(WP_GRENADE_LAUNCHER,-1)
		
		cl:GiveWeapon(WP_PLASMAGUN)
		cl:SetWeapon(WP_PLASMAGUN)
		cl:SetAmmo(WP_PLASMAGUN,-1)
	end
end
--hook.add("PlayerSpawned","GuidedMissileStuff",PlayerSpawned)

local function shouldDrop(class)
	if(class) then
		if(string.find(class,"rocket") or string.find(class,"bfg") or string.find(class,"grenade")) then
			print("^5Drop Denied: " .. class .. "\n")
			return false
		end
	end
end
hook.add("ShouldDropItem","GuidedMissileStuff",shouldDrop)

local function Guided()
	for k,v in pairs(GetEntitiesByClass({"bfg","rocket","grenade"})) do
		local parent = v:GetParent()
		local tab = GetEntityTable(v)
		tab.nextrv = tab.nextrv or CurTime()
		
		if(parent) then
			if(parent:GetInfo()["health"] <= 0) then
				tab.dead = true
			end
			if(!tab.dead) then
				
				local vel = v:GetVelocity()
				local forward = VectorForward(parent:GetAimAngles())
				local startpos = parent:GetMuzzlePos()
				local ignore = parent
				local mask1 = 1
				local mask2 = 33554432
				
				if(tab.lockon) then
					forward = VectorForward(v:GetVelocity())
					startpos = v:GetPos()
					ignore = v
				end
				
				local endpos = vAdd(startpos,vMul(forward,16000))
				
				local res = nil
				local solidtrace = TraceLine(startpos,endpos,ignore,mask1)
				local playertrace = TraceLine(startpos,endpos,ignore,mask2,Vector(-120,-120,-120),Vector(120,120,120))
				
				if(tab.lockon) then
					res = playertrace
				else
					res = solidtrace
				end
				
				--[[if(playertrace.entity != nil) then
					--res.entity != parent
					if(playertrace.entity:IsPlayer()) then
						if(!tab.lockon) then tab.lockon = playertrace.entity end
						--print("LOCKON\n")
						parent:SendMessage("Locked On",true)
					end
				end]]
				
				if(tab.lockon) then
					res.endpos = tab.lockon:GetPos()
					if(tab.lockon:GetInfo()["health"] <= 0) then
						tab.lockon = nil
					end
				end	
				
				local delta = vSub(res.endpos,v:GetPos())
				local tdist = VectorLength(delta)
				delta = VectorNormalize(delta)
				
				if(tab.nextrv <= CurTime()) then
					tab.rv = rv(.2)
					tab.nextrv = CurTime() + 0.3
				end
				
				if(tdist > 500) then
					--delta = vAdd(delta,tab.rv)
				end
				
				local normal = VectorNormalize(vel)
				normal = vAdd(normal,vMul(vSub(delta,normal),0.17))
				
				if(!tab.successive) then
					--normal = vAdd(normal,rv(0.4))
					if(v:Classname() == "grenade") then
						local callback = function(ent,other,trace)
							if(!tab.dead) then
							CreateTempEntity(vAdd(ent:GetPos(),{x=0,y=0,z=10}),EV_SCOREPLUM)
								tab.dead = true
							end
						end
						
						v:SetCallback(ENTITY_CALLBACK_TOUCH,callback)
					end
					tab.successive = true
				end
				
				if(tab.lockon) then
					vel = vMul(normal,700)
				else
					vel = vMul(normal,700)
				end
				v:SetVelocity(vel)
			end
		end
	end
end
hook.add("Think","GuidedMissileStuff",Guided)

for k,v in pairs(GetAllPlayers()) do
	--PlayerSpawned(v)
end