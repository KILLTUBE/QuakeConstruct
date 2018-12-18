configurator = {}

local tabmaxw = 0
local ptemp = {}
local main = nil
local tabBar = nil
local currTab = "Server"
local layout = nil

local sliderTemplate = UI_Create("valuebar")
sliderTemplate:SetTextSize(8,8)
sliderTemplate:SetSize(16,16)
sliderTemplate:Remove()

local textTemplate = UI_Create("textarea")
textTemplate:SetSize(16,16)
textTemplate:Remove()

local button = UI_Create("button")
button:SetSize(16,16)
button:Remove()

local seperatorTemplate = UI_Create("label")
seperatorTemplate:SetSize(22,22)
seperatorTemplate:Remove()

local SL_TYPE = 1
local SL_LABEL = 2
local SL_VAR = 3
local SL_MIN = 4
local SL_MAX = 5
local SL_DEF = 6
local SL_FMT = 7
local SL_STEP = 8
local SL_COMP = 9
local SL_CURRENT = 10

local IR_DEF = 2
local IR_CURRENT = 3
local IR_VAR = 4
local IR_INDEX = 5

local function sliderMoved(tab,v)
	print("Value For: " .. tab[SL_VAR] .. " [" .. v .. "]\n")
	SendString("cnfvar " .. tab[SL_VAR] .. " " .. v .. "")
	tab[SL_CURRENT] = v
end

local sliders = {
	["Presets"] = {
		{"presetmanager"}
	},
	["Pickups"] = {
		{"group","Quantities:"},
		{"slider","Pickup Multiplier","pk_multiplier",0,10,1,"lowerfloat",nil},
		{"slider","Ammo Multiplier","pk_mult_ammo",0,10,1,"lowerfloat",nil},
		{"slider","Armor Multiplier","pk_mult_armor",0,10,1,"lowerfloat",nil},
		{"slider","Health Multiplier","pk_mult_health",0,10,1,"lowerfloat",nil},
		{"slider","Powerup Multiplier","pk_mult_powerup",0,10,1,"lowerfloat",nil},
		{"slider","Weapon Multiplier","pk_mult_weapon",0,10,1,"lowerfloat",nil},
		{"group","Respawn Times:"},
		{"slider","Pickup Respawn","pk_wait",0,10,1,"lowerfloat",nil},
		{"slider","Ammo Respawn","pk_wait_ammo",0,10,1,"lowerfloat",nil},
		{"slider","Armor Respawn","pk_wait_armor",0,10,1,"lowerfloat",nil},
		{"slider","Health Respawn","pk_wait_health",0,10,1,"lowerfloat",nil},
		{"slider","Powerup Respawn","pk_wait_powerup",0,10,1,"lowerfloat",nil},
		{"slider","Weapon Respawn","pk_wait_weapon",0,10,1,"lowerfloat",nil},
		{"group","Replace:"}
	},
	["Hazards"] = {
		{"group","Damage%:"},
		{"slider","Water","hz_damage_water",0,1000,100,"int",10},
		{"slider","Slime","hz_damage_slime",0,1000,100,"int",10},
		{"slider","Lava","hz_damage_lava",0,1000,100,"int",10},
		{"slider","Crushers","hz_damage_crush",0,1000,100,"int",10},
		{"slider","Falling","hz_damage_falling",0,1000,100,"int",10},
	},
	["Weapons"] = {
		{"group","Global:"},
		{"slider","Delay%","wp_delay",0,1000,100,"int",10},
		{"slider","Damage%","wp_damage",0,1000,100,"int",10},
		{"slider","Quad Factor","-g_quadfactor",1,10,3,"int",1},
		{"group","Specific:"},
	},
	["Server"] = {
		{"group","Map:"},
		{"slider","Frag Limit","-fraglimit",0,500,20,"int",5},
		{"slider","Time Limit","-timelimit",0,120,0,"int",5},
		{"slider","Gravity","-g_gravity",0,1500,800,"int",50},
		{"group","Player:"},
		{"slider","Force Respawn","-g_forcerespawn",0,100,20,"int",1},
		{"slider","Speed","-g_speed",0,1000,320,"int",20},
		{"slider","Starting Health","g_starthp",1,1000,125,"int",5},
		{"slider","Maximum Health","g_maxhp",0,1000,100,"int",5},
		{"slider","Regen Rate","g_regen_rate",0,10,1,"float",nil},
		{"slider","Regen Amount","g_regen_amt",0,10,0,"int",1},
	},
}

