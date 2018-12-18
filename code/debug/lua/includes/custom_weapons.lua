local META = {}
local WEAPONS = {}
local active = {}
local FCF = FindCustomFiles
local WEAPON_CLASSES = {}

--[[function META:Think() end
function META:Initialized() end
function META:Removed() end
function META:MessageReceived() end
function META:VariableChanged() end

if(SERVER) then
	function META:Touch(other,trace) end
	function META:Pain(a,b,take) end
	function META:Die(a,b,take) end
	function META:Use(other) end
	function META:Blocked(other) end
	function META:Reached(other) end
	function META:ClientReady(ent) end
else
	function META:Draw() end
	function META:UserCommand() end
end]]

local function WriteWeaponFunctions(WEAPON)

end

local function metaCall(tab,func,...)
	if(tab[func] != nil) then
		local b,e = pcall(tab[func],tab,unpack(arg))
		if(!b) then
			print("^1Weapon Error[" .. tab._classname .. "]: ^2" .. e .. "\n")
		else
			return true,e
		end
	end
	return false
end

local function sortWeaponClasses()
	table.sort(WEAPON_CLASSES)
end

function ExecuteWeapon(v)
	WEAPON = {}
	WEAPON.ITEM = {}
	WEAPON._classname = string.lower(v[2])
	WEAPON._id = #WEAPON_CLASSES + 1
	WEAPON.register = true
	
	setmetatable(WEAPON,META)
	META.__index = META
	
	Execute(v[1])
	
	if(!WEAPON.Base) then
		WriteWeaponFunctions(WEAPON)
	end
	
	WEAPONS[WEAPON._classname] = WEAPON
	table.insert(_CUSTOM,{data=WEAPON,type="weapon"})
	if(WEAPON.register == true) then
		table.insert(WEAPON_CLASSES,WEAPON._classname)
		sortWeaponClasses()
	end
end

function ExecuteWeaponSub(v)
	print("^1EXECUTE WEAPON SUB! [" .. v[2] .. "]\n")
	local class = string.lower(v[2])
	local current = WEAPONS[class]
	if(current != nil) then
		WEAPON = {}
		Execute(v[1])
		
		--ENTS[class] = table.Inherit( ENT, ENTS[class] )
		table.Update(WEAPONS[class],WEAPON)
		
		--[[for k,v in pairs(active) do
			if(active[k]._classname == class) then
				table.Update(active[k],ENT)
				metaCall(active[k],"ReInitialize")
			end
		end]]
	else
		ExecuteWeapon(v)
	end
end

function RunInits()
	for k,v in pairs(WEAPONS) do
		if(v.register == true) then
			metaCall(v,"Init")
			metaCall(v,"RegisterItem",true)
		else
			metaCall(v,"RegisterItem",false)
		end
	end
end

local function InheritWeapons()
	local finished = false
	local nl = true
	local maxiter = 100
	local i = 0
	local lc = 0
	while(nl == true and i < maxiter) do
		nl = false
		for k,v in pairs(WEAPONS) do
			if(!v.__inherit) then
				local base = v.Base
				local name = string.lower(v._classname)
				if(type(base) == "string") then
					base = string.lower(base)
					if(WEAPONS[base] and base != name)  then
						if(WEAPONS[base].__inherit == true) then
							WEAPONS[name] = table.Inherit( WEAPONS[name], WEAPONS[base] )
							WEAPONS[name].ITEM = table.Inherit( WEAPONS[name].ITEM, WEAPONS[base].ITEM )
							if(SERVER) then
								print("^3Weapon Inherited: " .. name .. " -> " .. base .. "\n")
							else
								print("^4Weapon Inherited: " .. name .. " -> " .. base .. "\n")
							end
							lc = lc + 1
							v.__inherit = true
						else
							nl = true
						end
					end
				else
					lc = lc + 1
					v.__inherit = true
				end
			end
		end
		i = i + 1
	end
	print("Loaded " .. lc .. " weapons with " .. i .. " iterations.\n")
end

local list = FindCustomFiles("lua/weapons")
for k,v in pairs(list) do
	ExecuteWeapon(v)
end
InheritWeapons()
RunInits()
for k,v in pairs(list) do
	ExecuteWeaponSub(v)
end
print("Loading custom weapons\n")

