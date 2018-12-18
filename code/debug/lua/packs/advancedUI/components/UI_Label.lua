local Panel = {}
Panel.text = ""
Panel.align = 0
Panel.textwidth = 10
Panel.textheight = 10

function Panel:Initialize()

end

function Panel:SetText(t)
	if(type(t) == "string") then
		self.text = t
	end
end

function Panel:GetText()
	return self.text
end

function Panel:SetTextSize(s,h)
	self.textwidth = s
	self.textheight = s
	if(h) then
		self.textheight = h
	end
end

function Panel:GetTextSize()
	return self.textwidth,self.textheight
end

function Panel:TextAlignLeft()
	self.align = 1
end

function Panel:TextAlignRight()
	self.align = 2
end

function Panel:TextAlignCenter()
	self.align = 0
end

function Panel:ShouldMask()
	local par = self:GetDelegate()
	return (self:TouchingEdges(par) or self.w < self:TextWidth())
end

function Panel:StrLen()
	return string.len(fixcolorstring(self.text))
end

function Panel:ScaleToContents(padding)
	local ts = self.textwidth
	local sw = (ts * self:StrLen()) + (padding or 10)
	local sh = self.textheight + (padding or 10)
	self:SetSize(sw,sh)
end

function Panel:TextWidth()
	local ts = self.textwidth
	local sw = (ts * self:StrLen())
	return sw
end

function Panel:Draw()
	self:DrawBackground()
	SkinCall("DrawLabelForeground")
end

registerComponent(Panel,"label","panel")