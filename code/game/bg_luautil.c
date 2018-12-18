#include "q_shared.h"
#ifdef GAME
	#include "../game/g_local.h"
#else
	#include "../cgame/cg_local.h"
#endif

int bglua_getcstring(lua_State *L) {
	int			index;
	char		info[MAX_INFO_STRING];

	luaL_checktype(L,1,LUA_TNUMBER);

	index = lua_tointeger(L,1);
	if(index < 0 || index > MAX_CONFIGSTRINGS) {
		lua_pushstring(L,"Bad index for GetConfigString");
		lua_error(L);
	}

#ifdef GAME
	trap_GetConfigstring( index, info, sizeof(info) );
#else
	Q_strncpyz( info, CG_ConfigString(index), sizeof(info) );
#endif

	lua_pushstring(L,info);

	return 1;
}

int bglua_infoforkey(lua_State *L) {
	const char *info;
	const char *key;

	luaL_checkstring(L,1);
	luaL_checkstring(L,2);

	info = lua_tostring(L,1);
	key = lua_tostring(L,2);

	lua_pushstring(L,Info_ValueForKey( info, key ));
	return 1;
}

void BG_InitLuaUtil(lua_State *L) {
	lua_register(L,"GetConfigString",bglua_getcstring);
	lua_register(L,"CS_ValueForKey",bglua_infoforkey);
}