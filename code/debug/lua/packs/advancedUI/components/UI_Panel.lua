local Panel = {}

Panel.parent = nil
Panel.x = 0
Panel.y = 0
Panel.w = 0
Panel.h = 0
Panel.bgcolor = SkinCall("DefaultBG")
Panel.fgcolor = SkinCall("DefaultFG")
Panel.pset = false
Panel.visible = true
Panel.constToParent = false
Panel.valid = true
Panel.removeme = false
Panel.rmvx = 0
Panel.catchm = false
Panel.catchk = false
Panel.cc = 0
Panel.delegate = nil
Panel.lastsize = {0,0}
Panel.inLayout = false
Panel.maskviadelegate = true
Panel.alpha = 0
Panel.targalpha = 1
Panel.nofade = false

local function qcolor(tab)
	draw.SetColor(tab[1],tab[2],tab[3],tab[4])
end

--[[local function coloradjust(tab,amt,alpha)
	local out = {}
	for k,v in pairs(tab) do
		out[k] = math.min(math.max(v + amt,0),1)
	end
	out[4] = tab[4]/2
	if(alpha != nil) then
		out[4] = alpha
	end
	qcolor(out)
end]]

function Panel:ColorAdjust(tab,amt)
	tab = table.Copy(tab)
	for k,v in pairs(tab) do
		if(k != 4) then
			tab[k] = math.min(math.max(v * math.abs(amt),0),1)
		end
	end
	return tab
end

function Panel:Initialize()

end

function Panel:DoFGColor()
	SkinCall("DoFG")
end

function Panel:DoBGColor()
	SkinCall("DoBG")
end

function Panel:GetFGColor()
	return self.fgcolor
end

function Panel:GetBGColor()
	return self.bgcolor
end

function Panel:DrawShadow()
	self:DoBGColor()
	SkinCall("DrawShadow")
end

function Panel:DrawBackground()
	--[[coloradjust(self.bgcolor,-.3,1)
	draw.Rect(x,y,self.w,self.h)
	
	coloradjust(self.bgcolor,.1)
	draw.Rect(x,y,self.w,2)
	
	coloradjust(self.bgcolor,.07)
	draw.Rect(x+(self.w-2),y,2,self.h)
	
	coloradjust(self.bgcolor,-.07)
	draw.Rect(x,y+(self.h-2),self.w,2)
	
	coloradjust(self.bgcolor,-.1)
	draw.Rect(x,y,2,self.h)]]
	
	--if(self:MouseOver()) then
		--draw.Rect(x,y,self.w,self.h)
	--end
	self:DoBGColor()
	SkinCall("DrawBackground")
end

function Panel:MaskViaDelegate(b)
	self.maskviadelegate = b
end

function Panel:SetDelegate(d)
	self.delegate = d
end

function Panel:GetDelegate()
	return self.delegate or self.parent
end

function Panel:MaskMe()
	local par = self:GetDelegate()
	if(par) then
		local w,h = par:GetSize()
		if(w < 0) then w = 0 end
		if(h < 0) then h = 0 end
		if(self:ShouldMask()) then
			SkinCall("StartMask",par:GetX(),par:GetY(),w,h)
			return true
		end
	end
	return false
end

function Panel:ShouldMask()
	local par = self:GetDelegate()
	return self:TouchingEdges(par)
end

function Panel:GetMaskedRect()
	local par = self:GetDelegate()
	local x,y = self:GetPos()
	local w,h = self:GetSize()
	
	if(par) then
		if(x < par:GetX()) then x = par:GetX() end
		if(y < par:GetY()) then y = par:GetY() end
		
		local pw = par:GetX() + par:GetWidth()
		local ph = par:GetY() + par:GetHeight()
		
		if(x + w > pw) then w = pw - x end
		if(y + h > ph) then h = ph - y end
	end
	
	return x,y,w,h
end

function Panel:TouchingEdges(par)
	if(self:GetX() < par:GetX()) then return true end
	if(self:GetY() < par:GetY()) then return true end
	
	if(self.x + self.w > par.x + par:GetWidth()) then 
		return true
	end
	if(self.y + self.h > par.x + par:GetHeight()) then 
		return true
	end
	return false
end

function Panel:OutsidePanel(par)
	if(par == nil) then return false end
	if(self:GetX() + self.w < par:GetX() or self:GetX() - self.w > par:GetX() + par:GetWidth()) then
		return true
	end
	if(self:GetY() + self.h < par:GetY() or self:GetY() - self.h > par:GetY() + par:GetHeight()) then
		return true
	end
	return false
end

function Panel:OutsideDelegate()
	local par = self:GetDelegate()
	return self:OutsidePanel(par)
end

function Panel:ShouldDraw()
	if(self:OutsideDelegate()) then return false end
	return true
end

function Panel:Draw()
	self:DrawBackground()
	--self:DrawChildren()
end

function Panel:ConstrainToParent(b)
	self.constToParent = b
end

function Panel:Think()

end

function Panel:ThinkInternal()
	if(self.nofade) then self.alpha = 1 return end
	if(math.abs(self.alpha - self.targalpha) < .005) then
		self.alpha = self.targalpha
		return
	end
	self.alpha = self.alpha + (self.targalpha - self.alpha) * (.4)
	if(self.alpha <= .02 and self.hide) then
		self:_SetVisible(false)
		if(self.closing == 1) then
			self.closing = 0
			
			UI_EnableCursor(false)
			
			self:OnRemove()
			if(self.parent) then
				self.parent.cc = self.parent.cc - 1
			end
			UI_RemovePanel(self)		
		end
	end
