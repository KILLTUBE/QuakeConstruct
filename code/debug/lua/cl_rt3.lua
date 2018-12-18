render.SetupRenderTarget(2,640,480,true)
local data = 
[[{
	//sort nearest
	//cull disable
	{
		map $rendertarget 2
		blendFunc blend
		alphaGen vertex
		rgbGen vertex
		tcMod transform 1 0 0 -1 0 0
		//tcGen environment
	}
}]]
local renderTarget = CreateShader("f",data)

local function tpass(m)
	for i=0, 360, 45 do
		local a = i/57.3
		draw.Rect(math.cos(a)*m,math.sin(a)*m,640,480,renderTarget)
	end
end

local function post()
	if(_CG == nil) then return end
	local lt = LevelTime()
	local rd = _CG.refdef
	if(rd == nil) then return end
	
	render.ForceCommands()
	
	draw.SetColor(1,1,1,.99)
	draw.Rect(0,0,640,480,renderTarget)
	
	render.ForceCommands()
	render.UpdateRenderTarget(2)
	rd.isRenderTarget = false
	rd.renderTarget = 2
	
	render.SetRefDef(rd)
	
	draw.SetColor(0,0,0,1)
	draw.SetColor(1,1,1,1)
end
hook.add("PostDraw","cl_rt3",post)