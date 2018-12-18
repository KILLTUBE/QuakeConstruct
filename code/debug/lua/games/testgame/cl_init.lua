local function line(x1,y1,x2,y2)
	local dx = x2 - x1
	local dy = y2 - y1
	local cx = x1 + dx/2
	local cy = y1 + dy/2
	local rot = math.atan2(dy,dx)*57.3
	
	draw.RectRotated(cx,cy,math.sqrt(dx*dx + dy*dy),2,mark,rot)
end

local function drawLines(v1,v2,v3,v4,v5,v6,v7,v8)

end

local function drawBox(v1,v2,v3,v4,v5,v6,v7,v8)
	line(v1.x,v1.y,v2.x,v2.y)
	line(v2.x,v2.y,v3.x,v3.y)
	line(v3.x,v3.y,v4.x,v4.y)
	line(v4.x,v4.y,v1.x,v1.y)		
	line(v5.x,v5.y,v6.x,v6.y)
	line(v6.x,v6.y,v7.x,v7.y)
	line(v7.x,v7.y,v8.x,v8.y)
	line(v8.x,v8.y,v5.x,v5.y)		
	line(v1.x,v1.y,v5.x,v5.y)
	line(v2.x,v2.y,v6.x,v6.y)
	line(v3.x,v3.y,v7.x,v7.y)
	line(v4.x,v4.y,v8.x,v8.y)
end

local function BoundingBox(model,pos,angle)
	local f,r,u = AngleVectors(angle or Vector(0,0,0))
	local mins,maxs = render.ModelBounds(model)
	local ts1 = VectorToScreen(pos + (f*maxs.x) + (r*mins.y) + (u*mins.z))
	local ts2 = VectorToScreen(pos + (f*maxs.x) + (r*maxs.y) + (u*mins.z))
	local ts3 = VectorToScreen(pos + (f*mins.x) + (r*maxs.y) + (u*mins.z))
	local ts4 = VectorToScreen(pos + (f*mins.x) + (r*mins.y) + (u*mins.z))
	
	local ts5 = VectorToScreen(pos + (f*maxs.x) + (r*mins.y) + (u*maxs.z))
	local ts6 = VectorToScreen(pos + (f*maxs.x) + (r*maxs.y) + (u*maxs.z))
	local ts7 = VectorToScreen(pos + (f*mins.x) + (r*maxs.y) + (u*maxs.z))
	local ts8 = VectorToScreen(pos + (f*mins.x) + (r*mins.y) + (u*maxs.z))
	
	if(ts1.z < 0 and ts2.z < 0 and ts3.z < 0 and ts4.z < 0 and
	   ts5.z < 0 and ts6.z < 0 and ts7.z < 0 and ts8.z < 0) then
		draw.SetColor(1,1,1,1)
		drawBox(ts1,ts2,ts3,ts4,ts5,ts6,ts7,ts8)
	end
end

function GAME:Draw2D()
	--[[for k,v in pairs(GetEntitiesByClass('item')) do
		BoundingBox(util.GetItemModel(v:GetModelIndex()),v:GetPos(),v:GetLerpAngles())
	end]]
	--[[for k,v in pairs(GetEntitiesByClass('player')) do
		local legs,torso,head = LoadPlayerModels(v)
		legs:SetPos(v:GetPos())
		
		util.AnimatePlayer(v,legs,torso)
		util.AnglePlayer(v,legs,torso,head)

		--torso:Scale(Vector(1.2,1.2,1.2))
		
		torso:PositionOnTag(legs,"tag_torso")
		head:PositionOnTag(torso,"tag_head")
		
		BoundingBox(legs:GetModel(),legs:GetPos(),legs:GetAngles())
		BoundingBox(torso:GetModel(),torso:GetPos(),torso:GetAngles())
		BoundingBox(head:GetModel(),head:GetPos(),head:GetAngles())
	end]]
end

function GAME:Draw3D()

end