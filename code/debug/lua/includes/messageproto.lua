--*******
--GLOBALS
--*******

D_SHORT = 1
D_LONG = 2
D_STRING = 3
D_FLOAT = 4
D_BYTE = 5
D_VECTOR = 6

local strings = {}
strings[D_SHORT] = "Short"
strings[D_LONG] = "Long"
strings[D_STRING] = "String"
strings[D_FLOAT] = "Float"
strings[D_BYTE] = "Byte"
strings[D_VECTOR] = "Vector"

local types = {}
types[D_SHORT] = "number"
types[D_LONG] = "number"
types[D_STRING] = "string"
types[D_FLOAT] = "number"
types[D_BYTE] = "number"
types[D_VECTOR] = "userdata"

local defaults = {}
defaults[D_SHORT] = 0
defaults[D_LONG] = 0
defaults[D_STRING] = ""
defaults[D_FLOAT] = 0
defaults[D_BYTE] = 0
defaults[D_VECTOR] = Vector(0,0,0)

local MessageT = {}
local Prototypes = {}
local connections = {}
local standIns = {}
local funcs = {}
local QueueMessage = nil
local sendPrototype = nil

local d_Message = _Message
local d_Send = _SendDataMessage

if(SERVER) then
	funcs[D_SHORT] = _message.WriteShort
	funcs[D_LONG] = _message.WriteLong
	funcs[D_STRING] = _message.WriteString
	funcs[D_FLOAT] = _message.WriteFloat
	funcs[D_BYTE] = _message.WriteByte
	funcs[D_VECTOR] = function(m,v) 
		_message.WriteFloat(m,v.x)
		_message.WriteFloat(m,v.y)
		_message.WriteFloat(m,v.z)
	end
else
	funcs[D_BYTE] = _message.ReadByte
	funcs[D_SHORT] = _message.ReadShort
	funcs[D_LONG] = _message.ReadLong
	funcs[D_STRING] = _message.ReadString
	funcs[D_FLOAT] = _message.ReadFloat
	funcs[D_VECTOR] = function(m,v) 
		local x = _message.ReadFloat()
		local y = _message.ReadFloat()
		local z = _message.ReadFloat()
		return Vector(x,y,z)
	end
end

local function protoForName(name)
	for k,v in pairs(Prototypes) do
		if(v.name == name) then return k end
	end
	return nil
end

local function protoForId(id)
	for k,v in pairs(Prototypes) do
		if(v._id == id) then return k end
	end
	return nil
end

--*********
--METATABLE
--*********

function MessageT:Byte() table.insert(self.stack,D_BYTE) return self end
function MessageT:Short() table.insert(self.stack,D_SHORT) return self end
function MessageT:Long() table.insert(self.stack,D_LONG) return self end
function MessageT:String() table.insert(self.stack,D_STRING) return self end
function MessageT:Float() table.insert(self.stack,D_FLOAT) return self end
function MessageT:Vector() table.insert(self.stack,D_VECTOR) return self end
function MessageT:Recv(data) end

function MessageT:E()
	for k,v in pairs(GetAllPlayers()) do
		if(connections[v:EntIndex()] == true) then
			sendPrototype(self,v)
		end
	end
	return self
end

function MessageT:Send(pl,...) 
	if(type(pl) == "userdata") then pl = pl:EntIndex() end
	if(type(pl) ~= "number") then error("Not a player\n") return end
	
	local data = {}
	--local msg = d_Message(pl,LUA_PROTOMESSAGE_MSG)
	table.insert(data,{D_BYTE,self._id})
	for i=1, #self.stack do
		local v = arg[i]
		local t = self.stack[i]

		local b,e = nil,"Nan"
		if(types[t] == type(v)) then
			table.insert(data,{t,v})
			--b,e = pcall(funcs[t],v)
		else
			table.insert(data,{t,defaults[t]})
			--b,e = pcall(funcs[t],defaults[t])
		end
	end
	QueueMessage(LUA_PROTOMESSAGE_MSG,pl,data)
end

function MessageT:Read()
	if not (CLIENT) then return end
	self.data = {}
	for i=1, #self.stack do
		local v = self.stack[i]
		local b,e = pcall(funcs[v])
		if not (b) then
			print("Error reading message data: " .. strings[v] .. " : " .. e .. "\n")
		else
			--print("ProtoRead[" .. i .. "]: " .. strings[v] .. " - " .. tostring(e) .. "\n")
			table.insert(self.data, e)
		end
	end
	self:Recv(self.data)
end

function MessageT:Pack()
	local contents = ""
	for i=1, #self.stack do
		local v = self.stack[i]
		contents = contents .. tostring(v)
	end
	
	if(contents == "") then contents = "9" end
	return tonumber(contents)
end

function MessageT:SetStack(stack)
	stack = tostring(stack)
	self.stack = {}
	if(stack != "9") then
		stack = string.ToTable(stack)
		for k,v in pairs(stack) do
			v = tonumber(v)
			print("Loaded Into Stack: " .. v .. "\n")
			table.insert(self.stack,v)
		end
	end
