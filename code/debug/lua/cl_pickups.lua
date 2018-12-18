local items = {}

local function renderScene(x,y,size,viewpos,aimat)
	local aim = VectorNormalize(aimat - viewpos)
	local refdef = {}
	
	aim = VectorToAngles(aim)
	
	refdef.x = x
	refdef.y = y
	refdef.width = size
	refdef.height = size
	refdef.origin = viewpos
	
	refdef.angles = aim
	
	local b, e = pcall(render.RenderScene,refdef)
	if(!b) then
		print("^1" .. e .. "\n")
	end
end

local function DrawItem(x,y,item)
	local pki = util.GetItemIcon(item)
	local model = util.GetItemModel(item)
	local name = util.GetItemName(item)

	draw.SetColor(1,1,1,.3)
	draw.Rect(x,y,40,40,pki)

	render.CreateScene()

	local ref = RefEntity()
	ref:SetPos(Vector(0,0,0))
	ref:SetModel(model)
	ref:Render()

	local vp = Vector(0,100,0)
	if(string.find(name,"Health") or string.find(name,"Armor")) then
		vp = Vector(100,0,0)
	end

	renderScene(x,y,40,vp,Vector(0,0,0))
end

local function d2d()
	for i=1,#items do
		local item = items[i]
		if(item.t > 0) then
			item.spr.ideal.y = 10 + (40 * (i-1))

			if(item.t < .1) then
				item.spr.ideal.x = 550
			end

			if(item.t < .05) then
				item.spr.ideal.x = 700
			end

			item.spr:Update(true)
			DrawItem(item.spr.val.x,item.spr.val.y,item.item)
			item.t = item.t - 0.004
		else
			items[i].rmv = 1
		end
	end
	if(#items > 0) then
		while(#items > 0 and items[1].rmv == 1) do
			table.remove(items,1)
		end
	end
end
hook.add("Draw2D","cl_pickups",d2d)


local function itemPickup(i)
	local bl = function(x,y) return Vector(x or 0,y or 0) end
	local last = #items
	local spr = Spring(
		bl(700,(40*last)+10),
		bl(600,(40*last)+10),
		bl(.15,.15),
		bl(.92,.92),
		bl(0,0)
	)

	table.insert(items,{item=i,t=1,t2=1,rmv=0,spr=spr})
end
hook.add("ItemPickup","cl_pickups",itemPickup)

local function test() itemPickup(3) end
concommand.Add("pktest",test)