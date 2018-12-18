--[[for k,v in pairs(_G) do
	print(k .. "\n")
end]]
local TOTAL_LOADTIME = 0

local function includex(s)
	local t_start = ticks()
	local ext = "lua"
	local path = "lua/includes"
	if(COMPILED) then
		ext = "luc"
		path = "lua/includes/compiled"
	end
	local b,e = pcall(include,path .. "/" .. s .. "." .. ext)
	if(!b) then
		print("^1Failure To Load \"" .. s .. "\":\n" .. e .. "\n")
	else
		if(COMPILED) then
			--print("^2Loaded[compiled]: " .. s .. "\n")
		else
			--print("^2Loaded: " .. s .. "\n")
		end
	end
	local t_end = ticks()
	local t_rez = ticksPerSecond()
	local loadtime = (t_end - t_start) / t_rez
	TOTAL_LOADTIME = TOTAL_LOADTIME + loadtime
	
	print("^6---" .. s .. " took " .. loadtime .. " seconds. ::: " .. TOTAL_LOADTIME .. "\n")
end

--[[includex("tools")
includex("extensions/init")
includex("vector")
includex("angles")
includex("hooks")
if(CLIENT) then includex("input") end
if(CLIENT) then includex("view") end

_qlimit()
]]
--if(true) then return end

local toadd = {}

concommand = {}
concommand.Add = function(strcmd,func) table.insert(toadd,{strcmd,func}) end

includex("linkedlist")
includex("tools")
includex("extensions/init")
includex("base64")
includex("file")
includex("hooks")
includex("treeparser")
includex("entities")
includex("timer")
includex("enum")
includex("vector")
includex("spring")
includex("matrix")
includex("angles")
--includex("messages")
includex("messageproto")
includex("netvars")
--includex("scriptmanager")
includex("downloader2")
includex("commands")
if(CLIENT) then includex("sound") end
if(CLIENT) then includex("shader") end
if(CLIENT) then includex("sequence") end
if(CLIENT) then includex("animation") end
if(CLIENT) then includex("model") end
if(CLIENT) then includex("sprite") end
if(CLIENT) then includex("poly") end
if(CLIENT) then includex("fonts") end
if(CLIENT) then includex("view") end
if(CLIENT) then includex("qml") end
if(CLIENT) then includex("particletools") end
includex("input")
includex("packs")
if(SERVER) then
	includex("custom")
else
	if not (RESTARTED) then
		hook.add("RegisterGraphics","includes",function()
			--Load custom stuff during the graphics step.
			print("^6Registering Graphics\n")
			__RESOURCE_REGISTERING = true
			includex("custom")
			__RESOURCE_REGISTERING = false
		end)
	else
		includex("custom")
	end
end
includex("persistance")
--require "includes/functiondump"

_SendDataMessage = nil
_Message = nil
hook.lock("_HandleMessage")

for k,v in pairs(toadd) do
	concommand.Add(v[1],v[2])
end

ENTITYNUM_NONE = 1023
ENTITYNUM_WORLD	= 1022
ENTITYNUM_MAX_NORMAL = 1022

if(SERVER) then
	local readies = {}
	local function message(str,pl,clientnum)
		local pli = clientnum + 1
		if(str == "_clientready") then
			if not (readies[pli]) then
				print("CLIENT IS READY: " .. pli .. " | " .. clientnum .. "\n")
				CallHook("ClientReady",clientnum)
				--Timer(3.8,CallHook,"ClientReady",pl)
				if(pl:IsAdmin()) then
					Timer(1,pl.SendString,clientnum,"_admin")
				else
					Timer(1,pl.SendString,clientnum,"_verify")
				end
				readies[pli] = true
				Timer(20,function()
					readies[pli] = false
				end)
			end
		elseif(str == "_demostarted") then
			CallHook("DemoStarted",pl)
		elseif(str == "_clientfinished") then
			CallHook("ClientShutdownLua",pl)
		end
	end
	hook.add("MessageReceived","includes",message)
else
	local timers = {}
	--[[hook.add("InitialSnapshot","includes",function() 
		--Keep trying to tell the server that we're ready
		for i=1, 20 do
			local t = Timer(i,function() 
				SendString("_clientready")
				print("MSGConnect Attempt: " .. i .. "\n")
			end)
			table.insert(timers,t)
		end
	end)]]
	
	local files = {}
	local currentFile = 0
	local num_files = 0
	local DOWLOADING = false
	local function update()
		num_files = 0
		for k,v in pairs(files) do num_files = num_files + 1 end
	end
	
	function DrawDownloads()
		if(num_files == 0) then return end
		
		draw.SetColor(0,0,0,.8)
		draw.Rect(0,0,640,480)
		local y = 10
		for k,v in pairs(files) do
			if(v ~= nil) then
				draw.SetColor(1,1,.5,.8)
				if(k == currentFile) then
					draw.SetColor(1,1,1,1)
				end
				draw.Text(25,y,k .. ": " .. v.got .. "/" .. v.lines .. "",8,10)
				y = y + 10
			end
		end
	end
	
	hook.add("DLFileQueued","includes",function(name,lines)
		files[name] = {lines = lines, got = 0}
		update()
		DOWLOADING = true
	end)
	
	hook.add("DLFileAction","includes",function(name,lines,md5,accept)
		files[name] = files[name] or {lines = 0, got = 0}
		files[name].lines = lines or files[name].lines
		files[name].md5 = md5
		if(accept == false) then
			files[name] = nil
		else
			currentFile = name
		end
		update()
	end)
	
	hook.add("DLFileLine","includes",function(line)
		if(files[currentFile] == nil) then return end
		local file = files[currentFile]
		file.got = file.got + 1
		if(file.got == file.lines) then
			files[currentFile] = nil
		else
			files[currentFile] = file
		end
		update()
	end)
	
	local LOADED = false
	hook.add("Loaded","includes",function()
		SendString("_clientready")
		for i=1, 10 do
			Timer(i*2,function()
				if(DOWLOADING == false) then
					print("Notify Attempt: " .. i .. "\n")
					SendString("_clientready")
				end
			end)
		end
		LOADED = true
	end)
	
	hook.add("DrawInfo","includes",function()
		if(LOADED) then
			DrawDownloads()
		end
	end,-9999)
	
	hook.add("DownloadsFinished","includes",function()
		_setprimed()
		print("Downloads Are Finished\n")
	end,9999)
	
	hook.add("Draw2D","includes",DrawDownloads)
	
	local called = false
	
	local function demo()
		SendString("_demostarted")
	end
	hook.add("DemoStarted","includes",demo)	
	
	local ADMIN = false
	local function message(str,pl)
		if(str == "_admin") then
			print("Admin Verified!\n")
			ADMIN = true
			CallHook("ClientReady")
			CLIENT_READY = true
			called = true
			for k,v in pairs(timers) do StopTimer(v) end
			print("Got Server Validation\n")
		elseif(str == "_verify") then
			for k,v in pairs(timers) do StopTimer(v) end
			print("Got Server Validation\n")
		end
	end
	hook.add("MessageReceived","includes",message)
	
	local function finish()
		SendString("_clientfinished")
	end
	hook.add("Shutdown","includes",finish)
	
	
	Timer(10,function() if(!called) then 
		CallHook("ClientReady")
		CLIENT_READY = true
	end end)
	
	if(RESTARTED) then
		SendString("_clientready")
	end
	
	function IsAdmin()
		return ADMIN
	end
end

hook.reserve("includes")

_GBASELINE = table.Copy(_G)