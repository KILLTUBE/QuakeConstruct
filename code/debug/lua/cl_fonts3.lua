local corporate = LoadFont("gfx/fonts/elbaris.ini")

local function d2d()
	corporate:SetKern(5)
	
	local tw = 12
	local th = 12
	local x = 10
	
	local text = "Welcome to qconstruct! Have Fun!"

	for k,v in pairs(string.ToTable(text)) do
		local r,g,b = draw.GetPixel(x+tw/2,300 + th/2)
		r = r / 255
		g = g / 255
		b = b / 255
		draw.SetColor(r,g,b,1)
		x = corporate:DrawChar(x,300,v,tw,th)
	end
	
	--bloomish()
end
hook.add("Draw2D","cl_fonts3",d2d)