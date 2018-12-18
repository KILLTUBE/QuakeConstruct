

function dirtree(dir)
  assert(dir and dir ~= "", "directory parameter is missing or empty")
  if string.sub(dir, -1) == "/" then
    dir=string.sub(dir, 1, -2)
  end

  local diriters = {lfs.dir(dir)}
  local dirs = {dir}

  return function()
    repeat 
      local entry = diriters[#diriters]()
      if entry then 
        if entry ~= "." and entry ~= ".." then 
          local filename = table.concat(dirs, "/").."/"..entry
          local attr = lfs.attributes(filename)
          if attr.mode == "directory" then 
            table.insert(dirs, entry)
            table.insert(diriters, lfs.dir(filename))
          end
          return filename, attr
        end
      else
        table.remove(dirs)
        table.remove(diriters)
      end
    until #diriters==0
  end
end

function findFileByType(n,base)
	base = base or "."
	local tab = {}
	for filename, attr in dirtree(base) do
		if not(attr.mode == "directory") then
			if(string.GetExtensionFromFilename(filename) == string.GetExtensionFromFilename("." .. n)) then
				local f = string.sub(filename,3,string.len(filename))
				table.insert(tab,f)
			end
		end
	end
	return tab
end

function fileExists(n,base)
	base = base or "."
	file = io.open(base .. "/" .. n, "r")
	if(file != nil) then
		file:close()
		return true
	end
	return false
end

fmd5cnt = 0

function countFileLines(n,condition)
	file = io.open(n, "r")
	if(file != nil) then
		local lines = 0
		for line in file:lines() do
			local c = true
			if(condition) then
				local b,e = pcall(condition,line,lines)
				if(!b) then error(e) end
				c = e
			end
			if(c) then
				lines = lines + 1
			end
		end
		
		file:close()
		return lines
	end
	return 0
end

function fileMD5(file,condition)
	local wasStr = false
	if(type(file) == "string") then
		file = io.open(file, "r")
		wasStr = true
	end
	if(file != nil) then
		local dat = ""
		local lines = 0
		local current = file:seek()
		for line in file:lines() do			
			local c = true
			if(condition) then
				local b,e = pcall(condition,line,lines)
				if(!b) then error(e) end
				c = e
			end
			if(c) then	
				lines = lines + 1
				line = string.Replace(line,"\n","")
				line = string.Replace(line,"\t","")
				
				if(line != "") then
					dat = dat .. line
				end
			end
		end
		if(!wasStr) then 
			file:seek("set", current) 
		else
			file:close()
		end
		return MD5(dat)
	end
	return ""
end