altmenu = {}

local flash = LoadShader("flareShader")
local frame = LoadShader("menu/art/addbotframe")
local s_menu_open = LoadSound("sound/misc/menu1.wav")
local s_menu_item = LoadSound("sound/misc/menu2.wav")
local s_menu_close = LoadSound("sound/misc/menu3.wav")
local s_menu_select = s_menu_close
local s_menu_fail = LoadSound("sound/misc/menu4.wav")

local template = UI_Create("button")
template:SetPos(0,20)
template:SetSize(100,15)
template:SetTextSize(8)		
template:SetText("<nothing here>")
template:TextAlignRight()
template:Remove()

if(altmenuframe != nil) then altmenuframe:Remove()
	altmenuframe = nil
end
altmenuframe = UI_Create("frame")

local panel = altmenuframe
if(panel != nil) then
	panel.name = "base"
	panel:SetPos(10,150)
	panel:SetSize(200,275)
	panel:SetTitle("Alt Menu")
	panel:CatchMouse(true)
	panel:SetVisible(true)
	panel:EnableCloseButton(false)
	
	Timer(.2,function() panel:SetVisible(false) end)
end

local subpane = UI_Create("panel",panel)
if(subpane != nil) then
	subpane.Draw = function() end --Don't draw this one
	subpane.DoLayout = function(self)
		self:SetSize(self:GetParent():GetWidth(),self:GetParent():GetHeight() - 25)
		self:SetPos(0,0)
	end
end

local subpane2 = UI_Create("panel",panel)
if(subpane2 != nil) then
	--subpane2.Draw = function() end --Don't draw this one
	subpane2.DoLayout = function(self)
		self:SetSize(self:GetParent():GetWidth(),25)
		self:SetPos(0,self:GetParent():GetHeight() - 25)
	end
end

local back = UI_Create("button",subpane2)
if(back != nil) then
	back.DoLayout = function(self)
		self:Expand()
	end
	back:SetText("<-Back")
	back:SetVisible(false)
end

local panel2 = UI_Create("listpane",subpane)
if(panel2 != nil) then
	panel2.name = "base->listpane"
	panel2:SetSize(100,100)
	panel2:DoLayout()
	
	--[[btn:SetSize(100,14)
	btn:SetText("Close")
	btn.DoClick = function(btn)
		panel:SetVisible(false)
	end
	panel2:AddPanel(btn,true)]]
end

function altmenu.textSize(w,h)

end

function altmenu.setBack(func,...)
	back:SetVisible(true)
	back.DoClick = function(btn)
		pcall(func,unpack(arg))
	end
end

function altmenu.addButton(name,func,...)
	template:SetText(name)
	template.DoClick = function(btn)
		pcall(func,unpack(arg))
	end
	
	local pane = panel2:AddPanel(template,true)
	panel2:DoLayout()
	return pane
end

function altmenu.clearButtons()
	panel2:Clear()
	back:SetVisible(false)
end

local function keyed(key,state)
	if(key == K_ALT) then
		panel:SetVisible(state)
	end
end
hook.add("KeyEvent","cl_menu",keyed)