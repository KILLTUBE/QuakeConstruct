message.Precache("levt")
E = {}

function E.event(evt)
	local msg = Message()
	message.WriteShort(msg,evt)
	eventBuffer = msg
end

function E.WriteShort(v)
	if(v == nil) then v = 0 end
	message.WriteShort(eventBuffer,v)
end

function E.WriteLong(v)
	if(v == nil) then v = 0 end
	message.WriteLong(eventBuffer,v)
end

function E.WriteString(v)
	message.WriteString(eventBuffer,tostring(v))
end

function E.WriteFloat(v)
	if(v == nil) then v = 0 end
	message.WriteFloat(eventBuffer,v)
end

function E.WriteVector(v)
	if(v == nil) then v = Vector(0,0,0) end
	message.WriteVector(eventBuffer,v)
end

function E.dispatch(pl)
	if(eventBuffer == nil) then return end
	if(pl ~= nil) then
		SendDataMessage(eventBuffer,pl,"levt")
	else
		SendDataMessageToAll(eventBuffer,"levt")
	end
	eventBuffer = nil
end