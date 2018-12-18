local function messageAll(msg)
	for k,v in pairs(GetAllPlayers()) do
		v:SendMessage(msg,true)
	end
end

messageAll("5")
Timer(1,messageAll,"4")
Timer(2,messageAll,"3")
Timer(3,messageAll,"2")
Timer(4,messageAll,"1")
Timer(5,messageAll,"FIRE!")

for i=1, 4 do
	for k,v in pairs(GetAllEntities()) do
		if(string.find(v:Classname(),"shooter_")) then
			Timer(5+(math.random(2,40) / 10),v.Fire,v)
		end
	end
end
