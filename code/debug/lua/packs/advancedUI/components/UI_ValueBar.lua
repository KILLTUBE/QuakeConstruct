local Panel = {}
Panel.drag = false
Panel.lastvalue = nil
Panel.value = .1
Panel.title = "slider"
Panel.min = 0
Panel.max = 1

local function coloradjust(tab,amt)
	local out = {}
	for k,v in pairs(tab) do
		out[k] = math.min(math.max(v * (1 + amt),0),1)
	end
	return out
end

function Panel:Initialize()
	self:SetTitle("slider")
end

function Panel:SetMax(v)
	self.max = v
	self:SetValue(self.value)
end

function Panel:SetMin(v)
	self.min = v
	self:SetValue(self.value)
end

function Panel:SetTitle(t)
	if(t != nil and type(t) == "string") then
		self.title = t
	end
	self:SetText(self.title .. ": " .. tostring(self:GetValue()))
end

function Panel:SetValue(v,silent)
	v = self:FormatValue(v)
	if(v > self.max) then v = self.max end
	if(v < self.min) then v = self.min end
	self.value = v
	self:SetText(self.title .. ": " .. tostring(v))
	
	if((self.lastvalue != self.value) && !silent) then
		self:OnValue(v)
	end
	self.lastvalue = v
end

function Panel:OnValue(v) end

function Panel:GetFloatValue()
	return ((self.value-self.min) / (self.max-self.min))
end

function Panel:GetValue()
	return v
end

function Panel:FormatValue(v)
	return v
end

function Panel:Think()
	self.BaseClass:Think()
	if(self.drag) then
		local mx = GetXMouse()
		local x = self:GetX()
		local w = self:GetWidth()
		
		local v = (mx - x) / w
		v = self.min + (self.max - self.min)*v
		
		self:SetValue(v)
	end
end

function Panel:DrawBackground()
	SkinCall("DrawButtonBackground",self:MouseOver(),self:MouseDown())
	--draw.SetColor(.2,.4,1,.6)
	
	if(self.value != 0) then
		sk.coloradjust(self:GetBGColor(),.3,.5)
		SkinCall("DrawBevelRect",self:GetX(),self:GetY(),self:GetWidth()*self:GetFloatValue(),self:GetHeight(),1)
		--draw.Rect(self:GetX(),self:GetY(),self:GetWidth()*self:GetFloatValue(),self:GetHeight())
	end
end

function Panel:MousePressed()
	self.drag = true
end

function Panel:MouseReleased()
	self.drag = false
end

function Panel:MouseReleasedOutside(x,y,other)
	self.drag = false
end

registerComponent(Panel,"valuebar","button")