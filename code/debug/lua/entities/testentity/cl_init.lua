print("Loaded CL_Init\n")

local mach = LoadModel("models/weapons2/machinegun/machinegun.md3")
local sphere = LoadModel("models/powerups/health/medium_sphere.md3")

function ENT:VariableChanged()
	print("VAR CHANGED\n")
end

function ENT:Draw()
	local s = 1
	if(self.net.hitTime) then
		s = (LevelTime() - self.net.hitTime)/400
		if(s > 1) then s = 1 end
		s = 1 + (1-s)
	end
	self.rot = self.rot or 0
	self.rot = self.rot + 1
	local pos = self.Entity:GetPos()
	local gun = RefEntity()
	gun:SetModel(sphere)
	gun:SetPos(pos)
	gun:SetAngles(Vector(0,self.rot,0))
	gun:Scale(Vector(2 * s,2 * s,2 * s))
	gun:Render()
end