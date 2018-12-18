local number = ""
local store = 0
local store2 = nil
local store3 = nil
local calc = UI_Create("frame")
local currf = 0
calc:SetSize(200,350)
calc:SetTitle("Calculator")
calc:CatchMouse(true)

local text = UI_Create("label",calc)
text:SetPos(0,0)
text:SetSize(200,20)
text:SetText("0")
text:SetTextSize(10,20)
text:TextAlignRight()

local text2 = UI_Create("label",calc)
text2:SetPos(0,20)
text2:SetSize(200,20)
text2:SetText("")
text2:SetTextSize(10,20)
text2:TextAlignRight()

local text3 = UI_Create("label",calc)
text3:SetPos(0,40)
text3:SetSize(200,20)
text3:SetText("")
text3:SetTextSize(10,20)
text3:TextAlignRight()

local function f_str()
	if(currf == 1) then return "+" end
	if(currf == 2) then return "-" end
	if(currf == 3) then return "x" end
	if(currf == 4) then return "/" end
	return ""
end


local function numberPress(n)
	number = number .. tostring(n)
	
	if(currf != 0) then
		store2 = tonumber(number)
		text:SetText(store)
		text2:SetText(f_str() .. number)
	else
		store = tonumber(number)
		text:SetText(number)
	end
end

local function makeNumberButton(n,s,x,y)
	local b = UI_Create("button",calc)
	b:SetText(tostring(n))
	b:SetSize(s,s)
	b:SetPos(x,y)
	b:TextAlignCenter()
	b:SetTextSize(20)
	b.DoClick = function()
		numberPress(n)
	end
	return b
end

local function makeFuncButton(func,s,x,y,label)
	local b = UI_Create("button",calc)
	b:SetText(label)
	b:SetSize(s,s)
	b:SetPos(x,y)
	b:TextAlignCenter()
	b:SetTextSize(20)
	b.DoClick = function()
		pcall(func)
	end
	return b
end

local didEQ = false
local function f_eq()
	if(store != nil) then
		print(store .. "\n")
		local n = store
		if(store2 != nil) then
			print(store .. " | " .. store2 .. " | " .. currf .. "\n")
			store3 = n
			if(currf == 1) then
				n = n + store2
			elseif(currf == 2) then
				n = n - store2
			elseif(currf == 3) then
				n = n * store2
			elseif(currf == 4) then
				n = n / store2
			end
		end
		store = n
		if(store3 != nil) then
			text:SetText(tostring(store3))
			text3:SetText(tostring(store))
			if(store3 == 9000 and store > 9000) then
				text3:SetText("OVER NINETHOUSAND!!")
			elseif(string.find(tostring(store),"INF")) then
				text3:SetText("DIVIDE BY ZERO")
			end
		else
			text:SetText(tostring(store))
		end
	end
end

local lastf = 0
local function f_start()
	if(lastf != currf or didEQ) then
		store2 = nil
		store3 = nil
		lastf = currf
		text2:SetText("")
		text3:SetText("")
	end
	text2:SetText(f_str())
	number = ""
	text:SetText("0")
end

local function f_add()
	currf = 1
	f_start()
	f_eq()
end

local function f_minus()
	currf = 2
	f_start()
	f_eq()
end

local function f_mul()
	currf = 3
	f_start()
	f_eq()
end

local function f_div()
	currf = 4
	f_start()
	f_eq()
end

local function f_clear()
	number = ""
	store = 0
	store2 = nil
	store3 = nil
	text:SetText("0")
	text2:SetText("")
	text3:SetText("")
	currf = 0
	lastf = 0
end

local function f_decimal()
	numberPress(".")
end

local function f_flop()
	if(string.sub(number,0,1) == "-") then
		number = string.sub(number,2,string.len(number))
	else
		number = "-" .. number
	end
	
	if(currf != 0) then
		store2 = tonumber(number)
		text:SetText(store)
		text2:SetText(f_str() .. number)
	else
		store = tonumber(number)
		text:SetText(number)
	end
end

local bx,by = 0,60
local size = 50
makeNumberButton(1,size,bx,by) bx = bx + size
makeNumberButton(2,size,bx,by) bx = bx + size
makeNumberButton(3,size,bx,by) bx = bx + size
makeFuncButton(f_add,size,bx,by,"+") bx = bx + size
bx = 0
by = by + size
makeNumberButton(4,size,bx,by) bx = bx + size
makeNumberButton(5,size,bx,by) bx = bx + size
makeNumberButton(6,size,bx,by) bx = bx + size
makeFuncButton(f_minus,size,bx,by,"-")
bx = 0
by = by + size
makeNumberButton(7,size,bx,by) bx = bx + size
makeNumberButton(8,size,bx,by) bx = bx + size
makeNumberButton(9,size,bx,by) bx = bx + size
makeFuncButton(f_mul,size,bx,by,"x")
bx = 0
by = by + size
makeNumberButton(0,size,bx,by) bx = bx + size
makeFuncButton(f_decimal,size,bx,by,".") bx = bx + size
makeFuncButton(f_clear,size,bx,by,"C") bx = bx + size
makeFuncButton(f_div,size,bx,by,"/") bx = bx + size

bx = 0
by = by + size

makeFuncButton(f_flop,size,bx,by,"-+"):SetSize(100,50) bx = bx + 100
makeFuncButton(function() f_eq() didEQ = true end,size,bx,by,"="):SetSize(100,50) bx = bx + 100