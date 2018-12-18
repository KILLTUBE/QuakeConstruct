--include("lua/includes/treeparser.lua")

HSV = 2

local function RValueFromT(t,d)
	if(t == nil) then return d end
	if(type(t) == "table") then
		local k = 1
		local v = t[k]
		while(v ~= nil) do	
			k = k + 1
			v = t[k]
		end
		k = k - 1
		if(k ~= 0) then
			return t[math.random(1,k)]
		end
	else
		return t
	end
	return d
end

local function VectorFromT(v,d)
	if(type(v) == "number") then return Vector(v) end
	if(type(v) == "table") then 
		local a = v[1] or 0
		local b = v[2] or a
		local c = v[3] or b
		return Vector(a,b,c)
	end
	return d
end

local function ColorFromT(v,d)
	if(type(v) ~= "table") then return unpack(d) end
	local r = v[1] or 1
	local g = v[2] or r
	local b = v[3] or g
	local a = v[4] or 1
	
	if(r < 0 or g < 0 or b < 0 or a < 0) then
		r = r + HSV
		g = g + HSV
		b = b + HSV
		a = a + HSV
		
		if(g > 1) then g = 1 end
		if(b > 1) then b = 1 end
		r,g,b = hsv(r,g,b)
	end
	
	--print("COLOR: " .. r .. ", " .. g .. ", " .. b .. "\n")
	return r,g,b,a
end

local function BuildParticleEmitter(t)
	local ref = RefEntity()
	--ref:SetColor(ColorFromT(t.color.start,{1,1,1,1}))
	
	local le = LocalEntity()
	le:SetAngles(Vector(0))
	le:SetRefEntity(ref)
	le:SetType(t.type)
	return le,ref
end

function SetupParticleRef(t,l)
	local ref = l:GetRefEntity()
	if(t.scale) then ref:Scale(VectorFromT(t.scale,Vector(1))) end
	if(t.render) then ref:SetType(t.render or RT_SPRITE) end
	if(t.model) then
		local model = RValueFromT(t.model)
		if(model ~= nil) then
			--print("model: " .. model .. "\n")
			model = LoadModel(model)
		end
		if(model ~= nil) then ref:SetType(RT_MODEL) end
		if(model ~= nil) then ref:SetModel(model) end
	end
	
	if(t.shader) then ref:SetShader(LoadShader(RValueFromT(t.shader)) or 0) end
	if(t.radius) then ref:SetRadius(t.radius.start or 5) end
	if(t.trail) then
		ref:SetTrailLength(t.trail.length or 10)
		ref:SetTrailFade(t.trail.fade or FT_ALPHA)
	end
	
	l:SetRefEntity(ref)
end

function SetupParticle(t,l)
	if(t.type == LE_FRAGMENT and t.tr == nil) then t.tr = TR_GRAVITY end
	local trtype = t.tr
	local angle = VectorFromT(t.angle,nil)
	local anglevel = VectorFromT(t.spin,nil)
	if(angle ~= nil) then l:SetAngles(angle) end
	if(t.time ~= nil) then
		l:SetStartTime(LevelTime())
		l:SetEndTime(LevelTime() + t.time)
	end
	if(trtype ~= nil) then l:SetTrType(trtype) end
	if(anglevel ~= nil) then l:SetAngleVelocity(anglevel) end
	if(t.color) then
		local r,g,b,a = ColorFromT(t.color.start,{1,1,1,1})
		l:SetStartColor(r,g,b,a)
		l:SetEndColor(ColorFromT(t.color["end"],{r,g,b,a}))
	end
	if(t.radius) then
		local start = t.radius.start or 5
		--print(t.radius["end"] .. "\n")
		l:SetStartRadius(start)
		l:SetEndRadius(t.radius["end"] or start)
	end
	if(t.bounce) then
		l:SetBounceFactor(t.bounce)
	end
	if(t.stopped) then
		l:SetCallback(LOCALENTITY_CALLBACK_STOPPED,function(le)
			SetupParticle(t.stopped,le)
		end)
	end
	
	SetupParticleRef(t,l)
