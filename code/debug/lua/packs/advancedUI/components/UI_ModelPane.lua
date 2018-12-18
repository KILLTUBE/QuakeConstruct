local Panel = {}
Panel.model = nil
Panel.org = Vector()
Panel.nofade = true

function Panel:Initialize()
	self.ref = RefEntity()
	self.rot = 0
end

function Panel:SetModel(mdl)
	if(type(mdl) == "string") then
		self.model = LoadModel(mdl)
	elseif(type(mdl) == "number") then
		self.model = mdl
	end
	self.ref:SetModel(self.model)
end

function Panel:SetSkin(skin)
	self.skin = skin
end

function Panel:SetCamOrigin(org)
	self.org = org
end

function Panel:DoLayout()
	self:Expand()
end

function Panel:PositionModel(ref)
	ref:SetAngles(Vector(0,self.rot,0))
end

function Panel:DrawModel()
	self.ref:Render()
	self:PositionModel(self.ref)
	if(self.skin) then
		self.ref:SetSkin(self.skin)
	end
end

function Panel:DrawBackground()
	SkinCall("DrawModelPane")
end

registerComponent(Panel,"modelpane","panel")