local nxt = WP_GAUNTLET
local function weapVars(name)
	table.insert(sliders["Weapons"],{"slider",name .. " Delay%","wp_cw" .. nxt .. "_delay",0,1000,100,"int",10})
	table.insert(sliders["Weapons"],{"slider",name .. " Damage%","wp_cw" .. nxt .. "_damage",0,1000,100,"int",10})
	nxt = nxt + 1
end

local NUM_ITEMS = util.GetNumItems() - 31
local ITEM_INFOS = {}
local b,e = pcall(function()
	for i=1, NUM_ITEMS do
		ITEM_INFOS[i] = util.ItemInfo(i)
		local n = #sliders["Pickups"]
		table.insert(sliders["Pickups"],{"itemreplace",i,i,"replace"..i,n+1})
	end
end)
if not (b) then print("^1ERROR: " .. e .. "\n") end

local function outline(x,y,w,h,i)
	SkinCall("DrawBGRect",x,y,w,i,nil)
	--SkinCall("DrawBGRect",x+(w-i),y,i,h,nil)
	--SkinCall("DrawBGRect",x,y+(h-i),w,i,nil)
	SkinCall("DrawBGRect",x,y,i,h,nil)
end

local tool_template = UI_Create("button")
tool_template:SetSize(32,32)
tool_template.DrawBackground = function(self)
	self.data = sliders["Pickups"][self.data[IR_INDEX]]
	SkinCall("DrawButtonBackground",self:MouseOver(),self:MouseDown())
	draw.SetColor(1,1,1,1)
	SkinCall("DrawBGRect",self:GetX(),self:GetY(),32,32,ITEM_INFOS[self.data[2]].icon)
	SkinCall("DrawBGRect",self:GetX()+32,self:GetY(),32,32,ITEM_INFOS[self.data[3]].icon)
	draw.SetColor(1,.75,.5,1)
	outline(self:GetX()+32,self:GetY(),32,32,2)
	SkinCall("Text",self:GetX() + 64,self:GetY() + 11,ITEM_INFOS[self.data[3]].classname,10,10)
	--classname
	--[[for i=1, NUM_ITEMS do
		draw.SetColor(.5,.5,.5,1)
		if(i == self.data[3]) then draw.SetColor(1,1,1,1) end
		local x,y,w,h = self:GetX()+64 + ((i-1)*12),self:GetY()+22,12,12
		SkinCall("DrawBGRect",x,y,w,h,ITEM_INFOS[i].icon)
	end]]
end
tool_template.MousePressed = function(self) self.drag = true end
tool_template.MouseReleased = function(self) 
	self.drag = false 
	SendString("cnfvar replace" .. self.data[2] .. " " .. self.data[3] .. "")
end
tool_template.MouseReleasedOutside = function(self,x,y,other)
	if(self.drag) then
		self:MouseReleased()
	end
end

tool_template.Think = function(self)
	self.BaseClass:Think()
	if(self.drag) then
		local mx = GetXMouse()
		local x = self:GetX() + 64
		local w = self:GetWidth() - 64
		
		local v = ((mx - x) / w) * NUM_ITEMS
		v = math.ceil(v)
		if(v > NUM_ITEMS) then v = NUM_ITEMS end
		if(v < 1) then v = 1 end
		self.data[3] = v
		sliders["Pickups"][self.data[IR_INDEX]][3] = v
	end
end

tool_template:Remove()


