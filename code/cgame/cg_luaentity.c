#include "cg_local.h"

centity_t *qlua_getrealentity(int entnum) {
	//centity_t	*realent = NULL;
	centity_t	*tent = NULL;
	int numEnts = sizeof(cg_entities) / sizeof(cg_entities[0]);
	/*int i=0;
	int n=0;

	for (i = 0, tent = cg_entities, n = 1;
			i < numEnts;
			i++, tent++) {
			if(ent->currentState.number == tent->currentState.number) {
				if(tent != NULL) {
					return tent;
				}
			}
			n++;
	}
	CG_Printf("Unable To Find Entity: %i\n", ent->currentState.number);*/

	if ( entnum < 0 || entnum > numEnts ) {
		CG_Printf("Invalid Entity: %i\n", entnum);
	} else {
		tent = &cg_entities[entnum];
		if(tent != NULL) {
			return tent;
		}
	}
	
	return NULL;
}

void lua_cgentitytab(lua_State *L, centity_t *ent) {
	if(ent->luatablecent == 0) {
		lua_newtable(L);
		ent->luatablecent = qlua_storefunc(L,lua_gettop(L),0);
		//CG_Printf("Stored Table At %i\n",ent->luatablecent);
	} else {
		//CG_Printf("Didn't Store Table At %i\n",ent->luatablecent);
	}
}

int lua_cggetentitytable(lua_State *L) {
	centity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		//CG_Printf("ReCalled Table At %i\n",luaentity->luatablecent);
		lua_cgentitytab(L,luaentity);
		if(qlua_getstored(L,luaentity->luatablecent)) {
			return 1;
		}
	}
	return 0;
}


//lua_pushlightuserdata(L,cl);
void lua_pushentity(lua_State *L, centity_t *cl) {
	centity_t *ent = NULL;

	if(cl == NULL || cl->currentState.number == ENTITYNUM_MAX_NORMAL || cl->currentState.number < 0) {
		lua_pushnil(L);
		return;
	}

	lua_cgentitytab(L,cl);

	ent = (centity_t*)lua_newuserdata(L, sizeof(centity_t));
	memcpy(ent,cl,sizeof(centity_t));

	ent->currentState.number = cl->currentState.number;

	luaL_getmetatable(L, "Entity");
	lua_setmetatable(L, -2);
}

centity_t *lua_toentity(lua_State *L, int i) {
	centity_t	*luaentity;
	luaL_checktype(L,i,LUA_TUSERDATA);
	luaentity = (centity_t *)luaL_checkudata(L, i, "Entity");

	if (luaentity->currentState.number == cg.predictedPlayerEntity.currentState.number) {
		return &cg.predictedPlayerEntity;
	} else {
		luaentity = qlua_getrealentity(luaentity->currentState.number);
	}

	if (luaentity == NULL) luaL_typerror(L, i, "Entity");

	//CG_CalcEntityLerpPositions( luaentity );

	return luaentity;
}

centity_t *lua_toentityraw(lua_State *L, int i) {
	centity_t	*luaentity;
	luaL_checktype(L,i,LUA_TUSERDATA);
	luaentity = (centity_t *)luaL_checkudata(L, i, "Entity");

	if (luaentity == NULL) luaL_typerror(L, i, "Entity");

	if (luaentity->currentState.number == cg.predictedPlayerEntity.currentState.number) {
		return &cg.predictedPlayerEntity;
	}

	//CG_CalcEntityLerpPositions( luaentity );

	return luaentity;
}

int qlua_getpos(lua_State *L) {
	centity_t	*luaentity = lua_toentity(L,1);

	//luaL_checktype(L,1,LUA_TUSERDATA);

	//luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushvector(L,luaentity->lerpOrigin);
		return 1;
	}
	return 0;
}

int qlua_getlerppos(lua_State *L) {
	return qlua_getpos(L);
}

int qlua_setpos(lua_State *L) {
	centity_t	*luaentity;
	vec3_t		origin;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TVECTOR);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
			BG_EvaluateTrajectory( &luaentity->currentState.pos, cg.time, origin );
			lua_tovector(L,2,luaentity->currentState.pos.trBase);
			luaentity->currentState.pos.trDuration += (cg.time - luaentity->currentState.pos.trTime);
			luaentity->currentState.pos.trTime = cg.time;
			
			VectorCopy(luaentity->currentState.pos.trBase, luaentity->currentState.origin);
		return 1;
	}
	return 0;
}

