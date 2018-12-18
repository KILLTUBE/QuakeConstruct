UI_Components = {}
UI_Components_UnParent = {}
UI_Active = {}
local kcache = {}
local toRegister = 0
local nxtID = 0
local nextIDX = 0
local white = LoadShader("white")
local enablekey = false
local mouseIsDown = false

P:include("cursor.lua")
P:include("painting/cl_skins.lua")
P:include("painting/cl_skinutil.lua")
P:include("painting/cl_softwaremask.lua")

local function dc(x,y)
	draw.SetColor(1,1,1,1)
	draw.Rect(x-1,y-1,2,2)
end
hook.add("DrawCursor","UI2",dc)

local letters = string.alphabet

function UI_ERROR(txt,cmp)
	local err = "^1UI ERROR: " .. txt
	if(cmp != nil) then
		err =  err .. "(" .. cmp._myname .. ")"
	end
	print(err .. "\n")
end

function parentComponents()
	local finished = false
	local nl = true
	local maxiter = 100
	local i = 0
	local lc = 0
	while(nl == true and i < maxiter) do
		nl = false
		for k,v in pairs(UI_Components) do
			if(!v.__loaded) then
				local base = v._mybase
				local name = v._myname
				--if(base == nil) then base = "panel" end
				if(type(base) == "string" and UI_Components[base] and base != name) then
					if(UI_Components[base].__loaded == true) then
						v = table.Inherit( v, UI_Components[base] )
						debugprint("Parented: " .. name .. " -> " .. base .. "\n")
						lc = lc + 1
						v.__loaded = true
					else
						nl = true
					end
				else
					lc = lc + 1
					v.__loaded = true
				end
			end
		end
		i = i + 1
	end
	debugprint("Loaded " .. lc .. " components with " .. i .. " iterations.\n")
end

function registerComponent(tab,name,base)
	if(UI_Components[name] == nil) then
		UI_Components[name] = tab
		UI_Components_UnParent[name] = table.Copy(tab)
		tab._mybase = base
		tab._myname = name
	end
	debugprint("Registered " .. name .. "\n")
end

local currentInit = nil

function UI_EnableCursor(b)
	local hold = false
	for k,v in pairs(UI_Active) do
		if(v.catchm and v.removeme == false and v:IsVisible() and v.alpha == 1) then hold = true end
	end
	if(b != true and hold) then return end
	EnableCursor(b)
end

function UI_EnableKeyboard(b)
	local hold = false
	for k,v in pairs(UI_Active) do
		if(v.catchk and v.removeme == false and v:IsVisible()) then hold = true end
	end
	if(b != true and hold) then return end
	enablekey = b
end

