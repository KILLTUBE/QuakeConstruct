downloader.add("lua/levelup/cl_shop.lua")

local function RemoveStuff()
	local tab = table.Copy(GetAllEntities())
	for k,v in pairs(tab) do
		local class = v:Classname()
		if(string.find(class,"weapon")) then
			v:Remove()
		end
	end
end
RemoveStuff()

local function buyWeapon(pl,id)
	local t = LV_tableForPlayer(pl)
	if(t == nil) then return end
	local w = t.weapons[id] or 0
	local bcost = LVSHOP[1][id][1]*(600 + (w * 600))
	if(t.money >= bcost) then
		t.weapons[id] = w + 1
		t.money = t.money - bcost
		pl:GiveWeapon(id)
		pl:SetWeapon(id)
		if(id == WP_GAUNTLET) then
			pl:SetAmmo(id,-1)
		end
	end
end

hook.add("MessageReceived","lvshop",function(str,pl) 
	if(string.find(str,"lvbuy")) then
		local id = string.sub(str,6,string.len(str))
		buyWeapon(pl,tonumber(id))
		print("SV: Player: " .. pl:GetInfo().name .. " bought: " .. id .. "\n")
		LVgamestate(pl)
	end 
end)
