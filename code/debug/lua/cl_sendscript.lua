local str = ""
file = io.open("lua/demoscript.lua", "r")
if(file != nil) then
	for line in file:lines() do
		str = str .. line
	end
	file:close()
end

SendString("clientscript " .. base64.enc(str))