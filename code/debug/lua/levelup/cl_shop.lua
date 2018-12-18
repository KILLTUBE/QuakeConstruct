local frame = nil
local flist = nil
local template = nil
local weaponLabels = {}

local function cstat(s,i)
	local v = s[i]
	if(v == nil or v == 0) then return "" end
	if(i == 2) then return " damage +" .. v end
	if(i == 3) then return " firerate +" .. v end
	if(i == 4) then return " health +" .. v end
	if(i == 5) then return " resist +" .. v end
	if(i == 6) then return " speed +" .. v end
	if(i == 7) then return " stealth +" .. v end
end

local function getWeaponCost(id)
	local w = LVweapons[id] or 0
	return LVSHOP[1][id][1] * (600 + (w * 600))
end

local function updateWeaponButton(id)
	local w = LVweapons[id] or 0
	local name = WEAPONNAMES[id]
	local lb = weaponLabels[id]
	local cost = getWeaponCost(id)
	lb:SetText("lvl" .. (w+1) .. " " .. name .. " - $" .. cost .. "")
	lb:ScaleToContents()
	
	if(LVcurrentMoney >= cost) then
		lb:SetBGColor(.8,.7,.3,1)
	else
		lb:SetBGColor(.3,0,0,1)
	end
	
	local str = ""
	if(LVweapons[id] or 0 >= 1) then
		if(LVcurrentMoney >= cost) then
			for i=2,7 do
				str = str .. cstat(LVSHOP[1][id],i)
			end
		end
		weaponLabels[id].lb2:SetText(str)
	end
end

local function buy(id)
	if(LVcurrentMoney >= getWeaponCost(id)) then
		SendString("lvbuy" .. id)
		Timer(0.2,function()
			for i=WP_GAUNTLET,WP_BFG do
				updateWeaponButton(i)
			end
		end)
	end
end

local function buildWeaponSlot(id,pane)
	local st = LVSHOP[1][id]
	local lb = UI_Create("button",pane)
	lb:SetFGColor(0,0,0,1)
	lb:TextAlignCenter()
	lb.DoClick = function()
		buy(id)
	end
	weaponLabels[id] = lb
	
	--DAMAGE,FIRERATE,HEALTH,RESIST,SPEED,STEALTH
	local cost = st[1]
	local str = ""
	if(LVweapons[id] or 0 >= 1) then
		for i=2,7 do
			str = str .. cstat(st,i)
		end
	end
	
	local lb2 = UI_Create("label",pane)
	lb2:SetText(str)
	lb2:SetTextSize(8,10)
	lb2:TextAlignLeft()
	lb2:ScaleToContents()
	lb2:SetPos(20,20)
	weaponLabels[id].lb2 = lb2
	
	updateWeaponButton(id)
end

local function addShopWeapons()
	flist:Clear()
	for k,v in pairs(LVSHOP[1]) do
		print(k .. "\n")
		template:SetFGColor(1,1,1,.6)
		local pane = flist:AddPanel(template,true)
		buildWeaponSlot(k,pane)
	end
end

local function open()
	if(frame == nil) then
		frame = UI_Create("frame")
		local w,h = 640,480
		local pw,ph = w/1.5,h
		frame.name = "base"
		frame:SetPos((w/2) - pw/2,0)
		frame:SetSize(pw,ph)
		frame:SetTitle("Buy Menu")
		frame:SetVisible(true)
		frame:RemoveOnClose(false)
		--frame:EnableCloseButton(false)
		
		flist = UI_Create("listpane",frame)
		flist.name = "base->listpane"
		
		if(template == nil) then		
			template = UI_Create("panel")
			template:SetSize(100,40)
			template:Remove()
		end	
		addShopWeapons()
	end
	frame:CatchMouse(true)
	flist:CatchMouse(true)
	frame:SetVisible(true)
end

local function close()
	if(frame == nil) then return end
	frame:SetVisible(false)
end

local function useHook(s)
	if(s == true) then
		open()
		for k,v in pairs(LVSHOP[1]) do
			updateWeaponButton(k)
		end
	else
		close()
	end
end
hook.add("Use","lvshop_1",useHook)