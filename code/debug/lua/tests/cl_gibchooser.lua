print("Gib Chooser!\n")

local cache = {}
local listcache = {}

local default = {
	"models/gibs/abdomen.md3",
	"models/gibs/arm.md3",
	"models/gibs/chest.md3",
	"models/gibs/fist.md3",
	"models/gibs/foot.md3",
	"models/gibs/forearm.md3",
	"models/gibs/intestine.md3",
	"models/gibs/leg.md3",
	"models/gibs/brain.md3",
}

function getGibName(mdl)
	local ext = string.GetExtensionFromFilename(mdl)
	local fname = string.GetFileFromFilename(mdl)
	fname = string.sub(fname,2,string.len(fname) - (string.len(ext)+1))
	return fname
end

function getCustomGibs(pl)
	if(pl == nil) then return {} end
	local name = pl:GetInfo().modelName
	local temp = {}
	if(name != nil and cache[name] == nil) then
		local path = "models/players/" .. name .. "/gibs/"
		local plist = packList(path,".md3")
		
		print("Gibs For " .. name .. ":\n")
		for k,v in pairs(plist) do
			print(getGibName(path .. v) .. "\n")
			table.insert(temp,path .. v)
		end
		cache[name] = temp
	elseif(cache[name] != nil) then
		return cache[name]
	end
	return temp
end

function getCustomGib(pl,n)
	for k,v in pairs(getCustomGibs(pl)) do
		if(getGibName(v) == n) then return v end
	end
	return nil
end

local function addAux(tab,n,pl)
	local custom = getCustomGib(pl,n)
	if(custom != nil) then 
		table.insert(tab,{custom,true})
	end
end

function getGibList(pl)
	local out = {}
	local name = pl:GetInfo().modelName
	if(name == nil) then return {} end
	if(listcache[name] != nil) then return listcache[name] end
	for i=0,5 do
		local nn = ""
		if(i > 0) then nn = nn .. i end
		addAux(out,"aux" .. nn,pl)
		addAux(out,"aux_u" .. nn,pl)
		addAux(out,"aux_l" .. nn,pl)
	end
	for k,v in pairs(default) do
		local n = getGibName(v)
		local found = false
		for i=0,5 do
			local nn = n
			if(i > 0) then nn = nn .. i end
			local custom = getCustomGib(pl,nn)
			if(custom != nil) then 
				--print("Found Custom: " .. custom .. "\n")
				table.insert(out,{custom,true})
				found = true
			end
		end
		if(found == false) then table.insert(out,{v,false}) end
	end
	local cnt = #out
	for i=1,cnt do
		local v = out[i]
		if(string.find(v[1],"leg") or string.find(v[1],"arm") or string.find(v[1],"foot")) then
			table.insert(out,{v[1],v[2]})
		end
	end
	listcache[name] = out
	return out
end

function getGibModels(pl,customonly)
	local out = {}
	for k,v in pairs(getGibList(pl)) do
		if(!customonly or v[2]) then
			table.insert(out,LoadModel(v[1]))
		end
	end
	return out
end

function getGibSkins(pl,customonly)
	local out = {}
	local name = pl:GetInfo().modelName
	if(name == nil) then return {} end
	for k,v in pairs(getGibList(pl)) do
		local name = getGibName(v[1])
		if(v[2]) then
			if(string.find(name,"leg") or 
				string.find(name,"foot") or 
				string.find(name,"abdomen") or 
				string.find(name,"intestine")) then
					table.insert(out,pl:GetInfo().legsSkin)
			elseif(string.find(name,"aux_u")) then
				table.insert(out,pl:GetInfo().torsoSkin)
			elseif(string.find(name,"aux") or
				   string.find(name,"aux_l")) then
				table.insert(out,pl:GetInfo().legsSkin)
			else
				table.insert(out,pl:GetInfo().torsoSkin)
			end
		else
			if(!customonly) then
				table.insert(out,-1)
			end
		end
	end
	return out
end

getGibList(LocalPlayer())