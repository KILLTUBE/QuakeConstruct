#include "cg_local.h"

void setTableRefDef(lua_State *L, char *str, refdef_t refdef) {
	int tabid;
	lua_pushstring(L, str);
	lua_createtable(L,8,0);
	tabid = lua_gettop(L);

	setTableString(L,"glsl_override","");

	setTableBoolean(L,"isRenderTarget",refdef.renderTarget);
	setTableInt(L,"renderTarget",refdef.rt_index);
	setTableInt(L,"flags",refdef.rdflags);

	setTableFloat(L,"x",refdef.x);
	setTableFloat(L,"y",refdef.y);
	setTableFloat(L,"width",refdef.width);
	setTableFloat(L,"height",refdef.height);
	setTableFloat(L,"fov_x",refdef.fov_x);
	setTableFloat(L,"fov_y",refdef.fov_y);
	setTableVector(L,"origin",refdef.vieworg);
	setTableVector(L,"angles",refdef.viewaxis[0]);
	
	setTableFloat(L,"zNear",refdef.zNear);
	setTableFloat(L,"zFar",refdef.zFar);

	setTableVector(L,"forward",refdef.viewaxis[0]);
	setTableVector(L,"right",refdef.viewaxis[1]);
	setTableVector(L,"up",refdef.viewaxis[2]);
	lua_rawset(L, -3);
}

void getTableVector(lua_State *L, char *str, vec3_t v) {
	lua_pushstring(L, str);
	lua_gettable(L, -2);
	lua_tovector(L, -1, v);
}

void CG_ApplyCGTab(lua_State *L) {
	lua_getglobal(L, "_CG");

	getTableVector(L,"viewOrigin",cg.refdef.vieworg);
}

void setTableScore(lua_State *L, score_t score) {
	lua_newtable(L);
	setTableInt(L,"accuracy",score.accuracy);
	setTableInt(L,"assistCount",score.assistCount);
	setTableInt(L,"captures",score.captures);
	setTableInt(L,"client",score.client);
	setTableInt(L,"defendCount",score.defendCount);
	setTableInt(L,"excellentCount",score.excellentCount);
	setTableInt(L,"guantletCount",score.guantletCount);
	setTableInt(L,"impressiveCount",score.impressiveCount);
	setTableInt(L,"perfect",score.perfect);
	setTableInt(L,"ping",score.ping);
	setTableInt(L,"powerUps",score.powerUps);
	setTableInt(L,"score",score.score);
	setTableInt(L,"scoreFlags",score.scoreFlags);
	setTableInt(L,"team",score.team);
	setTableInt(L,"time",score.time);
}


void setTableScores(lua_State *L) {
	int i;
	int tabid;
	int size = cg.numScores;

	lua_pushstring(L, "scores");
	lua_createtable(L,size,0);
	tabid = lua_gettop(L);

	for(i=0;i<size;i++) {
		lua_pushinteger(L,i+1);
		
		setTableScore(L,cg.scores[i]);

		lua_settable(L, tabid);
	}
	lua_rawset(L, -3);

	lua_pushstring(L, "teamScores");
	lua_createtable(L,2,0);
	tabid = lua_gettop(L);

	lua_pushinteger(L,TEAM_BLUE);
	lua_pushinteger(L,cg.teamScores[1]);
	lua_settable(L, tabid);

	lua_pushinteger(L,TEAM_RED);
	lua_pushinteger(L,cg.teamScores[0]);
	lua_settable(L, tabid);

	lua_rawset(L, -3);
}

void CG_PushCGTab(lua_State *L) {
	lua_newtable(L);

	setTableFloat(L,"damageTime",cg.damageTime);
	setTableFloat(L,"damageValue",cg.damageValue);
	setTableFloat(L,"damageX",cg.damageX);
	setTableFloat(L,"damageY",cg.damageY);
	setTableVector(L,"viewAngle",cg.refdef.viewaxis[0]);
	setTableVector(L,"viewOrigin",cg.refdef.vieworg);
	setTableFloat(L,"fov_x",cg.refdef.fov_x);
	setTableFloat(L,"fov_y",cg.refdef.fov_y);
	setTableInt(L,"itemPickup", cg.itemPickup);
	setTableInt(L,"itemPickupTime", cg.itemPickupTime);
	setTableInt(L,"weaponSelect", cg.weaponSelect);
	setTableInt(L,"weaponSelectTime", cg.weaponSelectTime);
	setTableInt(L,"lowAmmoWarning", cg.lowAmmoWarning);
	setTableRefDef(L,"refdef",cg.refdef);
	setTableBoolean(L,"showScores",cg.showScores);
	setTableScores(L);

	if(cg.snap != NULL) {
		setTableInt(L,"weapon", cg.snap->ps.weapon);

		setTableTable(L,"stats", cg.snap->ps.stats, STAT_MAX_HEALTH+1);
		setTableTable(L,"pers", cg.snap->ps.persistant, PERS_CAPTURES+1);
#ifndef LUA_WEAPONS
		setTableTable(L,"ammo", cg.snap->ps.ammo, WP_NUM_WEAPONS);
		//HFIXME Lua Weapon Code
#endif
		setTableTable(L,"powerups", cg.snap->ps.powerups, PW_NUM_POWERUPS);
	}
	lua_setglobal(L,"_CG");

}

void CG_PushClientInfoTab(lua_State *L, clientInfo_t *ci) {
	if(ci != NULL) {
		lua_newtable(L);

		setTableString(L,"name",ci->name);
		setTableInt(L,"health",ci->health);
		setTableInt(L,"armor",ci->armor);
		setTableInt(L,"ammo",ci->ammo);
		setTableInt(L,"score",ci->score);
		setTableBoolean(L,"connected",qtrue);
		setTableBoolean(L,"deferred",ci->deferred);
		setTableInt(L,"weapon",ci->curWeapon);
		setTableInt(L,"buttons",0);
		setTableString(L,"modelName",ci->modelName);
		setTableInt(L,"modelIcon",ci->modelIcon);
		setTableString(L,"skinName",ci->skinName);
		setTableInt(L,"gender",ci->gender);
		setTableInt(L,"handicap",ci->handicap);
		setTableInt(L,"legsModel",ci->legsModel);
		setTableInt(L,"headModel",ci->headModel);
		setTableInt(L,"torsoModel",ci->torsoModel);
		setTableInt(L,"legsSkin",ci->legsSkin);
		setTableInt(L,"headSkin",ci->headSkin);
		setTableInt(L,"torsoSkin",ci->torsoSkin);
		setTableInt(L,"team",ci->team);
		setTableInt(L,"powerups",ci->powerups);
		setTableString(L,"blueTeam",ci->blueTeam);
		setTableString(L,"redTeam",ci->redTeam);
		setTableInt(L,"botSkill",ci->botSkill);
		setTableVector(L,"color1",ci->color1);
		setTableVector(L,"color2",ci->color2);
		setTableVector(L,"headOffset",ci->headOffset);
	} else {
		lua_pushstring(L,"<CLIENT WAS NIL>");
		lua_error(L);
	}
}

/*cg.refdef.*/