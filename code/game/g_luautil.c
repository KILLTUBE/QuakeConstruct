#include "g_local.h"

int luautil_pointcontents(lua_State *L) {
	vec3_t point;
	int pass = -1;
	int contents;

	//luaL_checkudata(L,1,"Vector");
	if(lua_type(L,1) != LUA_TUSERDATA) return 0;

	lua_tovector(L,1,point);

	if(lua_type(L,2) == LUA_TNUMBER) {
		pass = lua_tonumber(L,2);
	}
	contents = trap_PointContents(point,pass);

	lua_pushinteger(L,contents);
	return 1;
}

int luautil_getviewheight(lua_State *L) {
	gentity_t *ent = lua_toentity(L,1);
	
	if(ent == NULL || ent->client == NULL) return 0;
	lua_pushinteger(L,ent->client->ps.viewheight);
	return 1;
}

int luautil_itemInfo(lua_State *L) {
	int icon = 0;
	int size = bg_numItems;
	gitem_t item2;

	luaL_checktype(L,1,LUA_TNUMBER);

	icon = lua_tointeger(L,1);

	if(icon <= 0 || icon > size) {
		lua_pushstring(L,"Item Index Out Of Bounds\n");
		lua_error(L);
		return 1;
	}

	item2 = bg_itemlist[icon];

	lua_newtable(L);

	setTableString(L,"classname",item2.classname);
	setTableInt(L,"tag",item2.giTag);
	setTableInt(L,"type",item2.giType);
	setTableString(L,"pickupsound",item2.pickup_sound);
	setTableString(L,"pickupname",item2.pickup_name);
	setTableInt(L,"quantity",item2.quantity);

	return 1;
}

static const luaL_reg Util_methods[] = {
  {"GetPointContents",	luautil_pointcontents},
  {"GetViewHeight",		luautil_getviewheight},
  {"ItemInfo",			luautil_itemInfo},
  {0,0}
};

void G_InitLuaUtil(lua_State *L) {
	luaL_openlib(L, "util", Util_methods, 0);
}