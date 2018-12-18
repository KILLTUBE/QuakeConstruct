local enum = {}
local enumsets = {}
enum_weaponentities = {
	"weapon_gauntlet",
	"weapon_machinegun",
	"weapon_shotgun",
	"weapon_grenadelauncher",
	"weapon_rocketlauncher",
	"weapon_lightning",
	"weapon_railgun",
	"weapon_plasmagun",
	"weapon_bfg"
}

function killWhiteSpace(line)
	local tab = string.Explode ( "\t", line )
	for k,v in pairs(tab) do
		if not (v == "" or string.find(v, "//")) then
			return v
		end
	end
	return ""
end

function toNextChar(str)
	local tab = string.ToTable ( str )
	for k,v in pairs(tab) do
		if(v != " ") then
			return k
		end
	end
	return nil
end

function toNextSpace(str)
	local tab = string.ToTable ( str )
	for k,v in pairs(tab) do
		if(v == " ") then
			return k
		end
	end
	return nil
end

function parseEnumerationSet(file)
	local ef = io.input(file)
	local inEnum = false
	local enumlist = {}
	local enumcontents = {}
	while true do
		local line = io.read()
		if line == nil then break end
		line = string.Trim(line)
		if(string.find(line,"enum {")) then
			inEnum = true
		elseif(string.find(line,"#define")) then
			local name = ""
			line = string.sub(line,8)
			line = string.Replace(line,"\t"," ")
			local com = string.find(line,"//")
			if(com) then
				line = string.sub(line,0,com-1)
			end
			local first = toNextChar(line)
			if(first) then
				line = string.sub(line,first,string.len(line))
				local sec = toNextSpace(line)
				name = string.sub(line,0,sec-1)
				local rem = string.sub(line,sec,string.len(line))
				val = string.Replace(rem," ","")
			end
			local n = tonumber(val)
			if(n != nil) then
				_G[name] = n
			else
				val = string.Replace(val,"\"","")
				val = string.Replace(val,"'","")
				_G[name] = val
			end
		elseif(string.find(line,"}")) then
			inEnum = false
			line = string.Replace(line, ";", "")
			line = string.sub(line,3)
			enum[line] = enumcontents
			enumcontents = {}
		else
			if(inEnum) then
				line = killWhiteSpace(line)
				if not (line == "") then
					line = string.Replace(line, ",", "")
					line = string.Replace(line, " ", "")
					local t = {}
					local name = line
					local eq = string.find(line,"=")
					if(eq) then
						local num = string.sub(line,eq+1,string.len(line))
						name = string.sub(line,0,eq-1)
						t.forcevalue = tonumber(num)
					end
					t.name = name
					table.insert(enumcontents,t)
				end
			end
		end
	end
	io.close(ef)
end

local enumfiles = findFileByType("enum")
for k,v in pairs(enumfiles) do
	if(string.sub(v,1,4) == "lua/") then
		--print("^3Found Enumeration Set '" .. v .. "'.\n")
		parseEnumerationSet(v)
	end
end
--parseEnumerationSet("lua/includes/enum/input.enum")

local count = 0
local val = 0
local forced = 0
for n,e in pairs(enum) do
	--debugprint("^3Enumerated '" .. n .. "'.\n")
	for k,v in pairs(e) do
		--print(v.name)
		local value = val
		value = value + forced
		if(v.forcevalue) then
			forced = v.forcevalue
			value = forced
			val = 0
			--print(" " .. v.forcevalue .. "\n")
		else
			--print(" " .. value .. "\n")
		end
		_G[v.name] = value
		v.value = value
		count = count + 1
		val = val + 1
	end
	e.IsEnumeration = true
	_G[n] = e
	table.insert(enumsets,n)
	forced = 0
	val = 0
end

function GetEnumSets()
	return enumsets
end

function GetEnumSet(set)
	if not(set == nil) then
		if(type(set) == "table") then
			local out = table.Copy(set)
			out.IsEnumeration = nil
			return out
		end
	end
end

function EnumToString(set,val)
	if not(set == nil) then
		if(type(set) == "table") then
			for k,v in pairs(set) do
				if(type(v) == "table") then
					if(val == v.value) then
						if(type(v.name) == "string") then
							return v.name
						end
					end
				end
			end
		else
			error("Invalid Set Type.\n")
		end
	else
		error("Set Was Nil.\n")
	end
	error("Unable To Find Value\n")
	return ""
end

debugprint("^3" .. count .. " Enumerations loaded.\n")