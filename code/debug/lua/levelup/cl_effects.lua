local xpList = LinkedList()

local function pnum(pos,num,duration)
	local le = LocalEntity()
	le:SetPos(pos)
	le:SetVelocity(Vector(0,0,10))
	le:SetRadius(num)
	le:SetStartTime(LevelTime())
	le:SetEndTime(LevelTime() + duration)
	le:SetType(LE_SCOREPLUM)
	le:SetTrType(TR_LINEAR)
	local re = RefEntity()
	re:SetType(RT_SPRITE)
	re:SetRadius(16)
	re:SetColor(1,1,1,1)
	le:SetRefEntity(re)
	le:SetColor(1,1,1,1)
end

local function findNear(pos)
	return xpList:IterReverse(function(t)
		local len = VectorLength(t.pos - pos)
		if(len < 40) then
			return t
		end
	end)
end

function FX_XPText(xp,pos)
	--pnum(pos + Vector(0,0,0),xp,1000)
	pos = pos + (VectorRandom() * 10)
	local n = findNear(pos)
	if(n ~= nil) then
		n.pos = pos
		n.time = LevelTime()
		n.xp = n.xp + xp
		return
	end
	local t = {}
	t.pos = pos
	t.time = LevelTime()
	t.xp = xp
	xpList:Add(t)
end

local function colorXP(xp,a)
	draw.SetColor(0,1,0,a)
	if(xp >= 25) then draw.SetColor(1,1,0,a) end
	if(xp >= 50) then draw.SetColor(0,0,1,a) end
	if(xp >= 100) then draw.SetColor(1,0,0,a) end
	if(xp >= 200) then draw.SetColor(1,0,1,a) end
end

local function d2d()
	xpList:Iter(function(t)
		local dt = (LevelTime() - t.time) / 1600
		if(dt < 1) then 
			local pos = t.pos + Vector(0,0,dt*50)
			local ts,inview = VectorToScreen(pos)
			if(inview) then
				local d = VectorLength(_CG.refdef.origin - pos)
				local size = 4 - (d / 100)
				local x = ts.x - (string.len("" .. t.xp)*8*size) / 2
				local y = ts.y
				local a = 1 - dt
				if(size < 1) then size = 1 end
				size = size + (1 - math.min(dt * 60,1)) * 2
				draw.SetColor(0,0,0,a)
				draw.Text(x-1,y,"" .. t.xp,8*size,10*size)
				draw.SetColor(0,0,0,a)
				draw.Text(x+1,y,"" .. t.xp,8*size,10*size)
				draw.SetColor(0,0,0,a)
				draw.Text(x,y-1,"" .. t.xp,8*size,10*size)
				draw.SetColor(0,0,0,a)
				draw.Text(x,y+1,"" .. t.xp,8*size,10*size)
				colorXP(t.xp,a)
				draw.Text(x,y,"" .. t.xp,8*size,10*size)
			end
		else
			xpList:Remove()
		end
	end)
end
hook.add("Draw2D","levelup_fx",d2d)