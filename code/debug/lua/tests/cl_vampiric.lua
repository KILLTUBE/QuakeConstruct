if(CLIENT) then 
	local notifyt = 0;
	local notify2 = "";
	local val = 0
	local y = 0
	local title = 1
	local thp = 0
	local tname = 0
	local ttime = 0
	local gb = 0		
	
	local function draw2D()
		if(notifyt > 0) then
			draw.SetColor(math.abs(math.sin(CurTime()*10)),math.abs(math.cos(CurTime()*10)),0,notifyt)
			draw.Text(10,100+y,"+" .. val .. notify2,22,20)
			if(val <= 0) then
				notifyt = notifyt - 0.01
				y = y + 1
				gb = 0
				notify2 = ""
			end
		else
			val = 0
		end
		if(title > 0) then
			title = title - 0.002
			local text = "Vampiric Mod"
			draw.SetColor(.4,1,.2,title)
			draw.Text(320-(20*string.len(text)),240-20,text,40,40)			
		end
		if(ttime > 0) then
			ttime = ttime - 0.04
			local text = tname
			local text2 = "" .. thp
			draw.SetColor(1,1,1,ttime)
			draw.Text(320-(10*string.len(text)),240-10,text,20,20)
			draw.SetColor(1,0,0,ttime)
			
			draw.Text(320-(5*string.len(text2)),240+15,text2,10,14)
		end
	end
	hook.add("Draw2D","Vampiric",draw2D)

	local function messagetest(str)
		local args = string.Explode(" ",str)
		if(args[1] == "damagegiven") then
			val = val + tonumber(args[2])
			notifyt = 1
			y = 0
		end
		if(args[1] == "sub") then
			val = val - tonumber(args[2])
		end
		if(args[1] == "target") then
			thp = tonumber(args[2])
			tname = args[3]
			ttime = 1
			if(tname == "body") then
				gb = gb + 1
				notify2 = " INSTA-GIB BONUS!";
				if(gb > 1) then
					notify2 = " INSTA-GIB BONUS x" .. gb;
				end
			end
		end
	end
	hook.add("MessageReceived","Vampiric",messagetest)
return 
end