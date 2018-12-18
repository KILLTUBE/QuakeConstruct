local models = {}
local strings = {}

local function loaded(str,i)
	--debugprint("Loaded Model: " .. str .. " | " .. i .. "\n")
	--[[if(i != 0) then
		strings[i] = str
		table.insert(models,{str,i})
	end]]
end
hook.add("ModelLoaded","models",loaded)

function GetModelFile(i)
	return strings[i] or ""
end

function LoadModel(str)
	--[[for k,v in pairs(models) do
		if(v[1] == str) then
			--print("Loaded Model From Cache: " .. v[1] .. "(" .. v[2] .. ")\n")
			return v[2]
		end
	end]]
	if(__RESOURCE_REGISTERING) then
		util.LoadingString("lua media: " .. string.GetFileFromFilename(str))
	end
	return __loadmodel(str)
end

local function absvec(v)
	return Vector(math.abs(v.x),math.abs(v.y),math.abs(v.z))
end

function GetModelCenter(m)
	if(type(m) != "number") then return end
	mins,maxs = render.ModelBounds(m)

	return vMul(vSub(maxs,absvec(mins)),-.5)
end

function GetModelSize(m)
	if(type(m) != "number") then return end
	mins,maxs = render.ModelBounds(m)
	
	return VectorLength(vMul(vSub(maxs,mins),2))
end

function GetModelSize3(m)
	if(type(m) != "number") then return end
	mins,maxs = render.ModelBounds(m)
	
	return vMul(vSub(maxs,mins),2)
end