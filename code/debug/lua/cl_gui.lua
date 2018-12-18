local function absvec(v)
	return Vector(math.abs(v.x),math.abs(v.y),math.abs(v.z))
end

local function positionModel(ref)
	mins,maxs = render.ModelBounds(ref:GetModel())

	return vMul(vSub(maxs,absvec(mins)),-.5)
end

local function refSize(ref)
	mins,maxs = render.ModelBounds(ref:GetModel())
	
	return VectorLength(vMul(vSub(maxs,mins),2))
end


function MakeModelFrame(mdl)
	if(MDL_VIEWPANE == nil) then
		MDL_VIEWPANE = UI_Create("frame")
		if(MDL_VIEWPANE != nil) then
			MDL_VIEWPANE:SetSize(100,100)
			MDL_VIEWPANE:Center()
			MDL_VIEWPANE:CatchMouse(true)
			MDL_VIEWPANE.OnRemove = function(self)
				MDL_VIEWPANE = nil
			end
		end
	end
	
	if(MDL_VIEWPANE != nil and MDL_VIEWPANE.sub == nil) then
		local test = UI_Create("modelpane",MDL_VIEWPANE)
		if(test != nil) then
			local inf = LocalPlayer():GetInfo()
			test:SetModel(LoadModel(mdl))
			test:SetSkin(0)
			local pl = "models/players"
			if(string.sub(mdl,0,string.len(pl)) == pl) then
				test:SetSkin(LocalPlayer():GetInfo().torsoSkin)
				print("SetSkin\n")
			end
			test:SetCamOrigin(Vector(45,0,0))
			test.PositionModel = function(self,ref)
				ref:SetPos(positionModel(ref))
				
				local dist = refSize(ref)
				self:SetCamOrigin(Vector(math.cos(self.rot/57.3)*dist,-math.sin(self.rot/57.3)*dist,0))
			end
		end
		MDL_VIEWPANE.sub = test
	else
		MDL_VIEWPANE.sub:SetModel(mdl)
	end
end