local Panel = {}

function Panel:Initialize()
	self.value = 0
	self.title = "<slider>"
	self.sliderpane = UI_Create("panel",self)
	self.slide = UI_Create("scrollbar",self.sliderpane)
	self.slide:SetAxis(1)
	self.slide:SetSize(10,10)
	self.slide.OnScroll = function(sb,v)
		self.value = v
		self.label:SetText(self.title .. ": " .. self.value)
		self:OnValue(v)
	end
	
	self.label = UI_Create("label",self.sliderpane)
	self.label:SetPos(0,0)
	self.label.DoLayout = function(l) l:SetSize(self.sliderpane:GetWidth(),12) end
	self.label:SetText(self.title .. ": " .. self.value)
	self.label:SetTextSize(6)
	self.label:TextAlignLeft()
	self.label.DrawBackground = function() end --No Background
	
	self:DoLayout()
end

function Panel:SetTitle(str)
	self.title = str
	self.label:SetText(self.title .. ": " .. self.value)
end

function Panel:OnValue(v)

end

function Panel:DoLayout()
	local w = self:GetWidth()
	local h = self:GetHeight()
	if(h < 35) then h = 35 end
	if(w < 60) then w = 60 end
	self.sliderpane:SetPos(5,5)
	self.sliderpane:SetSize(w-10,h-10)
	self:SetSize(w,h)
	
	self.slide:SetRange(3)
	
	self:InvalidateLayout()
end


registerComponent(Panel,"slider","panel")