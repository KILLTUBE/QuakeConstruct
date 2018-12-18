local texture = LoadShader("gfx/anim_numbers")
local texture2 = LoadShader("gfx/anim_numbers_alpha")
local rows = 5
local cols = 5
local flicker = 1
local hp = 100
local shakex = 0
local shakey = 0
local flow = 1
local ddown = 1
local lastz = nil
local deltaz = 0
local lastang = nil
local deltaang = Vector()
local h_red = 0

local data = 
[[{
	{
		blendfunc add
		map $whiteimage
		alphaGen vertex
		rgbGen vertex
	}
}]]
local bright = CreateShader("f",data)

includesimple("xhud/cl_head")
includesimple("xhud/cl_items")

local spr = AnimSprite(texture,rows,cols)

local colors = {}
colors.ammo_norm = {{1,.5,0,1},{1,.8,0,1}}
colors.ammo_low = {{1,0,0,1},{1,0,0,1}}
colors.health_high = {{0,.5,1,1},{.7,.8,1,1}}
colors.health_norm = {{1,.5,0,1},{1,.8,0,1}}
colors.health_low = {{1,0,0,1},{1,0,0,1}}

local function nframe(f)
	if(f == 0) then f = 10 end
	local f1 = f-1
	local f2 = f+14
	return f1,f2
end

local function drawNum(x,y,w,h,n,c1,c2)
	x = x + w
	y = y + h
	local f1,f2 = nframe(n)
	
	if(n == -1) then
		f1 = 10
		f2 = 11
	end
	
	if(spr != nil) then
		local r,g,b,a = unpack(c1)
		local f = flicker
		
		x = x + shakex
		y = y + shakey
		
		spr:SetPos(x,y)
		draw.SetColor(r*f * flow,g*f * flow,b*f * flow,a*f * flow)
		spr:SetShader(texture)
		spr:SetFrame(f2)
		spr:SetSize(w,h)
		spr:Draw()
		--spr:SetSize(w,h)
		spr:Draw()
		
		spr:SetShader(texture2)
		spr:SetSize(w,h)
		spr:SetFrame(f1)
		
		draw.SetColor(0,0,0,c2[4]*f)
		spr:SetPos(x-1,y-1)
		--spr:Draw()
		
		r,g,b,a = unpack(c2)
		draw.SetColor(r*f,g*f,b*f,a*f)		
		spr:Draw()
	end
end

local function drawNumbers(x,y,w,h,n,kern,c1,c2)
	if(type(n) != "number") then return end
	local str = string.ToTable(tostring(n))
	local nx = x
	for i=1,#str do
		local v = tonumber(str[i]) or 9
		if(str[i] == "-") then v = -1 end
		drawNum(nx,y,w,h,v,c1,c2)
		nx = nx + (w+kern)
	end
end

local function doColors()
	local sinx = (1 - ((LevelTime() / 300) % 1)) * ddown
	local sinx2 = 1 - ((LevelTime() / ((hp*10) + 100)) % 1)
	colors.health_low[1][1] = sinx
	colors.health_low[2][4] = ddown
	
	colors.ammo_low[1][1] = sinx
	
	
	local r,g,b = hsv(hp*1.2,1,1)
	colors.health_norm[2] = {r,g,b,1}

	if(hp < 90) then
		r = r * sinx2
		g = g * sinx2
		b = b * sinx2
	end
	
	colors.health_norm[1] = {r,g,b,1}
	
	local hpx = hp/100
	if(hpx > 1) then hpx = 1 end
	if(hpx < 0) then hpx = 0 end
	
	flicker = math.random(200,255)/255
	flicker = flicker + (1 - flicker) * (hpx)
	
	shakex = (math.random(-4,4) * (1-flicker))
	shakey = (math.random(-8,8) * (1-flicker))
	
	shakex = shakex * (4 - (ddown*3))
	shakey = shakey * (4 - (ddown*3))
	
	flow = (math.sin(LevelTime() / 500)/8) + .8
end

local function angles()
	local ang = VectorToAngles(_CG.refdef.forward)
	local cz = _CG.refdef.origin.z
	
	lastang = lastang or ang
	lastz = lastz or cz
	
	deltaang = getDeltaAngle3(ang,lastang)
	lastang = lastang + (deltaang)*.2
	
	deltaz = (cz - lastz)
	lastz = lastz + (deltaz)*.2
end