int qlua_getangles(lua_State *L) {
	centity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushvector(L,luaentity->currentState.angles);
		return 1;
	}
	return 0;
}

int qlua_getlerpangles(lua_State *L) {
	centity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushvector(L,luaentity->lerpAngles);
		return 1;
	}
	return 0;
}

int qlua_setangles(lua_State *L) {
	centity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TVECTOR);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_tovector(L,2,luaentity->currentState.angles);
		return 1;
	}
	return 0;
}

int qlua_aimvec(lua_State *L) {
	centity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushvector(L,luaentity->currentState.angles);
		return 1;
	}
	return 0;
}

int qlua_isclient(lua_State *L) {
	centity_t	*luaentity;
	clientInfo_t	*ci;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);

	if(luaentity != NULL) {
		ci = &cgs.clientinfo[ luaentity->currentState.clientNum ];
		if(ci != NULL) {
			lua_pushboolean(L,1);
		} else {
			lua_pushboolean(L,0);
		}
		return 1;
	}
	return 0;
}

int qlua_isbot(lua_State *L) {
	centity_t	*luaentity;
	clientInfo_t	*ci;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		ci = &cgs.clientinfo[ luaentity->currentState.clientNum ];
		if(ci != NULL && ci->botSkill != 0) {
			lua_pushboolean(L,1);
		} else {
			lua_pushboolean(L,0);
		}
		return 1;
	}
	return 0;
}

int qlua_getclientinfo(lua_State *L) {
	centity_t	*luaentity;
	clientInfo_t	*ci;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		ci = &cgs.clientinfo[ luaentity->currentState.clientNum ];
		if(cg.snap && cg.snap->ps.commandTime != 0) {
			if(luaentity->currentState.clientNum == cg.clientNum) {
				ci->health = cg.snap->ps.stats[STAT_HEALTH];
				ci->armor = cg.snap->ps.stats[STAT_ARMOR];
				ci->curWeapon = cg.snap->ps.weapon;
#ifndef LUA_WEAPONS
				ci->ammo = cg.snap->ps.ammo[ci->curWeapon];
#else
				ci->ammo = BG_GetAmmo(cg.snap->ps.clientNum, ci->curWeapon);
#endif
			} else {
				ci->health = luaentity->currentState.health;
			}
		}
		CG_PushClientInfoTab(L,ci);
	}
	return 1;
}

int qlua_getotherentity(lua_State *L) {
	centity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(luaentity->currentState.otherEntityNum != ENTITYNUM_MAX_NORMAL) {
			lua_pushentity(L,&cg_entities[ luaentity->currentState.otherEntityNum ]);
			return 1;
		}
	}
	return 0;
}

int qlua_getotherentity2(lua_State *L) {
	centity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(luaentity->currentState.otherEntityNum2 != ENTITYNUM_MAX_NORMAL) {
			lua_pushentity(L,&cg_entities[ luaentity->currentState.otherEntityNum2 ]);
			return 1;
		}
	}
	return 0;
}

int qlua_getbytedir(lua_State *L) {
	centity_t	*luaentity;
	vec3_t		dir;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		ByteToDir( luaentity->currentState.eventParm, dir );
		lua_pushvector(L,dir);
		return 1;
	}
	return 0;
}

int qlua_entityid(lua_State *L) {
	centity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L,luaentity->currentState.number);
	}
	return 1;
}

int qlua_gettrx(lua_State *L) {
	centity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushtrajectory(L,&luaentity->currentState.pos);
		return 1;
	}
	return 0;
}

int lua_getweapon(lua_State *L) {
	centity_t	*luaentity;
	entityState_t *s1;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		s1 = &luaentity->currentState;
		if ( s1->weapon > WP_NUM_WEAPONS ) {
			s1->weapon = 0;
		}
		lua_pushinteger(L,s1->weapon);
		return 1;
	}
	return 0;
}

int qlua_getmodelindex(lua_State *L) {
	centity_t	*luaentity;
	entityState_t *s1;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		s1 = &luaentity->currentState;
		lua_pushinteger(L,s1->modelindex);
		lua_pushinteger(L,s1->modelindex2);
		return 2;
	}
	return 0;
}

