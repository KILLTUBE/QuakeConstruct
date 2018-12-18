local rtSize = 256
local rtSize2 = 196

render.SetupRenderTarget(1,rtSize,rtSize,true)
render.SetupRenderTarget(2,rtSize2,rtSize2,true)

local WATER_TYPE_WATER = 0
local WATER_TYPE_QUAD = .5
local WATER_TYPE_WATERANDQUAD = 1

local wType = 0
local RT = true
local data = 
[[{
	GLSL GLSL/sfx_2
	//sort nearest
	//cull disable
	{
		map $rendertarget 1
		//blendFunc add
		alphaGen vertex
		rgbGen vertex
		tcMod transform 1 0 0 -1 0 0
		//tcGen environment
	}
}]]
local renderTarget = CreateShader("f",data)

data = [[{
	GLSL GLSL/lava
	//sort nearest
	//cull disable
	{
		map textures/liquids/lavahell.tga
		blendFunc blend
		alphaGen vertex
		rgbGen vertex
		//tcGen environment
	}
}]]
local lava = CreateShader("f",data)

data = 
[[{
	//sort nearest
	//cull disable
	{
		map $rendertarget 2
		//blendFunc add
		alphaGen vertex
		rgbGen vertex
		tcMod transform 1 0 0 -1 0 0
		//tcGen environment
	}
}]]
local rtPlain = CreateShader("f",data)

local function doWaterEffect()
	local wl,liquid = entityWaterLevel(LocalPlayer())
	local inf = LocalPlayer():GetInfo()
	local pw = _CG.powerups[PW_QUAD+1] - LevelTime()
	if(liquid ~= nil) then
		if(bitAnd(liquid,CONTENTS_LAVA) ~= 0) then
			wl = wl + 2
		elseif(bitAnd(liquid,CONTENTS_SLIME) ~= 0) then
			wl = wl + 2
		end
	end
	
	pw = pw > 0
	if(wl > 2) then
		wType = WATER_TYPE_WATER
		if(pw) then
			wType = WATER_TYPE_WATERANDQUAD
		end
		return true 
	end
	if(pw) then
		wType = WATER_TYPE_QUAD
		return true
	end
	
	return false
end

local frame = 0

local function view()
	local rd = _CG.refdef
	if(rd == nil) then return end
	if(doWaterEffect()) then RT = true end
	
	if(RT) then
		rd.isRenderTarget = true
		rd.renderTarget = 1
		frame = 0
	else
		rd.isRenderTarget = false
	end
	
	render.SetRefDef(rd)
	local rth = rtSize/480
	if(RT) then
		draw.CustomScale(rtSize/640,rth)
		draw.CustomOffset(0,480 - rtSize)
	else
		draw.CustomScale(1,1)
		draw.CustomOffset(0,0)
	end
end
hook.add("PostView","cl_rt2",view)

local function tpass(m)
	for i=0, 360, 45 do
		local a = i/57.3
		draw.Rect(math.cos(a)*m,math.sin(a)*m,640,480,renderTarget)
	end
end

local lqin = 0
local waterTime = 0
local waterOutTime = 0
local function post()
	draw.CustomScale(1,1)
	draw.CustomOffset(0,0)
	if(_CG == nil) then return end
	local lt = LevelTime()
	local rd = _CG.refdef
	if(rd == nil) then return end
	
	rd.isRenderTarget = false
	rd.renderTarget = 1
	
	local dwt = (lt - waterTime) / 1000
	if(doWaterEffect() == false and dwt > 1) then RT = false frame = frame + 1 end
	if(frame > 1) then waterOutTime = lt return end
	local fade = (LevelTime() - waterOutTime) / 1000
	if(fade > 1) then fade = 1 end
	
	local level,liquid = entityWaterLevel(LocalPlayer())
	if(liquid ~= 0) then
		lqin = liquid
	else
		liquid = lqin
	end
	
	if(level == 0) then
		liquid = 0
	end
	
	render.ForceCommands()
	render.UpdateRenderTarget(1)
	
	render.SetRefDef(rd)
	
	local damageTime = (lt - _CG.damageTime) / 2000
	if(damageTime > 1) then damageTime = 1 end
	local s = (_CG.damageX/2) * (1-damageTime);
	local t = (_CG.damageY/2) * (1-damageTime);
	if(doWaterEffect()) then 
		waterTime = lt
	end
	
	--print(wType .. "\n")
	
	local rtoff = 480 - rtSize2
	draw.SetColor(0,0,0,1)
	draw.Rect(0,0,640,480)
	draw.SetColor(.5 + s,.5 + t,wType,(1-dwt)*fade)
	draw.Rect(0,rtoff,rtSize2,rtSize2,renderTarget)
	local a = .4
	if(level == 2) then
		a = .6
	elseif(level == 3) then
		a = .8
	end
	if(bitAnd(liquid,CONTENTS_LAVA) ~= 0) then
		draw.SetColor(1,.7,.3,((1-dwt)*fade) * a)
		draw.Rect(0,rtoff,rtSize2,rtSize2,lava)
	elseif(bitAnd(liquid,CONTENTS_SLIME) ~= 0) then
		draw.SetColor(.4,1,0,((1-dwt)*fade) * a)
		draw.Rect(0,rtoff,rtSize2,rtSize2,lava)	
	end
	
	render.ForceCommands()
	render.UpdateRenderTarget(2)
	
	draw.SetColor(1,1,1,1)
	draw.Rect(0,0,640,480,rtPlain)
end
hook.add("PostDraw","cl_rt2",post)