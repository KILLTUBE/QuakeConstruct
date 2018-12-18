#include "q_shared.h"
#include "bg_public.h"

void lua_pushtrajectory(lua_State *L, trajectory_t *tr) {
	trajectory_t *tr2 = NULL;

	tr2 = (trajectory_t*)lua_newuserdata(L, sizeof(trajectory_t));
	memcpy(tr2,tr,sizeof(trajectory_t));

	luaL_getmetatable(L, "Trajectory");
	lua_setmetatable(L, -2);
}

trajectory_t *lua_totrajectory(lua_State *L, int i) {
	trajectory_t	*tr;
	luaL_checktype(L,i,LUA_TUSERDATA);
	tr = (trajectory_t *)luaL_checkudata(L, i, "Trajectory");

	if (tr == NULL) luaL_typerror(L, i, "Trajectory");

	return tr;
}

int lua_newtrajectory(lua_State *L) {
	trajectory_t	tr;

	lua_pushtrajectory(L,&tr);
	return 1;
}

int qlua_getbase(lua_State *L) {
	trajectory_t	*tr = lua_totrajectory(L,1);

	if(tr != NULL) {
		lua_pushvector(L,tr->trBase);
		return 1;
	}
	return 0;
}

int qlua_setbase(lua_State *L) {
	trajectory_t	*tr = lua_totrajectory(L,1);

	luaL_checktype(L,2,LUA_TVECTOR);

	if(tr != NULL) {
		lua_tovector(L,2,tr->trBase);
		return 1;
	}
	return 0;
}

int qlua_getdelta(lua_State *L) {
	trajectory_t	*tr = lua_totrajectory(L,1);

	if(tr != NULL) {
		lua_pushvector(L,tr->trDelta);
		return 1;
	}
	return 0;
}

int qlua_setdelta(lua_State *L) {
	trajectory_t	*tr = lua_totrajectory(L,1);

	luaL_checktype(L,2,LUA_TVECTOR);

	if(tr != NULL) {
		lua_tovector(L,2,tr->trDelta);
		return 1;
	}
	return 0;
}

int qlua_gettime(lua_State *L) {
	trajectory_t	*tr = lua_totrajectory(L,1);

	if(tr != NULL) {
		lua_pushinteger(L,tr->trTime);
		return 1;
	}
	return 0;
}

int qlua_settime(lua_State *L) {
	trajectory_t	*tr = lua_totrajectory(L,1);

	luaL_checktype(L,2,LUA_TNUMBER);

	if(tr != NULL) {
		tr->trTime = lua_tonumber(L,2);
		return 1;
	}
	return 0;
}

int qlua_gettype(lua_State *L) {
	trajectory_t	*tr = lua_totrajectory(L,1);

	if(tr != NULL) {
		lua_pushinteger(L,tr->trType);
		return 1;
	}
	return 0;
}

int qlua_settype(lua_State *L) {
	trajectory_t	*tr = lua_totrajectory(L,1);

	luaL_checktype(L,2,LUA_TNUMBER);

	if(tr != NULL) {
		tr->trType = lua_tonumber(L,2);
		return 1;
	}
	return 0;
}

int qlua_getduration(lua_State *L) {
	trajectory_t	*tr = lua_totrajectory(L,1);

	if(tr != NULL) {
		lua_pushinteger(L,tr->trDuration);
		return 1;
	}
	return 0;
}

int qlua_setduration(lua_State *L) {
	trajectory_t	*tr = lua_totrajectory(L,1);

	luaL_checktype(L,2,LUA_TNUMBER);

	if(tr != NULL) {
		tr->trDuration = lua_tonumber(L,2);
		return 1;
	}
	return 0;
}

int qlua_evaluate(lua_State *L) {
	trajectory_t	*tr = lua_totrajectory(L,1);
	vec3_t			res;

	luaL_checktype(L,2,LUA_TNUMBER);

	if(tr != NULL) {
		BG_EvaluateTrajectory(tr,lua_tonumber(L,2),res);
		lua_pushvector(L,res);
		return 1;
	}
	return 0;
}

int qlua_evaluatedelta(lua_State *L) {
	trajectory_t	*tr = lua_totrajectory(L,1);
	vec3_t			res;

	luaL_checktype(L,2,LUA_TNUMBER);

	if(tr != NULL) {
		BG_EvaluateTrajectoryDelta(tr,lua_tonumber(L,2),res);
		lua_pushvector(L,res);
		return 1;
	}
	return 0;
}

static int Tr_tostring (lua_State *L)
{
	trajectory_t *tr = lua_totrajectory(L,1);
	lua_pushfstring(L, "Trajectory:\nBase: %f,%f,%f\nDelta: %f,%f,%f\n",
		tr->trBase[0],
		tr->trBase[1],
		tr->trBase[2],
		tr->trDelta[0],
		tr->trDelta[1],
		tr->trDelta[2]
	);
  return 1;
}

static int Tr_equal (lua_State *L)
{
	if(qtrue) {
		lua_pushboolean(L, 1);
	} else {
		lua_pushboolean(L, 0);
	}
  return 1;
}

static const luaL_reg Tr_methods[] = {
  {"GetBase",		qlua_getbase},
  {"SetBase",		qlua_setbase},
  {"GetDelta",		qlua_getdelta},
  {"SetDelta",		qlua_setdelta},
  {"GetTime",		qlua_gettime},
  {"SetTime",		qlua_settime},
  {"GetType",		qlua_gettype},
  {"SetType",		qlua_settype},
  {"GetDuration",	qlua_getduration},
  {"SetDuration",	qlua_setduration},
  {"Evaluate",		qlua_evaluate},
  {"EvaluateDelta",	qlua_evaluatedelta},
  {0,0}
};

static const luaL_reg Tr_meta[] = {
  {"__tostring", Tr_tostring},
  {"__eq", Tr_equal},
  {0, 0}
};

int Tr_register (lua_State *L) {
	luaL_openlib(L, "Trajectory", Tr_methods, 0);

	luaL_newmetatable(L, "Trajectory");

	luaL_openlib(L, 0, Tr_meta, 0);
	lua_pushliteral(L, "__index");
	lua_pushvalue(L, -3);
	lua_rawset(L, -3);
	lua_pushliteral(L, "__metatable");
	lua_pushvalue(L, -3);
	lua_rawset(L, -3);

	lua_setglobal(L,"M_Trajectory");

	lua_pop(L, 1);

	lua_register(L,"Trajectory",lua_newtrajectory);
	return 1;
}

void BG_InitLuaTrajectory(lua_State *L) {
	Tr_register(L);
}