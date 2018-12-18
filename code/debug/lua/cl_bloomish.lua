local flare = CreateShader("f",[[
{
	{
		map gfx/misc/flare.tga
		blendFunc add
		rgbGen vertex
		alphaGen vertex
	}
}
]])
local pcolors = {}

local function bloomish()
	local iw = 640/20
	local ih = 480/20
	
	local iw2 = 640/20
	local ih2 = 480/20
	local i = 160
	
	for x=0,20 do
		for y=0,20 do
			local r,g,b = draw.GetPixel(
				((x*iw2)+iw2/2) + (math.random(-iw2,iw2)/2),
				((y*ih2)+ih2/2) + (math.random(-ih2,ih2)/2))

			r = r / 255
			g = g / 255
			b = b / 255
			
			pcolors[x] = pcolors[x] or {}
			pcolors[x][y] = pcolors[x][y] or {0,0,0}
			pcolors[x][y][1] = pcolors[x][y][1] + (r - pcolors[x][y][1])*.1
			pcolors[x][y][2] = pcolors[x][y][2] + (g - pcolors[x][y][2])*.1
			pcolors[x][y][3] = pcolors[x][y][3] + (b - pcolors[x][y][3])*.1		
		end
	end
	
	--draw.SetColor(0,0,0,.5)
	--draw.Rect(0,0,640,480)
	
	for x=0,20 do
		for y=0,20 do
			r = pcolors[x][y][1]
			g = pcolors[x][y][2]
			b = pcolors[x][y][3]
			
			draw.SetColor(r/1.8,g/1.8,b/1.8,1)
			draw.Rect((x*iw) - i/2,(y*ih) - i/2,iw+i,ih+i,flare)
		end
	end
end
hook.add("Draw2D","cl_bloomish",bloomish)