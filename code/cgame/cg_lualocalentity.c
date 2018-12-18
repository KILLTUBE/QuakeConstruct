#include "cg_local.h"

int idx = 1;

localEntity_t *qlua_lgetrealentity( int id ) {
	int zc = 0;
	qboolean b = qfalse;
	localEntity_t	*le, *next;
	localEntity_t	cg_activeLocalEntities = CG_GetLocalEntityList();

	// walk the list backwards, so any new local entities generated
	// (trails, marks, etc) will be present this frame
	le = cg_activeLocalEntities.prev;

	for ( ; le != &cg_activeLocalEntities ; le = next ) {
		// grab next now, so if the local entity is freed we
		// still have it

		next = le->prev;

		if(zc > MAX_LOCAL_ENTITIES+1) {
			return NULL;
		}

/*		if(next->id == 0) {
			le = cg_activeLocalEntities.prev;
			zc ++;
		}*/

		zc++;

		if(le != NULL && le->id == id) {
			return le;
		}
	}
	return NULL;
}

/*int qlua_lgetnextid() {
	int nextid = 1;
	int x;
	qboolean bad = qfalse;
	localEntity_t	*le, *next;
	localEntity_t	cg_activeLocalEntities = CG_GetLocalEntityList();

	for(x=0; x<2000; x++) {
		bad = qfalse;
		le = cg_activeLocalEntities.prev;
		for ( ; le != &cg_activeLocalEntities ; le = next ) {
			next = le->prev;
			if(le->id == nextid) {
				bad = qtrue;
			}
		}
		if(bad) {
			nextid++;
		} else {
			CG_Printf("%i\n",nextid);
			return nextid;
		}
	}
	return 2001;
}*/

void lua_leentitytab(lua_State *L, localEntity_t *ent) {
	if(ent->luatable == 0) {
		lua_newtable(L);
		ent->luatable = qlua_storefunc(L,lua_gettop(L),0);
	}
}

int lua_legetentitytable(lua_State *L) {
	localEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		if(qlua_getstored(L,luaentity->luatable)) {
			return 1;
		}
	}
	return 0;
}

void lua_pushlocalentity(lua_State *L, localEntity_t *cl) {
	localEntity_t *le = NULL;

	if(cl == NULL) {
		lua_pushnil(L);
		return;
	}

	if(cl->id == 0) {
		cl->id = idx;
		idx++;
		if(idx > 20000) {
			idx = 1;
		}
	}

	lua_leentitytab(L,cl);

	le = (localEntity_t*)lua_newuserdata(L, sizeof(localEntity_t));
	//memcpy(le,cl,sizeof(localEntity_t));
	*le = *cl;

	luaL_getmetatable(L, "LocalEntity");
	lua_setmetatable(L, -2);
}

localEntity_t *lua_tolocalentity(lua_State *L, int i) {
	localEntity_t	*ptr = NULL;
	localEntity_t	*luaentity;

	luaL_checktype(L,i,LUA_TUSERDATA);

	ptr = (localEntity_t *)luaL_checkudata(L, i, "LocalEntity");//lua_touserdata(L, i);
	//luaentity2 = *ptr;

	if (ptr == NULL) luaL_typerror(L, i, "LocalEntity");

	luaentity = qlua_lgetrealentity(ptr->id);

	if (luaentity == NULL) return NULL; //luaL_typerror(L, i, "LocalEntity");

	return luaentity;
}

int qlua_lgetpos(lua_State *L) {
	localEntity_t	*luaentity;
	vec3_t		origin;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		BG_EvaluateTrajectory(&luaentity->pos,cg.time,origin);
		lua_pushvector(L,origin);
		return 1;
	}
	return 0;
}

int qlua_lsetpos(lua_State *L) {
	localEntity_t	*luaentity;
	vec3_t		origin;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TVECTOR);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		BG_EvaluateTrajectory(&luaentity->pos, cg.time, origin );
		lua_tovector(L,2,luaentity->pos.trBase);
		luaentity->pos.trDuration += (cg.time - luaentity->pos.trTime);
		luaentity->pos.trTime = cg.time;

		VectorCopy(luaentity->pos.trBase,luaentity->refEntity.origin);
		return 1;
	}
	return 0;
}

int qlua_lgetvelocity(lua_State *L) {
	localEntity_t	*luaentity;
	vec3_t		vel;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		BG_EvaluateTrajectoryDelta(&luaentity->pos,cg.time,vel);
		lua_pushvector(L,vel);
		return 1;
	}
	return 0;
}