local function getNewId()
	local incr = 0
	for i=0, (#letters*2) + 10 do
		local f = false
		for k,v in pairs(UI_Active) do
			if(string.len(v.ID) == 1) then
				if(v.rlID == incr) then 
					f = true
					break 
				end
			end
		end
		if(f == false) then
			return incr
		else
			incr = incr + 1
		end
	end
end

local function correctId(id)
	if(id >= 10) then
		local i = id - 9
		if(i > #letters) then
			i = i - #letters
			if(i > #letters) then
				i=1
				id = 0
			end			
			return string.upper(letters[i])
		else
			return letters[i]
		end
	end
	return id
end

local function doPanel(o,parent,force)
	local id = getNewId()
	o.rlID = id
	o.ID = tostring(correctId(id))
	o.IDX = nextIDX
	nextIDX = nextIDX + 1
	
	o.isPanel = true
	
	if(parent != nil) then
		local rparent = parent
		if(parent:GetContentPane() != nil and !force) then
			parent = parent:GetContentPane()
		end
		o.parent = parent
		o.ID = parent.ID .. correctId(o.parent.cc)
		o.parent.cc = o.parent.cc + 1
		rparent:OnChildAdded(o)
	end
	
	local level = string.len(o.ID)
	if(level == 1) then
		nxtID = nxtID + 1
	end
	
	currentInit = name
	o:Initialize()
	currentInit = nil
	o.rmvx = 0
	--print("Create ID: " .. o.ID .. " -> " .. level .. "\n")
end

function PaintSort()
	table.sort(UI_Active,function(a,b) return a.ID < b.ID end)
end

function UI_Create(name,parent,force)
	if(type(name) == "table" and name.isPanel) then
		local n = table.Copy(name)
		
		doPanel(n,parent,force)
		
		table.insert(UI_Active,n)
		
		n:DoLayout()
		
		PaintSort()
		
		return n
	end
	if(currentInit == name) then
		UI_ERROR("A " .. name .. " attempted to create itself in it's 'Initialize' function.")
		return nil
	end
	local tab = UI_Components[name]
	if(tab != nil) then
		local o = {}

		setmetatable(o,tab)
		tab.__index = tab
		
		o.type = name
		doPanel(o,parent,force)
		
		table.insert(UI_Active,o)
		
		o:DoLayout()
		
		PaintSort()
		
		return o
	end
end

local function loadComponents()
	local list = findFileByType("lua","./lua/packs/advancedUI/components")
	toRegister = #list
	for k,v in pairs(list) do
		include(v)
	end
	parentComponents()
end
loadComponents()

local function panelCollide(p,x,y)
	local px,py,pw,ph = p:GetMaskedRect()
	if(x > px and x < px + pw and y > py and y < py + ph) then
		return true
	else
		return false
	end
end

local function mDown()
	mouseIsDown = true
	local mx = GetMouseX()
	local my = GetMouseY()
	for i=0, #UI_Active-1 do
		local v = UI_Active[#UI_Active - i]
		if(v:IsVisible() and panelCollide(v,mx,my) and v.__wasPressed != true) then
			v:MousePressed(mx,my)
			v.__wasPressed = true
			return
		end
	end
end
hook.add("MouseDown","uimouse",mDown)

local function mUp()
	mouseIsDown = false
	local mx = GetMouseX()
	local my = GetMouseY()
	local other = nil
	for k,v in pairs(UI_Active) do
		if(v:IsVisible()) then
			if(panelCollide(v,mx,my)) then
				if(v.__wasPressed == true) then
					v:MouseReleased(mx,my)
					v.__wasPressed = false
					other = v
				end
			end
		end
	end
	for k,v in pairs(UI_Active) do
		if(v:IsVisible() and v != other) then
			if(!panelCollide(v,mx,my)) then
				v:MouseReleasedOutside(mx,my,other)
				v.__mouseInside = false
				v.__wasPressed = false
			end
		end
	end
end
hook.add("MouseUp","uimouse",mUp)

local function checkMouse()
	local mx = GetMouseX()
	local my = GetMouseY()
	--table.sort(UI_Active,function(a,b) return a.ID > b.ID end)
	for i=0, #UI_Active-1 do
		local v = UI_Active[#UI_Active - i]
		v.__mouseInside = false
	end
	for i=0, #UI_Active-1 do
		local v = UI_Active[#UI_Active - i]
		if(v:IsVisible() and panelCollide(v,mx,my)) then
			if(!mouseIsDown) then
				v.__mouseInside = true
			end
			return
		end
	end
	--PaintSort()
end

local function garbageCollect()
	local rm = 0
	if(#UI_Active > 0) then
		table.sort(UI_Active,function(a,b) return a.rmvx > b.rmvx end)
		if(UI_Active[1] == nil) then
			UI_Active = {}
			UI_ERROR("Invalid UI index, cleared table.\n")
		end
		
		while(UI_Active[1] != nil and UI_Active[1].rmvx == 1) do
			table.remove(UI_Active,1)
			rm = rm + 1
		end
		PaintSort()
	end
	UI_EnableCursor(false)
	UI_EnableKeyboard(false)
	debugprint("^2Garbage Collected -> " .. rm .. "\n")
end
concommand.Add("ui_fcollect",garbageCollect)

local function softRemove(v)
	v.removeme = true
	v.rmvx = 1
	if(v.name != nil) then print("Soft Removed: " .. v.name .. "\n") end
end

local function checkRemove(v)
	local batch = {}
	if(v.removeme) then
		for i=0, #UI_Active-1 do
			local other = UI_Active[#UI_Active - i]
			if(other != nil) then
				if(other != v) then
					if(other:GetParent() == v and other.removeme != true) then
						if(other.name != nil) then print("Removed: " .. other.name .. "\n") end
						table.insert(batch,other)
						didrmv = true
					end
				end
			else
				--Oh Shit
				--Remove the empty table index and start over
				debugprint("^1Oh Shit What Happen[" .. i .. "]!\n")
				table.remove(UI_Active,#UI_Active - i)
				checkRemove(v)
				return
			end
		end
	end
	if(#batch > 0) then
		for	i=1, #batch do
			softRemove(batch[i])
			checkRemove(batch[i])
		end
	end
	batch = nil
end

function UI_RemovePanel(v)
	v.removeme = true
	v.rmvx = 1
	if(v.name != nil) then print("Removed: " .. v.name .. "\n") end
	checkRemove(v)
	garbageCollect()
end

local drawtime = 0
local thinktime = 0
local mcount = 0
local collect = false
local layoutvalidate = {}
local tickdelay = ticks()
local thinks = 0

local function drawx()
	checkMouse()
	
	mcount = 0
	thinks = 0
	
	RECT_DRAW = 0
	TOUGH_DRAW = 0
	TEXT_DRAW = 0
	
	local count = #UI_Active
	
	if(count > 0) then
		t1 = ticks()
		
		for i=0, count-1 do
			local v = UI_Active[count - i]
			if(v != nil and v:IsVisible() and v:ShouldDraw()) then
				thinks = thinks + 1
				--[[if(v.parent and v.parent.valid != true) then
					v:DoLayout()
					v:InvalidateLayout()
					if(!table.HasValue(layoutvalidate,v.parent)) then
						table.insert(layoutvalidate,v.parent)
					end
				end]]
				if(v:GetDelegate() != nil and v:GetDelegate():IsVisible() == false) then
					v:SetVisible(v:GetDelegate():IsVisible())
				end
				v:Think()
			end
			if(v != nil and v:IsVisible()) then
				pcall(v.ThinkInternal,v)
			end
			--if(v and v.rmvx == 1) then collect = true end
		end
		
		t1 = (ticks()) - t1
		t2 = ticks()
		
		for i=0, count-1 do
			local v = UI_Active[i+1]
			if(v:IsVisible() and v:ShouldDraw()) then
				v:DoLayout()
				SkinPanel(v)
				if(v.type == "frame") then
					v:DrawShadow()
				end
				
				local m = v:MaskMe()
				v:Draw()
				if(m) then
					SkinCall("EndMask")
					mcount = mcount + 1
				end
			end
		end
		
		if(QLUA_DEBUG) then 
			softmask.Draw()
		else
			softmask.Clear()
		end
		
		t2 = (ticks()) - t2
		
		if(ticks() > tickdelay + 500000) then
			thinktime = t1 / 1000
			drawtime = t2 / 1000
			tickdelay = ticks()
		end
	end
	
	--[[if(#layoutvalidate > 0) then
		for k,v in pairs(layoutvalidate) do
			v.valid = true
			--v:Think()
		end
		layoutvalidate = {}
	end]]
	
	if(collect) then
		garbageCollect()
		collect = false
	end
end

function DrawUI()
	drawx()
end

local function profd()
	local dtime = ProfileFunction(drawx)
	if(QLUA_DEBUG) then 
		draw.SetColor(1,1,1,1)
		draw.Text(0,100,"TotalTime: " .. dtime,12,12)
		draw.Text(0,112,"Rects: " .. RECT_DRAW .. " - " .. TOUGH_DRAW .. " - " .. TEXT_DRAW,12,12)
		draw.Text(0,124,"DrawTime: " .. drawtime,12,12)
		draw.Text(0,136,"ThinkTime: " .. thinktime,12,12)
		draw.Text(0,148,"MaskCount: " .. mcount,12,12)
		draw.Text(0,160,"Thinks: " .. thinks,12,12)
	end
	--drawx()
end
hook.add("Draw2D","uidraw",profd)

local kmin = 999999
local kmax = 0

local function keyed(key,state)
	if(key > kmax) then kmax = key end
	if(key < kmin) then kmin = key end
	if(enablekey) then
		for i=0, #UI_Active-1 do
			local v = UI_Active[#UI_Active - i]
			if(v:IsVisible()) then
				if(state == true and kcache[key] != true) then
					v:KeyPressed(key)
				end
				if(state == true) then
					v:KeyTyped(key)
				end
			end
		end
		kcache[key] = state
		return true
	end
	kcache[key] = state
end
hook.add("KeyEvent","uikeys",keyed)