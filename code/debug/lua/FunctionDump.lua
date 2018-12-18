local sorted = {}

local function sortedIndexes(t)
	local sorted = {}
	for k,v in pairs(t) do
		table.insert(sorted,k)
	end
	table.sort(sorted)
	return sorted
end

sorted = sortedIndexes(_G)

local function isEnum(i)
	for _,k in pairs(GetEnumSets()) do
		for e,_ in pairs (_G[k]) do
			if(e == _G[i]) then return true end
		end
	end
	return false
end

local function isEnumSet(i)
	for _,k in pairs(GetEnumSets()) do
		if(k == i) then return true end
	end
	return false
end

local function getEnumSetFor(i) 
	for _,k in pairs(GetEnumSets()) do
		for e,_ in pairs (_G[k]) do
			if(e == _G[i]) then return k end
		end
	end
end

local function isMeta(i)
	--print(i .. "\n")
	if(type(_G[i]) != "table") then return false end
	if(isEnumSet(i)) then return false end
	return (_G[i].__metatable != nil)
end

local function isLib(i)
	if(type(_G[i]) != "table") then return false end
	if(isEnumSet(i)) then return false end
	return (_G[i].__metatable == nil)
end

local function doMetaTables(output,...)
	for _,k in pairs(sorted) do
		if(isMeta(k)) then
			local meta = k
			for i,t in pairs(sortedIndexes(_G[meta].__metatable)) do
				local t2 = _G[meta].__metatable[t]
				if(type(t2) == "function") then
					local f = string.sub(meta,3)
					pcall(output,(f .. ":" .. t .. "\n"),unpack(arg))
				end
			end
		end
	end
end

local function doLibs(output,...)
	for _,k in pairs(sorted) do
		if(isLib(k)) then
			local lib = k
			for i,t in pairs(sortedIndexes(_G[lib])) do
				if(type(_G[lib][t]) == "function") then
					if(lib == "_G") then
						pcall(output,(t .. "\n"),unpack(arg))
					else
						if(_G["M_" .. lib] == nil) then
							pcall(output,(lib .. "." .. t .. "\n"),unpack(arg))
						end
					end
				end
			end
		end
	end
end

local function doEnumerations(output,...)
	local lastEnum = ""
	for _,k in pairs(sorted) do
		if(isEnumSet(k)) then
			pcall(output,(k .. "\n"),unpack(arg))
			local set = _G[k]
			if(type(set) == "table") then
				for k,v in pairs(set) do
					if(type(v) == "table") then
						pcall(output,("  " .. v.name .. " = " .. v.value .. "\n"),unpack(arg))
					end
				end
			end
		end
	end
end

local function toFile(name,func)
	local side = "server_"
	if(CLIENT) then side = "client_" end
	local str = ""
	local function append(s) str = str .. s end
	pcall(func,append)
	
	local file = io.open("lua/defs/" .. side .. name,"w")
	if(file != nil) then
		file:write(str)
		file:close()
	end
end

--doMetaTables(print)
toFile("metatables.txt",doMetaTables)
toFile("libraries.txt",doLibs)
toFile("enumerations.txt",doEnumerations)