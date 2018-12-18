ENT.Base = "lua_gpanel"

downloader.add("lua/entities/lua_rtpanel/cl_init.lua")

function ENT:Initialized()
	self.BaseClass.Initialized(self)
	print("RTPanel Init\n")

	local targets = FindEntityTargets(self.Entity)
	if(#targets == 0) then print("^1RTPanel has no targets!\n") end
	
	self.net.camtarget = targets[1]:EntIndex()
end