--WRITE WEAPONS MANIFEST SO CLIENT KNOWS WHICH WEAPON IS WHICH
function WriteWeaponsManifest()

end

local function FindWeapon(name)
	return WEAPONS[string.lower(name)]
end

local function reloadWeapons()
	--ENTS
	local list = FCF("lua/weapons")
	for k,v in pairs(list) do
		ExecuteWeaponSub(v)
	end
	InheritWeapons()
end
if(SERVER) then
	concommand.add("reloadWeapons",reloadWeapons)
else
	concommand.add("reloadWeapons_cl",reloadWeapons)
end

if(CLIENT) then
	local function dlhook(file)
		if(string.find(file,"/lua.weapons.") and
		   (string.find(file,"shared.lua") or
		   string.find(file,"cl_init.lua"))) then
			local strt = string.len("lua/downloads/lua.weapons.")
			local name = string.sub(file,strt+1,string.len(file))
			local ed = string.find(name,".",0,true)
			
			--print(name .. " " .. ed .. "\n")
			if(!ed) then return false end
			name = string.sub(name,0,ed-1)
			--print(name .. "\n")
			if(string.len(name) <= 0) then return false end
			
			local class = string.lower(name)
			local current = WEAPONS[class]
			if(current != nil) then
				WEAPON = {}
				WEAPON.ITEM = {}
				local b,e = pcall(include,file)
				if not (b) then
					print("^1Error loading entity file: " .. e .. "\n")
				end
				
				--ENT
				
				table.Update(WEAPONS[class], WEAPON)
			else
				WEAPON = {}
				WEAPON.ITEM = {}
				WEAPON._classname = string.lower(name)
				WEAPON._id = #WEAPON_CLASSES + 1
				WEAPON.register = true
				
				setmetatable(WEAPON,META)
				META.__index = META
			
				pcall(include,file)
				
				if(!WEAPON.Base) then
					WriteWeaponFunctions(WEAPON)
				end
				
				WEAPONS[WEAPON._classname] = WEAPON
				table.insert(_CUSTOM,{data=WEAPON,type="weapon"})
				if(WEAPON.register == true) then
					table.insert(WEAPON_CLASSES,WEAPON._classname)
					sortWeaponClasses()
				end
				InheritWeapons()
				if(WEAPON.register == true) then
					metaCall(WEAPON,"Init")
					metaCall(WEAPON,"RegisterItem",true)
				else
					metaCall(WEAPON,"RegisterItem",false)
				end
			end
			--print("Downloaded Entity '" .. file .. "'\n")
			
			return true
		end
	end
	hook.add("FileDownloaded","checkweapons",dlhook)
end

local PLAYER_INVENTORY = {}

local GetPredictedClient
local GetClient
local UpdatePlayerInventory

local CMD_AMMOCHANGE = 1
local CMD_CLEARAMMO = 2
local CMD_CLEARWEAPONS = 3
local CMD_GOTWEAPON = 4
local CMD_LOSTWEAPON = 5

local INV_PROTO_0 = MessagePrototype("_winv0"):Byte():E()
local INV_PROTO_1 = MessagePrototype("_winv1"):Byte():Byte():Short():E()

local AMMO_CLASSES = {}

