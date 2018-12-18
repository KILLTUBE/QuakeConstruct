local npos = Vector()
local nang = Vector()
local lastAngle = Vector()
local offsetAngle = Vector()
local first = true

local function drawPlayer(pl)
	if(pl:GetInfo().health <= -40) then return end
	local legs,torso,head = LoadPlayerModels(pl)
	legs:SetPos(pl:GetPos())
	
	util.AnimatePlayer(pl,legs,torso)
	util.AnglePlayer(pl,legs,torso,head)

	--torso:Scale(Vector(1.2,1.2,1.2))
	
	torso:PositionOnTag(legs,"tag_torso")
	head:PositionOnTag(torso,"tag_head")
	
	util.PlayerWeapon(pl,torso)
	
	--head:Scale(Vector(2,2,2))
	
	legs:Render()
	torso:Render()
	head:Render()
end

local function d3d()
	drawPlayer(LocalPlayer())
end
hook.add("Draw3D","cl_demomove",d3d)

local vpos = Vector(0,0,0)
local function view(pos,ang,fovx,fovy)
	if(!_CG) then return end

	vpos = vpos + (npos - vpos) * .2
	pos = vpos;
	
	local p = LocalPlayer():GetPos()
	local f,r,u = AngleVectors(nang)
	
	p = p + r * -offsetAngle.y
	p = p + u * -offsetAngle.x
		
	local vang = VectorToAngles(VectorNormalize(p - pos))
	nang = nang + getDeltaAngle3(vang,nang)*.2
	ang = nang
	
	offsetAngle = offsetAngle + (Vector(0,0,0) - offsetAngle) * 0.005
	
	ApplyView(pos,ang)
end
hook.add("CalcView","cl_demomove",view)

local keys = {}
local function keyed(key,state)
	keys[key] = state
end
hook.add("KeyEvent","cl_demomove",keyed)

function UserCommand(pl,angle,fm,rm,um,buttons,weapon)
	local delta = getDeltaAngle3(angle,lastAngle)
	lastAngle = angle
	if(first == true) then
		delta = Vector(0,0,0)
		first = false
	end
	offsetAngle = offsetAngle + delta
	
	--nang = angle
	
	local f,r,u = AngleVectors(nang)
	npos = npos + (f * fm/10)
	npos = npos + (r * rm/10)
	npos = npos + (Vector(0,0,1) * um/10)
	
	print("UC: " .. tostring(delta) .. "\n")
	--print("UC: " .. tostring(angle) .. " " .. fm .. ", " .. rm .. ", " .. um .. "\n")
end
hook.add("UserCommand","cl_demomove",UserCommand)

local function ShouldDraw(str)
	if(str == "HUD_DRAWGUN") then
		return false
	end
	if(str == "HUD") then
		--return false
	end
end
hook.add("ShouldDraw","cl_junk",ShouldDraw)