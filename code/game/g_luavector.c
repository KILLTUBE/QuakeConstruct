#include "g_local.h"

void lua_pushtrace(lua_State *L, trace_t results) {
	lua_newtable(L);

	if(results.fraction != 1.0) {
		lua_pushstring(L, "allsolid");
		lua_pushboolean(L,results.allsolid);
		lua_rawset(L, -3);

		lua_pushstring(L, "contents");
		lua_pushinteger(L,results.contents);
		lua_rawset(L, -3);

		if(results.entityNum != ENTITYNUM_MAX_NORMAL) {
			lua_pushstring(L, "entity");
			lua_pushentity(L,&g_entities[ results.entityNum ]);
			lua_rawset(L, -3);
		}

		lua_pushstring(L, "entitynum");
		lua_pushinteger(L,results.entityNum);
		lua_rawset(L, -3);

		lua_pushstring(L, "normal");
		lua_pushvector(L,results.plane.normal);
		lua_rawset(L, -3);

		lua_pushstring(L, "surfaceflags");
		lua_pushinteger(L,results.surfaceFlags);
		lua_rawset(L, -3);
	}

	lua_pushstring(L, "startsolid");
	lua_pushboolean(L,results.startsolid);
	lua_rawset(L, -3);

	lua_pushstring(L, "endpos");
	lua_pushvector(L,results.endpos);
	lua_rawset(L, -3);

	lua_pushstring(L, "fraction");
	lua_pushnumber(L,results.fraction);
	lua_rawset(L, -3);

	lua_pushstring(L, "hit");
	lua_pushboolean(L, (results.fraction != 1.0));
	lua_rawset(L, -3);
}

int qlua_trace(lua_State *L) {
	trace_t results;
	vec3_t start, end;
	vec3_t mins, maxs;
	gentity_t *ent;
	int pass=ENTITYNUM_NONE, mask=MASK_ALL;
	int top = lua_gettop(L);

	if(top > 1) {
		lua_tovector(L,1,start);
		lua_tovector(L,2,end);
		VectorSet(mins,vec3_origin[0],vec3_origin[1],vec3_origin[2]);
		VectorSet(maxs,vec3_origin[0],vec3_origin[1],vec3_origin[2]);
		if(top > 2) {
			if(lua_type(L,3) == LUA_TNUMBER) {
				pass = lua_tointeger(L,3);
			} else if(lua_type(L,3) == LUA_TUSERDATA) {
				ent = lua_toentity(L,3);
				if(ent != NULL) {
					pass = ent->s.number;
				}
			}
			if(top > 3)
				mask = lua_tointeger(L,4);
			if(top > 4) {
				if(lua_type(L,5) == LUA_TVECTOR) lua_tovector(L,5,mins);
				if(lua_type(L,6) == LUA_TVECTOR) lua_tovector(L,6,maxs);
			}
		}

		trap_Trace( &results, 
			start, 
			mins, 
			maxs, 
			end, 
			pass, 
			mask );

		lua_pushtrace(L, results);

		return 1;
	}


	return 0;
}

void G_InitLuaVector(lua_State *L) {
	BG_InitLuaVector(L);

	lua_register(L,"TraceLine",qlua_trace);
}