local function itemReplacePanel(panel,v)
	local tool = panel:AddPanel(tool_template,true)
	tool.data = v
	SendString("gcnfvar " .. v[IR_VAR])
end


weapVars("Gauntlet")
weapVars("MachineGun")
weapVars("Shotgun")
weapVars("GrenadeLauncher")
weapVars("RocketLauncher")
weapVars("LightningGun")
weapVars("Railgun")
weapVars("PlasmaGun")
weapVars("BFG10K")

local function message(str,pl)
	local args = string.Explode(" ",str)
	if(args[1] == "rcnfvar") then
		local var = args[2]
		local val = tonumber(args[3])
		if(val == nil) then return end
		
		print("Got Value " .. var .. " = " .. val .. "\n")
		
		for k,v in pairs(sliders) do
			for _,sl in pairs(v) do
				if(sl[SL_TYPE] == "slider" and sl[SL_VAR] == var) then
					local panel = sl[SL_COMP]
					if(panel != nil) then
						local fnc = panel.OnValue
						panel:SetValue(val,true)
						sl[SL_CURRENT]  = val
						print("Set Value " .. var .. " = " .. val .. "\n")
					else
						sl[SL_CURRENT]  = val
					end
				elseif(sl[SL_TYPE] == "itemreplace" and sl[IR_VAR] == var) then
					sl[IR_CURRENT] = val
				end
			end
		end
	end
end
hook.add("MessageReceived","configurator",message)

local function slider(list,tab)
	--[[panel.DoLayout = function()
		panel:SetSize(par:GetWidth(),18)
	end]]
	
	local panel = list:AddPanel(sliderTemplate,true)
	
	local step = tab[SL_STEP]
	
	panel:SetTitle(tab[SL_LABEL])
	panel:SetMax(tab[SL_MAX])
	panel:SetMin(tab[SL_MIN])
	panel.FormatValue = function(self,v)
		if(step) then
			v = v / step
			v = math.floor(v)*step
		end
		if(tab[SL_FMT] == "int") then
			return math.floor(v)
		elseif(tab[SL_FMT] == "lowerfloat") then
			if(v > 1) then return math.floor(v) end
			v = v * 10
			v = math.floor(v)/10
			return v
		elseif(tab[SL_FMT] == "float") then
			v = v * 10
			v = math.floor(v)/10
			return v
		end
	end
	
	panel:SetValue(tab[SL_DEF],true)
	panel.OnValue = function(s,v)
		sliderMoved(tab,v)
	end
	panel:CatchMouse(true)
	
	list:DoLayout()
	
	SendString("gcnfvar " .. tab[SL_VAR])
	tab[SL_COMP] = panel
	
	return panel
end

local d = 0
for k,v in pairs(sliders) do
	for _,sl in pairs(v) do
		if(sl[SL_TYPE] == "slider") then
			Timer(d,function()
			SendString("gcnfvar " .. sl[SL_VAR])
			end)
			d = d + .05
		end
	end
end

local function seperator(list,label)
	local panel = list:AddPanel(seperatorTemplate,true)
	
	panel:SetText(label)
	
	list:DoLayout()
end

local function addPanel(class)
	local panel = UI_Create(class or "panel",main)
	--panel:CatchMouse(true)
	--panel:SetVisible(true)
	table.insert(ptemp,panel)
	return panel
end

local loadPresets = nil
local presetSaveDialog = nil
local function sliderForVar(var)
	for k,v in pairs(sliders) do
		for _,sl in pairs(v) do
			if(sl[SL_TYPE] == "slider") then
				if(sl[SL_VAR] == var) then return sl end
			end
		end
	end
	return nil
end

local function replacerForVar(var)
	for k,v in pairs(sliders) do
		for _,sl in pairs(v) do
			if(sl[SL_TYPE] == "itemreplace") then
				if(("replace" .. sl[IR_DEF]) == var) then return sl end
			end
		end
	end
	return nil
end

