local SequenceT = {}

function SequenceT:Init()
	self.lerp = 0
end

function SequenceT:SetLerp(lerp)
	if(lerp < 0) then lerp = 0 end
	if(lerp > 1) then lerp = 1 end
	if(self.ref == nil) then return end
	local frames = (self.endf - self.start)
	local lf = (math.ceil(lerp*frames) + self.start)
	local lf2 = (lerp*frames) % 1
	self.ref:SetFrame(lf)
	
	if(lf-1 < self.start) then lf = self.start+1 end
	self.ref:SetOldFrame(lf-1)
	self.ref:SetLerp(1-lf2)
end

function SequenceT:SetRef(r)
	self.ref = r
end

function SequenceT:SetStart(s)
	self.start = s
end

function SequenceT:SetEnd(e)
	self.endf = self.start + e
end

function SequenceT:GetLength()
	return self.endf - self.start
end

function SequenceT:GetStart()
	return self.start
end

function SequenceT:GetEnd()
	return self.endf
end

function Sequence(_start,_end)
	local o = {}

	setmetatable(o,SequenceT)
	SequenceT.__index = SequenceT

	o.start = _start
	o.endf = _start + _end
	
	o:Init()
	o.Init = nil
	
	return o;
end