local function PDamage(p)
	if(p:GetHealth() <= 0) then
		--return p:GetHealth() - 50
	end
end
hook.add("PostPlayerDamaged","ctf",PDamage)

local function tn(team)
	if(team == TEAM_RED) then return "Red" end
	if(team == TEAM_BLUE) then return "Blue" end
	return "Unknown"
end

local function flagPickup(flag,player,team)
	print(player:GetInfo().name .. " Picked Up The " .. tn(team) .. " ^3Flag.\n")
end
hook.add("FlagPickup","ctf",flagPickup)

local function flagDrop(flag,team)
	print(tn(team) .. " ^3Flag Dropped.\n")
end
hook.add("FlagDropped","ctf",flagDrop)

local function flagReturn(flag,player,team)
	print(player:GetInfo().name .. " Returned The " .. tn(team) .. " ^3Flag.\n")
end
hook.add("FlagReturned","ctf",flagReturn)

local function flagStat(team,status)
	print(tn(team) .. "Flag Status " .. status .. "\n")
end
hook.add("FlagStatus","ctf",flagStat)

local function flagCap(flag,player,team)
	print(player:GetInfo().name .. " Captured The " .. tn(team) .. " ^3Flag.\n")
end
hook.add("FlagCaptured","ctf",flagCap)