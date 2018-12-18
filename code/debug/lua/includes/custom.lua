_CUSTOM = {}

local function checkdir(str)
	--str, seperator, ll, true
	if(str == "" or string.find(str,".",0,true) != nil) then return false end
	return true
end

function Execute(dir)
	pcall(include,dir .. "/shared.lua")
	if(SERVER) then
		pcall(include,dir .. "/init.lua")
	else
		pcall(include,dir .. "/cl_init.lua")
	end
end

function FindCustomFiles(dir)
	local out = {}
	for filename in lfs.dir(dir) do
		local attr = lfs.attributes(dir .. "/" .. filename)
		--print(filename .. "\n")
		if (attr.mode == "directory" and checkdir(filename) ) then
			--print("Found " .. filename .. "\n")
			table.insert(out,{dir .. "/" .. filename,filename})
		end
	end
	return out
end

include("lua/includes/custom_ents.lua")
--include("lua/includes/custom_games.lua")
include("lua/includes/custom_weapons.lua")

FindCustomFiles = nil