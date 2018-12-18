#include "q_shared.h"
#include "bg_public.h"

void lua_pushPM(lua_State *L, pmove_t *pm) {
	pmove_t *pm2 = NULL;

	pm2 = (pmove_t*)lua_newuserdata(L, sizeof(pmove_t));
	memcpy(pm2,pm,sizeof(pmove_t));

	luaL_getmetatable(L, "PMove");
	lua_setmetatable(L, -2);
}

pmove_t *lua_toPM(lua_State *L, int i) {
	pmove_t	*pm;
	luaL_checktype(L,i,LUA_TUSERDATA);
	pm = (pmove_t *)luaL_checkudata(L, i, "PMove");

	if (pm == NULL) luaL_typerror(L, i, "PMove");

	return pm;
}

int pm_walking(lua_State *L) {
	pmove_t	*pm = PM_GetMove();//lua_toPM(L,1);
	return 0;
}

int pm_waterlevel(lua_State *L) {
	pmove_t	*pm = PM_GetMove();//lua_toPM(L,1);

	if(pm != NULL) {
		lua_pushinteger(L,pm->waterlevel);
		return 1;
	}

	return 0;
}

int pm_getvel(lua_State *L) {
	pmove_t	*pm = PM_GetMove();//lua_toPM(L,1);

	if(pm != NULL) {
		lua_pushvector(L,pm->ps->velocity);
		return 1;
	}

	return 0;
}

int pm_setvel(lua_State *L) {
	pmove_t	*pm = PM_GetMove();//lua_toPM(L,1);

	if(pm != NULL) {
		lua_tovector(L,2,pm->ps->velocity);
	}

	return 0;
}

int pm_getang(lua_State *L) {
	pmove_t	*pm = PM_GetMove();//lua_toPM(L,1);

	if(pm != NULL) {
		lua_pushvector(L,pm->ps->viewangles);
		return 1;
	}

	return 0;
}

int pm_setang(lua_State *L) {
	pmove_t	*pm = PM_GetMove();//lua_toPM(L,1);

	if(pm != NULL) {
		lua_tovector(L,2,pm->ps->viewangles);
	}

	return 0;
}

int pm_getpos(lua_State *L) {
	pmove_t	*pm = PM_GetMove();//lua_toPM(L,1);

	if(pm != NULL) {
		lua_pushvector(L,pm->ps->origin);
		return 1;
	}

	return 0;
}

int pm_setpos(lua_State *L) {
	pmove_t	*pm = PM_GetMove();//lua_toPM(L,1);

	if(pm != NULL) {
		lua_tovector(L,2,pm->ps->origin);
	}

	return 0;
}

int pm_getcmdscale(lua_State *L) {
	pmove_t	*pm = PM_GetMove();//lua_toPM(L,1);

	if(pm != NULL) {
		lua_pushnumber(L,PM_CmdScale(&pm->cmd));
		return 1;
	}

	return 0;
}

int pm_gettype(lua_State *L) {
	pmove_t	*pm = PM_GetMove();//lua_toPM(L,1);

	if(pm != NULL) {
		lua_pushnumber(L,pm->ps->pm_type);
		return 1;
	}

	return 0;
}

int pm_myindex(lua_State *L) {
	pmove_t	*pm = PM_GetMove();//lua_toPM(L,1);

	if(pm != NULL) {
		lua_pushnumber(L,pm->ps->clientNum);
		return 1;
	}

	return 0;
}

int pm_getmask(lua_State *L) {
	pmove_t	*pm = PM_GetMove();//lua_toPM(L,1);

	if(pm != NULL) {
		lua_pushnumber(L,pm->tracemask);
		return 1;
	}

	return 0;
}

int pm_setmask(lua_State *L) {
	pmove_t	*pm = PM_GetMove();//lua_toPM(L,1);

	luaL_checkinteger(L,2);

	pm->tracemask = lua_tointeger(L,2);
	//Com_Printf("Set Tracemask to %i.\n", pm->tracemask);

	return 0;
}

int pm_getflags(lua_State *L) {
	pmove_t *pm = PM_GetMove();

	if(pm != NULL) {
		lua_pushinteger(L,pm->ps->pm_flags);
		return 1;
	}
	return 0;
}

int pm_getmove(lua_State *L) {
	pmove_t	*pm = PM_GetMove();//lua_toPM(L,1);

	if(pm != NULL) {
		lua_pushnumber(L,(float)pm->cmd.forwardmove);
		lua_pushnumber(L,(float)pm->cmd.rightmove);
		lua_pushnumber(L,(float)pm->cmd.upmove);
		return 3;
	}

	return 0;
}

int pm_setmove(lua_State *L) {
	pmove_t	*pm = PM_GetMove();//lua_toPM(L,1);

	if(pm != NULL) {
		pm->cmd.forwardmove = luaL_optnumber(L,2,pm->cmd.forwardmove);
		pm->cmd.rightmove = luaL_optnumber(L,3,pm->cmd.rightmove);
		pm->cmd.upmove = luaL_optnumber(L,4,pm->cmd.upmove);
	}

	return 0;
}

