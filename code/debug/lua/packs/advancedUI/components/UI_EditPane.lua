local Panel = {}

Panel.bgcolor = {1,0.2,0,.5}
Panel.fgcolor = {0,1,0,.5}

function Panel:Initialize()

	self.container = UI_Create("panel",self)
	self.container.Draw = function(c) end
	self.container.DoLayout = function(c) self:DoLayout() end
	
	self.content = nil
	self.scrollbar = UI_Create("scrollbar",self)
	self.scrollbar:SetSize(12,12)
	self.scrollbar:SetLip(12)
	self.scrollbar.OnScroll = function(sb,v)
		if(self.canvas != nil) then
			self.canvas.y = -(self.canvas:GetHeight() - self:GetHeight())*v
		end
	end
	self.hscrollbar = UI_Create("scrollbar",self)
	self.hscrollbar:SetAxis(1)
	self.hscrollbar:SetSize(12,12)
	self.hscrollbar.OnScroll = function(sb,v)
		if(self.canvas != nil) then
			self.canvas.x = -(self.canvas:GetWidth() - self:GetWidth())*v
		end
	end
end

function Panel:Draw() end

function Panel:SetContent(panel)
	self.canvas = panel
	self.canvas:SetParent(self.container)
	self.canvas:DoLayout()
end

function Panel:KeyPressed(key) end

function Panel:DoLayout()		
	if(self:GetParent()) then
		self:Expand()
	end
	
	if(self.canvas != nil) then
		if(self.canvas:GetHeight() > self.container:GetHeight()) then
			self.scrollbar:SetRange((self.canvas:GetHeight() - self.container:GetHeight()) / self.container:GetHeight())
		else
			self.scrollbar:SetRange(0)
		end
	
		if(self.canvas:GetWidth() > self.container:GetWidth()) then
			self.hscrollbar:SetRange((self.canvas:GetWidth() - self.container:GetWidth()) / self.container:GetWidth())
		else
			self.hscrollbar:SetRange(0)
		end
	end
	
	self.scrollbar:DoLayout()
	self.hscrollbar:DoLayout()
	
	self.container:SetPos(0,0)
	self.container:SetSize(self:GetWidth()-self.scrollbar:GetWidth(),self:GetHeight()-self.hscrollbar:GetHeight())
end

registerComponent(Panel,"editpane","panel")