end

local function __MessagePrototype(name,stack)
	local o = {}

	if(type(name) ~= "string") then error("Invalid Prototype Name\n") end
	--if(protoForName(name) ~= nil) then error("Prototype Already Exists with that name: " .. name .. "\n") end
	
	local exist = protoForName(name)
	if(exist ~= nil) then
		Prototypes[exist].stack = {}
		Prototypes[exist].data = {}
		return Prototypes[exist]
	end
	
	setmetatable(o,MessageT)
	MessageT.__index = MessageT
	
	o.stack = {}
	o.name = name
	o.data = {}
	
	if(stack == nil) then
		o._id = #Prototypes + 1
		table.insert(Prototypes,o)
	else
		o._id = stack
	end
	
	return o;
end

function MessagePrototype(name)
	return __MessagePrototype(name,nil)
end

--*********
--SERVER IO
--*********

if(SERVER) then
	local messageQueue = {}
	
	local function Think()
		local ltime = LevelTime()
		for i=1, 3 do --try and do 3 messages
			if(#messageQueue == 0) then return end
			--print("Queue: " .. #MessageQueue .. "\n")
			local focus = messageQueue[1]
			local msgid = focus[1]
			local player = focus[2]
			local data = focus[3]
			local expires = focus[4]
			
			if(player == nil) then
				table.remove(messageQueue,1)	
			else
				if(connections[player]) then
					table.remove(messageQueue,1)
					local msg = d_Message(player,msgid)
					for i=1, #data do
						local t = data[i][1]
						local v = data[i][2]
						local b,e = pcall(funcs[t],msg,v)
						--print("Type: " .. t .. "\n")
						if not (b) then
							print("^1Error sending message data: " .. strings[t] .. " : " .. e .. "\n")
						else
							--print("  " .. v .. "\n")
						end
					end
					d_Send(msg)
				else
					if(expires < ltime) then
						table.remove(messageQueue,1)
						print("^6ProtoMessage Expired: " .. msgid .. "\n")
					end
				end
			end
		end
	end
	hook.add("Think","messageproto",Think)
	
	local function PlayerJoined(pl)
		if(pl == nil) then return end
		connections[pl] = true
		
		for k,v in pairs(Prototypes) do
			sendPrototype(v,pl)
		end
	end
	hook.add("ClientReady","messageproto",PlayerJoined,9998)
	
	local function PlayerStop(pl)
		if(pl == nil) then return end
		if(!pl:IsBot()) then connections[pl:EntIndex()] = false end
	end
	hook.add("ClientShutdownLua","messageproto",PlayerStop,9999)
	
	local function DemoSend(pl)
		if(pl == nil) then return end
		
		for k,v in pairs(Prototypes) do
			sendPrototype(v,pl:EntIndex())
		end
	end
	hook.add("DemoStarted","messageproto",DemoSend,9999)
	
	QueueMessage = function(msg,pl,data)
		table.insert(messageQueue,{msg,pl,data,LevelTime() + 100})
	end
	
	sendPrototype = function(proto,pl)
		local data = {}
		--local msg = d_Message(pl,LUA_PROTOMESSAGE_INDEX)
		--_message.WriteByte(msg,proto._id)
		--_message.WriteLong(msg,proto:Pack())
		print("Send Proto: " .. proto.name .. "\n")
		--_message.WriteString(msg,proto.name)
		table.insert(data,{D_BYTE,proto._id})
		table.insert(data,{D_LONG,proto:Pack()})
		table.insert(data,{D_STRING,proto.name})
		QueueMessage(LUA_PROTOMESSAGE_INDEX,pl,data)
	end
else

--*********
--CLIENT IO
--*********

	local function resolveProto(id)
		if(standIns[id] ~= nil) then
			local id2 = protoForName(standIns[id].name)
			return Prototypes[id2] or standIns[id]
		else
			local id2 = protoForId(id)
			return Prototypes[id2]
		end
		return nil
	end

	local function handle(msgid)
		if(msgid == LUA_PROTOMESSAGE_INDEX) then
			local id = _message.ReadByte()
			local contents = _message.ReadLong()
			local str = _message.ReadString()
			print("Got messageID: " .. id .. "->" .. str .. "->" .. tostring(contents) .. "\n")
			
			local proto = protoForName(str)
			
			if(proto == nil) then
				standIns[id] = __MessagePrototype(str,id)
				standIns[id]:SetStack(contents)
			else
				proto = Prototypes[proto]
				proto._id = id
				proto:SetStack(contents)
			end
		elseif(msgid == LUA_PROTOMESSAGE_CACHE) then

		elseif(msgid == LUA_PROTOMESSAGE_MSG) then
			local id = _message.ReadByte()
			local proto = resolveProto(id)
			
			if(proto ~= nil) then
				proto:Read()
				--print("Read Prototype\n")
			else
				error("GOT NO PROTOTYPE, MESSAGE LOST, GAME OVER [" .. id .. "]\n")
			end
		end
	end
	hook.add("_HandleMessage","messageproto",handle)
end