int pm_getmins(lua_State *L) {
	pmove_t	*pm = PM_GetMove();//lua_toPM(L,1);
	if(pm != NULL) {
		lua_pushvector(L,pm->mins);
	}
	return 1;
}

int pm_getmaxs(lua_State *L) {
	pmove_t	*pm = PM_GetMove();//lua_toPM(L,1);
	if(pm != NULL) {
		lua_pushvector(L,pm->maxs);
	}
	return 1;
}

static int PM_tostring (lua_State *L)
{
	pmove_t *pm = lua_toPM(L,1);
	lua_pushfstring(L, "PlayerMove Data");
  return 1;
}

static const luaL_reg PM_meta[] = {
  {"__tostring", PM_tostring},
  {0, 0}
};

static const luaL_reg PM_methods[] = {
  {"GetFlags",pm_getflags},
  {"GetMove",pm_getmove},
  {"SetMove",pm_setmove},
  {"GetScale",pm_getcmdscale},
  {"GetType",pm_gettype},
  {"GetMask",pm_getmask},
  {"SetMask",pm_setmask},
  {"GetMins",pm_getmins},
  {"GetMaxs",pm_getmaxs},
  {"SetVelocity",pm_setvel},
  {"GetVelocity",pm_getvel},
  {"SetAngles",pm_setang},
  {"GetAngles",pm_getang},
  {"SetPos",pm_setpos},
  {"GetPos",pm_getpos},
  {"EntIndex",pm_myindex},
  {"Walking", pm_walking},
  {"WaterLevel", pm_waterlevel},
  {0,0}
};

int PM_register (lua_State *L) {
	luaL_openlib(L, "PMove", PM_methods, 0);

	luaL_newmetatable(L, "PMove");

	luaL_openlib(L, 0, PM_meta, 0);
	lua_pushliteral(L, "__index");
	lua_pushvalue(L, -3);
	lua_rawset(L, -3);
	lua_pushliteral(L, "__metatable");
	lua_pushvalue(L, -3);
	lua_rawset(L, -3);

	lua_setglobal(L,"M_PMove");

	lua_pop(L, 1);
	return 1;
}

int lpm_accel(lua_State *L) {
	float	wish,accel;
	vec3_t	dir;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);
	luaL_checktype(L,3,LUA_TNUMBER);

	lua_tovector(L,1,dir);
	wish = lua_tonumber(L,2);
	accel = lua_tonumber(L,3);

	PM_Accelerate(dir,wish,accel);
	return 0;
}

int lpm_walk(lua_State *L) {
	PM_WalkMove();
	return 0;
}

int lpm_fly(lua_State *L) {
	PM_FlyMove();
	return 0;
}

int lpm_noclip(lua_State *L) {
	PM_NoclipMove();
	return 0;
}

int lpm_air(lua_State *L) {
	PM_AirMove();
	return 0;
}

int lpm_dead(lua_State *L) {
	PM_DeadMove();
	return 0;
}

int lpm_crash(lua_State *L) {
	PM_CrashLand();
	return 0;
}

int lpm_water(lua_State *L) {
	PM_WaterMove();
	return 0;
}

int lpm_waterjump(lua_State *L) {
	PM_WaterJumpMove();
	return 0;
}

int lpm_drop(lua_State *L) {
	PM_Drop();
	return 0;
}

int lpm_friction(lua_State *L) {
	PM_Friction();
	return 0;
}

int lpm_movepl(lua_State *L) {
	PM_MovePlayer();
	return 0;
}

int lpm_slidemove(lua_State *L) {
	PM_StepSlideMove( lua_toboolean(L,1) );
	return 0;
}

int lpm_addevent(lua_State *L) {
	luaL_checkinteger(L,1);

	PM_AddEvent( lua_tonumber(L,1) );
	return 0;
}

void BG_InitLuaPMove(lua_State *L) {
	PM_register(L);

	lua_register(L,"PM_Accelerate",lpm_accel);
	lua_register(L,"PM_WalkMove",lpm_walk);
	lua_register(L,"PM_FlyMove",lpm_fly);
	lua_register(L,"PM_NoclipMove",lpm_noclip);
	lua_register(L,"PM_AirMove",lpm_air);
	lua_register(L,"PM_DeadMove",lpm_dead);
	lua_register(L,"PM_CrashLand",lpm_crash);
	lua_register(L,"PM_WaterMove",lpm_water);
	lua_register(L,"PM_WaterJumpMove",lpm_waterjump);
	lua_register(L,"PM_Drop",lpm_drop);
	lua_register(L,"PM_Friction",lpm_friction);
	lua_register(L,"PM_MovePlayer",lpm_movepl);
	lua_register(L,"PM_StepSlideMove",lpm_slidemove);
	lua_register(L,"PM_AddEvent",lpm_addevent);
}