int qlua_lsetvelocity(lua_State *L) {
	localEntity_t	*luaentity;
	vec3_t		origin;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TVECTOR);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		BG_EvaluateTrajectory( &luaentity->pos, cg.time, origin );
		VectorCopy(origin, luaentity->pos.trBase);
		luaentity->pos.trDuration += (cg.time - luaentity->pos.trTime);
		luaentity->pos.trTime = cg.time;
		lua_tovector(L,2,luaentity->pos.trDelta);
		return 1;
	}
	return 0;
}

int qlua_lgetanglevelocity(lua_State *L) {
	localEntity_t	*luaentity;
	vec3_t		vel;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		BG_EvaluateTrajectoryDelta(&luaentity->angles,cg.time,vel);
		lua_pushvector(L,vel);
		return 1;
	}
	return 0;
}

int qlua_lsetanglevelocity(lua_State *L) {
	localEntity_t	*luaentity;
	vec3_t		angle;
	vec3_t		delta;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TVECTOR);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		BG_EvaluateTrajectory( &luaentity->angles, cg.time, angle );
		VectorCopy(angle, luaentity->angles.trBase);
		luaentity->angles.trDuration += (cg.time - luaentity->angles.trTime);
		luaentity->angles.trTime = cg.time;
		lua_tovector(L,2,luaentity->angles.trDelta);
		VectorCopy(luaentity->angles.trDelta,delta);
		//CG_Printf("SetAngleVelocity: %f,%f,%f\n", delta[0], delta[1], delta[2]);
		if(VectorLength(delta) <= 1) {
			luaentity->angles.trType = TR_STATIONARY;
			//CG_Printf("SetAngleVelocity: STATIONARY\n");
		} else {
			luaentity->angles.trType = TR_LINEAR;
			//CG_Printf("SetAngleVelocity: LINEAR\n");
		}
		return 1;
	}
	return 0;
}


int qlua_lgetangles(lua_State *L) {
	localEntity_t	*luaentity;
	vec3_t			angles;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		BG_EvaluateTrajectory(&luaentity->angles,cg.time,angles);
		lua_pushvector(L,angles);
		return 1;
	}
	return 0;
}

int qlua_lsetangles(lua_State *L) {
	localEntity_t	*luaentity;
	vec3_t angles;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TVECTOR);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		BG_EvaluateTrajectory(&luaentity->angles, cg.time, angles );
		lua_tovector(L,2,luaentity->angles.trBase);
		luaentity->angles.trDuration += (cg.time - luaentity->angles.trTime);
		luaentity->angles.trTime = cg.time;
		return 1;
	}
	return 0;
}

int qlua_lsetstart(lua_State *L) {
	localEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		luaentity->startTime = lua_tonumber(L,2);
		luaentity->lifeRate = 1.0 / ( luaentity->endTime - luaentity->startTime );
	}
	return 0;
}

int qlua_lsetend(lua_State *L) {
	localEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		luaentity->endTime = lua_tonumber(L,2);
		luaentity->lifeRate = 1.0 / ( luaentity->endTime - luaentity->startTime );
	}
	return 0;
}

int qlua_lsettype(lua_State *L) {
	localEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		if(lua_tointeger(L,2) < 0 || lua_tointeger(L,2) > LE_FADE_TWEEN) {
			lua_pushstring(L,"Index out of range (Local Entity Type).");
			lua_error(L);
			return 1;
		}
		luaentity->leType = lua_tointeger(L,2);
	}
	return 0;
}

int qlua_lgettype(lua_State *L) {
	localEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L,luaentity->leType);
		return 1;
	}
	return 0;
}

int qlua_lsettrtype(lua_State *L) {
	localEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		if(lua_tointeger(L,2) < 0 || lua_tointeger(L,2) > TR_GRAVITY) {
			lua_pushstring(L,"Index out of range (Tr Type).");
			lua_error(L);
			return 1;
		}
		luaentity->pos.trType = lua_tointeger(L,2);
	}
	return 0;
}

int qlua_lgettrtype(lua_State *L) {
	localEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L,luaentity->pos.trType);
		return 1;
	}
	return 0;
}

int qlua_lsetradius(lua_State *L) {
	localEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		luaentity->radius = lua_tonumber(L,2);
		luaentity->start_radius = luaentity->radius;
		luaentity->end_radius = luaentity->radius;
	}
	return 0;
}