end

function StartEmitter(t,le,cb)
	if(t.emit) then
		local estart = t.emit.start or 0
		local duration = t.emit.time or 0
		local d = t.emit.delay or 10
		if(t.emit.others) then
			local k = 1
			local v = t.emit.others[k]
			while(v ~= nil) do
				local lle,lref = BuildParticleEmitter(v)
				lle:SetPos(le:GetPos())
				lle:SetAngles(le:GetAngles())
				StartEmitter(v,lle)
				k = k + 1
				v = t.emit.others[k]
			end
		end
		le:Emitter(LevelTime()+estart, LevelTime()+estart+duration, d, function(l,lt)
			EMITTER_TIME = (1 - lt)
			--print(EMITTER_TIME .. "\n")
			local rnd = VectorRandom()*(t.emit.spread or 0)
			--rnd.z = 0
			local a = le:GetAngles()-- + rnd
			local f,r,u = AngleVectors(a)
			f = f  +  rnd/180
			f = VectorNormalize(f)
			SetupParticle(t,l)
			l:SetVelocity(f*(t.emit.speed or 0))
			l:SetPos(le:GetPos())
			if(t.emit.attach) then
				local k = 1
				local v = t.emit.attach[k]
				while(v ~= nil and l ~= nil) do
					local lle,lref = BuildParticleEmitter(v)
					StartEmitter(v,lle,function(le2,lt2)
						if(l ~= nil) then
							if(l:GetPos() ~= nil) then
								le2:SetPos(l:GetPos())
								le2:SetAngles(l:GetAngles())
							else
								le2:SetEndTime(0)
							end
						end
					end)
					k = k + 1
					v = t.emit.attach[k]
				end
			end
			if(t.emit.attachstatic) then
				local k = 1
				local v = t.emit.attachstatic[k]
				local particles = {}
				while(v ~= nil and l ~= nil) do
					local lle,lref = BuildParticleEmitter(v)
					local b,e = pcall(SetupParticle,v,lle)
					if not (b) then print("^1Error: " .. e .. "\n") end
					lle:SetPos(l:GetPos())					
					table.insert(particles,lle)
					k = k + 1
					v = t.emit.attachstatic[k]
				end
				l:SetCallback(LOCALENTITY_CALLBACK_THINK,function(lex)
					local pos = lex:GetPos()
					local angles = lex:GetAngles()
					for k,v in pairs(particles) do
						if(v ~= nil and pos ~= nil) then
							v:SetPos(pos)
							v:SetAngles(angles)
						end
					end
					lex:SetNextThink(LevelTime())
				end)
				l:SetNextThink(LevelTime())
			end
			if(cb) then
				local b,e = pcall(cb,l,lt)
				if not (b) then print("^1Error: " .. e .. "\n") end
			end
		end)
		if(t.emit.count and t.emit.count > 1) then
			for i=1, t.emit.count do
				le:Emit()
			end
		end
	end
	
	le:SetTrType(TR_STATIONARY)
	
	return le,ref
end

local parser = TreeParser()
parser:Clear()
local tree = {}
local test = packList("particles",".psf")
for k,v in pairs(test) do
	parser:ParseFile("particles/" .. v,tree)
end
parser:SetMeta(tree)

--print(tree["Test"].time .. "\n")

for k,v in pairs(tree) do
	local t = table.ToString(v,nil,true)
	t = string.Replace(t,"\t","  ")
	print(k .. ": " .. t .. "\n")
end

local function spawn(p,c,a)
	local n = a[1] or "Test"
	local tr = PlayerTrace()
	local le,ref = BuildParticleEmitter(tree[n])

	le:SetPos(tr.endpos + tr.normal * 40)
	le:SetAngles(VectorToAngles(tr.normal))

	StartEmitter(tree[n],le)
end

concommand.add("particles",spawn)
--parser.parse(s)