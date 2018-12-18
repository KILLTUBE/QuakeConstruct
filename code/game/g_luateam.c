#include "g_local.h"

qboolean LuaTeamChanged(gentity_t *luaentity,int team) {
	lua_State *L = GetServerLuaState();
	if(L == NULL) return qtrue;

	qlua_gethook(L, "PlayerTeamChanged");
	lua_pushentity(L,luaentity);
	lua_pushinteger(L,team);
	qlua_pcall(L,2,1,qtrue);
	if(lua_type(L,-1) == LUA_TBOOLEAN) {
		if(lua_toboolean(L,-1)) {
			lua_pop(L,1);
			return qfalse;
		} else {
			lua_pop(L,1);
			return qfalse;
		}
	}
	lua_pop(L,1);

	return qtrue;
}

int lua_tcustomscores(lua_State *L) {
	level.customScores = lua_toboolean(L,1);
	return 0;
}

int lua_tawardscore(lua_State *L) {
	vec3_t	origin;
	int team = lua_tointeger(L,2);
	int score = lua_tointeger(L,3);
	qboolean sound = lua_toboolean(L,4);

	lua_tovector(L,1,origin);

	if(team < TEAM_FREE) team = TEAM_FREE;
	if(team >= TEAM_NUM_TEAMS) team = TEAM_NUM_TEAMS-1;

	AddTeamScore(origin,team,score,sound);

	level.teamScores[ team ] += score;

	CalculateRanks();
	return 0;
}

static const luaL_reg Team_methods[] = {
  {"CustomScores",	lua_tcustomscores},
  {"AwardScore",	lua_tawardscore},
  {0,0}
};

void G_InitLuaTeam(lua_State *L) {
	level.customScores = qfalse;
	luaL_openlib(L, "team", Team_methods, 0);
}