int qlua_lsetstartradius(lua_State *L) {
	localEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		luaentity->start_radius = lua_tonumber(L,2);
	}
	return 0;
}

int qlua_lsetendradius(lua_State *L) {
	localEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		luaentity->end_radius = lua_tonumber(L,2);
	}
	return 0;
}

int qlua_lgetradius(lua_State *L) {
	localEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		lua_pushnumber(L,luaentity->radius);
		return 1;
	}
	return 0;
}

int	qlua_lsetref(lua_State *L) {
	localEntity_t	*luaentity;
	refEntity_t		*in;
	vec3_t			origin;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TUSERDATA);

	luaentity = lua_tolocalentity(L,1);
	in = lua_torefentity(L,2);
	if(luaentity != NULL && in != NULL) {
		memcpy(&luaentity->refEntity,in,sizeof(refEntity_t));

		//Might Break?
		//BG_EvaluateTrajectory(&luaentity->pos,cg.time,origin);
		//VectorCopy(origin,luaentity->refEntity.origin);
	}
	return 0;
}

int	qlua_lgetref(lua_State *L) {
	localEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		lua_pushrefentity(L,&luaentity->refEntity);
		return 1;
	}
	return 0;
}

int qlua_lnextthink(lua_State *L) {
	localEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		luaentity->lua_nextThink = lua_tonumber(L,2);
	}
	return 0;
}

int qlua_lsetcallback(lua_State *L) {
	localEntity_t	*ent;
	int	call;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);
	luaL_checktype(L,3,LUA_TFUNCTION);

	if(lua_gettop(L) >= 2) {
		ent = lua_tolocalentity(L,1);
		call = lua_tointeger(L,2);
		if(ent != NULL) {
			switch(call) {
				case 0: ent->lua_think = qlua_storefunc(L,3,ent->lua_think); break;
				case 1: ent->lua_bounce = qlua_storefunc(L,3,ent->lua_bounce); break;
				case 2: ent->lua_die = qlua_storefunc(L,3,ent->lua_die); break;
				case 3: ent->lua_stopped = qlua_storefunc(L,3,ent->lua_stopped); break;
				case 4: ent->lua_parentgone = qlua_storefunc(L,3,ent->lua_parentgone); break;
				case 5: ent->lua_render = qlua_storefunc(L,3,ent->lua_render); break;
			}		
		}
	}
	return 0;
}

int qlua_lsetcolor(lua_State *L) {
	localEntity_t	*luaentity;
	vec4_t	color;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaentity = lua_tolocalentity(L,1);
	qlua_toColor(L,2,color,qfalse);

	if(luaentity != NULL) {
		Vector4Copy(color,luaentity->color);
		Vector4Copy(color,luaentity->start_color);
		Vector4Copy(color,luaentity->end_color);
	}

	return 0;
}

int qlua_lsetstartcolor(lua_State *L) {
	localEntity_t	*luaentity;
	vec4_t	color;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaentity = lua_tolocalentity(L,1);
	qlua_toColor(L,2,color,qfalse);

	if(luaentity != NULL) {
		Vector4Copy(color,luaentity->start_color);
	}

	return 0;
}

int qlua_lsetendcolor(lua_State *L) {
	localEntity_t	*luaentity;
	vec4_t	color;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaentity = lua_tolocalentity(L,1);
	qlua_toColor(L,2,color,qfalse);

	if(luaentity != NULL) {
		Vector4Copy(color,luaentity->end_color);
	}

	return 0;
}

int qlua_lbounce(lua_State *L) {
	localEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		luaentity->bounceFactor = lua_tonumber(L,2);
	}
	return 0;
}

int qlua_lasgib(lua_State *L) {
	localEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TBOOLEAN);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		if(lua_toboolean(L,2)) {
			luaentity->leBounceSoundType = LEBS_BLOOD;
			luaentity->leMarkType = LEMT_BLOOD;
		} else {
			luaentity->leBounceSoundType = LEBS_NONE;
			luaentity->leMarkType = LEMT_NONE;
		}
	}
	return 0;
}
/*
int qlua_lflags(lua_State *L) {
	localEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		if(lua_tointeger(L,2) < 1 || lua_tointeger(L,2) >= 512) {
			lua_pushstring(L,"Index out of range (Local Entity Flags).");
			lua_error(L);
			return 1;
		}
		luaentity->leFlags = LEF_TUMBLE
		luaentity->renderfx |= lua_tointeger(L,2);
	}
	return 0;
}
*/

