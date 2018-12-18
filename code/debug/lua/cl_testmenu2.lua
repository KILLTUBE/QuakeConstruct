local sayings = {"I like pie","qconstruct is awesome","hello","woot","potato","nice shot","ouch","lol"}
local cheats = {"god","noclip","give all"}

local menutest = {}
local currmenu = ""

function menutest.scripts(side,dir)
	currmenu = "scripts"
	altmenu.textSize(10,20)
	altmenu.clearButtons()
	
	for filename in lfs.dir(dir) do
		local attr = lfs.attributes(dir .. "/" .. filename)
		if (attr.mode == "directory" and filename != ".." and filename != ".") then
			altmenu.addButton(filename,menutest.scripts,side,dir .. "/" .. filename)
		end
	end
	for filename in lfs.dir(dir) do
		local attr = lfs.attributes(dir .. "/" .. filename)
		if not(attr.mode == "directory") then
			if(string.GetExtensionFromFilename(filename) == "lua") then
				if(side == "client" and string.find(filename,"cl_")) then
					altmenu.addButton(filename,function() include(dir .. "/" .. filename) end)
				end
				if(side == "server" and !string.find(filename,"cl_")) then
					local dirx = string.sub(dir,6,string.len(dir))
					local filex = string.sub(filename,0,string.len(filename)-4)
					
					altmenu.addButton(filename,function() ConsoleCommand("load " .. dirx .. "/" .. filex) end)		
				end
			end
		end
	end
	if(dir == "./lua") then
		altmenu.setBack(menutest.main)
	else
		local fname = string.GetFileFromFilename(dir)
		local bdir = string.sub(dir,0,string.len(dir)-(string.len(fname)))
		altmenu.setBack(menutest.scripts,side,bdir)
	end
end

function menutest.speech()
	currmenu = "speech"
	altmenu.textSize(8,12)
	altmenu.clearButtons()
	for k,v in pairs(sayings) do
		altmenu.addButton("^2" .. v,function()
			ConsoleCommand("say " .. v)
		end)
	end
	altmenu.setBack(menutest.main)
end

function menutest.cheats()
	currmenu = "cheats"
	altmenu.textSize(12,10)
	altmenu.clearButtons()
	for k,v in pairs(cheats) do
		altmenu.addButton("^2" .. v,function() 
			ConsoleCommand(v)
		end)
	end
	altmenu.setBack(menutest.main)
end

local function listMusic()
	local test = packList("music","")
	local out = {}
	table.sort(test,function(a,b) return a < b end)
	for k,v in pairs(test) do
		if(v != nil and v != "") then
			if(string.find(v,"intro.wav") and
			   string.find(test[k+1],"loop.wav")) then
				table.insert(out,{string.sub(v,0,string.len(v) - 10),"music/" .. v,"music/" .. test[k+1]})
			else
				if(!string.find(v,"loop.wav")) then
				--string.sub(v,0,string.len(v) - 4)
					table.insert(out,{v,"music/" .. v,nil})
				end
			end
		end
	end
	return out
end

function menutest.music()
	currmenu = "music"
	altmenu.textSize(12,10)
	altmenu.clearButtons()

	altmenu.addButton("[StopMusic]",function() 
		StopMusic()
	end):SetBGColor(.4,.1,.1,1)
	
	for k,v in pairs(listMusic()) do
		altmenu.addButton(v[1],function() 
			StartMusic(v[2],v[3])
		end)
	end
	altmenu.setBack(menutest.main)
end

function menutest.disable(pane)
	pane:SetBGColor(.2,.2,.2,.4)
	pane:SetFGColor(.6,.6,.6,.5)
end

local maintemp = {}
function addToAltMenu(label,func)
	if(label != nil and func != nil) then
		for k,v in pairs(maintemp) do
			if(v.label == label) then
				maintemp[k].func = func
				menutest.main()
				return
			end
		end
		altmenu.addButton(label,func)
		table.insert(maintemp,{label=label,func=func})
	end
end

function menutest.main()
	currmenu = "main"
	altmenu.textSize(10,12)
	altmenu.clearButtons()
	--altmenu.addButton("^1Suicide",function() ConsoleCommand("kill") end)
	altmenu.addButton("Speech Menu",menutest.speech)
	altmenu.addButton("Cheats",menutest.cheats)
	altmenu.addButton("Client Scripts",menutest.scripts,"client","./lua",0,10)
	if(IsAdmin()) then
		altmenu.addButton("Server Scripts",menutest.scripts,"server","./lua",0,10)
	else
		menutest.disable(altmenu.addButton("Server Scripts",function() end))
	end
	altmenu.addButton("Custom Games",include,"lua/cl_gamelist.lua")
	altmenu.addButton("Music",menutest.music)
	for k,v in pairs(maintemp) do
		altmenu.addButton(v.label,v.func)
	end
end

if(CLIENT_READY) then
	menutest.main()
else
	hook.add("ClientReady","menutest",menutest.main)
end