local error = error
local print = print
local table = table
local pairs = pairs
local ipairs = ipairs
local type = type
local pcall = pcall
local string = string
local tostring = tostring
local io = io
local IsVector = IsVector

local function LoadInTable(file)
	local b,e = pcall(include,"persistance/" .. file .. ".ps")
	if(b == nil) then
		print(tostring(e) .. "\n")
	end
	local t = PERSISTANCE_TABLE
	PERSISTANCE_TABLE = nil
	return t or {}
end

module("persist")

PERS_IDLE = 'i'
PERS_WRITE = 'w'

local activeFile = nil
local rw_state = PERS_IDLE

function Load(file)
	return LoadInTable(file)
end

local function write(s)
	if(rw_state ~= PERS_WRITE and rw_state ~= PERS_APPEND) then return end
	activeFile:write(s)
end

function Start(file)
	local f = io.output("persistance/" .. file .. ".ps", rw)
	if(f == nil) then
		error("persist.Start: \"" .. file .. "\": file does not exist\n")
	end
	rw_state = PERS_WRITE
	activeFile = f
	write("PERSISTANCE_TABLE={")
end

local WriteValue = nil
local function WriteTable(v,nobrac)
	if not (nobrac) then write("{") end
	for k,v in pairs(v) do
		if(type(k) == "string") then
			local m = string.match(k,"^[A-Za-z_0-9]+$")
			--if(m) then print(k .. " | " .. m .. "\n") end
			if(m and m == k) then
				write(k .. "=")
			else
				write("[\"" .. k .. "\"]=")
			end
		elseif(type(k) == "number") then
			write("[" .. k .. "]=")
		end
		WriteValue(v)
		write(",")
	end
	if not (nobrac) then write("}") end
end

WriteValue = function(v)
	local t = type(v)
	--print(t .. "\n")
	if(t == "table") then
		WriteTable(v)
	elseif(t == "userdata") then
		if(IsVector(v)) then
			write("Vector(" .. v.x .. "," .. v.y .. "," .. v.z .. ")")
		end
	elseif(t == "string") then
		write("\"" .. tostring(v) .. "\"")
	elseif(t == "number") then
		write(tostring(v))
	elseif(t == "function") then
		local s,dump = pcall(string.dump,v)
		if(s) then
			write("loadstring(\"" .. dump .. "\")")
		else
			write("nil")
		end
	else
		write("nil")
	end
end

function Write(n,v)
	if(type(n) ~= "string") then error("persist.Write: Invalid Argument 1 (Expected String)\n") end
	write(n .. "=")
	WriteValue(v)
	write(",")
end

function Close()
	write("}")
	rw_state = PERS_IDLE
	if(activeFile ~= nil) then
		activeFile:close()
	end
end