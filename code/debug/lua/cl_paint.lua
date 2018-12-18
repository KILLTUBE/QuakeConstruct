local paint = UI_Create("frame")
paint:CatchMouse(true)
paint:SetSize(300,300)

local canvas = paint:GetContentPane()
canvas.ShouldMask = function() return false end
canvas.lines = {}
canvas.MousePressed = function(self)
	self.doPaint = true
	self.lastx = GetXMouse() - self:GetX()
	self.lasty = GetYMouse() - self:GetY()
end

local function lineCalc(x1,y1,x2,y2)
	local dx = x2 - x1
	local dy = y2 - y1
	local cx = x1 + dx/2
	local cy = y1 + dy/2
	local rot = math.atan2(dy,dx)*57.3
	
	return {cx,cy,rot,math.sqrt(dx*dx + dy*dy)}
end

canvas.MouseReleased = function(self)
	self.doPaint = false
end

canvas.MouseReleasedOutside = function(self)
	self.doPaint = false
end

local function constrainCoords(px,py,pw,ph,x,y)
	if(x > px + pw) then x = px + pw end
	if(x < px) then x = px end
	
	if(y > py + ph) then y = py + ph end
	if(y < py) then y = py end
	return x,y
end

paint:SetBGColor(0,0,0,0)

canvas.Draw = function(self)
	draw.SetColor(1,1,1,1)
	--SkinCall("DrawBackground")

	local x = self:GetX()
	local y = self:GetY()
	local w = self:GetWidth()
	local h = self:GetHeight()
	local nx = GetXMouse() - x
	local ny = GetYMouse() - y
	
	if(self.doPaint) then
		local x2 = self.lastx
		local y2 = self.lasty
		
		nx,ny = constrainCoords(0,0,w,h,nx,ny)
		x2,y2 = constrainCoords(0,0,w,h,x2,y2)
		
		table.insert(self.lines,lineCalc(nx,ny,x2,y2))
		self.lastx = nx
		self.lasty = ny
	end
	
	draw.SetColor(0,0,0,1)
	for i=1,#self.lines do
		local line = self.lines[i]
		draw.RectRotated(line[1]+x,line[2]+y,line[4],2,mark,line[3])
	end
end