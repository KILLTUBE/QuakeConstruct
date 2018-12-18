local Panel = {}
Panel.shader = 0
Panel.nofade = true
Panel.NO_SHADER = LoadShader("gfx/2d/defer.tga")

function Panel:Initialize()

end

function Panel:SetImage(image)
	if(type(image) == "number") then self.shader = image return end
	self.shader = LoadShader(image)
end

function Panel:DrawBackground()
	--SkinCall("DrawBackground")
	self:DoFGColor()
	if(self.shader != 0) then
		SkinCall("DrawBGRect",self:GetX(),self:GetY(),self:GetWidth(),self:GetHeight(),self.shader)
	else
		SkinCall("DrawBGRect",self:GetX(),self:GetY(),20,20,self.NO_SHADER)
	end
end

registerComponent(Panel,"image","button")