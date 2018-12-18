--Qconstruct markup language

local tags = {}

function newTag(macro,...)
	local tag = {}
	tag.args = unpack(arg)
	tag.macro = macro
	table.insert(tags,tag)
end

newTag("link","text","dest")
newTag("image","src","w","h")
newTag("font","w","h")

local function doArg(argdata)
	argdata = string.Explode('=',argdata)
	if(#argdata != 2) then error("Malformed Argument.\n") end
	return argdata[1],argdata[2]
end

local function spaceReplace(str)
	local tab = string.ToTable(str)
	local out = ""
	local quotes = false
	for i=1, #tab do
		local ch = tab[i]
		if(ch == "'" and quotes == false) then quotes = true
		elseif(ch == "'" and quotes == true) then quotes = false
		elseif(ch == " " and quotes == false) then
		else out = out .. ch end
	end
	return out
end

local function doTag(tagdata)
	local tagargs = {}
	local spc = string.find(tagdata," ")
	local name = string.sub(tagdata,2,string.len(tagdata))
	
	if(spc != nil) then
		name = string.sub(tagdata,2,spc-1)
		local remain = string.sub(tagdata,spc+1,string.len(tagdata))
		--remain = string.Replace(remain,' ','')
		remain = spaceReplace(remain)
		remain = string.Explode(',',remain)
		
		--print("^2Got Tag: '" .. tagdata .. "' " .. name .. ".\n")
		for i=1,#remain do
			local k,v = doArg(remain[i])
			tagargs[k] = v
		end	
	end
	
	local tag = {}
	tag.name = name
	tag.args = tagargs
	return tag
end

local function parseChunk(chunk,callback,callback_char)
	local intag = false
	local tab = string.ToTable(chunk)
	local tagtemp = ""
	for i=1, #tab do
		local ch = tab[i]
		if(ch == "[") then
			if(intag == false) then
				intag = true
			else
				error("Tag MisMatch.\n")
			end
		elseif(ch == "]") then
			if(intag == true) then
				intag = false
				local tag = doTag(tagtemp)
				if(tag != nil) then
					local b,e = pcall(callback,tag)
					if(!b) then error("QML: " .. e .. "\n") end
				end
				tagtemp = ""
			else
				error("Tag MisMatch.\n")
			end
		elseif(!intag) then
			if(callback_char != nil) then
				local b,e = pcall(callback_char,ch)
				if(!b) then error("QML: " .. e .. "\n") end
			end
		end
		if(intag) then tagtemp = tagtemp .. ch end
	end
end

function streamQML(filename,callback,callback_char,pak)
	if(pak) then
		local txt = packRead(filename)
		if(txt == nil) then 
			error("Could Not Read File: " .. filename .. ".\n") 
			return
		end
		parseChunk(txt,callback,callback_char)
	else
		file = io.open(filename, "r")
		if(file != nil) then
			local lines = 0
			local content = ""
			for line in file:lines() do
				content = content .. line .. "\n"
			end
			parseChunk(content,callback,callback_char)
			file:close()
		else
			error("File not found: '" .. filename .. "'.")
			return
		end	
	end
end

function doMarkupFile(filename,pak)
	local frame = UI_Create("frame")
	frame:SetPos(10,10)
	frame:SetSize(620,460)
	frame:SetTitle("QML - " .. filename)
	frame:CatchMouse(true)
	frame:SetVisible(true)
	frame:GetContentPane():SetBGColor(1,1,1,1)

	local editpane = UI_Create("editpane",frame)
	local template = UI_Create("panel",editpane)
	if(editpane) then
		template.Draw = function() end
		template:SetPos(0,0)
		template:SetSize(10,10)
		editpane:SetContent(template)
	end

	local cx = 0
	local cy = 2
	local cw = 0
	local ch = 0
	local font = {w = 8, h = 8, r=0,g=0,b=0}

	local function makeLabel(size)
		local clabel = UI_Create("label",template)
		
		clabel.Draw = function()
			SkinCall("DrawLabelForeground")
		end
		local w,h,r,g,b = font.w,font.h,font.r,font.g,font.b
		clabel:SetFGColor(r,g,b,1)
		clabel:SetPos(cx,cy)
		clabel:SetTextSize(size or w,h)
		clabel:TextAlignCenter()
		clabel:SetText("")
		clabel:SetDelegate(editpane.container)
		return clabel
	end

	local function makeButton(size,func)
		local clabel = UI_Create("button",template)
		clabel.Draw = function(self)
			--self:DrawBackground()
			local x,y = self:GetPos()
			local w,h = self:GetSize()
			SkinCall("DoBG")
			sk.coloradjust(nil,0,self:GetAlpha())
			SkinCall("DrawBGRect",x,y,w,h)
			
			SkinCall("DrawLabelForeground")
		end
		local w,h,r,g,b = font.w,font.h,font.r,font.g,font.b
		clabel:SetBGColor(1-r,1-g,1-b,1)
		clabel:SetFGColor(r,g,b,1)
		clabel.DoClick = func or function() end
		clabel:SetPos(cx,cy)
		clabel:SetTextSize(size or w,h)
		clabel:TextAlignCenter()
		clabel:SetText("")
		clabel:SetDelegate(editpane.container)
		return clabel
	end

	local cl = makeLabel()
	
	local function resize()
		if(cx > cw) then cw = cx end
		if(cw > template:GetWidth()) then
			template:SetSize(cw + 20,template:GetHeight())
		end
		if(cy + ch > template:GetHeight()) then
			template:SetSize(template:GetWidth(),(cy + ch) + 50)
		end
	end

	local function maxs(panel)
		local w,h = panel:GetSize()
		if(h > ch) then ch = h end
		resize()
	end

	local function append(str)
		cl:SetText(cl:GetText() .. str)
		cl:ScaleToContents(0)
		maxs(cl)
	end

	local function appendPanel(panel)
		cx = cx + panel:GetWidth()
		maxs(panel)
	end
	
	local function finishLabel()
		if(cl != nil) then
			cx = cx + cl:GetWidth()
		end
		maxs(cl)
	end

	local function newLine()
		if(ch == 0) then 
			ch = font.h 
			resize()
		end
		cy = cy + ch
		ch = 0
		cx = 0
	end
	
	local function onLink(file)
		frame:Remove()
		local f = doMarkupFile(file,pak)
		f:SetPos(frame:GetPos())
		f:SetSize(frame:GetSize())
	end
	
	local function onMacro(t)
		if(t == "closewindow") then frame:Close() end
	end

	local function link(args)
		local btn = makeButton(nil,function() onLink(args['dest']) end)
		btn:SetText(args['text'])
		btn:ScaleToContents(0)
		appendPanel(btn)
	end
	
	local function macro(args)
		local btn = makeButton(nil,function() onMacro(args['dest']) end)
		btn:SetText(args['text'])
		btn:ScaleToContents(0)
		appendPanel(btn)
	end
	
	local function image(args)
		local src,w,h = args['src'],args['w'],args['h']
		w = tonumber(w)
		h = tonumber(h)
		
		local img = UI_Create("image",template)
		img:SetImage(src)
		img:SetPos(cx,cy)
		img:SetSize(w,h)
		img:SetFGColor(1,1,1,1)
		img:SetDelegate(editpane.container)
		appendPanel(img)
	end

	local function tfont(args)
		font.w,font.h = args['w'] or 8,args['h'] or 8
		font.r = args['r'] or 0
		font.g = args['g'] or 0
		font.b = args['b'] or 0
		for k,v in pairs(font) do font[k] = tonumber(v) end
	end
	
	local function tbgcolor(args)
		local bgcolor = {}
		bgcolor[1] = args['r'] or 0
		bgcolor[2] = args['g'] or 0
		bgcolor[3] = args['b'] or 0
		bgcolor[4] = 0
		for k,v in pairs(bgcolor) do bgcolor[k] = tonumber(v) end
		frame:GetContentPane():SetBGColor(unpack(bgcolor))
	end
	
	streamQML(filename,
	function(tag)
		finishLabel()
		if(tag.name == "newline") then newLine() end
		if(tag.name == "nl") then newLine() end
		if(tag.name == "link") then link(tag.args) end
		if(tag.name == "macro") then macro(tag.args) end
		if(tag.name == "image") then image(tag.args) end
		if(tag.name == "font") then tfont(tag.args) end
		if(tag.name == "bgcolor") then tbgcolor(tag.args) end
		cl = makeLabel()
	end,
	function(ch)
		if(ch == "\n" or ch == "\t" or ch == "\r") then return end
		append(ch)
	end,
	pak)
	
	finishLabel()
	resize()
	
	return frame
end