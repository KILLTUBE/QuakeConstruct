function string.ToTable ( str )

	local tab = {}
	
	for i=1, string.len( str ) do
		table.insert( tab, string.sub( str, i, i ) )
	end
	
	return tab

end

string.alphabet = string.ToTable( "abcdefghijklmnopqrstuvwxyz")

function string.Explode ( seperator, str )

	if ( seperator == "" ) then
		return string.ToTable( str )
	end

	local tble={}	
	local ll=0
	
	while (true) do
	
		l = string.find( str, seperator, ll, true )
		
		if not (l == nil) then
			table.insert(tble, string.sub(str,ll,l-1)) 
			ll=l+1
		else
			table.insert(tble, string.sub(str,ll))
			break
		end
		
	end
	
	return tble
	
end


function string.Implode(seperator,Table) return 
	table.concat(Table,seperator) 
end

function string.GetExtensionFromFilename(path)
	local ExplTable = string.ToTable( path )
	for i = table.getn(ExplTable), 1, -1 do
		if ExplTable[i] == "." then return string.sub(path, i+1)end
		if ExplTable[i] == "/" or ExplTable[i] == "\\" then return "" end
	end
	return ""
end

function string.GetPathFromFilename(path)
	local ExplTable = string.ToTable( path )
	for i = table.getn(ExplTable), 1, -1 do
		if ExplTable[i] == "/" or ExplTable[i] == "\\" then return string.sub(path, 1, i) end
	end
	return ""
end

function string.GetFileFromFilename(path)
	local ExplTable = string.ToTable( path )
	for i = table.getn(ExplTable), 1, -1 do
		if ExplTable[i] == "/" or ExplTable[i] == "\\" then return string.sub(path, i) end
	end
	return ""
end

function string.FormattedTime( TimeInSeconds, Format )
	if not TimeInSeconds then TimeInSeconds = 0 end

	local i = math.floor( TimeInSeconds )
	local h,m,s,ms	=	( i/3600 ),
				( i/60 )-( math.floor( i/3600 )*3600 ),
				TimeInSeconds-( math.floor( i/60 )*60 ),
				( TimeInSeconds-i )*100

	if Format then
		return string.format( Format, m, s, ms )
	else
		return { h=h, m=m, s=s, ms=ms }
	end
end

function string.ToMinutesSecondsMilliseconds( TimeInSeconds )	return string.FormattedTime( TimeInSeconds, "%02i:%02i:%02i")	end
function string.ToMinutesSeconds( TimeInSeconds )		return string.FormattedTime( TimeInSeconds, "%02i:%02i")	end


function string.Left(str, num)
	return string.sub(str, 1, num)
end

function string.Right(str, num)
	return string.sub(str, -num)
end


function string.Replace(str, tofind, toreplace)
	local start = 1
	while (true) do
		local pos = string.find(str, tofind, start, true)
	
		if (pos == nil) then
			break
		end
		
		local left = string.sub(str, 1, pos-1)
		local right = string.sub(str, pos + #tofind)
		
		str = left .. toreplace .. right
		start = pos + #toreplace
	end
	return str
end

function string.Trim( s, char )
	if (char==nil) then char = "%s" end
	return string.gsub(s, "^".. char.."*(.-)"..char.."*$", "%1")
end

function string.TrimRight( s, char )
	
	if (char==nil) then char = " " end	
	
	if ( string.sub( s, -1 ) == char ) then
		s = string.sub( s, 0, -2 )
		s = string.TrimRight( s, char )
	end
	
	return s
	
end

function string.TrimLeft( s, char )

	if (char==nil) then char = " " end	
	
	if ( string.sub( s, 1 ) == char ) then
		s = string.sub( s, 1 )
		s = string.TrimLeft( s, char )
	end
	
	return s

end

function string.URLEncode(str)
	if (str) then
		str = string.gsub (str, "\n", "\r\n")
		str = string.gsub (str, "([^%w ])",
			function (c) return string.format ("%%%02X", string.byte(c)) end)
		str = string.gsub (str, " ", "+")
	end
	return str	
end

function string.URLDecode(str)
	str = string.gsub (str, "+", " ")
	str = string.gsub (str, "%%(%x%x)",
		function(h) return string.char(tonumber(h,16)) end)
	str = string.gsub (str, "\r\n", "\n")
	return str
end

function string.CountSlashes(str)
	local c = 0
	local tab = string.ToTable(str)
	for k,v in pairs(tab) do
		if(v == "/") then c = c + 1 end
	end
	return c
end

function string.StartsWith(str,key)
	local len = string.len(key)
	return string.sub(str,0,len) == key
end