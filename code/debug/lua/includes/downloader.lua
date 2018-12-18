if(downloader == nil) then
	downloader = {}
	downloader.queue = {}
end

DOWNLOAD_BUFFER_SIZE = 256

FILE_PENDING = 1
FILE_DOWNLOADING = 2
FILE_FINISHED = 3

DLFile = {}

function newFile(name,md5,lines)
	local o = {}

	setmetatable(o,DLFile)
	DLFile.__index = DLFile
	
	o.name = name
	o.md5 = md5
	o.status = FILE_PENDING
	o.isfile = true
	o.lines = lines
	
	return o;
end

function DLFile.__eq(a,b)
	if(a == nil or b == nil) then return false end
	if(a.isfile != true or b.isfile != true) then return false end
	return (a.name == b.name and a.md5 == b.md5)
end

function DLFile:Copy()
	return newFile(self.name,self.md5,self.lines)
end

function getFileByName(file,tab)
	for k,v in pairs(tab) do
		if(v.name == file.name) then return v end
	end
	return nil
end

local function fixLine(line)
	if(string.find(line,"//__DL_BLOCK")) then block = true return end
	if(string.find(line,"//__DL_UNBLOCK")) then block = false return end
	if(line == "--[[") then block = true return end
	if(line == "]]") then block = false return end
	if(block == true) then return nil end
	if(line != "" and line != " " and line != "\n") then
		line = string.Replace(line,"\t","")
		line = string.Replace(line,"\r","")
		line = string.Replace(line,"\n","")
		if(line != "" and line != " " and line != "\n") then
			return line .. "\n" --"_NL_"
		end
	end	
	return nil
end

