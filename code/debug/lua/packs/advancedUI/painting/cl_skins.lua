panel = panel or nil
local Skin = {}
local shader = LoadShader("9slice1")
local softwaremask = true
local maskOn = false

function SkinCall(func,...)
	if(Skin[func]) then
		local b,e = pcall(Skin[func],Skin,unpack(arg))
		if(!b) then print(e .. "\n") end
		if(b and e) then return e end
	end
end

function SkinPanel(p)
	panel = p
end

function Skin:DefaultBG()
	return {0.1,0.1,0.1,1}
end

function Skin:DefaultFG()
	return {0.8,0.5,0.04,1}
end

function Skin:StartMask(x,y,w,h)
	if(softwaremask) then
		softmask.Set(x,y,w,h)
	else
		draw.MaskRect(x,y,w,h)
	end
	maskOn = true
end

function Skin:EndMask()
	if(softwaremask) then
		softmask.Reset()
	else
		draw.EndMask()
	end
	maskOn = false
end

function Skin:DoFG()
	sk.qcolor(panel.fgcolor)
end

function Skin:DoBG()
	sk.qcolor(panel.bgcolor)
end

local function textSize(x,y,str,tw,th)
	return x,y,tw*string.len(str),th
end

function Skin:Text(...)
	local x,y,w,h = textSize(unpack(arg))
	if(softwaremask) then
		if(softmask.IsMasked(x,y,w,h)) then
			softmask.Text(unpack(arg))
		else
			draw.Text(unpack(arg))
		end
	else
		draw.Text(unpack(arg))
	end
end

function Skin:DrawBGRect(...)
	--drawNSBox(x,y,w,h,4,shader)
	if(softwaremask) then
		softmask.Rect(unpack(arg))
	else
		draw.Rect(unpack(arg))
	end
	RECT_DRAW = RECT_DRAW + 1
end

function Skin:DrawSoftBevelRect(x,y,w,h,d,i)
	SkinCall("DrawBGRect",x,y,w,h)
	
	sk.coloradjust(nil,2*d)
	SkinCall("DrawBGRect",x,y,w,i)
	sk.restore()
	
	sk.coloradjust(nil,1*d)
	SkinCall("DrawBGRect",x,y,i,h)
	sk.restore()
	
	sk.coloradjust(nil,-1*d)
	SkinCall("DrawBGRect",x+(w-i),y,i,h)
	sk.restore()
	
	sk.coloradjust(nil,-2*d)
	SkinCall("DrawBGRect",x,y+(h-i),w,i)
	sk.restore()
	TOUGH_DRAW = TOUGH_DRAW + 1
end

function Skin:DrawBevelRect(x,y,w,h,d,i)
	i=i or 2
	
	local al = panel:GetAlpha()
	
	x = x + (w/2)*(1-al)
	y = y + (h/2)*(1-al)
	
	w = w * al
	h = h * al
	
	if(softwaremask) then
		if(softmask.IsMasked(x,y,w,h)) then
			SkinCall("DrawSoftBevelRect",x,y,w,h,d,i)
			--SkinCall("DrawBGRect",x,y,w,h)
		else
			RECT_DRAW = RECT_DRAW + 1
			local r,g,b,a = unpack(sk.current())
			draw.BeveledRect(x,y,w,h,
							 r,g,b,a,
							 d,i)
		end
	else
		RECT_DRAW = RECT_DRAW + 1
		local r,g,b,a = unpack(sk.current())
		draw.BeveledRect(x,y,w,h,
						 r,g,b,a,
						 d,i)	
	end
end

function Skin:DrawNeon(x,y,w,h,i)
	sk.qcolor({.2,1,.1,.4})

	local i2 = i*2
	
	SkinCall("DrawBGRect",x+i,y+i,w-i2,1)
	SkinCall("DrawBGRect",x+i,y+i,1,h-i2)
	SkinCall("DrawBGRect",(x+(w-1))-i,y+i,1,h-i2)
	SkinCall("DrawBGRect",x+i,(y+(h-1))-i,w-i2,1)
