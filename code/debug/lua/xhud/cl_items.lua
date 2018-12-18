local armor_yellow = LoadModel("models/powerups/armor/armor_yel.md3")
local armor_red = LoadModel("models/powerups/armor/armor_red.md3")
local selectShader = LoadShader("gfx/2d/select")
local noammo = LoadShader("icons/noammo")

function DrawArmor(x,y,w,h,count)
	if(count <= 0) then return end
	local mdl = armor_yellow
	local pos = Vector(90,0,-12)
	local ang = Vector(0,LevelTime()/10,0)
	
	if(count >= 100) then
		mdl = armor_red
	end
	
	render.CreateScene()
	
	local ref = RefEntity()
	ref:SetAngles(ang)
	ref:SetModel(mdl)
	ref:SetPos(pos)
	ref:Render()
	
	local refdef = {}
	refdef.x = x
	refdef.y = y
	refdef.width = w
	refdef.height = h
	refdef.origin = Vector()
	refdef.angles = Vector()
	refdef.flags = 1
	render.RenderScene(refdef)
end

local inf = util.WeaponInfo(1)
for k,v in pairs(inf) do
	print(k .. "\n")
end

local weapons = {}
local sizes = {}
local weaponpickup = 0
for i=1, WP_NUM_WEAPONS do
	sizes[i] = 0
	weapons[i] = {}
	weapons[i].x = 0
	weapons[i].size = 0
	weapons[i].has = false
end

local selectorX = nil
function DrawWeaponSelector(x,y)
	selectorX = selectorX or x
	local selected = _CG.weapon
	--print(selected .. "\n")
	
	--if(1 == 1) then return end
	
	local to = _CG.weaponSelect
	local i_weapons = _CG.stats[STAT_WEAPONS]
	local num = WP_NUM_WEAPONS
	local iconsize = 30
	local h = iconsize
	local rx = x
	local name = util.GetWeaponName(to)
	local itempickuptime = _CG.itemPickupTime
	local item = _CG.itemPickup
	local selectorTime = _CG.weaponSelectTime
	local s_to = to
	
	if(item ~= 0) then
		local info = util.ItemInfo(item)
		if(info.type == IT_WEAPON or info.type == IT_AMMO ) then
			if(info.tag == to or info.type == IT_AMMO) then
				weaponpickup = itempickuptime
				s_to = info.tag
			end
		end
	end
	
	if(weaponpickup > selectorTime) then
		selectorTime = weaponpickup
	end
	
	local display = (LevelTime() - (selectorTime + 2000)) / 300
	if(display > 1) then return end
	if(display < 0) then display = 0 end
	
	local deltaPickup = (LevelTime() - weaponpickup) / 1000
	if(deltaPickup > 1) then deltaPickup = 1 end
	local dp = (1-deltaPickup)*5
	
	y = y - (display*display)*30
	
	sizes[to] = sizes[to] + (1 - sizes[to]) * .1
	
	if(dp > 1) then
		sizes[s_to] = sizes[s_to] + (dp - sizes[to]) * .1
	end
	
	for i=1,num do
		sizes[i] = sizes[i] - sizes[i] * .1
		local sh = bitAnd(bitShift(1,-i),i_weapons)
		if(sh ~= 0) then
			local is = 1 + (sizes[i] * 1)
			--if(i == selected) then is = 1.3 end
			
			weapons[i].x = x
			weapons[i].size = iconsize * is
			weapons[i].has = true
			
			x = x + iconsize * is
			
			if(iconsize * is > h) then
				h = iconsize * is
			end
		else
			weapons[i].has = false
			sizes[i] = -1
		end
	end
	
	local w = (x - rx)
	--local xo = ((weapons[to].x + weapons[to].size) - rx) / w
	
	--x = x + xo
	--print(xo .. "\n")
	
	local cx = w / 2
	
	local size = string.len(name)*15
	draw.SetColor(1,1,1,(1-display))
	draw.Text((rx) - size/2,y + h+2,name,15,10)		
	
	for i=1, num do
		if(weapons[i].has) then
			local ammo = _CG.ammo[i+1]
			if(i == WP_GAUNTLET) then ammo = 1 end
			
			local pki = util.GetWeaponIcon(i)
			local size = weapons[i].size
			local na = 1
			local wx = weapons[i].x
			if(ammo == 0) then na = .4 end
			draw.SetColor(na,na,na,(1-display))
			draw.Rect(wx - cx,y,size,size,pki)
			if(ammo == 0) then
				draw.SetColor(1,1,1,(1-display))
				draw.Rect(wx - cx,y,size,size,noammo)
			elseif(i ~= WP_GAUNTLET) then
				draw.SetColor(0,0,0,(1-display)/3)
				draw.Rect(wx-cx,(y + size/2),size,10)
				local ts = string.len(ammo) * 10
				draw.SetColor(1,1,1,(1-display))
				if(ammo <= 5) then
					draw.SetColor(1,0,0,(1-display))
				end
				draw.Text((wx - cx) + (size/2) - ts/2,y + size/2,tostring(ammo),10,10)
			end
		end
	end
	
	local size = weapons[to].size
	selectorX = selectorX + ((weapons[to].x - cx) - selectorX) * .4
	draw.SetColor(1,1,1,(1-display))
	draw.Rect(selectorX,y,size,size,selectShader)
	--selectorX = rx - size/2
end

function DrawAmmo(x,y,w,h)
	local id = _CG.weapon
	local pos = Vector(60,0,0)
	local ang = Vector(0,90 + (math.sin(LevelTime()/1000)*10),0)
	
	if(id == WP_NONE) then return end
	if(id == WP_GAUNTLET) then return end
	
	local inf = util.WeaponInfo(id)
	local mid = inf.weaponMidpoint
	local mins,maxs = render.ModelBounds(inf.weaponModel)
	if(inf.barrelModel != 0) then
		--local mins2,maxs2 = render.ModelBounds(inf.barrelModel)
		--mins = mins + mins2
		--maxs = maxs + maxs2
	end
	mins.y = 0
	mins.z = 0
	maxs.y = 0
	maxs.z = 0
	
	render.CreateScene()
	
	local ref = RefEntity()
	ref:SetAngles(ang)
	ref:SetModel(inf.ammoModel)
	ref:SetPos(pos - mins)
	ref:Render()
	
	local refdef = {}
	refdef.x = x
	refdef.y = y
	refdef.width = w
	refdef.height = h
	refdef.origin = Vector()
	refdef.angles = Vector()
	refdef.flags = 1
	render.RenderScene(refdef)
end