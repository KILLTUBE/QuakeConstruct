local users = {}

function PlayerUseKeyDown(pl)
	if(type(pl) == "table") then
		if(pl.EntIndex == nil) then return false end
		local id = pl:EntIndex()+1
		if(id > 0 and id <= #users) then
			return (users[id] == 1)
		end
	elseif(type(pl) == "number") then
		pl = pl + 1
		if(pl > 0 and pl <= #users) then
			return (users[pl] == 1)
		end
	end
	return false
end

if(SERVER) then
	message.Precache("input_playeruse")

	local function sendUse(index,b)
		local msg = Message("input_playeruse")
		message.WriteShort(msg,index)
		message.WriteShort(msg,b)
		for k,v in pairs(GetAllPlayers()) do
			SendDataMessage(msg,v)
		end
	end
	
	local function think()
		for k,v in pairs(GetAllPlayers()) do
			local id = v:EntIndex()+1
			users[id] = users[id] or 0
			local buttons = bitAnd(v:GetInfo().buttons,32)
			if(buttons == 32) then
				if(users[id] == 0) then
					print("USE: " .. id .. "\n")
					CallHook("Use",true,v)
					users[id] = 1
					sendUse(id,1)
				end
			else
				if(users[id] == 1) then
					print("UNUSE: " .. id .. "\n")
					CallHook("Use",false,v)
					users[id] = 0
					sendUse(id,0)
				end
			end
		end
	end
	hook.add("Think","input",think)
else
	local mouseDown = false
	local mx = 0
	local my = 0
	local cursorOn = false
	local keys = {}
	local usepress = false

	function KeyIsDown(k)
		if(keys[k] == true) then return true end
		return false
	end

	local function moused(x,y)
		if(!cursorOn) then return end
		mx = mx + x
		my = my + y
		
		if(mx > 640) then mx = 640 end
		if(mx < 0) then mx = 0 end
		
		if(my > 480) then my = 480 end
		if(my < 0) then my = 0 end
	end
	hook.add("MouseEvent","input",moused)

	function MouseFocused()
		return cursorOn
	end

	function MouseDown()
		return mouseDown
	end

	function GetXMouse() return mx end
	function GetYMouse() return my end

	function GetMouseX() return mx end
	function GetMouseY() return my end

	function SetMousePos(x,y)
		mx = x
		my = y
	end

	function EnableCursor(b)
		if(b) then
			util.LockMouse(true)
			cursorOn = true
		else
			util.LockMouse(false)
			cursorOn = false
		end
	end

	local function keyed(key,state)
		keys[key] = state
		if(key == K_MOUSE1) then
			if(state == false) then
				if(mouseDown != state) then
					mouseDown = state
					CallHook("MouseUp")
				end
			else
				if(mouseDown != state) then
					mouseDown = state
					CallHook("MouseDown")
				end
			end
		end
	end
	hook.add("KeyEvent","input",keyed)

	local function UserCmd(pl,angle,fm,rm,um,buttons,weapon)
		if(usepress) then buttons = bitOr(buttons,32) end
		
		--print(buttons .. "\n")
		
		SetUserCommand(angle,fm,rm,um,buttons,weapon)
	end
	hook.add("UserCommand","sidescroller",UserCmd)

	local function press()
		if(!usepress) then
			--print("PRESS\n")
			usepress = true;
			CallHook("Use",true,LocalPlayer())
		end
	end

	local function depress()
		if(usepress) then
			--print("DEPRESS\n")
			usepress = false
			CallHook("Use",false,LocalPlayer())
		end
	end
	concommand.Add("+use",press)
	concommand.Add("-use",depress)
	
	local function NetVar(msgid)
		if(msgid == "input_playeruse") then
			local tindex = message.ReadShort()
			local down = message.ReadShort()
			users[tindex] = down
		end
	end
	hook.add("HandleMessage","input",NetVar)
end