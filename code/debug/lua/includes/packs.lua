packlib = {}
packlib.packs = {}

local function gapFix(str)
	local nstr = ""
	local inquotes = false
	local l = string.len(str)
	for i=1,l do
		local ch = string.sub(str,i,i)
		if(ch == "\"") then
			inquotes = !inquotes
		elseif((ch != " " and ch != "\t") or inquotes) then
			nstr = nstr .. ch
		end
	end
	return nstr
end

local function fileDir(file)
	local fname = string.GetFileFromFilename(file)
	local bdir = string.sub(file,0,string.len(file)-(string.len(fname)))
	return bdir
end

function packlib.CreatePack(file)

	local o = {}

	setmetatable(o,{})
	
	o['PACK_DIR'] = fileDir(file)
	o['PACK_AUTHOR'] = "n/a"
	o['PACK_DESCRIPTION'] = "n/a"
	o['PACK_MODE'] = "manual"
	o['PACK_NAME'] = killGaps(string.sub(string.GetFileFromFilename(o['PACK_DIR']),2))
	o['PACK_NAME'] = string.lower(o['PACK_NAME'])
	
	o.include = function(self,name)
		P = table.Copy(self)
		P['PACK_DIR'] = fileDir(fileDir(file) .. "/" .. name)
		include(self['PACK_DIR'] .. "/" .. name)
		P = table.Copy(self)
	end
	
	return o
	
end

function packlib.LoadPacks()
	local packs = findFileByType("pack","./lua/packs")
	for k,v in pairs(packs) do
		local t = packlib.CreatePack(v)
		table.insert(packlib.packs,t)
	end
	packlib.ParseAll()
end

function packlib.Inits(dir)
	if(CLIENT and fileExists(dir .. "/cl_init.lua")) then
		include(dir .. "/cl_init.lua")
	end
	if(SERVER and fileExists(dir .. "/init.lua")) then
		include(dir .. "/init.lua")
	end
end

function packlib.ParsePack(pack)
	local err = 0
	local p = pack['PACK_DIR']
	local ef = io.input(p .. "/info.pack")
	P = pack
	while true do
		local line = io.read()
		if line == nil then break end
		line = gapFix(line)
		local eq = string.find(line,"=")
		if(eq == nil) then err = 1 break end
		local key = string.sub(line,0,eq-1)
		local val = string.sub(line,eq+1,string.len(line))
		pack[key] = val
	end
	io.close(ef)
	if(err == 0) then
		local dir = pack['PACK_DIR']
		local mode = pack['PACK_MODE']
		local name = pack['PACK_DESCRIPTION']
		if(name == "n/a") then name = dir end
		print("Loading Pack: '" .. name .. "' - " .. pack['PACK_NAME'] .. "\n")
		if(mode != "autorun" and mode != "manual") then 
			print("^1Unable to load pack: invalid mode, specify \"autorun\" or \"manual\"\n")
			return 
		end
		if(mode == "autorun") then
			packlib.Inits(dir)
		end
		return ptab
	else
		print("^1There was an error loading the pack.\n")
	end
	P = nil
end

function packlib.ParseAll()
	for k,v in pairs(packlib.packs) do
		packlib.ParsePack(v)
	end
end

function packlib.LoadPack(pname)
	if(type(pname) == "table") then
		if(pname['PACK_NAME'] != nil) then
			packlib.Inits(pname['PACK_DIR'])
			return
		end
	end
	for k,v in pairs(packlib.packs) do
		if(v['PACK_NAME'] == string.lower(pname)) then
			packlib.Inits(v['PACK_DIR'])
		end
	end
end

function packlib.List()
	return packlib.packs;
end

if(CLIENT) then
	local function cc(p,c,a)
		if(a[1] != nil) then
			packlib.LoadPack(a[1])
		else
			print("Please specify a pack.\n")
		end
	end
	concommand.Add("LoadPack_cl",cc)
else
	local function cc(p,c,a)
		if(a[1] != nil) then
			packlib.LoadPack(a[1])
		else
			print("Please specify a pack.\n")
		end
	end
	concommand.Add("LoadPack",cc)
end


packlib.LoadPacks()