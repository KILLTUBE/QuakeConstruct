message.Precache("deathnotify")
message.Precache("flagnotify")
local function death(self,inflictor,attacker,damage,means)
	if(self == nil) then return end
	local msg = Message()
	message.WriteShort(msg,self:EntIndex())
	if(attacker != nil and attacker:IsPlayer()) then
		message.WriteShort(msg,attacker:EntIndex())
	else
		message.WriteShort(msg,-1)
	end
	message.WriteShort(msg,means)
	SendDataMessageToAll(msg,"deathnotify")
end
hook.add("PlayerKilled","sh_notify",death)

local function flagPickup(flag,player,team)
	local msg = Message()
	message.WriteShort(msg,1)
	message.WriteShort(msg,player:EntIndex())
	SendDataMessageToAll(msg,"flagnotify")
end
hook.add("FlagPickup","scores",flagPickup)

local function flagReturn(flag,player,team)
	local msg = Message()
	message.WriteShort(msg,0)
	message.WriteShort(msg,player:EntIndex())
	SendDataMessageToAll(msg,"flagnotify")
end
hook.add("FlagReturned","scores",flagReturn)

local function flagCap(flag,player,team)
	local msg = Message()
	message.WriteShort(msg,2)
	message.WriteShort(msg,player:EntIndex())
	SendDataMessageToAll(msg,"flagnotify")
end
hook.add("FlagCaptured","scores",flagCap)