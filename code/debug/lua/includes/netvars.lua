_NetTables = _NetTables or {}
local network_meta = {}

local n_msgid = "_ntbvar"
local n_initid = "_newnt"
local types = {}
types["number"] = 1
types["string"] = 1
types["nil"] = 1

local sendQueue = 0
local senddelay = 0.02 --Prevent too many messages being sent at once

local blacklist = {
	"_previous",
	"_protected",
	"_ids",
	"_vars",
	"id",
	"tindex",
	"Init",
	"Reset",
	"VariableChanged",
	"SendVars",
}

local function isBlackListed(var)
	for i=1, #blacklist do
		if(blacklist[i] == var) then return true end
	end
	return false
end

local d_Message = _Message
local d_Send = _SendDataMessage

if(SERVER) then
	local function isFloat(n)
		return (math.floor(n) != n)
	end

	local function WriteBit(msg,bit)
		if(bit) then _message.WriteBits(msg,1,1) else _message.WriteBits(msg,0,1) end
	end
	
	local function _sendVariable(self,var,val,new,pl)
		local msg = d_Message(pl,LUA_NETVAR)

		_message.WriteShort(msg,self.tindex)
		_message.WriteByte(msg,self._ids[var] or -1)
		
		WriteBit(msg,val == nil)
		if(val == nil) then
			if(new == true) then msg = nil return end
		else
			WriteBit(msg,new)
			if(new) then
				_message.WriteString(msg,tostring(var))
			end
			
			WriteBit(msg,type(val) == "number")
			if(type(val) == "number") then
				WriteBit(msg,isFloat(val))
				if(isFloat(val)) then
					_message.WriteFloat(msg,val)
				else
					if(val < 32767 and val > -32768) then
						_message.WriteBits(msg,0,1)
						_message.WriteShort(msg,val)
					else
						_message.WriteBits(msg,1,1)
						_message.WriteLong(msg,val)
					end
				end
			elseif(type(val) == "string") then
				_message.WriteString(msg,val)
			end
		end

		d_Send(msg)
	end
	
	local function sendVariable(self,var,val,new,pl)
		if(pl ~= nil) then
			_sendVariable(self,var,val,new,pl)
		else
			for k,v in pairs(GetAllPlayers()) do
				_sendVariable(self,var,val,new,v:EntIndex())
			end
		end
	end
	
	local function variableChanged(self,last,var,val)
		if(last != nil) then
			if(last != val) then
				debugprint("Varable Changed: " .. var .. " " .. tostring(last) .. " -> " .. tostring(val) .. "\n")
				sendVariable(self,var,val,false)
			end
		else
			debugprint("New Variable[" .. self.id .. "]: " .. var .. " = " .. tostring(val) .. "\n")
			self._ids[var] = self.id
			sendVariable(self,var,val,true)
			self.id = self.id + 1
		end
		if(self.VariableChanged != nil) then
			pcall(self.VariableChanged,self,var,val,last)
		end
	end

	function network_meta:SendVars(pl)
		--print("Sending Vars To " .. pl:GetInfo().name .. "\n")
		for k,v in pairs(self._protected) do
			debugprint("Sent: " .. tostring(k) .. "\n")
			sendVariable(self,k,v,true,pl)
		end	
	end
	
	function network_meta:Reset()
		self.__mt._previous = {}
		self.__mt._protected = {}
		self.__mt._ids = {}
		self.__mt.id = 0
	end

	function network_meta:Init()
		self:Reset()
	end
	
	function network_meta.__index(self,var)
		local mt = rawget(self,"__mt")
		if(isBlackListed(var) == true) then
			return rawget(mt,var)
		end
		return mt._protected[var]
	end
	
	function network_meta.__newindex(self,var,val)
		local tab = self --rawget(self,"__mt")
		if(isBlackListed(var) == true) then
			rawset(self,var,val)
			return
		end
		if(types[type(val)] == 1) then
			if(val == nil and tab._previous[var] != nil) then
				variableChanged(tab,tab._previous[var],var,nil)
				tab._previous[var] = nil
				return
			end
			if(tab._previous[var] == nil or type(tab._previous[var]) == type(val)) then
				variableChanged(tab,tab._previous[var],var,val)
				tab._protected[var] = val
				tab._previous[var] = val
			else
				error("\n    Invalid Data Type[^7" .. var .. "^1]:\n" .. 
					  "       Last data type was ^7\"" .. type(tab._previous[var]) .. "\"^1\n" ..
					  "       Given data type was ^7\"" .. type(val) .. "\"^1")
			end
		else
			error("Invalid Data Type[^7" .. var .. "^1]!")
		end
	end
	
	local function PlayerJoined(pl)
		local add = 0
		for k,v in pairs(_NetTables) do
			if(v != nil) then
				Timer(.05+add,v.SendVars,v,pl)
				add = add + .05
			end
		end
	end
	hook.add("ClientReady","netvars2",PlayerJoined)
	
	local function DemoStart(pl)
		Timer(1,function()
			local add = 0
			for k,v in pairs(_NetTables) do
				if(v != nil) then
					Timer(.05+add,v.SendVars,v,pl)
					add = add + .05
				end
			end
		end)
	end
	hook.add("DemoStarted","netvars2",DemoStart)
