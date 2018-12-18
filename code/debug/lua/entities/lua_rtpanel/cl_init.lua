ENT.Base = "lua_gpanel"

render.SetupRenderTarget(4,512,512)

local data = 
[[{
	{
		map $rendertarget 4
		alphaGen vertex
		rgbGen vertex
		tcMod transform 1 0 0 -1 0 0
	}
}]]
ENT.renderTarget = CreateShader("f",data)

function ENT:DrawForeground(cr,cg)
	local camera = self.net.camtarget or 0
	local cameraEnt = GetEntityByIndex(camera)
	if(cameraEnt == nil) then return end
	
	draw.SetColor(1,1,1,1)
	draw.Text(30,30,"Cool RTCam: " .. camera,30,30)
	--draw.Text(30,60,"Position: " .. tostring(cameraEnt:GetPos()),20,30)
	
	draw.SetColor(1,1,1,1)
	draw.Rect(60,80,640-120,480-120,self.renderTarget)
	
	--print("RTCamera: " .. camera .. "\n")
end

function ENT:Initialized()
	--print("RTPANEL INIT!")
	if(self["BaseClass"].Initialized ~= nil) then self["BaseClass"].Initialized(self) end
	self.lastAngle = Vector(0,0,0)
	self.camMod = Vector(0,0,0)
end

function ENT:ReInitialize()
	--print("RTPANEL REINIT!")
	if(self["BaseClass"].ReInitialize ~= nil) then self["BaseClass"].ReInitialize(self) end
	self.lastAngle = Vector(0,0,0)
	self.camMod = Vector(0,0,0)
end

function GPanelUserCommand(self,pl,angle,fm,rm,um,buttons,weapon)
	self.buttonPress = bitAnd(buttons,BUTTON_ATTACK)
	if(self.block) then 
		buttons = 0
		SetUserCommand(self.lastAngle,fm,rm,um,buttons,weapon)
		--self.camMod = getDeltaAngle(self.lastAngle,angle)
	else
		if(self.buttonPress ~= 1) then
			--self.lastAngle.x = angle.x
			--self.lastAngle.y = angle.y
		end
	end
end

function ENT:UserCommand(...)
	GPanelUserCommand(self,unpack(arg))
end

function ENT:DrawRT()
	--print("^4" .. tostring(self.camMod) .. "\n")
	--print("^5" .. tostring(self.lastAngle) .. "\n")
	local camera = self.net.camtarget or 0
	local cameraEnt = GetEntityByIndex(camera)
	if(cameraEnt == nil or camera == 0) then 
		--print("^1 NULL CAMERA!\n")
		return
	end

	render.CreateScene()
	
	_RT_ORIGIN = cameraEnt:GetPos()
	
	render.AddPacketEntities()
	render.AddLocalEntities()
	render.AddMarks()

	--[[reftest:SetPos(org + u/2)
	reftest:Render()
	reftest:SetPos(org - u/2)
	reftest:Render()
	reftest:SetPos(org + r/2)
	reftest:Render()
	reftest:SetPos(org - r/2)
	reftest:Render()]]
	
	local ang = cameraEnt:GetAngles()
	if(self.mouse and self:InRect(0,0,640,480,self.mouse) and self.useable) then
		local mx = (self.mouse.x - 320) / 320
		local my = (self.mouse.y - 240) / 240
		ang.p = ang.p + my * 90
		ang.y = ang.y - mx * 90
		self:BlockUserCommands(true)
	else
		self:BlockUserCommands(false)
	end
	
	--ang = ang + self.camMod
	
	
	local refdef = {}
	refdef.x = 0
	refdef.y = 0
	refdef.fov_x = 90
	refdef.fov_y = 90
	refdef.width = 640
	refdef.height = 480
	refdef.origin = cameraEnt:GetPos()
	refdef.angles = ang
	refdef.flags = 0
	refdef.renderTarget = 4
	refdef.isRenderTarget = true
	render.RenderScene(refdef)
	
	_RT_ORIGIN = nil
end