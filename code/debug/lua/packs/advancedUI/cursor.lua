local tex = LoadShader("softcursor")

local function draw2d()
	if(MouseFocused() and !util.IsUI()) then
		draw.SetColor(1,1,1,1)
		if(MouseDown()) then draw.SetColor(1,.7,.7,1) end
		draw.Rect(GetXMouse(),GetYMouse(),16,16,tex)
	end
end
hook.add("Draw2D","UIcursor",draw2d,-9999)