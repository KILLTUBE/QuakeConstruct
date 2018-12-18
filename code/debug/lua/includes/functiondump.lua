
// Outputs functions and stuff in wiki format

OUTPUT = ""

local function UnderScore(str)
	if(string.sub(str,0,1) == "_") then
		return true
	end
	return false
end

local function XSide( class, name )
	
	return "[Q3GAME]"
	
end


local function GetFunctions( tab )

	local functions = {}

	for k, v in pairs( tab ) do

		if ( type(v) == "function" ) then
		
			table.insert( functions, tostring(k) )
		
		end
	
	end
	
	table.sort( functions )
	return functions

end

local function GetVars( tab )

	local vars = {}

	for k, v in pairs( tab ) do

		if ( type(v) != "function" ) then
		
			if(!UnderScore(tostring(k))) then
				table.insert( vars, tostring(k) )
			end
			
		end
	
	end
	
	table.sort( vars )
	return vars

end


local function DoMetaTable( name )
	
	OUTPUT = OUTPUT .. "\n\r==["..name.."] ([Object])==\n\r"
	func = GetFunctions( _G[ name ] )
	
	if ( type(_G[ name ]) != "table" ) then
		print("Error: _G["..name.."] is not a table!\n")
	end
	
	for k, v in pairs( func ) do
		OUTPUT = OUTPUT .. "|| " .. XSide( name, v ) .. " || ["..name.."]:["..v.."]() ||\n"
	end
	
end

local function DoLibrary( name )
	
	OUTPUT = OUTPUT .. "\n\r==["..name.."] ([Library])==\n\r"
	
	if ( type(_G[ name ]) != "table" ) then
		print("Error: _G["..name.."] is not a table!\n")
	end
	
	func = GetFunctions( _G[ name ] )
	for k, v in pairs( func ) do
		OUTPUT = OUTPUT .. "|| " .. XSide( name, v ) .. " || ["..name.."].["..v.."] ||\n"
	end
	
	vars = GetVars( _G[ name ] )
	for k, v in pairs( vars ) do
		OUTPUT = OUTPUT .. "|| " .. XSide( name, v ) .. " || ["..name.."].["..v.."] ||\n"
	end
end

local function DoEnum( name )

	OUTPUT = OUTPUT .. "\n\r==["..name.."] ([Enum])==\n\r"
	
	if ( type(_G[ name ]) != "table" ) then
		print("Error: _G["..name.."] is not a table!\n")
	end
	
	for k, v in pairs( _G[ name ] ) do
		if(type(v) == "string") then
			OUTPUT = OUTPUT .. "|| " .. XSide( name, v ) .. " || ["..name.."].["..v.."] ||\n"
		end
	end
	
end

local Ignores = { "_G", "_G", "_E", "_LOADLIB", "_LOADED", "func", "vars" }

local t ={}

for k, v in pairs(_G) do
	if ( type(v) == "table" && type(k) == "string" && !table.HasValue( Ignores, k ) && !v.IsEnumeration ) then
		table.insert( t, tostring(k) )
	end
end

table.sort( t )
for k, v in pairs( t ) do
	print("Library: "..v.."\n")
	DoLibrary( v )
end


local t = {}

for k, v in pairs(_G) do
	if ( type(v) == "table" && type(k) == "string" && !table.HasValue( Ignores, k ) && !v.IsEnumeration  ) then
		table.insert( t, tostring(k) )
	end
end

table.sort( t )
for k, v in pairs( t ) do
	print("MetaTable: "..v.."\n")
	DoMetaTable( v )
end

local t = {}

for k, v in pairs(_G) do
	if ( type(v) == "table" && v.IsEnumeration == true  ) then
		table.insert( t, tostring(k) )
	end
end

table.sort( t )
for k, v in pairs( t ) do
	print("Enum: "..v.."\n")
	DoEnum( v )
end


local f = io.output("test.txt")
io.write(OUTPUT)
io.close(f)