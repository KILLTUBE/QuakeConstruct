softmask = {}

local mask = {x=0,y=0,w=640,h=480}
local charmap = LoadShader("gfx/2d/bigchars")
local masklist = {}

local function drawOutlineRect(x,y,w,h,s,shd,color)
	if(color) then draw.SetColor(unpack(color)) end
	draw.Rect(x,y,w-s,s,shd)
	draw.Rect(x+(w-s),y,s,h-s,shd)
	draw.Rect(x+s,y+(h-s),w-s,s,shd)
	draw.Rect(x,y,s,h,shd)
	if(color) then draw.SetColor(1,1,1,1) end
end

function softmask.Get()
	return mask.x,mask.y,mask.w,mask.h
end

function softmask.IsMasked(x,y,w,h)
	local mx,my,mw,mh = softmask.Get()
	return (x < mx or y < my or x+w > mx+mw or y+h > my+mh)
end

function softmask.IsOutside(x,y,w,h)
	local mx,my,mw,mh = softmask.Get()
	return (x+w < mx or y+h < my or x > mx+mw or y > my+mh)
end

function softmask.Set(x,y,w,h)
	x = x or mask.x
	y = y or mask.y
	w = w or mask.w
	h = h or mask.h
	mask = {x=x,y=y,w=w,h=h}
	
	if(QLUA_DEBUG) then table.insert(masklist,mask) end
end

function softmask.Draw()
	for k,v in pairs(masklist) do
		drawOutlineRect(v.x,v.y,v.w,v.h,2,nil,{1,0,0,1})
	end
	masklist = {}
end

function softmask.Clear()
	masklist = {}
end

function softmask.Reset()
	mask = {x=0,y=0,w=640,h=480}
end

function softmask.Rect(rx,ry,rw,rh,shader,s,t,s1,t1,noReMap)
	s = s or 0
	t = t or 0
	s1 = s1 or 1
	t1 = t1 or 1
	
	local m = mask
	local r = {x=rx,y=ry,w=rw,h=rh}
	local v = {x=0,y=0,w=0,h=0}
	
	if(r.x < m.x) then v.x = m.x - rx end
	if(r.y < m.y) then v.y = m.y - ry end
	if(r.x + r.w > m.x + m.w) then v.w = (m.x + m.w) - (r.x + r.w) end
	if(r.y + r.h > m.y + m.h) then v.h = (m.y + m.h) - (r.y + r.h) end
	
	if(!noReMap) then
		s = s + v.x/r.w
		s1 = s1 + v.w/r.w
	
		t = t + v.y/r.h
		t1 = t1 + v.h/r.h
	end
		
	r.x = r.x + v.x
	r.w = r.w - (v.x - v.w)
	
	r.y = r.y + v.y
	r.h = r.h - (v.y - v.h)
	
	if(r.w < 0) then return end
	if(r.h < 0) then return end
	
	draw.Rect(r.x,r.y,r.w,r.h,shader,s,t,s1,t1)
end

local function drawChar(x,y,ch,tw,th)
	if(softmask.IsOutside(x,y,tw,th)) then return end
	if(softmask.IsMasked(x,y,tw,th)) then
		local row,col,s = util.CharData(ch)
		softmask.Rect(x,y,tw,th,charmap,col,row,col+s,row+s,true)
		TEXT_DRAW = TEXT_DRAW + 1
	else
		draw.Text(x,y,ch,tw,th)
	end
end

local function color(ch)
	if(ch == "1") then draw.SetColor(1,0,0,1) return true end
	if(ch == "2") then draw.SetColor(0,1,0,1) return true end
	if(ch == "3") then draw.SetColor(1,1,0,1) return true end
	if(ch == "4") then draw.SetColor(0,0,1,1) return true end
	if(ch == "5") then draw.SetColor(0,1,1,1) return true end
	if(ch == "6") then draw.SetColor(1,0,1,1) return true end
	if(ch == "7") then draw.SetColor(1,1,1,1) return true end
	if(ch == "8") then draw.SetColor(0,0,0,1) return true end
	return false
end

function softmask.Text(x,y,str,tw,th)
	local tab = string.ToTable(str)
	local skipn = false
	for k,ch in pairs(tab) do
		if(!skipn) then
			if(ch == "^" and color(tab[k+1])) then
				skipn = true
			end
			if(!skipn) then
				if(ch == "\n") then
					return
				else
					drawChar(x,y,ch,tw,th)
					x = x + tw
				end
			end
		else
			skipn = false
		end
	end
end