local Panel = {}

local function coloradjust(tab,amt)
	local out = {}
	for k,v in pairs(tab) do
		out[k] = math.min(math.max(v * (1 + amt),0),1)
	end
	return out
end

function Panel:Press() end
function Panel:DoClick() end
function Panel:OtherClick(other) end

function Panel:DrawBackground()
	SkinCall("DrawButtonBackground",self:MouseOver(),self:MouseDown())
end

function Panel:MousePressed()
	self:Press()
end

function Panel:MouseReleased()
	self:DoClick()
end

function Panel:MouseReleasedOutside(x,y,other)
	self:OtherClick(other)
end

registerComponent(Panel,"button","label")