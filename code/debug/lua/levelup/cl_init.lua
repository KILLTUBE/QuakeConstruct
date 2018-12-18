print("OPENED CLINIT\n")
local mfuncs = {}
LVcurrentMoney = 0
LVcurrentXP = 0
LVtargetXP = 0
LVlevel = 0
LVweapons = {}
local levelUp = 0

mfuncs[LVMSG_XP_ADDED] = function()
	local xp = message.ReadShort()
	local money = message.ReadShort()
	local source = message.ReadVector()
	--print("CL_XP_ADDED: " .. xp .. " : " .. tostring(source) .. "\n")
	FX_XPText(xp - LVcurrentXP,source)
	LVcurrentXP = xp
	LVcurrentMoney = money
end

mfuncs[LVMSG_LEVELUP] = function()
	local tXP = message.ReadShort()
	local lvl = message.ReadShort()
	print("CL_LEVELUP: " .. lvl .. " : " .. tXP .. "\n")
	LVtargetXP = tXP
	LVlevel = lvl
	levelUp = LevelTime()
end

mfuncs[LVMSG_GAMESTATE] = function()
	local xp = message.ReadShort()
	local tXP = message.ReadShort()
	local lvl = message.ReadShort()
	local money = message.ReadShort()
	local weaps = message.ReadString()
	LVweapons = LVDecodeWeapons(weaps)
	print("CL_GAMESTATE: " .. xp .. " : " .. tXP .. " : " .. lvl .. "\n")
	LVcurrentXP = xp
	LVtargetXP = tXP
	LVlevel = lvl
	LVcurrentMoney = money
end

function requestGameState()
	print("CL_RequestingGameState\n")
	SendString("lvl_gamestate")
end

local function HandleMessage(msgid)
	if(msgid == "levt") then
		local t = message.ReadShort()
		local b,e = pcall(mfuncs[t])
		if(!b) then
			print("^1LVERROR: " .. tostring(e) .. "\n")
		end
	end
end
hook.add("HandleMessage","levelup",HandleMessage)

local function d2d()
	draw.SetColor(1,1,1,1)
	local wp = ""
	for i=WP_GAUNTLET, WP_BFG do
		wp = wp .. (LVweapons[i] or "0")
		wp = wp .. "|"
	end
	draw.Text(10,280,"WEAPONS: |" .. wp,15,20)
	draw.Text(10,300,"LEVEL-" .. LVlevel,15,20)
	draw.Text(10,320,"XP: " .. LVcurrentXP .. "/" .. LVtargetXP .. " | $" .. LVcurrentMoney,15,20)
	local lt = (LevelTime() - levelUp) / 8000
	if(lt < 1) then
		draw.SetColor(0,1,0,1 - lt)
		draw.Text(10,340,"LEVEL UP!",10,16)
	end
end
hook.add("Draw2D","levelup",d2d)

requestGameState()