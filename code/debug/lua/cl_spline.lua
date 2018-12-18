local points = {}
local trails = {}
EnableCursor(true)

local function addpoint(x,y)
	table.insert(points,Vector(x,y,0))
end

local function lerp(p1,p2,t)
	return p1 + (p2 - p1) * t
end

local function interpolatePoints(set,t)
	if(#set > 1) then
		local interpolated = {}
		for i=1, #set-1 do
			local p1 = set[i]
			local p2 = set[i+1]
			local lerped = lerp(p1,p2,t)
			draw.SetColor(.2,.2,.2,.6)
			draw.Line(p1.x,p1.y,p2.x,p2.y)
			draw.SetColor(1,.4,0,.8)
			draw.Rect(lerped.x-1,lerped.y-1,2,2)
			table.insert(interpolated,lerped)
		end
		return interpolatePoints(interpolated,t)
	elseif(#set > 0) then
		return set[1]
	end
	return Vector()
end

local order = 1
--addpoint(math.random(100,540),math.random(100,380))

local function keyed(key,state)
	if(key == K_MWHEELDOWN) then
		if(state == true) then
			order = order - 1
			if(order < 1) then order = 1 end
		end
	end
	if(key == K_MWHEELUP) then
		if(state == true) then
			order = order + 1
		end
	end
	if(key == K_MOUSE1) then
		if(state == true) then
			local x,y = GetXMouse(),GetYMouse()
			for i=1, order do
				addpoint(x,y)
			end
		end
	end
	if(key == K_MOUSE2) then
		if(state == true) then
			points = {}
		end
	end
end
hook.add("KeyEvent","cl_spline",keyed)

local lt = 0

local function drawCurve()
	if(#points == 0) then return end
	local last = points[1]
	
	local rez = 30
	for i=1, rez do
		local t = i/rez
		local vec = VectorSpline(points,t)
		draw.Line(vec.x,vec.y,last.x,last.y)
		last = vec
	end
end

local function drawTrace()
	lt = lt + 100
	local t = (lt/5000) % 1
	local vec = VectorSpline(points,t)
	draw.SetColor(1,.2,1,.6)
	for k,v in pairs(points) do
		draw.Rect(v.x-2,v.y-2,4,4)
	end
	draw.SetColor(1,1,1,1)
	draw.Rect(vec.x-2,vec.y-2,4,4)
	
	if(#trails > 0) then
		for k,v in pairs(trails) do
			local al = k / #trails
			draw.SetColor(1,1,1,al)
			draw.Rect(v.x-(2*al),v.y-(2*al),4*al,4*al)
		end
	end
end

local function d2d()
	--LevelTime()
	draw.SetColor(0,0,0,1)
	draw.Rect(0,0,640,480)
	draw.SetColor(1,1,1,1)
	
	draw.Text(20,20,"Tension: " .. order,8,8)
	
	draw.SetColor(1,1,1,1)
	drawCurve()
	
	table.insert(trails,vec)
	if(#trails > 60) then table.remove(trails,1) end
end
hook.add("Draw2D","cl_spline",d2d)