for i=1, #WEAPON_CLASSES do
	local class = FindWeapon(WEAPON_CLASSES[i])
	if(class ~= nil and type(class.ammoClass) == "string") then
		if not table.HasValue( AMMO_CLASSES, class.ammoClass ) then
			table.insert(AMMO_CLASSES,class.ammoClass)
			print("Registered New Ammo Class: " .. class.ammoClass .. " | " .. #AMMO_CLASSES .. "\n")
			class.ammoClass = #AMMO_CLASSES
		else
			local l = table.ReverseLookup(AMMO_CLASSES,class.ammoClass)
			print("Using Ammo Class: " .. class.ammoClass .. " | " .. l .. "\n")
			class.ammoClass = l
		end
	end
end

if(SERVER) then
	

	GetPredictedClient = function(pl)
		return GetPlayerByIndex(pl:GetPredicted()) or pl
	end

	GetClient = function(n)
		return n--GetPlayerByIndex(n)
	end

	UpdatePlayerInventory = function(pl,cmd,w,n)
		--pl = GetPredictedClient(GetClient(pl))
		if(pl == nil) then print("^1No Predicted Client") return end
		
		if(cmd == CMD_AMMOCHANGE or cmd == CMD_GOTWEAPON or cmd == CMD_LOSTWEAPON) then
			INV_PROTO_1:Send(pl,cmd,w,n)
		else
			INV_PROTO_0:Send(pl,cmd)
		end
	end
end

function CheckPlayer(i)
	PLAYER_INVENTORY[i] = PLAYER_INVENTORY[i] or {}
	if(PLAYER_INVENTORY[i].ammo == nil) then
		PLAYER_INVENTORY[i].ammo = {}
		for x=1, 255 do
			PLAYER_INVENTORY[i].ammo[x] = 0
		end
	end
	PLAYER_INVENTORY[i].weapons = PLAYER_INVENTORY[i].weapons or {}
	PLAYER_INVENTORY[i].index = i
	if(SERVER) then
		--PLAYER_INVENTORY[i].ammo[3] = PLAYER_INVENTORY[i].ammo[3] or 15
	end
	return PLAYER_INVENTORY[i]
end

function GetWeaponByClass(class)
	local i = table.ReverseLookup(WEAPON_CLASSES,class)
	if(i == nil) then return nil end
	return i,FindWeapon(class)
end

function GetWeaponClass(weapon)
	local class = WEAPON_CLASSES[weapon]
	if(class ~= nil) then
		local wc = FindWeapon(class)
		return wc
	end
end

function GetAmmoIndexForWeapon(i_weapon)
	local class = GetWeaponClass(i_weapon)
	if(class == nil) then return 1 end
	return class.ammoClass
end

function WeaponMeta(weapon,func,...)
	local class = GetWeaponClass(weapon)
	if(class == nil) then return end
	return metaCall(class,func,unpack(arg))
end

function __HasWeapon(client,weapon)
	return CheckPlayer(client).weapons[weapon] == 1
end

function __GetAmmo(client,weapon)
	local inv = CheckPlayer(client)
	local ammoType = GetAmmoIndexForWeapon(weapon)
	return inv.ammo[ammoType] or 0
end

function __SetAmmo(client,weapon,ammo,nosend)
	if(ammo > 200) then ammo = 200 end
	if(SERVER and nosend == nil) then
		UpdatePlayerInventory(client,CMD_AMMOCHANGE,weapon,ammo)
	end
	local ammoType = GetAmmoIndexForWeapon(weapon)
	local inv = CheckPlayer(client)
	inv.ammo[ammoType] = ammo
end

function __ConsumeAmmo(client,weapon,n)
	if(SERVER) then
		local ammo = __GetAmmo(client,weapon)
		__SetAmmo(client,weapon,ammo-n)
	end
end

function __FindBestWeapon(client)
	for i=1, 255 do
		local ammo = __GetAmmo(client,256-i)
		if(ammo == -1 and __HasWeapon(client,256-i)) then return 256-i end
	end
	for i=1, 255 do
		local ammo = __GetAmmo(client,256-i)
		if(ammo > 0 and __HasWeapon(client,256-i)) then return 256-i end
	end
	return 0
end

function __WeaponEmpty(client,weapon)
	if(SERVER) then
		local best = __FindBestWeapon(client)
		print("Weapon Empty: " .. weapon .. ", switch to " .. best .. "\n")
		GetPlayerByIndex(client):SetWeapon(best)
	else
		print("Client can't do this\n")
	end
end

function __CanFire(client,weapon,weapontime,addtime,angles,ws)
	--ws = WEAPON_FIRING
	local class = GetWeaponClass(weapon)
	if(class ~= nil) then
		print(class.Firerate .. " - " .. class._classname .. "\n")
		addtime = class.Firerate
	end
	
	local n = weapontime + addtime
	local ammo = __GetAmmo(client,weapon)
	if(SERVER) then print("AMMO: " .. weapon .. " | " .. ammo .. "\n") end
	if(__HasWeapon(client,weapon) == false or ammo == 0) then __WeaponEmpty(client,weapon) return true,WEAPON_READY,n end
	if(ammo ~= -1) then __ConsumeAmmo(client,weapon,1) end
	
	return false,ws,n
end

if(SERVER) then

	function __WeaponFired(player,iweapon,muzzle,angles) 
		print("FIRE: " .. iweapon .. "\n")
		if not (WeaponMeta(iweapon,"Fire",player,muzzle,angles)) then
			__FireDefault(player,iweapon)
		end
	end
	
	function __RemoveAllWeapons(client)
		UpdatePlayerInventory(client,CMD_CLEARWEAPONS)
		local inv = CheckPlayer(client)
		for i=1,255 do
			inv.weapons[i] = 0
			inv.ammo[i] = 0
		end
	end
	
	function __RemoveCustomWeapon(client,weaponclass)
		local i_weapon = GetWeaponByClass(weaponclass)
		if(i_weapon == nil) then print("^1Attempted to give null weapon: " .. weaponclass .. "\n") end
		local inv = CheckPlayer(client)
		if(inv.weapons[i_weapon] == 1) then
			UpdatePlayerInventory(client,CMD_LOSTWEAPON,i_weapon)
			inv.weapons[i_weapon] = 0
		end
	end

	function __GiveCustomWeapon(player,weaponclass,quantity,dropped)
		local i_weapon,class = GetWeaponByClass(weaponclass)
		if(i_weapon == nil) then print("^1Attempted to give null weapon: " .. weaponclass .. "\n") end
		local client = player:EntIndex()
		local ammo = __GetAmmo(client,i_weapon)
		if(quantity > 0) then
			if not dropped then
				if(ammo < quantity) then ammo = quantity else ammo = ammo + 1 end
			else
				if(quantity > class.ITEM.Quantity) then
					quantity = class.ITEM.Quantity --Don't give us more ammo than default
				end
				ammo = ammo + quantity
			end
			__SetAmmo(client,i_weapon,ammo,true)
		else
			__SetAmmo(client,i_weapon,-1,true)
		end
		local inv = CheckPlayer(client)
		--if(inv.weapons[i_weapon] == 0) then
			UpdatePlayerInventory(client,CMD_GOTWEAPON,i_weapon,__GetAmmo(client,i_weapon))
			inv.weapons[i_weapon] = 1
		--end
		print("SET WEAPON: " .. i_weapon .. "\n")
		player:SetWeapon(i_weapon)
		WeaponMeta(i_weapon,"Pickup",player)
	end
	
	function __DropWeapon(player,iweapon)
		print("Player Drop Weapon\n")
		WeaponMeta(iweapon,"Drop",player)
	end

	hook.add("SVFiredWeapon","weapons",function(a,iweapon,b,muzzle,angles,player)
		__WeaponFired(player,iweapon,muzzle,angles)
	end)

	local spawned = {}
	function PlayerSpawned(pl)
		if(pl == nil) then print ("^3WHY NULL PLAYER?") return end
		local client = pl:EntIndex()
		spawned[client] = true
		pl:SetWeapon(0)
		__RemoveAllWeapons(client)
		--__GiveCustomWeapon(pl,"weapon_deagle",25)
		--pl:SetWeapon(2)
		for i=1, #WEAPON_CLASSES do
			__GiveCustomWeapon(pl,WEAPON_CLASSES[i],25)
		end
	end
	hook.add("PlayerSpawned","weapons",PlayerSpawned)
	
	--This checks to make sure that players get their stuff
	function PostSpawned(client)
		if(spawned[client]) then
			local inv = CheckPlayer(client)
			for k,v in pairs(inv.weapons) do
				if(v == 1) then
					UpdatePlayerInventory(client,CMD_GOTWEAPON,k,__GetAmmo(client,k))
				end
			end
		end
	end
	hook.add("ClientReady","weapons",PostSpawned)
	
	Timer(2,function()
		for k,v in pairs(GetAllEntities()) do
			if(string.find(v:Classname(),"weapon_") or string.find(v:Classname(),"ammo_")) then
				if not (FindCustomEntityClass(v:Classname())) then
					v:Remove()
				end
			end
		end
	end)
	
else
	
	local SELECTED = 0
	function client()
		return LocalPlayer():EntIndex()
	end

	function LocalInventory()
		return CheckPlayer(client())
	end
	
	function __WeaponChange(from,to)
		if(from == to) then return end
		WeaponMeta(from,"Holster")
		WeaponMeta(to,"Deploy")
	end	
	
	function WeaponsForSlot(i_slot)
		local weapons = {}
		for i=1, #WEAPON_CLASSES do
			if(__HasWeapon(client(),i)) then
				local class = GetWeaponClass(i)
				if(class ~= nil and class.slot == i_slot) then
					table.insert(weapons,{i_weapon = i,class = class})
				end
			end
		end
		return weapons
	end
	
	local currentSlot = 1
	local slotPos = 1
	local wasIncrement = false
	local _weaponslots = {}
	function __WeaponSlots()
		for i=1, 10 do _weaponslots[i] = WeaponsForSlot(i) end
		return _weaponslots
	end
	
	function __SetSelection(i) 
		__WeaponChange(SELECTED,i)
		SELECTED = i
		util.SetWeaponSelect(i)
		local class = GetWeaponClass(i)
		if(class ~= nil) then
			currentSlot = class.slot
			local slot = WeaponsForSlot(currentSlot)
			for x=1, #slot do
				if(slot.i_weapon == i) then
					slotPos = x
					return
				end
			end
		end
	end
	
	local iconRef = RefEntity()
	local refdef = {}
	local function Icon3d(model,x,y,w,h)
		render.CreateScene()
		
		iconRef:SetModel(model)
		iconRef:SetPos(Vector(0,0,0))
		iconRef:SetAngles(Vector(10,90,0))
		iconRef:Render()

		refdef.flags = 1
		refdef.x = x
		refdef.y = y
		refdef.width = h
		refdef.height = w
		refdef.origin = Vector(-24,0,0)
		refdef.angles = Vector(0,0,0)
		local b, e = pcall(render.RenderScene,refdef)
		if(!b) then
			print("^1" .. e .. "\n")
		end
	end
	
	local SLOT_SIZE = 40
	function drawSlot(id,slot,x,y,dt)
		dt = 1 - dt
		if(#slot > 0) then
			draw.SetColor(1,1,1,dt)
			local txt = "" .. id
			draw.Text((x - string.len(txt) * 5) + SLOT_SIZE/2,y + SLOT_SIZE,txt,10,10)
		end
		for i=#slot, 1, -1 do
			draw.SetColor(.5,.2,0,.5*dt)
			if(slot[i].i_weapon == SELECTED) then
				draw.SetColor(1,.5,0,1*dt)
			end
			draw.Rect(x,y,SLOT_SIZE,SLOT_SIZE)
			Icon3d(slot[i].class.gun,x,y,SLOT_SIZE*dt,SLOT_SIZE*dt)
			y = y - (SLOT_SIZE + 2)
		end
	end
	
	function __SelectWeapon(i)
		local slot = __WeaponSlots()[i]
		if(wasIncrement) then
			wasIncrement = false
			currentSlot = 0
		end
		if(#slot == 0) then return end
		if(i ~= currentSlot) then
			slotPos = 1
			currentSlot = i
		else
			slotPos = slotPos + 1
			if(slotPos > #slot) then slotPos = 1 end
		end
		__SetSelection(slot[slotPos].i_weapon)
		--[[
		if(__HasWeapon(client(),i) or i == 0) then
			__SetSelection(i)
		end
		]]
	end

	function __PrevWeapon(i) 
		if(currentSlot == 0) then currentSlot = 1 slotPos = 0 end
		local slots = __WeaponSlots()
		local slot = slots[currentSlot]
		slotPos = slotPos - 1
		if(slotPos <= 0) then 
			local t = (#slots - currentSlot) + 1
			for i=#slots, 1, -1 do
				local id = (i - t) % #slots
				if(id == 0) then id = #slots end
				if(#slots[id] > 0) then 
					currentSlot = id
					slot = slots[currentSlot]
					slotPos = #slot
					break
				end
			end
		end
		__SetSelection(slot[slotPos].i_weapon)
		wasIncrement = true
	end
	
	function __NextWeapon(i)
		if(currentSlot == 0) then currentSlot = 1 slotPos = 0 end
		local slots = __WeaponSlots()
		local slot = slots[currentSlot]
		slotPos = slotPos + 1
		if(slotPos > #slot) then 
			slotPos = 1
			for i=1, #slots do
				local id = (i + currentSlot) % #slots
				if(id == 0) then id = 10 end
				if(#slots[id] > 0) then 
					currentSlot = id
					slot = slots[currentSlot]
					break
				end
			end
		end
		__SetSelection(slot[slotPos].i_weapon)
		wasIncrement = true
	end
	
	function __DrawWeaponSelector(t)
		local dt = (LevelTime() - t) / 3500
		dt = (CLAMP(dt,.7,1) - .7) * (1/.3)
		if(dt < 1) then
			local class = GetWeaponClass(SELECTED)
			if(class == nil) then return end
			local text = class.printName
			draw.SetColor(1,1,1,1-dt)
			draw.Text(320 - string.len(text)*5,400,text,10,10)
			
			local slots = __WeaponSlots()
			local x = 320 - (SLOT_SIZE + 2)*5
			local y = 350
			for i=1, #slots do
				drawSlot(i,slots[i],x,y,dt)
				x = x + SLOT_SIZE + 2
			end
		else
			--currentSlot = 0
			--slotPos = 0
		end
	end
	
	function __OutOfAmmo()
		__SetSelection(__FindBestWeapon(client()))
	end
	
	function __AddPlayerWeapon(parent,entity,team,iweapon,renderfx)
		if(entity == LocalPlayer()) then
			if(__HasWeapon(entity:EntIndex(),iweapon) == false) then return end
		end
		WeaponMeta(iweapon,"AdjustHand",parent,entity,renderfx == RF_FIRST_PERSON)
		WeaponMeta(iweapon,"Draw",parent,entity,team,renderfx == RF_FIRST_PERSON)
	end
	
	function __WeaponFired(player,iweapon,angles)
		local muzzle = player:GetPos()
		if(player == LocalPlayer()) then
			if(__GetAmmo(player:EntIndex(),iweapon) == 0) then return end
		end
		WeaponMeta(iweapon,"Fire",player,muzzle,angles)
	end
	
	local defaultHand = LoadModel("models/weapons2/shotgun/shotgun_hand.md3")	
	function __GetHandModel(iweapon)
		local s,r = WeaponMeta(iweapon,"GetHandModel")
		if not (s) then
			return defaultHand
		end
		return r
	end
	
	local defaultAmmo = LoadModel("models/weapons2/grapple/grapple.md3")
	function __GetAmmoModel(iweapon)
		local class = GetWeaponClass(iweapon)
		if(class ~= nil) then
			return class.gun or defaultAmmo
		end
		return defaultAmmo
	end
	
	local defaultAmmoIcon = LoadShader("icons/iconw_grapple")
	function __GetAmmoIcon(iweapon)
		local s,r = WeaponMeta(iweapon,"GetAmmoIcon")
		if not (s) then
			return defaultAmmoIcon
		end	
		return r
	end
	
	function __AmmoWarning(prev) 
		return 0
	end
	
	function __RegisterWeapon(i)
		WeaponMeta(i,"Register")
	end
	
	function INV_PROTO_1:Recv(data)
		local cmd = data[1]
		local index = data[2]
		local value = data[3]
		
		if(cmd == CMD_AMMOCHANGE) then
			local inv = LocalInventory()
			__SetAmmo(inv.index,index,value)
		elseif(cmd == CMD_GOTWEAPON) then
			local inv = LocalInventory()
			inv.weapons[index] = 1
			__SetAmmo(inv.index,index,value)
			print("Got Weapon: " .. index .. "\n")
			__SetSelection(index)
		elseif(cmd == CMD_LOSTWEAPON) then
			local inv = LocalInventory()
			inv.weapons[index] = 0
			__SetSelection(__FindBestWeapon(client()))
		end
	end
	
	function INV_PROTO_0:Recv(data)
		local cmd = data[1]
		if(cmd == CMD_CLEARWEAPONS) then
			local inv = LocalInventory()
			for i=1,255 do
				inv.weapons[i] = 0
				inv.ammo[i] = 0
			end
			print("Clearing Weapons\n")
		elseif(cmd == CMD_CLEARAMMO) then
			local inv = LocalInventory()
			for i=1,255 do
				inv.ammo[i] = 0
			end
		end
	end
	

	for i=1, #WEAPON_CLASSES do
		__RegisterWeapon(i)
	end
	--__RegisterWeapon(2)
end