int qlua_lgettrx(lua_State *L) {
	localEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		lua_pushtrajectory(L,&luaentity->pos);
		return 1;
	}
	return 0;
}

int qlua_lsettrx(lua_State *L) {
	localEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TUSERDATA);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		luaentity->pos = *lua_totrajectory(L,2);
		return 1;
	}
	return 0;
}

int qlua_lsetparent(lua_State *L) {
	localEntity_t	*luaentity, *parent;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TUSERDATA);

	luaentity = lua_tolocalentity(L,1);
	parent = lua_tolocalentity(L,2);
	if(luaentity != NULL && parent != NULL) {
		luaentity->parent = parent;

		if(lua_gettop(L) >= 3 && lua_type(L,3) == LUA_TSTRING) {
			luaentity->parent_tag = lua_tostring(L,3);
		}
	}
	return 0;
}

int qlua_lemit(lua_State *L) {
	localEntity_t	*luaentity;
	localEntity_t	*emitted;
	//int count = 1;
	int i = 0;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaentity = lua_tolocalentity(L,1);

	//if(lua_gettop(L) > 1 && lua_type(L,2) == LUA_TNUMBER) count = lua_tointeger(L,2);
	//if(count <= 0) count = 1;

	if(luaentity != NULL) {
		//for(i=0;i<count;i++) {
		emitted = CG_LocalEntityEmit(luaentity);
		if(emitted != NULL) {
			lua_pushlocalentity(L,emitted);
			return 1;
		}
		//}
	}
	return 0;
}

int qlua_setemitter(lua_State *L) {
	localEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);
	luaL_checktype(L,3,LUA_TNUMBER);
	luaL_checktype(L,4,LUA_TNUMBER);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL) {
		luaentity->emitTime = cg.time;
		luaentity->startEmit = lua_tointeger(L,2);
		luaentity->endEmit = lua_tointeger(L,3);
		luaentity->emitRate = lua_tointeger(L,4);
		luaentity->emitter = qtrue;

		luaentity->startTime -= cg.time;
		luaentity->endTime -= cg.time;

		if(lua_gettop(L) >= 5 && lua_type(L,5) == LUA_TFUNCTION) {
			luaentity->lua_emitted = qlua_storefunc(L,5,luaentity->lua_emitted); 
		}
	}
	return 0;
}

int qlua_removeme(lua_State *L) {
	localEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_tolocalentity(L,1);
	if(luaentity != NULL && luaentity->active) {
		luaentity->active = qfalse;
		if(luaentity->emitter) {
			luaentity->endEmit = cg.time + 10;
			luaentity->emitTime = cg.time + 1000;
		} else {
			luaentity->endTime = cg.time + 10;
		}
	}
	return 0;
}

static int Entity_tostring (lua_State *L)
{
  lua_pushfstring(L, "RefEntity: %p", lua_touserdata(L, 1));
  return 1;
}

static int Entity_equal (lua_State *L)
{
	localEntity_t *e1 = lua_tolocalentity(L,1);
	localEntity_t *e2 = lua_tolocalentity(L,2);
	if(e1 != NULL && e2 != NULL) {
		lua_pushboolean(L, (e1->id == e2->id));
	} else {
		lua_pushboolean(L, 0);
	}
  return 1;
}

static const luaL_reg LEntity_methods[] = {
  {"GetPos",		qlua_lgetpos},
  {"SetPos",		qlua_lsetpos},
  {"GetVelocity",	qlua_lgetvelocity},
  {"SetVelocity",	qlua_lsetvelocity},
  {"GetAngles",		qlua_lgetangles},
  {"SetAngles",		qlua_lsetangles},
  {"GetAngleVelocity",	qlua_lgetanglevelocity},
  {"SetAngleVelocity",	qlua_lsetanglevelocity},
  {"SetType",		qlua_lsettype},
  {"GetType",		qlua_lgettype},
  {"SetTrType",		qlua_lsettrtype},
  {"GetTrType",		qlua_lgettrtype},
  {"SetTrajectory",		qlua_lsettrx},
  {"GetTrajectory",		qlua_lgettrx},
  {"SetStartTime",	qlua_lsetstart},
  {"SetEndTime",	qlua_lsetend},
  {"SetRadius",		qlua_lsetradius},
  {"SetStartRadius",	qlua_lsetstartradius},
  {"SetEndRadius",		qlua_lsetendradius},
  {"GetRadius",		qlua_lgetradius},
  {"SetColor",		qlua_lsetcolor},
  {"SetStartColor",	qlua_lsetstartcolor},
  {"SetEndColor",	qlua_lsetendcolor},
  {"SetRefEntity",	qlua_lsetref},
  {"GetRefEntity",	qlua_lgetref},
  {"SetCallback",	qlua_lsetcallback},
  {"SetNextThink",	qlua_lnextthink},
  {"SetBounceFactor", qlua_lbounce},
  {"SetAsGib",		qlua_lasgib},
  {"GetTable",		lua_legetentitytable},
  {"SetParent",		qlua_lsetparent},
  {"Emitter",	qlua_setemitter},
  {"Emit",		qlua_lemit},
  {"Remove",	qlua_removeme},
  {0,0}
};

