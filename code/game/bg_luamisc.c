#include "q_shared.h"
#include "bg_public.h"

char *toChars(const char *str) {
	return (char *)str;
}

int additem(lua_State *L) {
	int id;
	gitem_t item;
	qboolean replace;

	//memset(&item,0,sizeof(item));

	luaL_checktype(L,1,LUA_TNUMBER);
	luaL_checktype(L,2,LUA_TBOOLEAN);
	luaL_checktype(L,3,LUA_TSTRING);

	id = lua_tointeger(L,1);
	replace = lua_toboolean(L,2);

	item.classname = toChars(lua_tostring(L,3));
	item.giType = luaL_optinteger(L,4,IT_BAD);
	item.giTag = luaL_optinteger(L,5,WP_NONE);
	item.icon = toChars(luaL_optstring(L,6,"icons/iconw_grapple"));
	item.pickup_name =  toChars(luaL_optstring(L,7,"Unknown Item"));
	item.pickup_sound = toChars(luaL_optstring(L,8,"sound/misc/w_pkup.wav"));
	item.quantity = luaL_optinteger(L,9,0);

	item.world_model[0] = toChars(luaL_optstring(L,10,"models/powerups/health/medium_cross.md3"));
	item.world_model[1] = toChars(luaL_optstring(L,11,""));
	item.world_model[2] = toChars(luaL_optstring(L,12,""));
	item.world_model[3] = toChars(luaL_optstring(L,13,""));

	item.precaches = "";
	item.sounds = "";

	BG_AddItem(&item, id, replace);
	return 0;
}

int qlua_finditem(lua_State *L) {
	const char *str = "";
	luaL_checkstring(L,1);

	str = lua_tostring(L,1);

	lua_pushinteger(L,BG_FindItemIndexByClass(str));
	return 1;
}

/*int qlua_pmove(lua_State *L) {
	pmove_t		pm;
	usercmd_t	*ucmd;
	
	memset (&pm, 0, sizeof(pm));
	memset (&pm.ps, 0, sizeof(pm.ps));
	memset (&pm.cmd, 0, sizeof(pm.cmd));


	if ( pm.ps->pm_type == PM_DEAD ) {
		pm.tracemask = MASK_PLAYERSOLID & ~CONTENTS_BODY;
	}
	else if ( ent->r.svFlags & SVF_BOT ) {
		pm.tracemask = MASK_PLAYERSOLID | CONTENTS_BOTCLIP;
	}
	else {
		pm.tracemask = MASK_PLAYERSOLID;
	}
	pm.trace = trap_Trace;
	pm.pointcontents = trap_PointContents;
	pm.debugLevel = g_debugMove.integer;
	pm.noFootsteps = ( g_dmflags.integer & DF_NO_FOOTSTEPS ) > 0;

	pm.pmove_fixed = pmove_fixed.integer;
	pm.pmove_msec = pmove_msec.integer;
	Pmove (&pm,L);
}*/

void BG_InitLuaMisc(lua_State *L) {
	lua_register(L,"AddItem",additem);
	lua_register(L,"FindItemByClassname",qlua_finditem);
}