else
	function network_meta:Reset()
		self.__mt._vars = {}
		self.__mt._ids = {}
	end
	
	function network_meta:Init()
		self:Reset()
	end
	
	function network_meta.__index(self,var)
		local mt = rawget(self,"__mt")
		if(isBlackListed(var) == true) then
			return rawget(mt,var)
		end
		return mt._vars[var]
	end
	
	function network_meta.__newindex(self,var,val)
		if(isBlackListed(var) == true) then
			return
		end
		local mt = rawget(self,"__mt")
		mt._vars[var] = val
	end

	local function readBit()
		return _message.ReadBits(1) == 1
	end
	
	local function NetVar(msgid)
		if(msgid ~= LUA_NETVAR) then return end
		local tableindex = _message.ReadShort()
		local varindex = _message.ReadByte()
		local varname = nil
		local data = nil
		
		if not (readBit()) then --nil
			if(readBit()) then
				varname = _message.ReadString()
			end
			
			if(readBit()) then --number
				if not (readBit()) then --int
					if(readBit()) then
						local long = _message.ReadLong()
						data = long
					else
						local short = _message.ReadShort()
						data = short
					end
				else --float
					local float = _message.ReadFloat()
					data = float
				end
			else --string
				local str = _message.ReadString()
				data = str
			end
		end
		
		print("TABLEINDEX: " .. tableindex .. "\n")
		if(_NetTables[tableindex] == nil) then
			_NetTables[tableindex] = {}
			setmetatable(_NetTables[tableindex],network_meta)
			rawset(_NetTables[tableindex],"__mt",table.Copy(network_meta))
			
			_NetTables[tableindex].tindex = tableindex
			_NetTables[tableindex]:Init()
			nt = _NetTables[tableindex]
			print("^3Server Forced Client Networked Table: " .. tableindex .. "\n")
		end
		
		local mtab = _NetTables[tableindex].__mt
		if(varname ~= nil) then
			debugprint("Got New Variable\n")
			local var = varname
			local id = varindex
			local value = data
			var = tonumber(var) or var
			mtab._ids[id] = var
			if (var ~= nil) then
				debugprint(var .. "[" .. id .. "]: " .. tostring(value) .. "\n")
			else
				debugprint("NIL " .. "[" .. id .. "]: " .. tostring(value) .. "\n")
			end

			mtab._vars[var] = value
			local self = _NetTables[tableindex]
			if(self.VariableChanged != nil) then
				pcall(self.VariableChanged,self,var,value,nil)
			end
		elseif(data ~= nil) then
			debugprint("Variable Changed\n")
			local id = varindex
			local var = tostring(mtab._ids[id])
			var = tonumber(var) or var
			local value = data
			debugprint(var .. "[" .. id .. "]: " .. tostring(value) .. "\n")

			local self = _NetTables[tableindex]
			if(self.VariableChanged != nil) then
				pcall(self.VariableChanged,self,var,value,mtab._vars[var])
			end
			mtab._vars[var] = value
		elseif(data == nil) then
			debugprint("Variable Cleared\n")
			local id = varindex
			local var = tostring(mtab._ids[id])				
			var = tonumber(var) or var

			local self = _NetTables[tableindex]
			if(self.VariableChanged != nil) then
				pcall(self.VariableChanged,self,var,nil,mtab._vars[var])
			end
			mtab._vars[var] = value
		end
	
		--[[if(msgid == n_msgid) then
			local tindex = message.ReadShort()
			local first = message.ReadRaw()

			if(_NetTables[tindex] == nil) then
				_NetTables[tindex] = {}
				setmetatable(_NetTables[tindex],network_meta)
				rawset(_NetTables[tindex],"__mt",table.Copy(network_meta))
				
				_NetTables[tindex].tindex = tindex
				_NetTables[tindex]:Init()
				nt = _NetTables[tindex]
				print("^3Server Forced Client Networked Table: " .. tindex .. "\n")
			end
			
			local mtab = _NetTables[tindex].__mt
			if(type(first) == "string") then
				debugprint("Got New Variable\n")
				local var = first
				local id = message.ReadShort()
				local value = message.ReadRaw()
				var = tonumber(var) or var
				mtab._ids[id] = var
				debugprint(var .. "[" .. id .. "]: " .. tostring(value) .. "\n")

				mtab._vars[var] = value
				local self = _NetTables[tindex]
				if(self.VariableChanged != nil) then
					pcall(self.VariableChanged,self,var,value,nil)
				end
			elseif(type(first) == "number" and message.StackSize() >= 1) then
				debugprint("Variable Changed\n")
				local id = first
				local var = tostring(mtab._ids[id])
				var = tonumber(var) or var
				local value = message.ReadRaw()
				debugprint(var .. "[" .. id .. "]: " .. tostring(value) .. "\n")

				local self = _NetTables[tindex]
				if(self.VariableChanged != nil) then
					pcall(self.VariableChanged,self,var,value,mtab._vars[var])
				end
				mtab._vars[var] = value
			elseif(type(first) == "number" and message.StackSize() == 0) then
				debugprint("Variable Cleared\n")
				local id = message.ReadShort()
				local var = tostring(mtab._ids[id])				
				var = tonumber(var) or var

				local self = _NetTables[tindex]
				if(self.VariableChanged != nil) then
					pcall(self.VariableChanged,self,var,nil,mtab._vars[var])
				end
				mtab._vars[var] = value
			end
		end]]
	end
	hook.add("_HandleMessage","netvars2",NetVar)