static const luaL_reg LEntity_meta[] = {
  {"__tostring", Entity_tostring},
  {"__eq", Entity_equal},
  {0, 0}
};

int LEntity_register (lua_State *L) {
	luaL_openlib(L, "LocalEntity", LEntity_methods, 0);

	luaL_newmetatable(L, "LocalEntity");

	luaL_openlib(L, 0, LEntity_meta, 0);
	lua_pushliteral(L, "__index");
	lua_pushvalue(L, -3);
	lua_rawset(L, -3);
	lua_pushliteral(L, "__metatable");
	lua_pushvalue(L, -3);
	lua_rawset(L, -3);

	lua_setglobal(L,"M_LocalEntity");

	lua_pop(L, 1);
	return 1;
}

/*int qlua_createlocalentity (lua_State *L) {
	localEntity_t   *le = NULL;
	localEntity_t   *le2;
	
	if(lua_type(L,1) == LUA_TUSERDATA) {
		le2 = lua_tolocalentity(L,1);
		if(le2 != NULL) {
			le = CG_AllocLocalEntity();
			memcpy(le,le2,sizeof(localEntity_t));
			lua_pushlocalentity(L,le);
			return 1;
		}
	}

	le = CG_AllocLocalEntity();
	le->pos.trType = TR_GRAVITY;
	le->leBounceSoundType = LEBS_BLOOD;

	lua_pushlocalentity(L,le);
	return 1;
}*/

int qlua_createlocalentity (lua_State *L) {
	localEntity_t   *le;
	//localEntity_t   *le2;
	
	/*if(lua_type(L,1) == LUA_TUSERDATA) {
		le2 = lua_tolocalentity(L,1);
		if(le2 != NULL) {
			memset(&le, 0, sizeof( localEntity_t ) );
			memcpy(&le,le2,sizeof(localEntity_t));
			lua_pushlocalentity(L,&le);
			return 1;
		}
	}*/

	le = CG_AllocLocalEntity();

	//memset(&le, 0, sizeof( localEntity_t ) );

	le->pos.trType = TR_GRAVITY;
	le->angles.trType = TR_LINEAR;
	//le->leBounceSoundType = LEBS_BLOOD;
	//le->leMarkType = LEMT_BLOOD;
	le->bounceFactor = 0.6f;

	lua_pushlocalentity(L,le);
	return 1;
}

int qlua_addlocalentity (lua_State *L) {
	localEntity_t   *le;
	localEntity_t   *le2 = NULL;
	
	if(lua_type(L,1) == LUA_TUSERDATA) {
		le = lua_tolocalentity(L,1);
		if(le != NULL) {
			CG_Printf("Found Model: %i\n",le->refEntity.hModel);
			le2 = CG_AllocLocalEntity();
			memcpy(le,le2,sizeof(localEntity_t));
			memcpy(&le->refEntity,&le2->refEntity,sizeof(refEntity_t));
			//le2->refEntity = le->refEntity;
			CG_Printf("Got Model: %i\n",le2->refEntity.hModel);
		}
	}
	return 0;
}

void CG_InitLuaLEnts(lua_State *L) {
	LEntity_register(L);
	//lua_register(L,"GetEntitiesByClass",qlua_getentitiesbyclass);
	//lua_register(L,"GetAllPlayers",qlua_getallplayers);
	lua_register(L,"LocalEntity",qlua_createlocalentity);
	//lua_register(L,"AddLocalEntity",qlua_addlocalentity);
}