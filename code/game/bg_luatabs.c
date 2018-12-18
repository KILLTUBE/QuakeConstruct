#include "q_shared.h"
#include "bg_public.h"

void setTableInt(lua_State *L, char *str, int v) {
	lua_pushstring(L, str);
	lua_pushinteger(L,v);
	lua_rawset(L, -3);
}

void setTableFloat(lua_State *L, char *str, float v) {
	lua_pushstring(L, str);
	lua_pushnumber(L,v);
	lua_rawset(L, -3);
}

void setTableVector(lua_State *L, char *str, vec3_t v) {
	lua_pushstring(L, str);
	lua_pushvector(L, v);
	lua_rawset(L, -3);
}

void setTableString(lua_State *L, char *str, char *v) {
	lua_pushstring(L, str);
	lua_pushstring(L, v);
	lua_rawset(L, -3);
}

void setTableBoolean(lua_State *L, char *str, qboolean v) {
	lua_pushstring(L, str);
	lua_pushboolean(L, v);
	lua_rawset(L, -3);
}

void setTableTable(lua_State *L, char *str, int tab[], int size) {
	int i;
	int tabid;

	lua_pushstring(L, str);
	lua_createtable(L,size,0);
	tabid = lua_gettop(L);

	for(i=0;i<size;i++) {
		lua_pushinteger(L,i+1);
		lua_pushinteger(L,tab[i]);
		lua_settable(L, tabid);
	}
	lua_rawset(L, -3);
}

float qlua_pullfloat(lua_State *L, char *str, qboolean req, float def) {
	float v = def;
	lua_pushstring(L,str);
	lua_gettable(L,1);
	if(req) luaL_checktype(L,lua_gettop(L),LUA_TNUMBER);
	if(lua_type(L,lua_gettop(L)) == LUA_TNUMBER) {
		v = lua_tonumber(L,lua_gettop(L));
	}
	return v;
}

float qlua_pullfloat_i(lua_State *L, int i, qboolean req, float def, int m) {
	float v = def;
	lua_pushinteger(L,i);
	lua_gettable(L,m);
	if(req) luaL_checktype(L,lua_gettop(L),LUA_TNUMBER);
	if(lua_type(L,lua_gettop(L)) == LUA_TNUMBER) {
		v = lua_tonumber(L,lua_gettop(L));
	}
	return v;
}

int qlua_pullboolean(lua_State *L, char *str, qboolean req, qboolean def) {
	qboolean v = def;
	lua_pushstring(L,str);
	lua_gettable(L,1);
	if(req) luaL_checktype(L,lua_gettop(L),LUA_TBOOLEAN);
	if(lua_type(L,lua_gettop(L)) == LUA_TBOOLEAN) {
		v = lua_toboolean(L,lua_gettop(L));
	}
	return v;
}

int qlua_pullint(lua_State *L, char *str, qboolean req, int def) {
	int v = def;
	lua_pushstring(L,str);
	lua_gettable(L,1);
	if(req) luaL_checktype(L,lua_gettop(L),LUA_TNUMBER);
	if(lua_type(L,lua_gettop(L)) == LUA_TNUMBER) {
		v = lua_tointeger(L,lua_gettop(L));
	}
	return v;
}

const char *qlua_pullstring(lua_State *L, char *str, qboolean req, const char *def) {
	const char *v = def;
	lua_pushstring(L,str);
	lua_gettable(L,1);
	if(req) luaL_checktype(L,lua_gettop(L),LUA_TSTRING);
	if(lua_type(L,lua_gettop(L)) == LUA_TNUMBER) {
		v = lua_tostring(L,lua_gettop(L));
	}
	return v;
}

int qlua_pullint_i(lua_State *L, int i, qboolean req, int def, int m) {
	int v = def;
	lua_pushinteger(L,i);
	lua_gettable(L,m);
	if(req) luaL_checktype(L,lua_gettop(L),LUA_TNUMBER);
	if(lua_type(L,lua_gettop(L)) == LUA_TNUMBER) {
		v = lua_tointeger(L,lua_gettop(L));
	}
	return v;
}

void qlua_pullvector(lua_State *L, char *str, vec3_t vec, qboolean req) {
	vec3_t v;
	VectorClear(v);
	lua_pushstring(L,str);
	lua_gettable(L,1);
	if(req) luaL_checktype(L,lua_gettop(L),LUA_TVECTOR);
	if(lua_type(L,lua_gettop(L)) == LUA_TVECTOR) {
		lua_tovector(L,lua_gettop(L),v);
		vec[0] = v[0];
		vec[1] = v[1];
		vec[2] = v[2];
	}
}

void qlua_pullvector_i(lua_State *L, int i, vec3_t vec, qboolean req, int m) {
	vec3_t v;
	VectorClear(v);
	lua_pushinteger(L,i);
	lua_gettable(L,m);
	if(req) luaL_checktype(L,lua_gettop(L),LUA_TVECTOR);
	if(lua_type(L,lua_gettop(L)) == LUA_TVECTOR) {
		lua_tovector(L,lua_gettop(L),v);
		vec[0] = v[0];
		vec[1] = v[1];
		vec[2] = v[2];
	}
}