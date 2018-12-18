tablex = table

if (table.Inherit) then return end
--Define Once

function table.Inherit( t, base )

	for k, v in pairs( base ) do 
		if ( t[k] == nil ) then t[k] = v end
	end
	
	t["BaseClass"] = base
	
	return t

end


function table.Copy(t, lookup_table)
	if (t == nil) then return nil end
	
	local copy = {}
	setmetatable(copy, getmetatable(t))
	for i,v in pairs(t) do
		if type(v) ~= "table" then
			copy[i] = v
		else
			lookup_table = lookup_table or {}
			lookup_table[t] = copy
			if lookup_table[v] then
				copy[i] = lookup_table[v] -- we already copied this table. reuse the copy.
			else
				copy[i] = table.Copy(v,lookup_table) -- not yet copied. copy it.
			end
		end
	end
	return copy
end


function table.Update(dest, source, tf)
	for k,v in pairs(source) do
		if(tf ~= nil) then
			if(type(v) == tf) then
				dest[k] = source[k]
			end
		else
			dest[k] = source[k]
		end
	end
end

function table.Instance(t)
	local o = {}
	for k,v in pairs(t) do
		o[k] = v
	end
	return o
end

function table.Merge(dest, source)
	for k,v in pairs(source) do
		if type(v)=='table' and type(dest[k])=='table' then
			-- don't overwrite one table with another;
			-- instead merge them recurisvely
			table.Merge(dest[k], v)
		else
			dest[k] = v
		end
	end
	return dest
end

function table.HasKey( t, key )
	for k,v in pairs(t) do
		if (k == key ) then return true end
	end
	return false
end

function table.HasValue( t, val )
	for k,v in pairs(t) do
		if (v == val ) then return true end
	end
	return false
end

table.InTable = HasValue


function table.Add( dest, source )

	if not (type(source)=='table') then return dest end
	
	if not (type(dest)=='table') then dest = {} end

	for k,v in pairs(source) do
		table.insert( dest, v )
	end
	
	return dest
end

function table.sortdesc( Table )

	return table.sort( Table, function(a, b) return a > b end )
end


function table.SortByKey( Table, Desc )

	local temp = {}

	for key, _ in pairs(Table) do table.insert(temp, key) end
	if ( Desc ) then
		table.sort(temp, function(a, b) return Table[a] < Table[b] end)
	else
		table.sort(temp, function(a, b) return Table[a] > Table[b] end)
	end

	return temp
end


function table.Count (t)
  local i = 0
  for k in pairs(t) do i = i + 1 end
  return i
end


function table.IsSequential(t)
	local i = 1
	for key, value in pairs (t) do
		if not tonumber(i) or key ~= i then return false end
		i = i + 1
	end
	return true
end


function table.ToString(t,n,nice)
	local 		nl,tab  = "",  ""
	if nice then 	nl,tab = "\n", "\t"	end

	local function MakeTable ( t, nice, indent, done)
		local str = ""
		local done = done or {}
		local indent = indent or 0
		local idt = ""
		if nice then idt = string.rep ("\t", indent) end

		local sequential = table.IsSequential(t)

		for key, value in pairs (t) do

			str = str .. idt .. tab .. tab

			if not sequential then
				if type(key) == "number" or type(key) == "boolean" then 
					key ='['..tostring(key)..']' ..tab..'='
				else
					key = tostring(key) ..tab..'='
				end
			else
				key = ""
			end

			if type (value) == "table" and not done [value] then

				done [value] = true
				str = str .. key .. tab .. '{' .. nl
				.. MakeTable (value, nice, indent + 1, done)
				str = str .. idt .. tab .. tab ..tab .. tab .."},".. nl

			else

				value = tostring(value)
				
				str = str .. key .. tab .. value .. ",".. nl

			end

		end
		return str
	end
	local str = ""
	if n then str = n.. tab .."=" .. tab end
	str = str .."{" .. nl .. MakeTable ( t, nice) .. "}"
	return str
end

function table.Sanitise( t, done )

	local done = done or {}
	local tbl = {}

	for k, v in pairs ( t ) do
	
		if ( type( v ) == "table" and not done[ v ] ) then

			done[ v ] = true
			tbl[ k ] = table.Sanitise ( v, done )

		else
			
			tbl[k] = tostring(v)
			
		end
		
		
	end
	
	return tbl
	
end


function table.DeSanitise( t, done )

	local done = done or {}
	local tbl = {}

	for k, v in pairs ( t ) do
	
		if ( type( v ) == "table" and not done[ v ] ) then
		
			done[ v ] = true

			if ( v.__type ) then
					
				if ( v.__type == "Bool" ) then
					
					tbl[ k ] = ( v[1] == "true" )
					
				end
			
			else
			
				tbl[ k ] = table.DeSanitise( v, done )
				
			end
			
		else
		
			tbl[ k ] = v
			
		end
		
	end
	
	return tbl
	
