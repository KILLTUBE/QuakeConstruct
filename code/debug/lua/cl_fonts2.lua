local corporate = LoadFont("gfx/fonts/corporate.ini")

local tx = 0

local function d2d()
	corporate:SetKern(5)
	
	local text = "Welcome to quake construct, this is an awesome program writen by Hxrmn."
	local tw = 12
	local th = 12
	local x = 10 + tx
	local x1 = 10
	local x2 = 130
	for k,v in pairs(string.ToTable(text)) do
		if(x >= x1 and x < x2) then
			local f1 = math.min(1,(x - x1)/12)
			local f2 = math.min(1,(x2 - x)/12)
			draw.SetColor(0,0,0,(f1*f2)/2)
			corporate:DrawChar(x,300 + math.cos((LevelTime()/200) + k/2)*5,v,tw,th)
			
			draw.SetColor(1,1,1,f1*f2)
			x = corporate:DrawChar(x,300 + math.sin((LevelTime()/200) + k/2)*5,v,tw,th)
		else
			x = x + corporate:GetWidth(v,tw)
		end
	end
	
	tx = tx - Lag()/3
	
	if(tx < -corporate:GetWidth(text,tw)) then
		tx = x1 + x2
	end
end
hook.add("Draw2D","cl_fonts2",d2d)