end

local function Internal_CreateNetworkedTable(index)
	local nt = _NetTables[index]
	if(nt == nil) then
		_NetTables[index] = {}
		setmetatable(_NetTables[index],network_meta)
		rawset(_NetTables[index],"__mt",table.Copy(network_meta))
		
		_NetTables[index].tindex = index
		_NetTables[index]:Init()
		nt = _NetTables[index]
		if(SERVER) then
			--print("Server Created Networked Table: " .. index .. "\n")
		else
			--print("Client Created Networked Table: " .. index .. "\n")
		end
	end
	return nt
end

function NetworkTableInUse(index)
	return (_NetTables[index] != nil)
end

function CreateEntityNetworkedTable(index)
	if(index > 0) then
		return Internal_CreateNetworkedTable(index + 1024)
	else
		error("Bad networked table index: " .. index .. "\n")
	end
end
--[[for i=1,1024 do
	CreateEntityNetworkedTable(i)
end]]

function ClearEntityNetworkedTable(index)
	if(index > 0) then
		if(_NetTables[index + 1024] != nil) then
			_NetTables[index + 1024]:Reset()
		end
	else
		error("Bad networked table index: " .. index .. "\n")
	end
end

local function GetNextNetTableIndex()
	for i=1,1024 do
		if(_NetTables[i] == nil) then
			return i
		end
	end
end

function CreateNetworkedTable(index)
	if(index <= 1024 and index > 0) then
		if(_NetTables[index] != nil) then
			error("Networked table is in use, use \"ClearNetworkedTable(id)\" to clear it.\n")
		end
		return Internal_CreateNetworkedTable(index)
	else
		error("Bad networked table index: " .. index .. "\n")
	end
end

function ClearNetworkedTable(index)
	if(index <= 1024 and index > 0) then
		_NetTables[index] = nil
	else
		error("Bad networked table index: " .. index .. "\n")
	end
end