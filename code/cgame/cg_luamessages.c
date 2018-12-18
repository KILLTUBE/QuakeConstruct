#include "cg_local.h"

void qlua_HandleMessage() {
	if(GetClientLuaState() != NULL) {
		int data = trap_N_ReadByte();
		qlua_gethook(GetClientLuaState(),"_HandleMessage");
		lua_pushinteger(GetClientLuaState(),data);
		qlua_pcall(GetClientLuaState(),1,0,qtrue);
	}
}

int qlua_readbyte(lua_State *L) {
	lua_pushinteger(L,trap_N_ReadByte());
	return 1;
}

int qlua_readshort(lua_State *L) {
	lua_pushinteger(L,trap_N_ReadShort());
	return 1;
}

int qlua_readlong(lua_State *L) {
	lua_pushinteger(L,trap_N_ReadLong());
	return 1;
}

int qlua_readstring(lua_State *L) {
	char *str = trap_N_ReadString();
	lua_pushstring(L,str);
	return 1;
}

int qlua_readfloat(lua_State *L) {
	lua_pushnumber(L,trap_N_ReadFloat());
	return 1;
}

int qlua_readbits(lua_State *L) {
	int n = lua_tointeger(L,1);
	lua_pushnumber(L,trap_N_ReadBits(n));
	return 1;
}

static const luaL_reg Message_methods[] = {
  {"ReadByte",		qlua_readbyte},
  {"ReadShort",		qlua_readshort},
  {"ReadLong",		qlua_readlong},
  {"ReadString",	qlua_readstring},
  {"ReadFloat",		qlua_readfloat},
  {"ReadBits",		qlua_readbits},
  {0,0}
};

void CG_InitLuaMessages(lua_State *L) {
	luaL_openlib(L, "_message", Message_methods, 0);
}