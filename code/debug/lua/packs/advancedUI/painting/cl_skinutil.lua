sk = {}

local curTab = {}
local last = nil

function sk.qcolor(tab)
	curTab = tab
	draw.SetColor(tab[1],tab[2],tab[3],tab[4])
end

function sk.current()
	return curTab
end

function sk.coloradjust(tab,amt,alpha)
	if(tab == nil) then
		if(curTab != nil) then
			tab = table.Copy(curTab)
		else
			return {1,1,1,1}
		end
	end
	
	last = table.Copy(tab)
	
	local out = {}
	for k,v in pairs(tab) do
		out[k] = math.min(math.max(v + amt,0),1)
	end
	out[4] = tab[4]
	--out[4] = tab[4]/2
	if(alpha != nil) then
		out[4] = alpha
	end
	sk.qcolor(out)
	return out
end

function sk.restore()
	if(last != nil) then
		sk.qcolor(last)
	end
end