local function loadDefaults()
	local d = 0
	for k,v in pairs(sliders) do
		for _,sl in pairs(v) do
			if(sl[SL_TYPE] == "slider") then
				if(sl[SL_CURRENT] ~= nil and sl[SL_CURRENT] ~= sl[SL_DEF]) then
					Timer(d,function()
						SendString("cnfvar " .. sl[SL_VAR] .. " " .. sl[SL_DEF] .. "")
					end)
					sl[SL_CURRENT] = sl[SL_DEF]
					d = d + .1
				end
			end
			if(sl[SL_TYPE] == "itemreplace") then
				if(sl[IR_CURRENT] ~= nil and sl[IR_CURRENT] ~= sl[IR_DEF]) then
					Timer(d,function()
						SendString("cnfvar replace" .. sl[IR_DEF] .. " " .. sl[IR_DEF] .. "")
					end)
					sl[IR_DEF] = sl[IR_DEF]
					d = d + .1
				end
			end
		end
	end
end

local function loadPreset(name,preset)
	local d = 0
	for k,v in pairs(preset.values) do
		local sl = sliderForVar(k)
		if(sl ~= nil) then
			local value = sl[SL_CURRENT] or sl[SL_DEF]
			if(v ~= value) then
				sl[SL_CURRENT] = v
				Timer(d,function()
					SendString("cnfvar " .. k .. " " .. v .. "")
				end)
				d = d + .1
			end
		else
			local ir = replacerForVar(k)
			if(ir ~= nil) then
				local value = ir[IR_CURRENT] or ir[IR_DEF]
				if(v ~= value) then
					ir[IR_CURRENT] = v
					Timer(d,function()
						SendString("cnfvar " .. k .. " " .. v .. "")
					end)
					d = d + .1
				end
			end
		end
	end
	--SendString("cnfvar replace" .. self.data[2] .. " " .. self.data[3] .. "")
	print("Loaded Preset: " .. name .. "\n")
end

local function savePreset(name)
	local presets = persist.Load("configpresets").presets or {}
	presets[name] = {}
	presets[name].values = {}
	
	for k,v in pairs(sliders) do
		for _,sl in pairs(v) do
			if(sl[SL_TYPE] == "slider") then
				local v = sl[SL_CURRENT] or sl[SL_DEF]
				if(v ~= sl[SL_DEF]) then
					presets[name].values[sl[SL_VAR]] = v
				end
			elseif(sl[SL_TYPE] == "itemreplace") then
				local v = sl[IR_CURRENT] or sl[IR_DEF]
				if(v ~= sl[IR_DEF]) then
					presets[name].values["replace" .. sl[IR_DEF]] = v
				end
			end
		end
	end
	
	persist.Start("configpresets")
	persist.Write("presets",presets)
	print("Saved Preset: '" .. name .. "'\n")
	persist.Close()
end

local function deletePreset(name,list)
	local presets = persist.Load("configpresets").presets or {}
	presets[name] = nil
	
	persist.Start("configpresets")
	persist.Write("presets",presets)
	print("Delete Preset: '" .. name .. "'\n")
	persist.Close()
	loadPresets(list)
end

--Close()
--Write()
--Start()
loadPresets = function(list)
	list:Clear()
	
	button:SetSize(16,30)
	local btn = list:AddPanel(button,true)
	btn:SetText("Save Preset")
	btn.DoClick = function() presetSaveDialog(list) end
	
	local presets = persist.Load("configpresets").presets or {}
	local t_panel = UI_Create("button")
	t_panel:SetSize(16,20)
	t_panel:Remove()
	
	button:SetSize(16,30)
	local btn = list:AddPanel(button,true)
	btn:SetText("Load Defaults")
	btn.DoClick = function(self) loadDefaults() end
	
	for k,v in pairs(presets) do
		local panel = list:AddPanel(t_panel,true)
		--[[local label = UI_Create("button",panel)
		label.DoLayout = function(self)
			self:SetSize(panel:GetWidth()-80,panel:GetHeight()) end
		label:SetText(k)]]
		
		panel:SetText(k)
		panel:TextAlignLeft()
		panel.DoClick = function(self) loadPreset(k,v) end
		
		local btn0 = UI_Create("button",panel)
		btn0.DoLayout = function(self)
			self:SetSize(80,panel:GetHeight()) 
			self:SetPos(panel:GetWidth()-80,0) 
		end
		btn0.DoClick = function(self) deletePreset(k,list) end
		btn0:SetText("^1Delete")
	end
	
	list:DoLayout()
