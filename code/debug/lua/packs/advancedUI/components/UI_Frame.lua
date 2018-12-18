local Panel = {}
Panel.removeOnClose = true
--Panel.bgcolor = {0.3,0.3,0.3,.8}

function Panel:Initialize()
	--self:ColorAdjust(self.bgcolor,.3)
	self.contentPane = UI_Create("panel",self)
	self.contentPane.bgcolor = self:ColorAdjust(self.contentPane.bgcolor,.5)
	
	self.dragbar = UI_Create("dragbutton",self,true)
	self.dragbar:AffectParent(true)
	self.dragbar:SetText("Untitled")
	self.dragbar:SetTextSize(8)
	
	self.close = UI_Create("button",self,true)
	self.close:SetText("X")
	self.close.DoClick = function()
		--self:Remove()
		if(self.removeOnClose) then
			self:Close()
		else
			self:SetVisible(false)
		end
	end
	
	self.dragbar2 = UI_Create("dragbutton",self,true)
	self.dragbar2:SetSize(12,12)
	self.dragbar2:LockCenter(true)
	self.dragbar2.Affect = function(db,dx,dy)
		--db.x = db.x + dx
		--db.y = db.y + dy
	
		if(db.x < 20) then
			db.x = 20
		end
		if(db.y < 25) then 
			db.y = 25
		end
	
		self:SetSize(db.x+12,db.y+10)
	end
	
	self:PositionBar()
	self:AlignContentPane()
end

function Panel:RemoveOnClose(b)
	self.removeOnClose = b
end

function Panel:EnableCloseButton(b)
	self.close:SetVisible(b)
end

function Panel:SetTitle(t)
	self.dragbar:SetText(t)
end

function Panel:AlignContentPane()
	self.contentPane:SetPos(2,15)
	self.contentPane:SetSize(self:GetWidth()-4,self:GetHeight()-30)
end

function Panel:GetContentPane()
	return self.contentPane
end

function Panel:PositionBar()
	self.dragbar:SetPos(2,2)
	self.dragbar:SetSize(self:GetWidth() - 4,15)
	self.close:SetSize(20,15)
	
	self.dragbar2:SetPos(self:GetWidth() - self.dragbar2:GetWidth() - 2,
						 self:GetHeight() - self.dragbar2:GetHeight() - 2)
						 
	self.close:SetPos(self:GetWidth() - self.close:GetWidth() - 2,2)
end

function Panel:SetSize(w,h)
	self.BaseClass.SetSize(self,w,h)
	self:PositionBar()
	self:AlignContentPane()
end

function Panel:ConstrainToScreen(b)
	self.dragbar:ConstrainToScreen(b)
end

registerComponent(Panel,"frame","panel")