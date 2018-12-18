local Panel = {}
--Panel.bgcolor = {0.3,0.3,0.3,.8}
Panel.draging = false
Panel.dragx = 0
Panel.dragy = 0
Panel.constrain = false
Panel.affectParent = false
Panel.lockCenter = false

function Panel:Initialize()
	self.bgcolor = self:ColorAdjust(self.bgcolor,-.7)
end

function Panel:Affect(dx,dy)
	if(self.parent and self.affectParent) then
		self.parent.x = self.parent.x + dx
		self.parent.y = self.parent.y + dy
	else
		self:SetPos(self.x + dx, self.y + dy)
	end
end

function Panel:LockCenter(b)
	self.lockCenter = b
end

function Panel:Think()
	self.BaseClass:Think()
	
	if(!self.draging) then return false end
	local dx = GetXMouse() - self.dragx
	local dy = GetYMouse() - self.dragy
	
	if(self.lockCenter) then
		local nx = GetXMouse()
		local ny = GetYMouse()
		if(self.parent) then
			nx = nx - self.parent:GetX()
			ny = ny - self.parent:GetY()
		end
		nx = nx - self:GetWidth()/2
		ny = ny - self:GetHeight()/2
		
		--Smooth out the movement
		--self:SetPos(
			--self.x + (nx - self.x)*.3, 
			--self.y + (ny - self.y)*.3)
		self:SetPos(nx,ny)
	end
	
	self:Affect(dx,dy)
		
	self.dragx = GetXMouse()
	self.dragy = GetYMouse()
	
	if(self.constrain) then
		if(self.x + self.w > 640) then
			self.x = (640 - self.w)
		end
		if(self.y + self.h > 480) then
			self.y = (480 - self.h)
		end
		if(self.x < 0) then self.x = 0 end
		if(self.y < 0) then self.y = 0 end
	end
	return true
end

function Panel:AffectParent(b)
	self.affectParent = b
end

function Panel:ConstrainToScreen(b)
	self.constrain = b
end

function Panel:DoLayout() 
	self:SetPos(self.x,self.y)
end

function Panel:MousePressed(x,y)
	self.dragx = x
	self.dragy = y
	self.draging = true
end
function Panel:MouseReleased(x,y) self.draging = false end
function Panel:MouseReleasedOutside(x,y) self.draging = false end

registerComponent(Panel,"dragbutton","button")