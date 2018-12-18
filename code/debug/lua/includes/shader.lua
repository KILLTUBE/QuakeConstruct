local shaders = {}
local strings = {}

local function loaded(str,i,nomip)
	--debugprint("Loaded Shader: " .. str .. " | " .. i .. "\n")
	if(i != 0) then
		strings[i] = str
		table.insert(shaders,{str,i,nomip})
	end
end
hook.add("ShaderLoaded","shaders",loaded)

function GetShaderName(i)
	return strings[i] or ""
end

function LoadShader(str,nomip)
	for k,v in pairs(shaders) do
		if(v[1] == str) then
			--debugprint("Loaded Shader From Cache: " .. v[1] .. "(" .. v[2] .. ")\n")
			return v[2]
		end
	end
	if(__RESOURCE_REGISTERING) then
		util.LoadingString("lua media: " .. string.GetFileFromFilename(str))
	end
	return __loadshader(str,nomip)
end