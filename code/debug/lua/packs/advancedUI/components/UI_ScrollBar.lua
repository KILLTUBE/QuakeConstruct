local Panel = {}

function Panel:Initialize()

	self.axis = 0
	--self.bgcolor = {.4,.4,.4,1}
	self.bgcolor = self:ColorAdjust(self.bgcolor,-.8)
	self.range = 0
	self.wo = false
	self.lip = 0
	self.dragbar = UI_Create("dragbutton",self,true)
	self.dragbar:SetSize(self:GetWidth(),50)
	
	--self.dragbar.bgcolor = {.7,.7,.7,1}
	self.dragbar.bgcolor = self:ColorAdjust(self.dragbar.bgcolor,1.5)
	self.dragbar:SetPos(0,0)
	self.dragbar:LockCenter(false)
	self.dragbar:ConstrainToParent(true)
	self.dragbar.Affect = function(db,dx,dy)
		if(self.axis == 0) then 
			db.y = db.y + dy
			if(db.y < 0) then 
				db.y = 0
			end
			
			if(db.y > self:GetHeight() - db:GetHeight()) then 
				db.y = self:GetHeight() - db:GetHeight()
			end
		else
			db.x = db.x + dx
			if(db.x < 0) then 
				db.x = 0
			end
			
			if(db.x > self:GetWidth() - db:GetWidth()) then 
				db.x = self:GetWidth() - db:GetWidth()
			end
		end
		
		if(self:BarScale() < 1) then
			self:OnScroll(self:Value())
		else
			self:OnScroll(0)
		end
	end
	
end

function Panel:BarScale()
	if(self.range <= 0) then return 1 end
	
	return 1 / (self.range + 1)
	
end

function Panel:Value()
	if(self.axis == 0) then
		return (self.dragbar.y / self.dragbar:GetHeight()) / self.range
	else
		return (self.dragbar.x / self.dragbar:GetWidth()) / self.range
	end
end

function Panel:SetRange(desired)
	self.range = desired
end

function Panel:SetSize(w,h)
	self.BaseClass.SetSize(self,w,h)
	if(self.axis == 0) then
		self.dragbar:SetSize(self:GetWidth(),self.dragbar:GetHeight())
	else
		self.dragbar:SetSize(self.dragbar:GetWidth(),self:GetHeight())
	end
end

function Panel:SetAxis(axis)
	self.axis = axis;
	if(self.axis != 0) then 
		self.dragbar:SetSize(50,self:GetHeight())
	else
		self.dragbar:SetSize(self:GetWidth(),50)
	end
	self:DoLayout()
end

function Panel:SetLip(l)
	self.lip = l
end

function Panel:OnScroll(v) end

function Panel:Layout(n)
	local par = self:GetParent()
	if(par) then
		if(self.axis == 0) then
			self:SetPos(par:GetWidth() - self:GetWidth(),0)
			self:SetSize(self:GetWidth(),par:GetHeight() - self.lip)
			
			if(self.dragbar.y < 0) then
				self.dragbar:SetPos(0,0)
			end
			if(self.dragbar.y > self:GetHeight() - self.dragbar:GetHeight()) then
				self.dragbar:SetPos(0,self:GetHeight() - self.dragbar:GetHeight())
			end
		else
			self:SetPos(0,par:GetHeight() - self:GetHeight())
			self:SetSize(par:GetWidth() - self.lip,self:GetHeight())
			
			if(self.dragbar.x < 0) then
				self.dragbar:SetPos(0,0)
			end
			if(self.dragbar.x > self:GetWidth() - self.dragbar:GetWidth()) then
				self.dragbar:SetPos(self:GetWidth() - self.dragbar:GetWidth(),0)
			end
		end
	end
	--print(self.dragbar.y .. " " .. self.dragbar:GetWidth() .. "\n")
	
	if(self.wo) then
		self.wo = false
		self:OnScroll(0)
	end
	
	if(self:BarScale() < 1) then
		self.dragbar:SetVisible(true)
		if(self.axis == 0) then
			self.dragbar:SetSize(self.dragbar:GetWidth(),self:GetHeight()*self:BarScale())
			if(self.dragbar:GetHeight() < 10) then
				self.dragbar:SetSize(self.dragbar:GetWidth(),10)
			end
		else
			self.dragbar:SetSize(self:GetWidth()*self:BarScale(),self.dragbar:GetHeight())
			if(self.dragbar:GetWidth() < 10) then
				self.dragbar:SetSize(10,self.dragbar:GetHeight())
			end		
		end
		
		self:OnScroll(self:Value())
	else
		self.dragbar:SetVisible(false)
		self:OnScroll(0)
		self.wo = true
	end
	if(n == 1) then self:Layout(2) end
end

function Panel:DoLayout()
	self:Layout(1)
end

registerComponent(Panel,"scrollbar","panel")