end

function Panel:SetBGColor(r,g,b,a)
	if(type(r) == "table") then
		self.bgcolor = r
		return
	end
	self.bgcolor = {r,g,b,a}
end

function Panel:SetFGColor(r,g,b,a)
	if(type(r) == "table") then
		self.fgcolor = r
		return
	end
	self.fgcolor = {r,g,b,a}
end

function Panel:GetParent()
	return self.parent
end

function Panel:SetParent(p)
	self.parent = p
end

function Panel:SetPos(x,y)
	self.x = x
	self.y = y
	
	if(self.constToParent and self.parent) then
		if(self.x < 0) then self.x = 0 end
		if(self.y < 0) then self.y = 0 end
		
		if(self.x + self.w > self.parent:GetWidth()) then 
			self.x = self.parent:GetWidth() - self.w 
		end
		if(self.y + self.h > self.parent:GetHeight()) then 
			self.y = self.parent:GetHeight() - self.h 
		end
	end
end

function Panel:GetX()
	if(self.parent) then
		return self.x + self.parent:GetX()
	end
	return self.x
end

function Panel:GetY()
	if(self.parent) then
		return self.y + self.parent:GetY()
	end
	return self.y
end

function Panel:GetPos()
	return self:GetX(), self:GetY()
end

function Panel:GetLocalX()
	return self.x
end

function Panel:GetLocalY()
	return self.y
end

function Panel:GetLocalPos()
	return self:GetLocalX(), self:GetLocalY()
end

function Panel:ISetSize(w,h)
	if(w < 0) then w = 0 end
	if(h < 0) then h = 0 end
	if(self.lastsize[1] != w or self.lastsize[2] != h) then 
		self.w = w
		self.h = h
		self:InvalidateLayout()
		self.lastsize = {w,h}
		return true
	end
	return false
end

function Panel:SetSize(w,h)
	if(self.inLayout == true) then return self:ISetSize(w,h) end
	if(self:ISetSize(w,h)) then
		self.inLayout = true
		self:DoLayout()
		self.inLayout = false
		return true
	end
	return false
end

function Panel:GetWidth() return self.w end
function Panel:GetHeight() return self.h end

function Panel:GetSize()
	return self:GetWidth(), self:GetHeight()
end

function Panel:Center()
	local sw = 640
	local sh = 480
	local mw = self:GetWidth()
	local mh = self:GetHeight()
	local w = self.w
	local h = self.h
	local par = self:GetParent()
	
	if(par != nil) then
		sw = par:GetWidth()
		sh = par:GetHeight()
	end
	
	self:SetPos((sw/2) - mw/2,(sh/2) - mh/2)
end

function Panel:Expand()
	self:SetPos(0,0)
	self:SetSize(648,480)
	
	local par = self:GetParent()
	
	if(par != nil) then
		self:SetSize(par:GetWidth(),par:GetHeight())
	end	
end

function Panel:OnRemove() end

function Panel:Close()
	if(self.nofade) then
		self:Remove()
		return
	end
	
	self:SetVisible(false)
	self.closing = 1
	self.targalpha = 0
	if(self.catchm) then
		UI_EnableCursor(false)
	end
	self.catchm = false
end

function Panel:Remove()
	self:OnRemove()
	if(self.parent) then
		self.parent.cc = self.parent.cc - 1
	end
	if(self.catchm) then
		UI_EnableCursor(false)
	end
	self.catchm = false
	UI_RemovePanel(self)
end

function Panel:_SetVisible(b)
	self.visible = b
	if(self.catchm) then
		UI_EnableCursor(self.visible)
	end
end

function Panel:SetVisible(b)
	if(self.nofade) then
		self:_SetVisible(b)
		return
	end
	if(b) then
		if(!self.closing) then
			self:_SetVisible(true)
			self.targalpha = 1
			self.hide = false
			if(self.catchm) then
				UI_EnableCursor(true)
			end
		end
	else
		self.targalpha = 0
		self.hide = true
		if(self.catchm) then
			UI_EnableCursor(false)
		end
	end
end

function Panel:CatchMouse(b)
	self.catchm = b
	if(self:IsVisible()) then 
		UI_EnableCursor(b)
	end
end

function Panel:CatchKeyboard(b)
	self.catchk = b
	if(self:IsVisible()) then 
		UI_EnableKeyboard(b)
	end
end

function Panel:GetContentPane() return nil end
function Panel:OnChildAdded(panel) end
function Panel:KeyPressed(key) end
function Panel:KeyTyped(key) end
function Panel:MouseOver() return self.__mouseInside end
function Panel:MouseDown() return self.__wasPressed end
function Panel:MousePressed(x,y) end
function Panel:MouseReleased(x,y) end
function Panel:MouseReleasedOutside(x,y) end
function Panel:DoLayout() end

function Panel:Valid()
	if(self.valid) then
		if(self.parent) then
			return self.parent:Valid()
		else
			return true
		end
	end
	return false
end

function Panel:GetAlpha()
	if(self:GetDelegate()) then
		local al = self:GetDelegate():GetAlpha()
		if(al < self.alpha) then
			return al
		end
	end
	return self.alpha
end

function Panel:InvalidateLayout()
	self.valid = false
end

function Panel:IsVisible()
	if(self.visible) then
		if(self.parent) then
			return self.parent:IsVisible()
		end
		return true
	end
	return false
end

function Panel:ScaleToContents() end


function Panel.__eq(p1,p2)
	--Quick and dirty fixes here, beware.
	return (p1.IDX == p2.IDX)
end

registerComponent(Panel,"panel")