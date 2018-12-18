print("Loaded CL_Init\n")

ENT.PanelModel = LoadModel("models/misc/scoreboard.MD3")

local scr = {Vector(0,0),Vector(640,0),Vector(640,480),Vector(0,480)}

local function warpVectors(warp,vectors)
	local out = {}
	for k,v in pairs(vectors) do
		out[k] = warp:Warp(v)
	end
	return out;
end

function ENT:InRect(x,y,w,h,v)
	if(v.x < x or v.x > x+w) then return false end
	if(v.y < y or v.y > y+h) then return false end
	return true
end

local data = 
[[{
	{
		blendfunc add
		map textures/sfx/console02.tga
		alphaGen vertex
		rgbGen vertex
	}
}]]
ENT.consoleTexture = CreateShader("f",data)


function GPanelUserCommand(self,pl,angle,fm,rm,um,buttons,weapon)
	if(self.block) then 
		self.buttonPress = bitAnd(buttons,BUTTON_ATTACK)
		buttons = 0
		SetUserCommand(angle,fm,rm,um,buttons,weapon)
	end
end

function ENT:UserCommand(...)
	GPanelUserCommand(self,unpack(arg))
end

function ENT:FirePanel(findex)
	SendString("panelfired " .. self.Entity:EntIndex() .. " " .. findex)
end

function ENT:BlockUserCommands(b)
	self.block = b
end

function ENT:ShouldDraw()
	local org = _RT_ORIGIN or _CG.refdef.origin
	local res = TraceLine(org,self.Entity:GetPos())
	return (res.endpos == self.Entity:GetPos())
end

function ENT:DrawModel()
	local pos = self.Entity:GetPos()
	self.panelref = RefEntity()
	self.panelref:SetModel(self.PanelModel)
	self.panelref:SetPos(pos)
	self.panelref:SetAngles(self.Entity:GetAngles() + Vector(0,90,-10))
	self.panelref:Scale(Vector(.1,.1,.1))
	self.panelref:Render()
end

function ENT:Start2D()
	self.invwarp = self.invwarp or qmath.Warper()
	local f,r,u = AngleVectors(self.Entity:GetAngles() + Vector(0,0,-10))
	local pos = GetTag(self.panelref,"tag_origin")
	local right = GetTag(self.panelref,"tag_right")
	local down = GetTag(self.panelref,"tag_down")
	local mouse = true
	
	local dp = DotProduct(VectorNormalize(_CG.refdef.origin - self.Entity:GetPos()), f)
	
	local quad = {}
	quad[1] = pos
	quad[2] = right
	quad[3] = right + (down - pos)
	quad[4] = down
	
	for k,v in pairs(quad) do
		quad[k], d = VectorToScreen(quad[k])
		if(d == false) then mouse = false end
	end
	
	self.invwarp:SetSource(unpack(quad))
	self.invwarp:SetDest(unpack(scr))
	self.mouseOn = mouse
	self.mouse = self.invwarp:Warp(Vector(320,240))
	self.useable = ((VectorLength(_CG.refdef.origin - self.Entity:GetPos()) < 100) and (dp > 0))
	
	
	draw.Start3D(pos,right,down,Vector(0,0,0))
end

function ENT:DrawForeground(cr,cg)
	draw.SetColor(1,1,1,cr)
	draw.Text(30,30,"Panel Locked",20,(cr*50))
	
	draw.SetColor(1,1,1,cr)
	draw.Text(30,370 + (100*cg),"Function:",20,30)
	draw.SetColor(1,1,1,cr)
	draw.Text(30,400 + (100*cg),self.net.message or "nil",20,50*cr)
	
	if(self.light != 0) then
		draw.SetColor(self.light*cr,self.light*cg,.2,1)
		draw.RectRotated(320,240,240-(cr*80),240-(cr*80),self.consoleTexture,-LevelTime()/10)
	end
	
	local msg = self.net.message or "nil"
	
	if(self.net.locked == 1) then return end
	
	local ins = 100
	if((1-self.light) != 0) then
		draw.SetColor(.1,1,.3,.7*(1-self.light))
		draw.BeveledRect(ins/2,ins/2,640-ins,480-ins,
		.1,1,.3,.7*(1-self.light)
		,.1,10)
		
		draw.SetColor(0,0,0,.7*(1-self.light))
		draw.Text(320 - string.len(msg)*15,240 - 25,msg,30,50)
	end
	
	--draw.SetColor(0,0,0,self.light)
	--draw.Rect(0,0,640,480)

	
	if(self.mouse and self:InRect(0,0,640,480,self.mouse) and self.useable) then
		if(self:InRect(ins/2,ins/2,640-ins,480-ins,self.mouse)) then
			draw.SetColor(0,0,0,0)
			draw.BeveledRect(ins/2,ins/2,640-ins,480-ins,
			1,1,1,.7*(1-self.light)
			,.1,10)
			
			draw.SetColor(1,1,1,.7)
			draw.Text(320 - string.len(msg)*15,240 - 25,msg,30,50)
			if(self.buttonPress == 1) then
				draw.SetColor(0,0,0,0)
				draw.BeveledRect(ins/2,ins/2,640-ins,480-ins,
				1,0,0,.7
				,.1,10)			
			end
			
			if(self.buttonPress == 1 and self.msg == 0) then
				self:FirePanel(1)
				self.msg = 1
			elseif(self.buttonPress == 0) then
				self.msg = 0
			end
		end
		
		draw.SetColor(1,1,1,1)
		draw.Rect(self.mouse.x, self.mouse.y, 10, 10)
		self:BlockUserCommands(true)
		self.light = self.light - .1
		if(self.light < 0) then self.light = 0 end
	else
		self.buttonPress = 0
		self.msg = 0
		self:BlockUserCommands(false)
		self.light = self.light + .1
		if(self.light > 1) then self.light = 1 end
	end
end

function ENT:DrawUI()
	self.buttonPress = self.buttonPress or 0
	self.msg = self.msg or 0
	
	self.rot = self.rot or 0
	self.rot = self.rot + 1
	self.light = self.light or 1
	self.light2 = self.light2 or 1
	
	if(self.net.locked == 0) then
		self.light2 = self.light2 + .1
		if(self.light2 > 1) then self.light2 = 1 end
	else
		self.light2 = self.light2 - .1
		if(self.light2 < 0) then self.light2 = 0 end
	end
	
	local cr = 1 - (self.light2*self.light2)
	local cg = self.light2*self.light2
	local alp = (1 - ((LevelTime()/800)%1)) * cr
	
	draw.SetColor((cr*.4) + alp*.5,(cg*.4) + alp*.1,0,.3 + alp*.3)
	draw.Rect(0,0,640,480)
	
	draw.SetColor(cr,cg,0,.3)
	draw.Rect(0,20,640,5+(cr*100))
	draw.Rect(0,(480-20)-(cr*100),640,5+(cr*100))
	
	if(self.light2 < 1) then
		--draw.Rect(50*cr,140,10 + (60*cr),205)
		
		draw.Rect(640 - (600*cr),140,10 + (60*cr),205)
		draw.Rect((530*cr),140,10 + (60*cr),205)
	end
	
	self:DrawForeground(cr,cg)
end

function ENT:End2D()
	draw.End3D()
end

function ENT:Draw()
	if(!self:ShouldDraw()) then return end
	self:DrawModel()
	self:Start2D()
	self:DrawUI()
	self:End2D()
end