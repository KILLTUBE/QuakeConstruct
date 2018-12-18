--[[
cluster.lua
SERVER

Example script made for Hxrmn's Mod :P
]]

CLUSTERNADES	 			=	3;
CLUSTERNADE_SPEED			=	500;
CLUSTERNADE_DEPLOY_RANGE	=	200;

local function ClusterBomb(roc,owner,target)
	local rocPos=roc:GetPos();
	
	for i=1,CLUSTERNADES do
		local g=CreateMissile("grenade",owner);
		
		local tpos=target:GetPos()+target:GetVelocity()/2
		tpos = tpos + Vector(0,0,26)
		local gpos=rocPos+(VectorRandom()*5);
		g:SetPos(gpos);

		local angle = VectorToAngles(tpos-gpos)
		angle = angle + VectorRandom()*15
		local normal = AngleVectors(angle) * CLUSTERNADE_SPEED
		
		local speed = normal + Vector(0,0,25);
		g:SetVelocity(speed);
		g:SetNextThink(LevelTime() + math.random(1400,11000))
		g:SetDamage(40,25) --normal,[splash damage],[radius]
		--g:SetTrType(TR_LINEAR)
		g:SetWeapon(WP_ROCKET_LAUNCHER) --make it look like a rocket
		
		local touch = function(ent,other,trace)
			if ent then
				ent:SetNextThink(LevelTime())
			end
		end
		g:SetCallback(ENTITY_CALLBACK_TOUCH, touch)
	end
	
	--Our missile is now 5 nades
	roc:Remove();
end

local function RocketsThink()
	for k,roc in pairs(GetEntitiesByClass("rocket")) do --right here! --oops
		local owner = roc:GetParent();
		local rocPos= roc:GetPos();
		for k,pl in pairs(GetEntitiesByClass("player")) do
			if pl!=owner and pl:GetHealth() > 0 then
				local plPos=pl:GetPos();
				if(VectorLength(plPos-rocPos)<CLUSTERNADE_DEPLOY_RANGE) then
					ClusterBomb(roc,owner,pl);
				end
			end
		end
	end
end
hook.add("Think","RocketsThink",RocketsThink);