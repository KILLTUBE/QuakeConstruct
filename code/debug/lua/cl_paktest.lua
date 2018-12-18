require "cl_gui"

function countSlashes(str)
	local c = 0
	local tab = string.ToTable(str)
	for k,v in pairs(tab) do
		if(v == "/") then c = c + 1 end
	end
	return c
end

function lastChar(v)
	return string.sub(v,string.len(v),string.len(v))
end

local function PlayThisSound(snd)
	local snd = LoadSound(snd)
	PlaySound(snd)
end

local lister = {}

function lister.dirlist()
	altmenu.clearButtons()
	altmenu.addButton("Sounds", lister.plist, "sound/")
	altmenu.addButton("Models", lister.plist, "models/")
	altmenu.addButton("-Reload ModelPane-", function() 
		MDL_VIEWPANE:Remove()
		MDL_MODEL:Remove()
	end)
end

function lister.plist(path,init)
	print("Iter Dir: " .. path .. "\n")
	altmenu.clearButtons()
	
	altmenu.setBack(lister.dirlist)
	
	if(init == nil) then init = path end
	
	if(path != init) then
		local pth = string.sub(path,0,string.len(path)-1)
		local fname = string.GetFileFromFilename(pth)
		local bdir = string.sub(pth,0,string.len(pth)-(string.len(fname))) .. "/"
		print("Back: " .. bdir .. "\n")
		altmenu.addButton("..",lister.plist,bdir,init)
	end
	
	local test = packList(path,"")
	table.sort(test,function(a,b) return a < b end)
	for k,v in pairs(test) do
		local ext = string.GetExtensionFromFilename(v)
		if((countSlashes(v) == 0 or countSlashes(v) == 1 and lastChar(v) == "/")) then
			if(v != "") then
				if(ext == "md3") then
					altmenu.addButton(v,function() MakeModelFrame(path .. v) end)
				elseif(ext == "wav") then
					altmenu.addButton(v,function() PlayThisSound(path .. v) end)
				elseif(ext == "") then
					altmenu.addButton(v,function() lister.plist(path .. v,init or path) end)
				end
			end
		end
	end
end

lister.dirlist()
--lister.plist("models/players/sorlag/gibs/",nil)

--altmenu.setBack(menutest.main)