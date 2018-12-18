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

local function compareVectors(v1,v2)
	if(v2.x > v1.x) then v2.x = v1.x end
	if(v2.y > v1.y) then v2.y = v1.y end
	if(v2.z > v1.z) then v2.z = v1.z end
	return v1
end

local function rectifyBounds(mins,maxs,vec)
	return mins+vec,maxs+vec
end

local function compareBounds(mins,maxs,mins2,maxs2)
	maxs = compareVectors(maxs,maxs2)
	mins = compareVectors(mins2,mins)
	return mins,maxs
end

local function colectiveBounds(legs,torso,head)
	mins,maxs = render.ModelBounds(legs:GetModel())
	mins2,maxs2 = render.ModelBounds(torso:GetModel())
	mins3,maxs3 = render.ModelBounds(head:GetModel())
	
	mins2,maxs2 = rectifyBounds(mins2,maxs2,torso:GetPos() - legs:GetPos())
	mins3,maxs3 = rectifyBounds(mins3,maxs3,head:GetPos() - torso:GetPos())
	
	mins,maxs = compareBounds(mins,maxs,mins2,maxs2)
	mins,maxs = compareBounds(mins,maxs,mins3,maxs3)
	return mins,maxs
end

local function positionChar(legs,torso,head,mins,maxs)
	return vMul(vSub(maxs,absvec(mins)),-.5)
end

local function charSize(legs,torso,head,mins,maxs)
	return VectorLength(vMul(vSub(maxs,mins),2))
end

function setupModelView(panel,char,skin)
	if(char == "") then return end
	
	ConsoleCommand("model " .. char .. "/" .. (skin or "default") .. "\n")
	
	local legs,torso,head = LoadCharacter(char,skin,"default")
	panel.ref = legs
	panel.torso = torso
	panel.head = head
	panel.model = 0
	
	local anims = loadPlayerAnimations(char)
	local lanim = anims["LEGS_RUN"]
		lanim:SetRef(panel.ref)
		lanim:SetType(ANIM_ACT_LOOP_LERP)
		lanim:Play()
		
	local lanim_idle = anims["LEGS_IDLE"]
		lanim_idle:SetRef(panel.ref)
		lanim_idle:SetType(ANIM_ACT_LOOP_LERP)
		lanim_idle:Play()

	local tanim = anims["TORSO_STAND"]
		tanim:SetRef(panel.torso)
		tanim:SetType(ANIM_ACT_LOOP)
		tanim:Play()
	
	local first = true
	panel.DrawModel = function(self)
		self:PositionModel(self.ref)
				
		self.ref:SetAngles(Vector())
		self.torso:SetAngles(Vector(
		math.cos(LevelTime()/1700)*20,
		math.sin(LevelTime()/700)*20,0))
		self.head:SetAngles(Vector(
		math.cos(LevelTime()/1700)*30,
		math.sin(LevelTime()/700)*30,0))
		
		self.torso:PositionOnTag(self.ref,"tag_torso")
		self.head:PositionOnTag(self.torso,"tag_head")
		
		lanim_idle:Animate()
		--lanim:Animate()
		tanim:Animate()
		
		if(first) then
			first = false
			self.ref:SetPos(Vector(0,0,-self.torso:GetPos().z/2))
			return
		end
		
		util.PlayerWeapon(LocalPlayer(),self.torso)
		self.ref:Render()
		torso:Render()
		head:Render()
	end
	
	panel.PositionModel = function(self,ref)
		local dist = 150
		self:SetCamOrigin(Vector(math.cos(self.rot/57.3)*dist,-math.sin(self.rot/57.3)*dist,0))
	end
	
	panel.DrawBackground = function(self)
		draw.SetColor(0,0,0,1)
		draw.Text2(self:GetX()+2,self:GetY()+2,char,.8,true)
		draw.SetColor(1,1,1,1)
		draw.Text2(self:GetX()+2,self:GetY()+2,char,.8)
		
		draw.SetColor(1,1,1,1)
		draw.Text2(self:GetX()+2,self:GetY()+20,skin or "default",.5)
		SkinCall("DrawModelPane")
	end
end

local template = UI_Create("image")
template:SetPos(0,0)
template:SetSize(40,40)
--template:SetTextSize(8)		
--template:SetText("<nothing here>")
--template:TextAlignRight()
template:Remove()

local function addButton(label,target,func,...)
	template:SetImage(label)
	template.DoClick = function(btn)
		pcall(func,unpack(arg))
	end
	
	local pane = target:AddPanel(template,true)
	target:DoLayout()
	return pane
end

function MakeModelFrame()
	local ICON_SIZE = 60
	template:SetSize(ICON_SIZE,ICON_SIZE)
	if(MDL_VIEWPANE == nil) then
		MDL_VIEWPANE = UI_Create("frame")
		if(MDL_VIEWPANE != nil) then
			MDL_VIEWPANE:SetSize(400,300)
			MDL_VIEWPANE:Center()
			MDL_VIEWPANE:CatchMouse(true)
			MDL_VIEWPANE.OnRemove = function(self)
				MDL_VIEWPANE = nil
				print("Removed!\n")
			end
			--MDL_VIEWPANE.Draw = function() end
		end
		
		local subpane = UI_Create("panel",MDL_VIEWPANE)
		if(subpane != nil) then
			subpane.Draw = function() end --Don't draw this one
			subpane.DoLayout = function(self)
				self:SetSize(self:GetParent():GetWidth()-(ICON_SIZE+8),self:GetParent():GetHeight()-20)
				self:SetPos(0,0)
			end
		end

		local subpane2 = UI_Create("panel",MDL_VIEWPANE)
		if(subpane2 != nil) then
			subpane2.Draw = function() end --Don't draw this one
			subpane2.DoLayout = function(self)
				self:SetSize((ICON_SIZE+8),self:GetParent():GetHeight()-20)
				self:SetPos(self:GetParent():GetWidth()-(ICON_SIZE+8),0)
			end
		end
		
		local modelpane = nil
		if(subpane != nil) then
			local test = UI_Create("modelpane",subpane)
			if(test != nil) then
				test:SetCamOrigin(Vector(45,0,0))
				setupModelView(test,"")
				modelpane = test
			end
		end	
		
		if(subpane2 != nil) then
			local panel2 = UI_Create("listpane",subpane2)
			if(panel2 != nil) then
				panel2.name = "base->listpane"
				panel2:SetSize(100,100)
				panel2:DoLayout()
				
				local test = packList("models/players",".tga")
				table.sort(test,function(a,b) return a < b end)
				print(#test .. "\n")
				for k,v in pairs(test) do
					local ext = string.GetExtensionFromFilename(v)
					if(string.CountSlashes(v) == 1 and string.find(v,"icon_")) then
						local sl = string.find(v,"/")
						local ico = string.find(v,"icon_")
						local dot = string.find(v,".tga")
						local model = string.sub(v,0,sl-1)
						local skin = string.sub(v,ico+5,dot-1)
						print(model .. " - " .. skin .. " - " .. v .. "\n")
						addButton("models/players/" .. v,panel2,function() 
							if(modelpane) then
								setupModelView(modelpane,model,skin)
							end
						end):CatchMouse(true)
					end
				end
			end
		end
	end
end

MakeModelFrame()