if(SERVER) then
	message.Precache("__fileheader")
	message.Precache("__fileline")
	message.Precache("__queuefile")
	message.Precache("__runfile")
	
	local lastNumPlayers = 0
	
	local function cleanFilename(f)
		local out = string.lower(f)
		if(!string.find(out,".lua")) then
			out = out .. ".lua"
		end

		local ex = string.Explode("/",out)
		return ex[#ex]
	end

	local block = false
	

	function downloader.add(filename,force)
		if(filename != nil and type(filename) == "string") then
			if(!fileExists(filename)) then filename = filename .. ".lua" end
			if(!fileExists(filename)) then filename = "lua/" .. filename end
			print(filename .. "\n")
			if(fileExists(filename)) then
				local md5sum = fileMD5(filename,function(l,n) return (fixLine(l) != nil) end)
				local flines = {}--countFileLines(filename,function(l,n) return (fixLine(l) != nil) end)
				
				file = io.open(filename, "r")
				if(file != nil) then
					local lines = 0
					local buffer = ""
					for line in file:lines() do
						local fixed = fixLine(line)
						if(fixed != nil) then
							for k,v in pairs(string.ToTable(fixed)) do
								buffer = buffer .. v
								if(string.len(buffer) > DOWNLOAD_BUFFER_SIZE) then
									table.insert(flines,buffer)
									buffer = ""
								end
							end
						end
					end
					if(string.len(buffer) > 0) then
						table.insert(flines,buffer)
					end
					file:close()
				else
					error("File not found: '" .. filename .. "'.")
					return
				end	
				
				local file = newFile(filename,md5sum,flines)
				if(!table.HasValue(downloader.queue,file) or force) then
					local exist = getFileByName(file,downloader.queue)
					if(exist) then
						exist.status = FILE_PENDING
						exist.md5 = md5sum
						exist.lines = flines
						debugprint("File updated in queue: '" .. file.name .. "'\n")
						downloader.notify(force)
						return 
					end
					table.insert(downloader.queue,file)
					debugprint("File added to queue: '" .. file.name .. "'\n")
					downloader.notify()
				else
					debugprint("Did nothing with file: '" .. file.name .. "'\n")
				end
			else
				error("File not found: '" .. filename .. "'.")
			end
		else
			error("String expected got '" .. type(filename) .. "'.")
		end
	end
	downloader.Add = downloader.add
	
	function downloader.playerready(pl)
		if(pl == nil) then return false end
		if(pl:GetTable() == nil) then return false end
		if(pl:GetTable().ready != true) then return false end
		return true
	end
	
	function downloader.putqueue(pl,file)
		local msg = Message(pl,"__queuefile")
		message.WriteString(msg,base64.enc(file.name))
		message.WriteShort(msg,#file.lines)
		SendDataMessage(msg)
	end
	
	function downloader.runfile(pl,file)
		local msg = Message(pl,"__runfile")
		message.WriteString(msg,base64.enc(file.name))
		SendDataMessage(msg)
	end
	
	function downloader.putplayerfile(pl,filex,force)
		if(!downloader.playerready(pl)) then return end
		local ptab = pl:GetTable()
		local fqueue = ptab.files
		if(!table.HasValue(fqueue,filex) or filex.status == FILE_PENDING or force) then
			local pfile = getFileByName(filex,fqueue)
			if(pfile != nil) then
				if(pfile.status == FILE_FINISHED and !force and pfile.md5 == filex.md5) then
					debugprint("Executed Player File " .. pfile.name .. ".\n")
					downloader.runfile(pl,pfile)
					return
				end
				if(pfile.status != FILE_DOWNLOADING) then
					debugprint("Updated Player File " .. pfile.name .. ".\n")
					pfile.status = FILE_PENDING
					pfile.md5 = filex.md5
					pfile.lines = filex.lines
					downloader.putqueue(pl,pfile)
				end
			else
				debugprint("Added Player File " .. filex.name .. ".\n")
				filex = filex:Copy()
				table.insert(ptab.files,filex:Copy())
				downloader.putqueue(pl,filex)
			end
		end
	end
	
	function downloader.sendline(pl,line)
		local ptab = pl:GetTable()
		local fl = line
		if(fl != nil) then
			local msg = Message(pl,"__fileline")
			message.WriteString(msg,base64.enc(fl) or "")
			SendDataMessage(msg)
		end
	end
	
	function downloader.sendheader(pl,file)
		local msg = Message(pl,"__fileheader")
		message.WriteString(msg,base64.enc(file.name))
		message.WriteShort(msg,#file.lines)
		message.WriteString(msg,base64.enc(file.md5))
		SendDataMessage(msg)
	end
	
	function downloader.beginlines(pl,filex)
		if(filex == nil) then return end
		if(!fileExists(filex.name)) then return end
		--file = io.open(filex.name, "r")
		if(filex.lines != nil) then
			local lines = 0
			for _,line in pairs (filex.lines) do
				Timer(.1*lines,downloader.sendline,pl,line)
				lines = lines + 1
			end
			Timer((.1*lines) + 0.2,downloader.stopdownload,pl,filex)
		else
			downloader.stopdownload(pl,filex)
		end	
	end
	
	function downloader.stopdownload(pl,file)
		local ptab = pl:GetTable()
		if(!ptab.downloading) then return end
		debugprint("Finished Downloading: " .. file.name .. "\n")
		file.status = FILE_FINISHED
		ptab.downloading = false
		downloader.notify()
		
		--local msg = Message(pl,"__fileheader")
		--SendDataMessage(msg)
	end
	
	function downloader.begindownload(pl,file)
		local ptab = pl:GetTable()
		if(ptab.downloading) then return end
		debugprint("Sending File: " .. file.name .. "[" .. file.md5 .. "] - " .. #file.lines .. " lines.\n")
		file.status = FILE_DOWNLOADING
		ptab.downloading = true
		ptab.currentdownload = file
		Timer(.2,downloader.sendheader,pl,file)
		Timer(.4,downloader.beginlines,pl,file)
	end
	
	function downloader.updateplayer(pl)
		if(!downloader.playerready(pl)) then return end
		local ptab = pl:GetTable()
		local fqueue = ptab.files
		if(ptab.downloading) then return end
		for i=1, #fqueue do
			local v = fqueue[i]
			if(v.status == FILE_PENDING) then
				downloader.begindownload(pl,v)
				return
			end
		end
	end
	
	function downloader.notify(force)
		for _,pl in pairs(GetAllPlayers()) do
			for k,v in pairs(downloader.queue) do
				downloader.putplayerfile(pl,v,force)
			end
			downloader.updateplayer(pl)
		end
		for k,v in pairs(downloader.queue) do
			v.status = FILE_FINISHED
		end
	end
	
	local function message(str,pl)
		if(str == "__canceldownload") then
			local ptab = pl:GetTable()
			downloader.stopdownload(pl,ptab.currentdownload)
		end
	end
	hook.add("MessageReceived","__downloader.lua",message)
	
	function downloader.initplayer(pl)
		Timer(4,function()
			if(pl != nil) then
				local ptab = pl:GetTable()
				ptab.files = {}
				ptab.ready = true
				ptab.downloading = false
				ptab.currentdownload = nil
				debugprint("Initialized Player: " .. pl:GetInfo().name .. " " .. #ptab.files .. " " .. pl:EntIndex() .. "\n")
				downloader.notify()
			end
		end)
	end
	hook.add("ClientReady","__downloader.lua",downloader.initplayer)
	hook.add("Think","__downloader.lua",function()
		if(#GetAllPlayers() != lastNumPlayers) then
			if(#GetAllPlayers() > lastNumPlayers) then
				downloader.notify()
			end
			lastNumPlayers = #GetAllPlayers()
		end
	end) --A crappy way to check for new players
	
	function SendScript(script) print("^1SendScript is Depricated\n") end
elseif(CLIENT) then
	local FILENAME = "Please Wait..."
	local CONTENTS = ""
	local LINECOUNT = 0
	local LINEITER = 0
	local QUEUE = {}
	local frame = nil
	local flist = nil
	local template = nil
	local queuebuttons = {}
	local start = false
	local cancelled = false
	
	local function makeFrame()
		queuebuttons = {}
		frame = UI_Create("frame")
		local w,h = 640,480
		local pw,ph = w/2,h/3
		frame.name = "base"
		frame:SetPos((w/2) - pw/2,460 - ph)
		frame:SetSize(pw,ph)
		frame:SetTitle("Awaiting Files...")
		--frame:CatchMouse(true)
		frame:SetVisible(true)
		frame:EnableCloseButton(false)
		
		flist = UI_Create("listpane",frame)
		flist.name = "base->listpane"
		
		if(template != nil) then return end
		
		template = UI_Create("label")
		template:SetSize(100,15)
		template:SetTextSize(6)
		template:SetText("<nothing here>")
		template:TextAlignCenter()
		template:Remove()
	end

	local function update()
		local per = math.floor((LINEITER / LINECOUNT)*100)
		if(LINEITER <= 0) then per = 0 end
		if(LINECOUNT <= 0) then per = 0 end
		if(frame != nil) then frame:SetTitle("Downloading...") else return end
		local text2 = FILENAME .. "(" .. per .. "%) [" .. LINECOUNT .. " chunks]"
		
		if(#queuebuttons > #QUEUE) then 
			flist:Clear()
			queuebuttons = {}
		end
		
		while(#queuebuttons < #QUEUE) do
			template:SetFGColor(1,1,1,.6)
			template:SetText("")
			local pane = flist:AddPanel(template,true)
			table.insert(queuebuttons,pane)
		end
		
		for k,v in pairs(QUEUE) do
			local panel = queuebuttons[k]
			if(panel != nil) then
				if(k != 1) then
					local text = v[1] .. "[-" .. v[2] .. "-]"
					panel:SetFGColor(1,1,1,.6)
					panel:SetText(text)
				else
					panel:SetFGColor(1,1,1,1)
					panel:SetText(text2)
				end
			end
		end
	end
	
	local function localFile(f)
		return string.Replace(f,"/",".")
	end
	
	local function includeFile()
		local rez = "lua/downloads/" .. localFile(FILENAME)
		if(!CallHook("FileDownloaded",rez)) then
			debugprint("Execute: " .. rez .. "\n")
			local b,e = pcall(include,rez)
			if(!b) then
				debugprint("^1Script Downloader Error (Script Execution): " .. e .. "\n")
			end
		end
	end
	
	local function writeToFile()
		local rez = "lua/downloads/" .. localFile(FILENAME)
		debugprint("Writing File: '" .. rez .. "'\n")
		--CONTENTS = string.Replace(CONTENTS,"_NL_","\n")
		local file = io.open(rez,"w")
		if(file != nil) then
			file:write(CONTENTS)
			file:close()
			includeFile()
		else
			debugprint("^1Script Downloader Error (Script Copy): Unable to write file: " .. rez .. "\n")
		end
	end
	
	local function finished()
		if(#QUEUE > 0) then table.remove(QUEUE,1) end
		if(#QUEUE == 0 and frame != nil) then 
			frame:Close()
			frame = nil
			flist = nil
		end
		writeToFile()
		LINECOUNT = 0
		LINEITER = 0
		FILENAME = "Please Wait..."
		start = false
	end

	local function checkMD5(f1,md5)
		local fmd5 = fileMD5(f1,function(l,n) return (fixLine(l) != nil) end)
		fmd5 = base64.dec(base64.enc(fmd5))
		print("^3" .. base64.enc(fmd5) .. "\n")
		print("^3" .. base64.enc(md5) .. "\n")
		if(fmd5 == md5) then return true end
		return false	
	end
	
	local function checkForFile(FILENAME,md5)
		--print("^2" .. FILENAME .. "\n")
		if(checkMD5(FILENAME,md5)) then return true end
	
		local fn1 = string.Replace(FILENAME,"/",".")
		--print("^2" .. "lua/downloads/" .. fn1 .. "\n")
		if(checkMD5("lua/downloads/" .. fn1,md5)) then return true end
		return false
	end
	
	local function HandleMessage(msgid,tab)
		if(msgid == "__queuefile") then
			local name = base64.dec(message.ReadString() or "")
			local lines = message.ReadShort()
			for k,v in pairs(QUEUE) do
				if(v[1] == name) then v[2] = lines return end
			end
			table.insert(QUEUE,{name,lines})
			if(frame == nil) then
				makeFrame()
			end
			--print("F_QUEUE: " .. name .. " - " .. lines .. " lines.\n")
		elseif(msgid == "__fileheader") then
			if(#tab == 0 and start) then
				--print("CL_FINISH\n")
				finished()
				return
			end
			start = true
			local name = base64.dec(message.ReadString() or "")
			local lines = message.ReadShort()
			local md5 = base64.dec(message.ReadString() or "")
			--print("F_HEADER: " .. name .. " - " .. lines .. " lines.\n")
			CONTENTS = ""
			FILENAME = name
			LINECOUNT = lines
			LINEITER = 0
			cancelled = false
			if(checkForFile(FILENAME,md5)) then
				cancelled = true
				SendString("__canceldownload")
				includeFile(FILENAME)
			end
		elseif(msgid == "__fileline") then
			if(cancelled) then return end
			local str = base64.dec(message.ReadString() or "")
			CONTENTS = CONTENTS .. str -- .. "\n"
			LINEITER = LINEITER + 1
			--print("F_LINE: " .. str .. " [X] " .. LINEITER .. "/" .. LINECOUNT .. "\n")
			update()
			if(LINEITER == LINECOUNT) then
				--finished()
			end
		elseif(msgid == "__runfile") then
			local name = base64.dec(message.ReadString() or "")
			FILENAME = name
			includeFile()
		end
	end
	hook.add("HandleMessage","__downloader.lua",HandleMessage)
end