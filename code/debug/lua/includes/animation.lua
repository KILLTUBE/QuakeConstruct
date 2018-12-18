ANIM_ACT_LOOP = 0
ANIM_ACT_LOOP_LERP = 1
ANIM_ACT_STOP = 2
ANIM_ACT_PINGPONG = 3

local AnimationT = {}

function AnimationT:Init()
	self.playing = false
	--self:Reset()
	self.frame = self.start
	self.oldframe = self.start
	self.act = ANIM_ACT_LOOP
end

function AnimationT:Reset()
	self.playing = false
	--print("Stopped Playing!\n")
	self.frame = self.start
	self.oldframe = self.start
	self:Play()
end

function AnimationT:Stop()
	self.playing = false
	--print("Stopped Playing!\n")
end

function AnimationT:Play()
	if(self.playing == false) then
		self.playing = true
		self.frameTime = LevelTime()
		self.oldFrameTime = LevelTime() + self.lerp
		--print("Started Playing!\n")
	end
end

function AnimationT:Animate()
	--print("Animate\n")
	if(self.playing != true) then return end
	--print("Is Playing\n")
	if(self.frameTime == nil) then return end
	if(LevelTime() > self.frameTime) then
		--print("New Frame\n")
		self.oldFrameTime = self.frameTime
		self.oldframe = self.frame
		
		self.frameTime = LevelTime() + self.lerp
		
		if(self.reverse) then
			self.frame = self.frame - 1
		else
			self.frame = self.frame + 1
		end
		
		if(self.frame >= self.endf) then
			if(self.act == ANIM_ACT_LOOP) then
				self.frame = self.start
				self.oldframe = self.start
			elseif(self.act == ANIM_ACT_LOOP_LERP) then
				self.frame = self.start
			elseif(self.act == ANIM_ACT_STOP) then
				self.frame = self.endf
				self.oldframe = self.endf
				self:Stop()
			elseif(self.act == ANIM_ACT_PINGPONG) then
				self.frame = self.endf
				self.oldframe = self.endf
				self.reverse = !self.reverse
			end
		end
		
		if(self.frame < self.start) then
			self.frame = self.start
			self.oldframe = self.start
			if(self.act == ANIM_ACT_PINGPONG) then
				self.reverse = !self.reverse
			else
				self:Stop()
			end		
		end
		
		if ( self.frameTime > LevelTime() + self.lerp ) then
			self.frameTime = LevelTime();
		end

		if ( self.oldFrameTime > LevelTime() ) then
			self.oldFrameTime = LevelTime();
		end
	end
	if(self.ref != nil) then
		--print("Ref-Frame\n")
		local backlerp = 1.0 - (LevelTime() - self.oldFrameTime ) / ( self.frameTime - self.oldFrameTime );
		self.ref:SetOldFrame(self.oldframe)
		self.ref:SetFrame(self.frame)
		self.ref:SetLerp(backlerp)
	else
		--print("Ref was nil\n")
	end
end

function AnimationT:SetRef(r)
	self.ref = r
end

function AnimationT:SetType(t)
	if(t >= 0 and t <= ANIM_ACT_PINGPONG) then
		self.act = t
	end
end

function AnimationT:SetStart(s)
	self.start = s
end

function AnimationT:SetEnd(e)
	self.endf = self.start + e
	self.length = e
end

function AnimationT:GetStart()
	return self.start
end

function AnimationT:GetLength()
	return self.length
end

function AnimationT:GetFrame()
	return self.frame
end

function AnimationT:SetFPS(f)
	self.fps = f
	self.lerp = 1000/f
end

function AnimationT:GetFPS()
	return self.fps
end

function AnimationT:New()
	return Animation(self.start,self.length,self.fps)
end

function Animation(_start,_end,_lerp)
	local o = {}

	setmetatable(o,AnimationT)
	AnimationT.__index = AnimationT

	o.start = _start
	o.endf = _start + _end
	o.length = _end
	o.fps = _lerp
	o.lerp = 1000/_lerp
	o.reverse = false
	
	o:Init()
	o.Init = nil
	
	return o;
end


local function parseSingleAnim(animtab,line)
	local args = string.Explode("\t",line)
	local temp = {}
	for k,v in pairs(args) do
		v = string.Replace(v," ","")
		local fc = firstChar(v)
		local n = tonumber(fc)
		if(fc == "/") then
			v = string.sub(v,3,string.len(v))
			if(lastChar(v) == "\r") then
				v = string.sub(v,0,string.len(v)-1)
			end
			--print("Anim:" .. v .. "|" .. temp[4] .. "|\n")
			animtab[v] = Animation(temp[1],temp[2],temp[4])
			--animtab[v]:Play()
			return
		end
		if(n) then
			--print(tonumber(v) .. "\n")
			table.insert(temp,tonumber(v))
		end
	end
end

local function fixLegs(tab)
	local torsoStart = 9999
	local torsoEnd = 0
	animtab = table.Copy(tab)
	for k,v in pairs(animtab) do
		if(string.find(k,"TORSO")) then
			if(v:GetStart() < torsoStart) then
				torsoStart = v:GetStart()-1
			end
			if(v:GetStart() > torsoEnd) then
				torsoEnd = v:GetStart()
			end
		end
	end
	if(torsoStart == 9999 and torsoEnd == 0) then return animtab end
	for k,v in pairs(animtab) do
		if(string.find(k,"LEGS")) then
			local start = v:GetStart()
			local len = v:GetLength()
			v:SetStart(start - (torsoEnd - torsoStart))
			v:SetEnd(v:GetLength())
			--print("Fixed Leg Anim: " .. k .. "\n")
			--print("- " .. start .. " " .. len .. "\n")
			--print("- " .. v:GetStart() .. " " .. v:GetLength() .. "\n")
			animtab[k] = v
		end
	end
	return animtab
end

function parseAnims(txt)
	local animtab = {}
	local list = string.Explode("\n",txt)
	for k,v in pairs(list) do
		if(v != "\r" and firstChar(v) != "/" and 
			string.find(v,"footsteps") == nil and
			string.find(v,"sex") == nil) then
			parseSingleAnim(animtab,v)
		end
	end
	return fixLegs(animtab)
end

function loadPlayerAnimations(name)
	local path = "models/players/" .. name .. "/animation.cfg"
	local txt = packRead(path)
	if(txt == nil) then 
		error("Could Not Read File: " .. f .. ".\n") 
		return {} 
	end
	
	return parseAnims(txt)
end