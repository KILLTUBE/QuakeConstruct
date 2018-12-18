local data = 
[[{
	{
		blendfunc blend
		map gfx/ui_rect.tga
		alphaGen vertex
		rgbGen vertex
		//tcGen environment
	}
}]]
local boxy = CreateShader("f",data)
local panelid = 0

local function dc(x,y)
	draw.SetColor(1,1,1,1)
	draw.Rect(x-1,y-1,2,2)
end
hook.add("DrawCursor","nui_test",dc)

local function adjust(r,g,b,a,amt)
	r = math.min(math.max(r + amt,0),1)
	g = math.min(math.max(g + amt,0),1)
	b = math.min(math.max(b + amt,0),1)
	return r,g,b,a
end

local function fades(panel)
	panel.focusFade_a = panel.focusFade_a or 0
	if(panel.focusFadeIn and panel.focusFade_a < 1) then
		panel.focusFade_a = panel.focusFade_a + .1
		if(panel.focusFade_a > 1) then panel.focusFade_a = 1 end
	elseif(panel:IsOnTop() and panel.focusFadeIn != true) then
		panel.focusFadeIn = true
		panel.focusFadeOut = false
		--panel.focusFade_a = 0
	end
	
	if(panel.focusFadeOut and panel.focusFade_a > 0) then
		panel.focusFade_a = panel.focusFade_a - .1
		if(panel.focusFade_a < 0) then panel.focusFade_a = 0 end
	elseif(!panel:IsOnTop() and panel.focusFadeOut != true) then
		panel.focusFadeIn = false
		panel.focusFadeOut = true
		--panel.focusFade_a = 1
	end
end

function drawPanel(panel)
	local rx, ry = panel:GetPos()
	local x,y = panel:GetLocalPos()
	local w,h = panel:GetSize()
	local class = panel:Classname()
	

	if(class == "button" or class == "frame") then
		fades(panel)
		local amt = 0
		local r,g,b,a = panel:GetBGColor()
		if(panel:MouseOver()) then amt = .15 end
		if(panel:MouseDown()) then amt = -.15 end
		--if(!panel:IsOnTop()) then amt = -.1 end
		amt = amt - ((1 - panel.focusFade_a)*.2)
		
		draw.SetColor(adjust(r,g,b,a,amt))
	else
		draw.SetColor(panel:GetBGColor())
	end
	
	drawNSBox(x,y,w,h,5,boxy)
	
	if(class == "inset") then
		render.CreateScene()
		local legs,torso,head = LoadPlayerModels(LocalPlayer())
		head:SetAngles(Vector(0,LevelTime()/10,0))
		head:Render()
		
		local refdef = {}
		refdef.flags = 1
		refdef.x = x
		refdef.y = y
		refdef.width = w
		refdef.height = h
		refdef.fov_x = 30
		refdef.fov_y = 30
		refdef.origin = Vector(40,0,0)
		refdef.angles = Vector(0,180,0)	
		
		render.RenderScene(refdef)
	end
	
	if(class == "frame") then
		draw.SetColor(.2,.6,1,.5)
		drawNSBox((x+w)-30,(y+h) - 10,30,10,5,boxy)

		local r,g,b,a = panel:GetFGColor()
		draw.SetColor(r,g,b,panel.focusFade_a)
		draw.Text(x+w,y+h,"resize",6,8)
		--draw.Text(x+2,y+2,panel.title or "",8,10)
	end
	if(class == "button") then
		draw.SetColor(panel:GetFGColor())
		draw.Text(x+2,y+2,panel.title or "",8,10)	
	end
	
	--[[if(panel:MouseDown()) then
		draw.SetColor(1,0,0,.3)
		drawNSBox(x,y,w,h,5,boxy)
	elseif(panel:MouseOver()) then
		draw.SetColor(0,1,0,.3)
		drawNSBox(x,y,w,h,5,boxy)
	end]]
	
	if(class == "frame") then
		local r,g,b,a = panel:GetFGColor()
		draw.SetColor(r,g,b,a)
		draw.Text(x+2,y+2,"depth: " .. panel:Depth(),5,7)
	end
end

gui.EnableMouse(true)

local function created(panel)
	panel.Draw = drawPanel
	print("Spawned Panel: " .. panel:Classname() .. "[" .. panel:Index() .. "]" .. "\n")
end
hook.add("PanelCreated","nui_test",created)

local function make(add)
	add = add or 0
	panelid = panelid + 1
	
	local p1 = gui.CreatePanel("frame")
	p1:SetPos(300 + add,200 + add)
	p1:SetSize(128,64)
	p1:SetBGColor(.4,.4,.4,1)
	p1.title = "Panel #" .. panelid
	p1.MouseMove = function(panel,x,y)
		if(panel:MouseDown()) then
			local mx,my = gui.GetMousePos()
			local px,py = panel:GetPos()
			local lx,ly = panel:GetLocalPos()
			local w,h = panel:GetSize()
			my = my - y
			if(my > (ly + (h-16))) then
				local pw = w+x
				local ph = h+y
				if(pw < 30) then pw = 30 end
				if(ph < 30) then ph = 30 end
				panel:SetSize(pw,ph)
			else
				panel:SetPos(px+x,py+y)
			end
		end
	end
	p1.MousePressed = function(panel)
		panel:Focus()
	end

	local p3 = gui.CreatePanel("button",p1)
	p3:SetPos(10,10)
	p3:SetSize(40,10)
	p3:SetBGColor(.8,0,0,.5)
	p3.DoLayout = function(self)
		local parent = self:GetParent()
		local w,h = parent:GetSize()
		self:SetPos(w-30,4)
		self:SetSize(26,12)
	end
	
	p3.MouseReleased = function(panel)
		panel:GetParent():Remove()
	end
	p3.MousePressed = function(panel)
		panel:GetParent():Focus()
	end
	
	local p2 = gui.CreatePanel("inset",p1)
	p2:SetBGColor(.1,.1,.1,1)
	p2.DoLayout = function(self)
		local parent = self:GetParent()
		local w,h = parent:GetSize()
		self:SetPos(2,12)
		self:SetSize(w-4,h-18)
	end
	p2.MousePressed = function(panel)
		panel:GetParent():Focus()
	end
	return p1
end

if(pmaker != nil) then pmaker:Remove() end

pmaker = gui.CreatePanel("button")
pmaker:SetPos(550,460)
pmaker:SetSize(90,20)
pmaker:SetBGColor(.4,.4,.4,1)
pmaker.title = "make panel"
pmaker.Draw = drawPanel

pmaker.MouseReleased = function(panel)
	make()
end

make()
--make(30)
--make(60)