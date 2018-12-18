local editframe = UI_Create("frame")
local editor = UI_Create("textarea")

local panel = editframe
if(panel != nil) then
	panel.name = "base"
	panel:SetPos(10,150)
	panel:SetSize(200,275)
	panel:SetTitle("Editor")
	panel:CatchMouse(true)
	panel:CatchKeyboard(true)
	panel:SetVisible(true)
end

local subpane = UI_Create("panel",panel)
if(subpane != nil) then
	subpane.Draw = function() end --Don't draw this one
	subpane.DoLayout = function(self)
		self:SetSize(self:GetParent():GetWidth(),self:GetParent():GetHeight() - 20)
		self:SetPos(0,0)
	end
end

local subpane2 = UI_Create("panel",panel)
if(subpane2 != nil) then
	subpane2.DoLayout = function(self)
		self:SetSize(self:GetParent():GetWidth(),20)
		self:SetPos(0,self:GetParent():GetHeight() - 20)
	end
end

local nextx = 0

local function addBtn(txt,func)
	local btn = UI_Create("button",subpane2)
	if(btn != nil) then
		btn:SetTextSize(8)
		btn:SetPos(nextx,0)
		btn:SetSize(100,0)
		btn.DoClick = function(self)
			pcall(func)
		end
		btn.DoLayout = function(self)
			self:SetPos(self.x,0)
			self:SetSize(self:GetWidth(),subpane2:GetHeight())
		end
		btn:SetText(txt)
		btn:ScaleToContents()
		btn:TextAlignLeft()
		btn:SetVisible(true)
		nextx = nextx + btn:GetWidth()
	end

end

addBtn("Save",function()
	local editorscript = editor:GetText()

	local file = io.open("lua/editortemp.lua","w")
	if(file != nil) then
		file:write(editorscript)
		file:close()
	end
end)

addBtn("Exec CL",function()
	local editorscript = editor:GetText()

	local file = io.open("lua/editortemp.lua","w")
	if(file != nil) then
		file:write(editorscript)
		file:close()
	end
	
	local b,e = pcall(include,"lua/editortemp.lua")
	if(!b) then
		print("^1" .. e .. "\n")
	end
end)

addBtn("Exec SV",function()
	local editorscript = editor:GetText()

	local file = io.open("lua/editortemp.lua","w")
	if(file != nil) then
		file:write(editorscript)
		file:close()
	end
	
	ConsoleCommand("load editortemp")
end)

local editpane = UI_Create("editpane",subpane)
if(editpane) then
	local template = editor
	template:SetPos(0,0)
	template:SetText("")
	
	file = io.open("lua/editortemp.lua", "r")
	if(file != nil) then
		for line in file:lines() do
			template:SetText(template:GetText() .. line .. "\n")
		end
		file:close()
	end
	
	editpane:SetContent(template)
end
print("^1test\n")
print("^3test2\n")