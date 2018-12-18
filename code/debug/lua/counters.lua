_FIRSTRUN = false
if(_COUNTERS == nil) then _FIRSTRUN = true end

_COUNTERS = persist.Load("counters").counters
_COUNTERS = _COUNTERS or {}

local function zero(t,f)
	if(t[f] < 10) then t[f] = "0" .. t[f] end
end

local function datetime()
	local t = os.date('*t')
	zero(t,"hour")
	zero(t,"min")
	zero(t,"sec")
	zero(t,"month")
	zero(t,"day")

	return "[" .. t.month .. "/" .. t.day .. "/" .. t.year .. "] - " .. t.hour .. ":" .. t.min .. ":" .. t.sec
end

local function saveCounters()
	persist.Start("counters")
	persist.Write("counters",_COUNTERS)
	persist.Close()
	print("Counters Saved\n")
end

local function check(k,v)
	if(_COUNTERS[k] == nil) then
		_COUNTERS[k] = {}
		_COUNTERS[k].est = datetime()
		_COUNTERS[k].value = v
	end
	if(_COUNTERS[k].sv == nil) then
		if(SERVER) then
			_COUNTERS[k].sv = 1
		else
			_COUNTERS[k].sv = 0
		end
	end
end

function _INCREMENT_COUNTER(name,v)
	check(name,0)
	local val = _COUNTERS[name].value
	_COUNTERS[name].value = val + v
end

if(_FIRSTRUN) then
	_INCREMENT_COUNTER("lua_runs",1)
end

for k,v in pairs(_COUNTERS) do
	print(k .. " = " .. v.value .. "\n")
end

saveCounters()
hook.add("Shutdown","counters.lua",saveCounters)