end

function Skin:DrawBackground(d)
	local x,y = panel:GetPos()
	d = d or .04
	sk.coloradjust(nil,0,panel:GetAlpha())
	--draw.Rect(x,y,panel.w,panel.h)
	SkinCall("DrawBevelRect",x,y,panel.w,panel.h,d,1)
	--SkinCall("DrawNeon",x,y,panel.w,panel.h,-1)
end

function Skin:DrawButtonBackground(over,down)
	local nbg = {panel.bgcolor[1],panel.bgcolor[2],panel.bgcolor[3],panel.bgcolor[4]}
	
	if(down) then
		panel.bgcolor = sk.coloradjust(nbg,-.08)
		SkinCall("DrawBackground",-.1)
	elseif(over) then
		panel.bgcolor = sk.coloradjust(nbg,.08)
		SkinCall("DrawBackground",.1)
	else
		sk.qcolor(panel.bgcolor)
		SkinCall("DrawBackground")
	end
	
	panel.bgcolor[1] = nbg[1]
	panel.bgcolor[2] = nbg[2]
	panel.bgcolor[3] = nbg[3]
	panel.bgcolor[4] = nbg[4]
end

function Skin:DrawLabelForeground()
	local tw,th = panel:GetTextSize()
	local x,y = panel:GetPos()
	
	y = y + (panel.h/2) - (th/2)	
	
	if(panel.align == 0) then
		x = x + (panel.w/2) - (tw * panel:StrLen())/2
	elseif(panel.align == 2) then
		x = x + (panel.w) - (tw * panel:StrLen())
		x = x - 2
	else
		x = x + 2
	end
	
	panel:DoFGColor()
	sk.coloradjust(nil,0,panel:GetAlpha())
	SkinCall("Text",x,y,panel.text,tw,th)
end

function Skin:DrawModelPane()
	if(panel.model != nil) then
		render.CreateScene()

		panel:DrawModel()		

		local refdef = {}
		
		refdef.origin = panel.org

		local aim = VectorNormalize(refdef.origin)
		aim = vMul(aim,-1)
		aim = VectorToAngles(aim)

		refdef.angles = aim

		refdef.flags = RDF_NOWORLDMODEL
		refdef.x = panel:GetX()
		refdef.y = panel:GetY()
		refdef.width = panel:GetWidth()
		refdef.height = panel:GetHeight()
		render.RenderScene(refdef)

		panel.rot = panel.rot + 1
	end
end

function Skin:DrawShadow()
	--if(true) then return end
	local al = panel:GetAlpha()
	local i = 0
	panel:DoBGColor()
	sk.coloradjust(panel.bgcolor,-.3,.2)
	
	local x,y = panel:GetPos()
	sk.coloradjust(nil,0,.6*al)
	SkinCall("DrawBGRect",x-(2+i/2),y-(2+i/2),panel.w+(4+i),panel.h+(4+i))
	sk.coloradjust(nil,0,.4*al)
	SkinCall("DrawBGRect",x-(4+i/2),y-(4+i/2),panel.w+(8+i),panel.h+(8+i))
	sk.coloradjust(nil,0,.2*al)
	SkinCall("DrawBGRect",x-(6+i/2),y-(6+i/2),panel.w+(12+i),panel.h+(12+i))
end

function Skin:DrawTextArea()
	if(panel.drawborder) then
		panel:DoBGColor()
		SkinCall("DrawBackground")
	end
	panel:DoFGColor()
	
	sk.coloradjust(nil,0,panel:GetAlpha())
	for k,v in pairs(panel.lines) do
		k = k * panel.spacing
		SkinCall("Text",panel:GetX(),(panel:GetY() + ((k-panel.spacing)*panel.th)),v,panel.tw,panel.th)
	end
	
	if((LevelTime() % 500) > 200) then
		if(panel:ShouldDrawCaret()) then
			SkinCall("Text",panel:GetX() + panel.caret[1]*panel.tw,panel:GetY() + panel.caret[2]*panel.th,"\t",panel.tw,panel.th)
		end
	end
end