int qlua_getmisctime(lua_State *L) {
	centity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L,luaentity->miscTime);
		return 1;
	}
	return 0;
}

int lua_customdraw(lua_State *L) {
	centity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TBOOLEAN);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		luaentity->customdraw = lua_toboolean(L,2);
	}
	return 0;
}

int	lua_classname(lua_State *L) {
	centity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentityraw(L,1); //Get raw entity so classname is consistant
	if(luaentity != NULL) {
		if ( luaentity->currentState.eType >= (ET_EVENTS) ) {
			lua_pushstring(L,"unknown");
			return 1;
		}

		switch ( luaentity->currentState.eType ) {
		default:
			lua_pushstring(L,"unknown");
			break;
		case ET_INVISIBLE:
		case ET_PUSH_TRIGGER:
		case ET_TELEPORT_TRIGGER:
			lua_pushstring(L,"trigger");
			break;
		case ET_GENERAL:
			lua_pushstring(L,"general");
			break;
		case ET_PLAYER:
			lua_pushstring(L,"player");
			break;
		case ET_ITEM:
			lua_pushstring(L,"item");
			break;
		case ET_MISSILE:
			lua_pushstring(L,"missile");
			break;
		case ET_MOVER:
			lua_pushstring(L,"mover");
			break;
		case ET_BEAM:
			lua_pushstring(L,"beam");
			break;
		case ET_PORTAL:
			lua_pushstring(L,"portal");
			break;
		case ET_SPEAKER:
			lua_pushstring(L,"speaker");
			break;
		case ET_GRAPPLE:
			lua_pushstring(L,"grapple");
			break;
		case ET_LUA:
			lua_pushstring(L,luaentity->currentState.luaname);
			break;
		}
		return 1;
	}
	return 0;
}

int qlua_settrx(lua_State *L) {
	centity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		luaentity->currentState.pos = *lua_totrajectory(L,2);
		return 1;
	}
	return 0;
}

int qlua_getflags(lua_State *L) {
	centity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L,luaentity->currentState.eFlags);
		return 1;
	}
	return 0;
}

int qlua_getflashtime(lua_State *L) {
	centity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushnumber(L,luaentity->muzzleFlashTime);
		return 1;
	}
	return 0;
}

int qlua_stopsounds(lua_State *L) {
	centity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		trap_S_StopLoopingSound(luaentity->currentState.number);
	}
	return 0;
}

int qlua_getctime(lua_State *L) {
	centity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L, luaentity->currentState.time);
		//lua_pushinteger(L, luaentity->currentState.time2);
		return 1;
	}
	return 0;
}

int qlua_getlegsanim(lua_State *L) {
	centity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L, (luaentity->currentState.legsAnim & ~ANIM_TOGGLEBIT));
		return 1;
	}
	return 0;
}

int qlua_gettorsoanim(lua_State *L) {
	centity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L, (luaentity->currentState.torsoAnim & ~ANIM_TOGGLEBIT));
		return 1;
	}
	return 0;
}

static int Entity_tostring (lua_State *L)
{
  lua_pushfstring(L, "Entity: %p", lua_touserdata(L, 1));
  return 1;
}

static int Entity_equal (lua_State *L)
{
	centity_t *e1 = lua_toentity(L,1);
	centity_t *e2 = lua_toentity(L,2);
	if(e1 != NULL && e2 != NULL) {
		//CG_Printf("EQ CHECK: %i %i\n",e1->currentState.clientNum,e2->currentState.clientNum);
		lua_pushboolean(L, (e1->currentState.clientNum == e2->currentState.clientNum) &&
		(e1->currentState.number == e2->currentState.number));
	} else {
		lua_pushboolean(L, 0);
	}
  return 1;
}

