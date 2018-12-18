entity_tabs = {}

local function UnlinkEntity(ent)
	local index = ent:EntIndex()
	if(ent:IsPlayer() == false) then
		if(entity_tabs[index] != nil) then
			entity_tabs[index] = nil
		end
		debugprint("^2QLUA Entity Unlinked: " .. index .. " | " .. ent:Classname() .. "\n")
	else
		if(entity_tabs[index] != nil) then
			entity_tabs[index].wasUnlinked = true
		end
		debugprint("Entity Unlinked: " .. index .. " | " .. ent:Classname() .. "\n")
	end
end

local function UnlinkPlayer(ent)
	local index = ent:EntIndex()
	if(ent:IsPlayer() == true) then
		if(entity_tabs[index] != nil) then
			entity_tabs[index] = nil
		end
		debugprint("^2QLUA Entity Unlinked: " .. index .. " | " .. ent:Classname() .. "\n")
	end
end

local function LinkEntity(ent)
	local index = ent:EntIndex()
	if(entity_tabs[index] == nil) then
		entity_tabs[index] = {}
		debugprint("^2QLUA Entity Linked: " .. index .. " | " .. ent:Classname() .. "\n")
	elseif(entity_tabs[index].wasUnlinked) then
		entity_tabs[index].wasUnlinked = false
		debugprint("Entity Linked: " .. index .. " | " .. ent:Classname() .. "\n")
	end
end

function GetEntityTable(ent)
	LinkEntity(ent)
	local index = ent:EntIndex()
	return entity_tabs[index]
end


hook.add("EntityLinked",LinkEntity)
hook.add("EntityUnlinked",UnlinkEntity)
hook.add("PlayerDisconnected",UnlinkPlayer)

print("^3Entity code loaded.\n")