local function HealthBar(recty,mx,my)
	--if(hp <= 0) then return end
	
	local col_hp = colors.health_norm
	if(hp > 100) then col_hp = colors.health_high end
	if(hp <= 25) then col_hp = colors.health_low end

	local hpp = (hp/100)
	local crecty = 480 - recty
	local hrh = 10
	local hrw = 150
	local cx = 2
	local hrx = mx+cx --(hrw/2)
	local hry = recty-hrh  --+(crecty/2)-(hrh/2)
	
	local r,g,b,a = unpack(col_hp[1])
	r = (r / 3) + .2
	g = (g / 3) + .2
	b = (b / 3) + .2
	
	draw.SetColor(r,g,b,a)
	draw.Rect(hrx-2,hry-2,hrw+4,hrh+4,bright)
	
	local hppx = (hpp - 1)
	local ew = (hrw*hppx)
		
	if(hpp > 1) then
		draw.Rect((hrx-2) + hrw+4,hry-10,ew,hrh+12,bright)
	end
	
	r,g,b,a = unpack(col_hp[2])
	r = (r / 3)
	g = (g / 3)
	b = (b / 3)

	draw.SetColor(r,g,b,a/2)
	local e = 0
	if(hpp > 1) then 
		hpp = 1
		e = 4
		draw.Rect(hrx+e+hrw*hpp,hry-8,ew-4,hrh+8)
	end
	draw.Rect(hrx,hry,e+hrw*hpp,hrh)
	
	draw.SetColor(1,1,1,1)
	draw.Text(mx+5,recty-hrh,"health: " .. hp,10,10)
end

local HEAD_CENTER = true
local function draw2D()
	hp = _CG.stats[STAT_HEALTH]
	local mx = deltaang.y
	local my = -deltaang.x
	my = my + deltaz
	mx = mx / 5
	my = my / 5
	--if(mx > 40) then mx = 40 end
	--if(mx < -40) then mx = -40 end
	--if(my > 40) then my = 40 end
	--if(my < -40) then my = -40 end
	
	local armor = _CG.stats[STAT_ARMOR]
	--local ammo = _CG.ammo[_CG.weapon+1]
	
	if(hp <= 0) then armor = 0 end
	if(hp <= 0) then ammo = 0 end
	if(hp > 0) then ddown = 1 else
		ddown = ddown + (0-ddown) * .008
		if(ddown < .1) then ddown = .1 end
	end
	
	angles()
	
	--if(hp < 0) then hp = 0 end
	--if(ammo < 0) then ammo = 0 end
	
	doColors()
	
	local recty = my+415
	local red = 0
	
	local lt = LevelTime()
	if(h_red > lt) then
		red = (h_red - lt) / 2500
	end
	
	draw.SetColor(red,0,0,.2 + (red/3))
	draw.Rect(0,recty,640,480-recty)
	draw.SetColor(1,1,1,1)
	
	--DrawAmmo(mx+95+shakex,my+430+shakey,50,50)
	
	if(HEAD_CENTER) then
		DrawHead(mx+(200),my+295,180,hp)
	else
		DrawHead(mx+395,my+275,200,hp)
	end
	
	local col_ammo = colors.ammo_norm
	local col_armor = colors.ammo_norm
	--if(ammo <= 5) then col_ammo = colors.ammo_low end
	if(armor > 100) then col_armor = colors.health_high end
	
	
	local c1 = {1,.5,0,1}
	local c2 = {1,.8,0,1}
	local num_y = my+(480-45)
	
	HealthBar(recty,mx,my)
	
	draw.SetColor(1,1,1,1)
	--draw.Text(10,50,"" .. deltaang.x .. " - " .. deltaang.y .. "",10,10)
	
	--if(_CG.weapon != WP_NONE or true) then draw.Text(mx+5,my+420,"ammo:",10,10) end
	--draw.Text(mx+200,my+420,"health:",10,10)
	--if(_CG.weapon != WP_NONE or true) then drawNumbers(mx,num_y,20,20,ammo,8,unpack(col_ammo)) end
	
	--drawNumbers(mx+190,num_y,20,20,hp,8,unpack(col_hp))
	
	local armorx = mx+300
	if(HEAD_CENTER) then armorx = mx+500 end
	DrawArmor((armorx - 50)+shakex,my+430+shakey,50,50,armor)
	draw.SetColor(1,1,1,1)
	if(armor > 0) then draw.Text(armorx,my+420,"armor:",10,10) end
	if(armor > 0) then drawNumbers(armorx,num_y,20,20,armor,8,unpack(col_armor)) end
	
	--DrawWeaponSelector(320,0)
end
hook.add("Draw2D","cl_xhud",draw2D)

function DrawXHUD()
	draw2D()
end

local function processDamage(attacker,pos,dmg,death,waslocal,wasme,health)
	if(death == MOD_WATER) then
		dmg = dmg * 40
	end
	if(dmg > 50) then dmg = 50 end
	if(waslocal) then
		h_red = LevelTime() + (dmg*50)
	end
end
hook.add("Damaged","cl_xhud",processDamage)

local function shouldDraw(str)
	if(str == "HUD_STATUSBAR_HEALTH") then return false end
	if(str == "HUD_STATUSBAR_ARMOR") then return false end
	if(str == "HUD_STATUSBAR_AMMO") then return false end
	if(str == "HUD_PICKUP") then return false end
	--if(str == "HUD_WEAPONSELECT") then return false end
end
hook.add("ShouldDraw","cl_xhud",shouldDraw)