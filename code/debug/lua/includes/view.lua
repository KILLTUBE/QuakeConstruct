local vpos = Vector()
local vang = Vector()
local bpos = Vector()
local bang = Vector()
local vfovx = 0
local vfovy = 0
function ApplyView(pos,ang,fovx,fovy)
	pos = pos or Vector()
	ang = ang or Vector()
	fovx = fovx or vfovx
	fovy = fovy or vfovy
	
	--print("TFORM: " .. tostring(ang) .. "\n-" .. tostring(vang) .. "\n")
	
	vpos = vpos + (pos - bpos)
	vang = vang - getDeltaAngle3(bang,ang)
	
	vfovx = vfovx + (fovx - vfovx)
	vfovy = vfovy + (fovy - vfovy)
end

local function tform(pos,ang,fovx,fovy)
	return {Vectorv(bpos),Vectorv(bang),fovx,fovy}
end

function _ViewCalc(pos,ang,fovx,fovy)
	if(_CG == nil) then return end
	bpos = pos
	bang = ang
	vpos = Vectorv(pos)
	vang = Vectorv(ang)
	vfovx = fovx
	vfovy = fovy
	--print("CALL\n")
	CallHookArgTForm("CalcView",tform,vpos,vang,fovx,fovy)
	--print("DONE\n")
	
	local def = {
		origin = vpos,
		angles = vang,
		fov_x = vfovx,
		fov_y = vfovy,
	}
	render.SetRefDef(def)
end