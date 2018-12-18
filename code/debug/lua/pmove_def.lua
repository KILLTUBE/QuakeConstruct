if(SERVER) then
	downloader.Add("lua/pmove_def.lua")
end
function PlayerMove(pm,walk,forward,right,up)
	--PM_Accelerate(Vector(0,0,1),4,10)
	--print(tostring(up) .. "\n")
	local mx,my,mz = pm:GetMove()
	if(pm:WaterLevel() > 1) then
		PM_WaterMove()
	elseif(walk) then
		PM_WalkMove()
	else
		PM_AirMove()
	end
	--PM_FlyMove()
	--PM_AirMove()
	
	PM_Accelerate(Vector(0,0,1),mz*2,mz*2)
	
	return true
end
hook.add("PlayerMove","pmove_def.lua",PlayerMove)