local function PlayerDamaged(self,inflictor,attacker,damage,meansOfDeath,dir,pos)
	if(self:GetHealth() <= 0 and self:GetHealth() > -50) then
		--CreateExplosion(self:GetPos() + Vector(0,0,5),200,6,200,self)
		return self:GetHealth() - 100
	end
end

hook.add("PostPlayerDamaged","yo",PlayerDamaged)

if(CLIENT) then
	local t = 0
	local sp = Spring(Vector(10),Vector(320,240),Vector(.4),Vector(.85),Vector(160,0))
	function d2d()
		t = t + 1*Lag()
		local x = sp:GetValue().x
		local y = sp:GetValue().y
		--draw.Rect(x,y,20,20)
		draw.BeveledRect(x,y,20,20,
						 .4,.6,.2,1,
						 .2,2)
		sp:Update(true)
	end
	hook.add("Draw2D","yo.lua",d2d)
end