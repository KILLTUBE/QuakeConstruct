local SpringT = {}

local function doValue(val,dist,spd,vel,fr)
	vel = vel + (dist * spd);
	
	val = val + (vel * spd);
	
	vel = vel * fr;
	return val,vel
end

function SpringT:GetDelta()
	return self.ideal - self.val
end

function SpringT:GetValue()
	return self.val
end

function SpringT:Update(lcompensate)
	local spd = self.spd
	local fr = self.fr
	if(lcompensate) then
		local l = Lag()
		spd = spd * l
	end
	self.val,self.vel = doValue(self.val,self:GetDelta(),self.spd,self.vel,fr)
end

function SpringT:__index()
	return self.val
end

function Spring(val,videal,vspeed,vfriction,vvel)
	local o = {}

	setmetatable(o,SpringT)
	SpringT.__index = SpringT

	o.vel = vvel or 0
	o.val = val
	o.ideal = videal or val
	o.spd = vspeed
	o.fr = vfriction
	
	return o;
end