static const luaL_reg Entity_methods[] = {
  {"GetTime",		qlua_getctime},
  {"GetPos",		qlua_getpos},
  {"GetLerpPos",	qlua_getlerppos},
  {"SetPos",		qlua_setpos},
  {"GetTrajectory",	qlua_gettrx},
  {"SetTrajectory", qlua_settrx},
  {"GetAngles",		qlua_getangles},
  {"GetLerpAngles",	qlua_getlerpangles},
  {"SetAngles",		qlua_setangles},
  {"GetInfo",		qlua_getclientinfo},
  {"GetFlags",		qlua_getflags},
  {"GetFlashTime",	qlua_getflashtime},
  {"GetOtherEntity",	qlua_getotherentity},
  {"GetOtherEntity2",	qlua_getotherentity},
  {"GetByteDir",		qlua_getbytedir},
  {"GetModelIndex",		qlua_getmodelindex},
  {"ModelIndex",		qlua_getmodelindex},
  {"GetMiscTime",		qlua_getmisctime},
  {"EntIndex",		qlua_entityid},
  {"IsBot",			qlua_isbot},
  {"IsClient",		qlua_isclient},
  {"IsPlayer",		qlua_isclient},
  {"GetTable",		lua_cggetentitytable},
  {"Classname",		lua_classname},
  {"GetWeapon",		lua_getweapon},
  {"CustomDraw",	lua_customdraw},
  {"StopSound",		qlua_stopsounds},
  {"GetLegsAnim",	qlua_getlegsanim},
  {"GetTorsoAnim",	qlua_gettorsoanim},
  {0,0}
};

static const luaL_reg Entity_meta[] = {
  {"__tostring", Entity_tostring},
  {"__eq", Entity_equal},
  {0, 0}
};

int Entity_register (lua_State *L) {
	luaL_openlib(L, "Entity", Entity_methods, 0);

	luaL_newmetatable(L, "Entity");

	luaL_openlib(L, 0, Entity_meta, 0);
	lua_pushliteral(L, "__index");
	lua_pushvalue(L, -3);
	lua_rawset(L, -3);
	lua_pushliteral(L, "__metatable");
	lua_pushvalue(L, -3);
	lua_rawset(L, -3);

	lua_setglobal(L,"M_Entity");

	lua_pop(L, 1);
	return 1;
}

int qlua_unlink(lua_State *L) {
	centity_t *ent;
	luaL_checktype(L,1,LUA_TUSERDATA);

	ent = lua_toentity(L,1);
	if(ent != NULL) {
		//qlua_UnlinkEntity(ent);
	}
	return 0;
}

int qlua_link(lua_State *L) {
	centity_t *ent;
	luaL_checktype(L,1,LUA_TUSERDATA);

	ent = lua_toentity(L,1);
	if(ent != NULL) {
		//qlua_LinkEntity(ent);
	}
	return 0;
}

int qlua_localplayer(lua_State *L) {
	centity_t *ent = &cg.predictedPlayerEntity;//&cg_entities[ cg.clientNum ];
	if(cg.snap != NULL) {
		ent->currentState.clientNum = cg.snap->ps.clientNum;
	}
	if(ent != NULL) {
		lua_pushentity(L, ent);
		return 1;
	}
	return 0;
}

int qlua_entbyindex(lua_State *L) {
	centity_t *ent;

	luaL_checktype(L,1,LUA_TNUMBER);

	ent = qlua_getrealentity(lua_tonumber(L,1));
	if(ent != NULL) {
		lua_pushentity(L,ent);
		return 1;
	}
	return 0;
}

void CG_InitLuaEnts(lua_State *L) {
	Entity_register(L);
	//lua_register(L,"GetEntitiesByClass",qlua_getentitiesbyclass);
	//lua_register(L,"GetAllPlayers",qlua_getallplayers);
	lua_register(L,"LocalPlayer",qlua_localplayer);
	lua_register(L,"UnlinkEntity",qlua_unlink);
	lua_register(L,"LinkEntity",qlua_link);
	lua_register(L,"GetEntityByIndex",qlua_entbyindex);
}

qboolean IsEntity(lua_State *L, int i) {
	void *p = lua_touserdata(L, i);
	if (p != NULL) {  /* value is a userdata? */
		if (lua_getmetatable(L, i)) {  /* does it have a metatable? */
			lua_getfield(L, LUA_REGISTRYINDEX, "Entity");  /* get correct metatable */
			if (lua_rawequal(L, -1, -2)) {  /* does it have the correct mt? */
				lua_pop(L, 2);  /* remove both metatables */
				return qtrue;
			}
		}
	}
	return qfalse;
}