end

presetSaveDialog = function(plist)
	local frame = UI_Create("frame")
	local w,h = 640,480
	local pw,ph = w/3,h/5
	frame:SetPos((w/2) - pw/2,(h/2) - ph/2)
	frame:SetSize(pw,ph)
	frame:SetTitle("Save Preset")
	frame:CatchMouse(true)
	frame:RemoveOnClose(true)

	local list = UI_Create("listpane",frame)
	local panel = list:AddPanel(textTemplate,true)
	
	panel:SetText("unnamed")
	panel:CatchKeyboard(true)
	panel:SetTextSize(14,16)
	panel:SetExpandable(false)
	panel:SetMultiline(false)
	panel:SetDrawBorder(true)
	panel:SetSize(16,17)
	panel:SetCaret(9999,1)
	
	local btn = list:AddPanel(button,true)
	btn:SetText("Ok")
	btn.DoClick = function() 
		savePreset(panel:GetText())
		frame:Close()
		loadPresets(plist)
	end
	
	list:DoLayout()
end


local function presets(list,tab)
	loadPresets(list)
end

local function populate(panel)
	--local list = UI_Create("listpane",panel)
	--list:CatchMouse(true)
	--list:DoLayout()
	local group = sliders[currTab]
	
	if(group != nil) then
		for k,v in pairs(group) do
			if(v[1] == "slider") then slider(panel,v) end
			if(v[1] == "group") then seperator(panel,v[SL_LABEL]) end
			if(v[1] == "presetmanager") then presets(panel,v) end
			if(v[1] == "itemreplace") then itemReplacePanel(panel,v) end
		end
	end
end

local function addTab(name)
	local tab = UI_Create("button",tabBar)
	tab.DoClick = function()
		currTab = name
		layout(main)
	end
	tab:SetPos(tabmaxw,0)
	tab:SetText(name)
	tab:ScaleToContents()
	tab:SetSize(tab:GetWidth(),32)
	tabmaxw = tabmaxw + tab:GetWidth()
end

layout = function(panel)
	for k,v in pairs(ptemp) do
		v:Remove()
	end
	ptemp = {}
	tabmaxw = 0
	
	main = panel
	tabBar = addPanel()
	tabBar:SetPos(0,0)
	tabBar.DoLayout = function(self)
		self:SetSize(main:GetWidth(),32)
	end
	for k,v in pairs(sliders) do
		addTab(k)
	end
	
	local contents = addPanel()--addPanel()
	contents:SetPos(0,32)
	contents.DoLayout = function(self)
		self:SetSize(main:GetWidth()-4,main:GetHeight() - 62)
	end
	contents:DoLayout()
	
	local list = UI_Create("listpane",contents)
	--list:CatchMouse(true)
	--list:SetVisible(true)
	
	populate(list)
end

configurator_panel = nil
function configurator.open()
	if(configurator_panel == nil) then
		configurator_panel = UI_Create("frame")
		local panel = configurator_panel
		if(panel != nil) then
			local w,h = 640,480
			local pw,ph = w/1.2,h/2
			panel:SetPos((w/2) - pw/2,(h/2) - ph/2)
			panel:SetSize(pw,ph)
			panel:SetTitle("Configurator")
			panel:CatchMouse(true)
			panel:RemoveOnClose(false)
			layout(panel)
		end
	else
		configurator_panel:SetVisible(true)
	end
end
if(addToAltMenu) then
	addToAltMenu("Configurator",configurator.open)
end
concommand.add("openconfig",configurator.open)

--configurator.open()
print("BLAH\n")