end

function table.ForceInsert( t, v )

	if ( t == nil ) then t = {} end
	
	table.insert( t, v )
	
end


function table.SortByMember( Table, MemberName, bAsc )

	local TableMemberSort = function( a, b, MemberName, bReverse ) 
	

		if not ( type(a) == "table" ) then return not bReverse end
		if not ( type(b) == "table" ) then return bReverse end
		if not ( a[MemberName] ) then return not bReverse end
		if not ( b[MemberName] ) then return bReverse end
	
		if ( bReverse ) then
			return a[MemberName] < b[MemberName]
		else
			return a[MemberName] > b[MemberName]
		end
		
	end

	table.sort( Table, function(a, b) return TableMemberSort( a, b, MemberName, bAsc or false ) end )
	
end


function table.LowerKeyNames( Table )

	local OutTable = {}

	for k, v in pairs( Table ) do
	
		if ( type( v ) == "table" ) then
			v = table.LowerKeyNames( v )
		end
		
		OutTable[ k ] = v
		
		if ( type( k ) == "string" ) then
	
			OutTable[ k ]  = nil
			OutTable[ string.lower( k ) ] = v
		
		end		
	
	end
	
	return OutTable
	
end


function table.CollapseKeyValue( Table )

	local OutTable = {}
	
	for k, v in pairs( Table ) do
	
		local Val = v.Value
	
		if ( type( Val ) == "table" ) then
			Val = table.CollapseKeyValue( Val )
		end
		
		OutTable[ v.Key ] = Val
	
	end
	
	return OutTable

end


function table.ClearKeys( Table, bSaveKey )

	local OutTable = {}
	
	for k, v in pairs( Table ) do
		if ( bSaveKey ) then
			v.__key = k
		end
		table.insert( OutTable, v )	
	end
	
	return OutTable

end


function table.Flip( Table )
	local t2 = {}
	
	for i=1,#Table do
		t2[#Table - (i-1)] = Table[i]
	end
	
	return t2
end

function table.ReverseLookup( Table, value )
	for k,v in pairs(Table) do
		if(v == value) then return k end
	end
	
	return nil
end

function table.Fuse( Table, Condition )
	if(Condition == nil or Table == nil) then return end
	
	local out = Table
	
	for x=1, #out-1 do
		for y=x+1, #out do
			if(x != y) then
				local v1 = out[x]
				local v2 = out[y]
				local b,e = pcall(Condition,v1,v2)
				if(!b) then
					error("Table Condition Error: " .. e)
				else
					if(e) then
						--[[if(type(v1) == "table") then
							table.Merge(out[y], out[x])
						else
							out[y] = v1
						end]]
						out[y] = out[x]
					end
				end
			end
		end
	end
	return out
end

local function fnPairsSorted( pTable, Index )

	if ( Index == nil ) then
	
		Index = 1
	
	else
	
		for k, v in pairs( pTable.__SortedIndex ) do
			if ( v == Index ) then
				Index = k + 1
				break
			end
		end
		
	end
	
	local Key = pTable.__SortedIndex[ Index ]
	if not ( Key ) then
		pTable.__SortedIndex = nil
		return
	end
	
	Index = Index + 1
	
	return Key, pTable[ Key ]

end

function SortedPairs( pTable, Desc )

	pTable = table.Copy( pTable )
	
	local SortedIndex = {}
	for k, v in pairs( pTable ) do
		table.insert( SortedIndex, k )
	end
	
	if ( Desc ) then
		table.sort( SortedIndex, function(a,b) return a>b end )
	else
		table.sort( SortedIndex )
	end
	pTable.__SortedIndex = SortedIndex

	return fnPairsSorted, pTable, nil
	
end

function SortedPairsByValue( pTable, Desc )

	pTable = table.ClearKeys( pTable )
	
	if ( Desc ) then
		table.sort( pTable, function(a,b) return a>b end )
	else
		table.sort( pTable )
	end

	return ipairs( pTable )
	
end

function SortedPairsByMemberValue( pTable, pValueName, Desc )

	Desc = Desc or false
	
	local pSortedTable = table.ClearKeys( pTable, true )
	
	table.SortByMember( pSortedTable, pValueName, not Desc )
	
	local SortedIndex = {}
	for k, v in ipairs( pSortedTable ) do
		table.insert( SortedIndex, v.__key )
	end
	
	pTable.__SortedIndex = SortedIndex

	return fnPairsSorted, pTable, nil
	
end