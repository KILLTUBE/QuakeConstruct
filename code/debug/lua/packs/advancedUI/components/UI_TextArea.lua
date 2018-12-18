local Panel = {}
Panel.faketab = "    "
Panel.editable = true

local caps = {}
caps[7] = '\"'
caps[12] = '<'
caps[13] = '_'
caps[14] = '>'
caps[15] = "?"
caps[16] = ')'
caps[17] = '!'
caps[18] = '@'
caps[19] = '#'
caps[20] = '$'
caps[21] = '%'
caps[22] = '^'
caps[23] = '&'
caps[24] = '*'
caps[25] = '('
caps[27] = ':'
caps[29] = '+'
caps[59] = '['
caps[60] = '|'
caps[61] = ']'

--Panel.bgcolor = {1,0.2,0,.5}
--Panel.fgcolor = {0,1,0,.5}

function Panel:Initialize()
	self.lines = {}
	self.tw = 7
	self.th = 8
	self.totalw = 0
	self.totalh = 0
	self.spacing = 1
	self.str = ""
	self.caret = {0,0}
	self.latch = false
	self.ex = 20
	self.edited = false
	self.multiline = true
	self.expandable = true
	self.drawborder = false
end

function Panel:ParseLine(str)
	return str
end

function Panel:ParseToLines(str)
	self.str = str
	str = string.Replace(str,"\t",self.faketab)
	local ex = string.Explode("\n",str)
	self.lines = ex
end

function Panel:ParseStringWidth()
	local w = 0
	for k,v in pairs(self.lines) do
		local len = string.len(v)*self.tw
		if(len > w) then w = len end
	end
	
	return w
end

function Panel:ParseStringHeight()
	local h = (((#self.lines-1) * self.spacing) * self.th)
	return h
end

function Panel:SetTextSize(w,h)
	self.tw = w
	self.th = h
end

function Panel:Draw()
	SkinCall("DrawTextArea")
end

function Panel:MousePressed(x,y)
	x = x - self:GetX()
	y = y - self:GetY()
	local w = self.totalw
	local h = self.totalh
	local tw = self.totalw
	
	x = x - self.tw
	y = y - self.th
	
	x = x / self.tw
	x = math.ceil(x)-- * self.tw
	
	y = y / self.th
	y = math.ceil(y)-- * self.th
	
	self.caret[1] = x
	self.caret[2] = y
	
	self:ContrainCaret()
	
	local line = self.lines[self.caret[2] + 1]
	local char = string.sub(line,self.caret[1]+1,self.caret[1]+1)
end

function Panel:ShouldDrawCaret()
	return self.editable
end

function Panel:SetEditable(b)
	self.editable = b
end

function Panel:SetExpandable(b)
	self.expandable = b
end

function Panel:SetDrawBorder(b)
	self.drawborder = b
end

function Panel:SetCaret(x,y)
	self.caret[1] = x
	self.caret[2] = y
	self:ContrainCaret()
end

function Panel:ContrainCaret()
	if(self.caret[1] < 0) then self.caret[1] = 0 end
	if(self.caret[2] < 0) then self.caret[2] = 0 end
	
	if(self.caret[2] >= #self.lines-1) then
		self.caret[2] = #self.lines-1
	end

	local line = self.lines[self.caret[2] + 1]
	local len = string.len(line)
	if(self.caret[1] > len) then
		self.caret[1] = len
	end
end

function Panel:InsertText(id,txt)
	local line = self.lines[id]
	local s = string.sub(line,0,self.caret[1])
	local e = string.sub(line,self.caret[1]+1,string.len(line))
	
	self.lines[id] = s .. txt .. e
	
	self.caret[1] = self.caret[1] + string.len(txt)
end

function Panel:SetMultiline(b)
	self.multiline = b
end

function Panel:KeyTyped(k)
	local id = self.caret[2] + 1
	if(k == K_UPARROW) then
		self.caret[2] = self.caret[2] - 1
	elseif(k == K_DOWNARROW) then
		self.caret[2] = self.caret[2] + 1
	elseif(k == K_LEFTARROW) then
		self.caret[1] = self.caret[1] - 1
		if(self.caret[1] < 0 and self.caret[2] > 0) then
			self.caret[2] = self.caret[2] - 1
			local line = self.lines[id-1]
			self.caret[1] = string.len(line)
		end
	elseif(k == K_RIGHTARROW) then
		self.caret[1] = self.caret[1] + 1
		local line = self.lines[id]
		if(self.caret[1] > string.len(line)) then
			self.caret[1] = 0
			self.caret[2] = self.caret[2] + 1
		end
	elseif(k == K_SPACE) then
		self:InsertText(id," ")
	elseif(k == K_TAB) then
		self:InsertText(id,self.faketab)
	elseif(k == K_ENTER) then
		if(self.multiline) then
			local line = self.lines[id]
			local s = string.sub(line,0,self.caret[1])
			local e = string.sub(line,self.caret[1]+1,string.len(line))
		
			table.insert(self.lines,id+1,"")
			
			self.lines[id] = s
			self.lines[id+1] = e
			
			self.caret[1] = 0
			self.caret[2] = self.caret[2] + 1
		end
	elseif(k == K_BACKSPACE) then
		if(self.caret[1] <= 0 and self.caret[2] <= 0) then return end
		if(self.caret[1] <= 0 and #self.lines > 1 and self.caret[2] > 0) then
			local t = self.lines[id]
			self.caret[2] = self.caret[2] - 1
			self.caret[1] = string.len(self.lines[id-1])
			
			self.lines[id-1] = self.lines[id-1] .. t
			
			table.remove(self.lines,id)
			self:ContrainCaret()
			self:PerformLineSize()
			
			return 
		end
		
		local line = self.lines[id]
		local s = string.sub(line,0,self.caret[1]-1)
		local e = string.sub(line,self.caret[1]+1,string.len(line))
		line = s .. e
		self.caret[1] = self.caret[1] - 1
		
		self.lines[id] = line
	elseif(k >= 39 and k <= 122) then
		local char = string.char(k)
		if(KeyIsDown(K_SHIFT)) then
			local cap = k - (string.byte("a") - string.byte("A"))
			char = string.char(cap)
			if(caps[cap] != nil) then char = caps[cap] end
		end
		self:InsertText(id,char)
	end
	
	self:PerformLineSize()
	self:ContrainCaret()
	self.edited = true
end

function Panel:PerformLineSize()
	if(self.expandable) then
		self.totalw = self:ParseStringWidth() - self.ex
		self.totalh = self:ParseStringHeight() - self.ex
		self:DoLayout()
		if(self:GetParent() != nil) then
			self:GetParent():DoLayout()
		end
	end
end

function Panel:SetText(str)
	self:ParseToLines(str)
	self:PerformLineSize()
	self.edited = false
end

function Panel:GetText(str)
	if(self.edited) then
		local str = ""
		for k,v in pairs(self.lines) do
			if(k == #self.lines) then
				str = str .. v
			else
				str = str .. v .. "\n"
			end
		end
		return str
	end
	return self.str
end

function Panel:DoLayout()
	if(self.expandable) then
		self:SetSize(self.totalw + self.ex*2,self.totalh + self.ex*2)
	else
		self["BaseClass"].DoLayout(self)
	end
	if(self:GetParent() != nil and self.latch != true) then
		self:GetParent().MousePressed = function(par,x,y) self:MousePressed(x,y) end
		self.latch = true
	end
end

registerComponent(Panel,"textarea","panel")