#include "g_local.h"

gentity_t *qlua_getrealentity(gentity_t *ent) {
	gentity_t	*tent = NULL;
	int numEnts = sizeof(g_entities) / sizeof(g_entities[0]);
	/*int i=0;
	int n=0;

	for (i = 0, tent = g_entities, n = 1;
			i < level.num_entities;
			i++, tent++) {
		if (tent->classname) {
			if(ent->s.number == tent->s.number) {
				if(tent != NULL) {
					return tent;
				}
			}
			n++;
		}
	}

	tent = g_entities + ent->s.number;
	if(tent != NULL) {
		tent->classname = "player";
		return tent;
	}

	G_Printf("Unable To Find Entity: %i\n", ent->s.number);*/

	if ( !ent || ent->s.number < 0 || ent->s.number > numEnts ) {
		G_Printf("Invalid Entity: %i\n", ent->s.number);
	} else {
		tent = &g_entities[ent->s.number];
		if(tent != NULL) {
			return tent;
		}
	}
	
	return NULL;
}

void lua_entitytab(lua_State *L, gentity_t *ent) {
	if(ent->lua_persistanttable == 0) {
		lua_newtable(L);
		ent->lua_persistanttable = qlua_storefunc(L,lua_gettop(L),0);
	}
}

int lua_getentitytable(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(qlua_getstored(L,luaentity->lua_persistanttable)) {
			return 1;
		}
	}
	return 0;
}

/*int lua_setentitytable(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TTABLE);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_gettable(L,2);
		luaentity->lua_persistanttable = qlua_storefunc(L,lua_gettop(L),0);
		return 1;
	}
	return 0;
}*/

//lua_pushlightuserdata(L,cl);
void lua_pushentity(lua_State *L, gentity_t *cl) {
	gentity_t *ent = NULL;

	if(cl == NULL) {
		lua_pushnil(L);
		return;
	}

	if(cl->s.number == ENTITYNUM_MAX_NORMAL || (cl->client == NULL && cl->s.number == 0)) {
		lua_pushnil(L);
		return;
	}

	lua_entitytab(L, cl);

	ent = (gentity_t*)lua_newuserdata(L, sizeof(gentity_t));
	memcpy(ent,cl,sizeof(gentity_t));
	
	ent->s.number = cl->s.number;

	luaL_getmetatable(L, "Entity");
	lua_setmetatable(L, -2);
}

gentity_t *lua_toentity(lua_State *L, int i) {
	gentity_t	*luaentity = NULL;
	luaL_checktype(L,i,LUA_TUSERDATA);
	
	if(lua_type(L,i) == LUA_TTABLE ) {
		G_Printf("^1Got Table Instead Of Entity, we'll roll with that\n");
		lua_pushstring(L,"Entity");
		lua_gettable(L,i);
		i = lua_gettop(L);
	}

	if(luaL_checkudata(L,i,"Entity") == NULL) {
		luaL_typerror(L,i,"Entity");
		return NULL;
	}

	luaentity = (gentity_t *)lua_touserdata(L, i);
	luaentity = qlua_getrealentity(luaentity);

	if (luaentity == NULL) luaL_typerror(L, i, "Entity");
	return luaentity;
}

int qlua_getclientinfo(lua_State *L) {
	gentity_t	*luaentity;

	lua_newtable(L);

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL && luaentity->client != NULL) {
		lua_pushstring(L, "name");
		lua_pushstring(L,luaentity->client->pers.netname);
		lua_rawset(L, -3);

		lua_pushstring(L, "health");
		lua_pushinteger(L,luaentity->health);
		lua_rawset(L, -3);

		lua_pushstring(L, "score");
		lua_pushinteger(L,luaentity->client->ps.persistant[PERS_SCORE]);
		lua_rawset(L, -3);

		lua_pushstring(L, "connected");
		lua_pushboolean(L,(luaentity->client->pers.connected == CON_CONNECTED));
		lua_rawset(L, -3);

		lua_pushstring(L, "weapon");
		lua_pushinteger(L,luaentity->client->ps.weapon);
		lua_rawset(L, -3);

		lua_pushstring(L, "buttons");
		lua_pushinteger(L,luaentity->client->buttons);
		lua_rawset(L, -3);

		lua_pushstring(L, "entertime");
		lua_pushinteger(L,luaentity->client->pers.enterTime);
		lua_rawset(L, -3);

		lua_pushstring(L, "model");
		lua_pushinteger(L,luaentity->s.modelindex);
		lua_rawset(L, -3);

		lua_pushstring(L, "team");
		lua_pushinteger(L,luaentity->client->sess.sessionTeam);
		lua_rawset(L, -3);
	} else {
		lua_pushstring(L,"<CLIENT WAS NIL>");
	}
	return 1;
}

int qlua_setclientinfo(lua_State *L) {
	gentity_t	*luaentity;
	int			inf;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	if(lua_gettop(L) < 2) {
		lua_pushstring(L,"Invalid Number Of Arguments For \"SetClientInfo\".");
		lua_error(L);
	}

	luaentity = lua_toentity(L,1);
	inf = lua_tonumber(L,2);
	if(luaentity != NULL && luaentity->client != NULL) {
		if (inf == PLAYERINFO_NAME) {
			luaL_checktype(L,3,LUA_TSTRING);
			strncpy(luaentity->client->pers.netname, lua_tostring(L,3), 36);
		} else if (inf == PLAYERINFO_HEALTH) {
			luaL_checktype(L,3,LUA_TNUMBER);
			luaentity->health = lua_tonumber(L,3);
			if(luaentity->health <= 0) {
				luaentity->health = luaentity->health - 1;
				//player_die(luaentity, NULL, NULL, -luaentity->health, MOD_CRUSH);
			}
			//trap_SendServerCommand( -1, va("playerhealth %i %i", luaentity->s.number, luaentity->health) );
		} else if (inf == PLAYERINFO_SCORE) {
			luaL_checktype(L,3,LUA_TNUMBER);
			luaentity->client->ps.persistant[PERS_SCORE] = lua_tonumber(L,3);
			CalculateRanks();
		} else {
			lua_pushfstring(L,"Invalid Argument For \"SetClientInfo\": %s.",inf);
			lua_error(L);
		}
	} else {
		lua_pushstring(L,"<CLIENT WAS NIL>");
	}
	return 1;
}

int qlua_isclient(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL && luaentity->client != NULL) {
		lua_pushboolean(L,1);
	} else {
		lua_pushboolean(L,0);
	}
	return 1;
}

int qlua_isbot(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL && luaentity->client != NULL) {
		if(luaentity->r.svFlags & SVF_BOT) {
			lua_pushboolean(L,1);
		} else {
			lua_pushboolean(L,0);
		}
	}
	return 1;
}

int qlua_islocal(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL && luaentity->client != NULL) {
		if(luaentity->client->pers.localClient) {
			lua_pushboolean(L,1);
		} else {
			lua_pushboolean(L,0);
		}
		return 1;
	}
	lua_pushboolean(L,0);
	return 1;
}

int qlua_setweapon(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);
#ifndef LUA_WEAPONS
	if(lua_gettop(L) == 2) {
		int weap = lua_tointeger(L,2);
		if(weap < 1 || weap > WP_NUM_WEAPONS-1) {
			lua_pushstring(L,"Invalid Argument For \"SetPlayerWeapon\"\n (out of range).\n");
			lua_error(L);
			return 1;
		}

		luaentity = lua_toentity(L,1);
		if(luaentity != NULL) {
			if(luaentity->client != NULL) {
				int actuallweap = luaentity->client->ps.weapon;
				if((luaentity->client->ps.stats[STAT_WEAPONS] & (1 << weap)) && (luaentity->client->ps.ammo[weap] || actuallweap == WP_GAUNTLET)) {
					luaentity->client->ps.weapon = weap;
					luaentity->client->ps.weaponstate = WEAPON_READY;
				} else {
					lua_pushstring(L,"Invalid Argument For \"SetPlayerWeapon\"\n (client does not have that weapon or weapon has no ammo).\n");
					lua_error(L);
					return 1;				
				}
			} else {
				luaentity->s.weapon = weap;
			}
		}
	} else {
		lua_pushstring(L,"Invalid Number Of Arguments.\n");
		lua_error(L);
		return 1;
	}
	//HFIXME Implement Lua Weapon Code
#else
	if(lua_gettop(L) == 2) {
		int weap = lua_tointeger(L,2);
		luaentity = lua_toentity(L,1);
		if(luaentity != NULL) {
			if(luaentity->client != NULL) {
				luaentity->client->ps.weapon = weap;
			} else {
				luaentity->s.weapon = weap;
			}
		}
	}
#endif
	return 0;
}

int qlua_hasweapon(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);
#ifndef LUA_WEAPONS
	if(lua_gettop(L) == 2) {
		int weap = lua_tointeger(L,2);
		if(weap < 1 || weap > WP_NUM_WEAPONS-1) {
			lua_pushstring(L,"Invalid Argument For \"HasWeapon\"\n (out of range).\n");
			lua_error(L);
			return 1;
		}

		luaentity = lua_toentity(L,1);
		if(luaentity != NULL && luaentity->client != NULL) {
			if((luaentity->client->ps.stats[STAT_WEAPONS] & (1 << weap))) {
				lua_pushboolean(L,qtrue);
			} else {
				lua_pushboolean(L,qfalse);
			}
			return 1;
		}
	} else {
		lua_pushstring(L,"Invalid Number Of Arguments.\n");
		lua_error(L);
		return 1;
	}
	//HFIXME Implement Lua Weapon Code
#endif
	return 0;
}

int qlua_hasammo(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);
#ifndef LUA_WEAPONS
	if(lua_gettop(L) == 2) {
		int weap = lua_tointeger(L,2);
		if(weap < 1 || weap > WP_NUM_WEAPONS-1) {
			lua_pushstring(L,"Invalid Argument For \"HasAmmo\"\n (out of range).\n");
			lua_error(L);
			return 1;
		}

		luaentity = lua_toentity(L,1);
		if(luaentity != NULL && luaentity->client != NULL) {
			if((luaentity->client->ps.stats[STAT_WEAPONS] & (1 << weap)) && (luaentity->client->ps.ammo[weap])) {
				lua_pushboolean(L,qtrue);
			} else {
				lua_pushboolean(L,qfalse);
			}
			return 1;
		}
	} else {
		lua_pushstring(L,"Invalid Number Of Arguments.\n");
		lua_error(L);
		return 1;
	}
	//HFIXME Implement Lua Weapon Code
#endif
	return 0;
}


int qlua_giveweapon(lua_State *L) {
	gentity_t	*luaentity;
	int		i;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);
#ifndef LUA_WEAPONS
	if(lua_gettop(L) == 2) {
		int weap = lua_tointeger(L,2);
		if(weap < 1 || weap > WP_NUM_WEAPONS-1) {
			lua_pushstring(L,"Invalid Argument For \"GiveWeapon\"\n (out of range).\n");
			lua_error(L);
			return 1;
		}

		luaentity = lua_toentity(L,1);
		if(luaentity != NULL && luaentity->client != NULL) {
			luaentity->client->ps.stats[STAT_WEAPONS] |= ( 1 << weap );
			if(luaentity->client->ps.ammo[weap] == 0) {
				for ( i = 0 ; i < bg_numItems ; i++ ) {
					if ( bg_itemlist[i].giTag == weap ) {
						luaentity->client->ps.ammo[weap] = bg_itemlist[i].quantity;
					}
				}
			} else {
				if(luaentity->client->ps.ammo[weap] < 999) {
					luaentity->client->ps.ammo[weap] = luaentity->client->ps.ammo[weap] + 1;
				}
			}
			if(luaentity->client->ps.ammo[weap] < 1) {
				luaentity->client->ps.ammo[weap] = 1;
			}
		}
	} else {
		lua_pushstring(L,"Invalid Number Of Arguments.\n");
		lua_error(L);
		return 1;
	}
	//HFIXME Implement Lua Weapon Code
#endif
	return 0;
}

int qlua_removeweapons(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
#ifndef LUA_WEAPONS
	luaentity = lua_toentity(L,1);
	if(luaentity != NULL && luaentity->client != NULL) {
		luaentity->client->ps.stats[STAT_WEAPONS] = (1 << WP_NONE);
		luaentity->client->ps.ammo[WP_NONE] = 0;
		luaentity->client->ps.weapon = WP_NONE;
		luaentity->client->ps.weaponstate = WEAPON_READY;
	}
	//HFIXME Implement Lua Weapon Code
#endif
	return 0;
}

int qlua_removepowerups(lua_State *L) {
	gentity_t	*luaentity;
	int i=0;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL && luaentity->client != NULL) {
		for ( i = 0 ; i < MAX_POWERUPS ; i++ ) {
			luaentity->client->ps.powerups[ i ] = 0;
		}
	}
	return 1;
}

int qlua_setanim(lua_State *L) {
	gentity_t	*luaentity;
	int anim = 0;
	int leg = 0;
	int torso = 0;
	int target = 0;
	int time = 1000;

	luaL_checkint(L,2);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		anim = lua_tointeger(L,2);
		if(lua_type(L,3) == LUA_TNUMBER) target = lua_tointeger(L,3);
		if(lua_type(L,4) == LUA_TNUMBER) time = lua_tointeger(L,4);
		if(anim >= MAX_ANIMATIONS) anim = MAX_ANIMATIONS-1;
		if(anim < 0) anim = 0;
		luaentity->timestamp = level.time;
		trap_UnlinkEntity(luaentity);
		trap_LinkEntity(luaentity);
		if(target == 0) {
			luaentity->s.legsAnim = ( ( luaentity->s.legsAnim & ANIM_TOGGLEBIT ) ^ ANIM_TOGGLEBIT ) | anim;
			G_Printf("Set Leg Animation To: %i\n",luaentity->s.legsAnim);
		} else if (target == 1) {
			luaentity->s.torsoAnim = ( ( luaentity->s.torsoAnim & ANIM_TOGGLEBIT ) ^ ANIM_TOGGLEBIT ) | anim;
			G_Printf("Set Torso Animation To: %i\n",luaentity->s.torsoAnim);
		}
		if(luaentity->client != NULL) {
			if(target == 0) {
				leg = ( ( luaentity->client->ps.legsAnim & ANIM_TOGGLEBIT ) ^ ANIM_TOGGLEBIT ) | anim;
				luaentity->client->ps.legsAnim = leg;
				luaentity->client->ps.legsTimer = time;
			} else if (target == 1) {
				torso = ( ( luaentity->client->ps.torsoAnim & ANIM_TOGGLEBIT ) ^ ANIM_TOGGLEBIT ) | anim;
				luaentity->client->ps.torsoAnim = torso;
				luaentity->client->ps.torsoTimer = time;
			}
		}
	}
	return 0;
}

int qlua_getpowerup(lua_State *L) {
	gentity_t	*luaentity;
	int pw = PW_NONE;
	int time = 0;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checkint(L,2);

	pw = lua_tointeger(L,2);

	if(pw < PW_NONE || pw > PW_BLUEFLAG) {
		lua_pushstring(L,"Invalid Argument For \"GetPowerup\"\n (out of range).\n");
		lua_error(L);
		return 1;
	}

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL && luaentity->client != NULL) {
		lua_pushinteger(L,luaentity->client->ps.powerups[pw]);
	}
	return 1;
}

int qlua_setpowerup(lua_State *L) {
	gentity_t	*luaentity;
	int pw = PW_NONE;
	int time = 0;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checkint(L,2);
	luaL_checkint(L,3);

	pw = lua_tointeger(L,2);
	time = lua_tointeger(L,3);

	if(pw < PW_NONE || pw > PW_BLUEFLAG) {
		lua_pushstring(L,"Invalid Argument For \"SetPowerup\"\n (out of range).\n");
		lua_error(L);
		return 1;
	}

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL && luaentity->client != NULL) {
		luaentity->client->ps.powerups[pw] = level.time + time;
		if(time <= 0) {
			luaentity->client->ps.powerups[pw] = 0;
		}
	}
	return 1;
}

int qlua_setspeed(lua_State *L) {
	gentity_t	*luaentity;
	float spd = 0;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checknumber(L,2);

	spd = lua_tonumber(L,2);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL && luaentity->client != NULL && spd >= 0) {
		luaentity->client->ps.speed = g_speed.value * spd;
	}
	return 0;
}


int qlua_setammo(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);
	luaL_checktype(L,3,LUA_TNUMBER);
#ifndef LUA_WEAPONS
	if(lua_gettop(L) == 3) {
		int weap = lua_tointeger(L,2);
		int ammo = lua_tointeger(L,3);
		if(weap < 1 || weap > WP_NUM_WEAPONS-1) {
			lua_pushstring(L,"Invalid Argument For \"SetAmmo\"\n (out of range).\n");
			lua_error(L);
			return 1;
		}

		luaentity = lua_toentity(L,1);
		if(luaentity != NULL && luaentity->client != NULL) {
			if(ammo >= -1 && ammo <= 999) {
				luaentity->client->ps.ammo[weap] = ammo;
			}
		}
	} else {
		lua_pushstring(L,"Invalid Number Of Arguments.\n");
		lua_error(L);
		return 1;
	}
	//HFIXME Implement Lua Weapon Code
#endif
	return 0;
}

int qlua_getammo(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);
#ifndef LUA_WEAPONS
	if(lua_gettop(L) == 2) {
		int weap = lua_tointeger(L,2);
		if(weap < 1 || weap > WP_NUM_WEAPONS-1) {
			lua_pushstring(L,"Invalid Argument For \"GetAmmo\"\n (out of range).\n");
			lua_error(L);
			return 1;
		}

		luaentity = lua_toentity(L,1);
		if(luaentity != NULL && luaentity->client != NULL) {
			lua_pushinteger(L,luaentity->client->ps.ammo[weap]);
			return 1;
		}
	} else {
		lua_pushstring(L,"Invalid Number Of Arguments.\n");
		lua_error(L);
		return 1;
	}
	//HFIXME Implement Lua Weapon Code
#endif
	return 0;
}

int qlua_getclass(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL && luaentity->classname != NULL) {
		if(!strcmp("luaentity",luaentity->classname)) {
			if(luaentity->s.luaname != NULL) {
				lua_pushstring(L,luaentity->s.luaname);
			}
		} else {
			lua_pushstring(L,luaentity->classname);
		}
	} else {
		lua_pushstring(L,"<INVALID ENTITY>");
	}
	return 1;
}

int qlua_getpos(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(luaentity->client) {
			lua_pushvector(L,luaentity->client->ps.origin);
		} else {
			lua_pushvector(L,luaentity->r.currentOrigin);
		}
		return 1;
	}
	return 0;
}

int qlua_setpos(lua_State *L) {
	gentity_t	*luaentity;
	vec3_t		origin;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TVECTOR);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(luaentity->client) {
			lua_tovector(L,2,luaentity->client->ps.origin);
		} else {
			BG_EvaluateTrajectory( &luaentity->s.pos, level.time, origin );
			lua_tovector(L,2,luaentity->s.pos.trBase);
			luaentity->s.pos.trDuration += (level.time - luaentity->s.pos.trTime);
			luaentity->s.pos.trTime = level.time;
			VectorCopy(luaentity->s.pos.trBase, luaentity->r.currentOrigin);
			VectorCopy(luaentity->s.pos.trBase, luaentity->s.origin);
		}
		return 1;
	}
	return 0;
}

int qlua_setpos2(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TVECTOR);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_tovector(L,2,luaentity->s.origin2);
	}
	return 0;
}

int qlua_getangles(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushvector(L,luaentity->s.angles);
		return 1;
	}
	return 0;
}

int qlua_setangles(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TVECTOR);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_tovector(L,2,luaentity->s.angles);
		return 1;
	}
	return 0;
}

int qlua_getmuzzlepos(lua_State *L) {
	vec3_t forward,right,up,muzzle;

	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(luaentity->client) {
			AngleVectors (luaentity->client->ps.viewangles, forward, right, up);
			CalcMuzzlePointOrigin ( luaentity, luaentity->client->oldOrigin, forward, right, up, muzzle );
			lua_pushvector(L,muzzle);
		}
		return 1;
	}
	return 0;
}

int qlua_getvel(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(luaentity->client) {
			lua_pushvector(L,luaentity->client->ps.velocity);
		} else {
			lua_pushvector(L,luaentity->s.pos.trDelta);
		}
		return 1;
	}
	return 0;
}

int qlua_setvel(lua_State *L) {
	gentity_t	*luaentity;
	vec3_t	origin;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TVECTOR);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(luaentity->client) {
			lua_tovector(L,2,luaentity->client->ps.velocity);
		} else {
			if(luaentity->s.pos.trType == TR_STATIONARY) {
				luaentity->s.pos.trType = TR_GRAVITY;
			}
			BG_EvaluateTrajectory( &luaentity->s.pos, level.time, origin );
			VectorCopy(origin, luaentity->s.pos.trBase);
			luaentity->s.pos.trDuration += (level.time - luaentity->s.pos.trTime);
			luaentity->s.pos.trTime = level.time;
			lua_tovector(L,2,luaentity->s.pos.trDelta);
		}
		return 1;
	}
	return 0;
}



int qlua_getaimvec(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(luaentity->client) {
			lua_pushvector(L,luaentity->client->ps.viewangles);
			return 1;
		}
	}
	return 0;
}

int qlua_setaimvec(lua_State *L) {
	gentity_t	*luaentity;
	vec3_t		angle;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(luaentity->client) {
			lua_tovector(L,2,angle);
			SetClientViewAngle(luaentity,angle);
		}
	}
	return 0;
}

int qlua_setteam(lua_State *L) {
	gentity_t	*luaentity;
	int			team = TEAM_FREE;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(luaentity->client) {
			team = lua_tonumber(L,2);
			if(team < TEAM_FREE) {
				// || team >= TEAM_NUM_TEAMS
				team = luaentity->client->sess.sessionTeam;
			}
			if(luaentity->client->sess.sessionTeam != team) {
				LuaTeamChanged(luaentity,team);
				luaentity->client->sess.sessionTeam = team;
				ClientUserinfoChanged(luaentity->s.number);
			}
		}
	}
	return 0;
}

int qlua_getteam(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(luaentity->client) {
			lua_pushinteger(L,luaentity->client->sess.sessionTeam);
			return 1;
		}
	}
	return 0;
}

int qlua_setspectatorstate(lua_State *L) {
	gentity_t	*luaentity;
	int			state = SPECTATOR_NOT;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(luaentity->client) {
			state = lua_tonumber(L,2);
			if(state < SPECTATOR_NOT || state > SPECTATOR_SCOREBOARD) {
				state = luaentity->client->sess.spectatorState;
			}
			if(luaentity->client->sess.spectatorState != state) {
				luaentity->client->sess.spectatorState = state;
			}
		}
	}
	return 0;
}

int qlua_getspectatorstate(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(luaentity->client) {
			lua_pushinteger(L,luaentity->client->sess.spectatorState);
			return 1;
		}
	}
	return 0;
}

int qlua_respawn(lua_State *L) {
	gentity_t	*luaentity;
	gentity_t	*body = NULL;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(luaentity->s.eType == ET_ITEM && luaentity->item->giType != 0) {
			if((luaentity->r.svFlags & SVF_NOCLIENT) == 0) return 0;
			if((luaentity->s.eFlags & EF_NODRAW) == 0) return 0;
			if(luaentity->r.contents != 0) return 0;
			luaentity->think = RespawnItem;
			luaentity->nextthink = level.time;
			return 0;
		}
		if(luaentity->client) {
			if(luaentity->health <= 0) body = CopyToBodyQue(luaentity);
			ClientSpawn(luaentity,NULL);
			if(body != NULL) {
				lua_pushentity(L,body);
				return 1;
			}
		}
	}
	return 0;
}

int qlua_setrespawntime(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(luaentity->client) {
			luaentity->client->respawnTime = lua_tointeger(L,2);
		}
	}
	return 0;
}

int qlua_getotherentity(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(luaentity->s.otherEntityNum != ENTITYNUM_MAX_NORMAL) {
			lua_pushentity(L,&g_entities[ luaentity->s.otherEntityNum ]);
			return 1;
		}
	}
	return 0;
}

int qlua_getotherentity2(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(luaentity->s.otherEntityNum2 != ENTITYNUM_MAX_NORMAL) {
			lua_pushentity(L,&g_entities[ luaentity->s.otherEntityNum2 ]);
			return 1;
		}
	}
	return 0;
}

int qlua_setotherentity(lua_State *L) {
	gentity_t	*luaentity,*other;
	int i;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(lua_type(L,2) == LUA_TUSERDATA) {
			other = lua_toentity(L,2);
			if(other == NULL) return 0;
			luaentity->s.otherEntityNum = other->s.number;
		} else if (lua_type(L,2) == LUA_TNUMBER) {
			i = lua_tointeger(L,2);
			if(i < 0) return 0;
			if(i >= MAX_GENTITIES) return 0;
			luaentity->s.otherEntityNum = i;
		} else {
			luaentity->s.otherEntityNum = ENTITYNUM_NONE;
		}
	}
	return 0;
}

int qlua_setotherentity2(lua_State *L) {
	gentity_t	*luaentity,*other;
	int i;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(lua_type(L,2) == LUA_TUSERDATA) {
			other = lua_toentity(L,2);
			if(other == NULL) return 0;
			luaentity->s.otherEntityNum2 = other->s.number;
		} else if (lua_type(L,2) == LUA_TNUMBER) {
			i = lua_tointeger(L,2);
			if(i < 0) return 0;
			if(i >= MAX_GENTITIES) return 0;
			luaentity->s.otherEntityNum = i;
		} else {
			luaentity->s.otherEntityNum2 = ENTITYNUM_NONE;
		}
	}
	return 0;
}

int qlua_settargetname(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TSTRING);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		strcpy(luaentity->targetname,lua_tostring(L,2));
	}
	return 0;
}

int qlua_gettargetname(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(luaentity->target != NULL) {
			lua_pushstring(L,luaentity->targetname);
			return 1;
		}
	}
	return 0;
}

int qlua_settarget(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TSTRING);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		strcpy(luaentity->target,lua_tostring(L,2));
	}
	return 0;
}

int qlua_gettarget(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(luaentity->target != NULL) {
			lua_pushstring(L,luaentity->target);
			return 1;
		}
		/*if(luaentity->target_ent) {
			lua_pushentity(L,luaentity->target_ent);
			return 1;
		} else if (luaentity->target) {
			target = G_PickTarget(luaentity->target);
			if(target) {
				lua_pushentity(L,target);
				return 1;
			}
		}*/
	}
	return 0;
}

int qlua_gettargetent(lua_State *L) {
	gentity_t	*luaentity, *target;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(luaentity->target_ent) {
			lua_pushentity(L,luaentity->target_ent);
			return 1;
		} else if (luaentity->target != NULL) {
			target = G_PickTarget(luaentity->target);
			if(target) {
				lua_pushentity(L,target);
				return 1;
			}
		}
	}
	return 0;
}

int qlua_getallentities(lua_State *L) {
	int numEnts = sizeof(g_entities) / sizeof(g_entities[0]);
	int i=0;
	int n=0;
	gentity_t	*ent;

	lua_newtable(L);

	for (i = 0, ent = g_entities, n = 1;
			i < level.num_entities;
			i++, ent++) {
		if (ent->classname) {
			lua_pushnumber(L, n);
			lua_pushentity(L,ent);
			lua_rawset(L, -3);
			n++;
		}
	}

	return 1;
}

int qlua_getentitiesbyclass(lua_State *L) {
	int numEnts = sizeof(g_entities) / sizeof(g_entities[0]);
	int i=0;
	int n=0;
	const char *filter = "";

	gentity_t	*ent;

	if(lua_gettop(L) > 0) {
		filter = lua_tostring(L,1);
		lua_newtable(L);

		for (i = 0, ent = g_entities, n = 1;
				i < level.num_entities;
				i++, ent++) {
				if (ent->classname && strcmp(ent->classname, filter) == 0) {
					lua_pushnumber(L, n);
					lua_pushentity(L,ent);
					lua_rawset(L, -3);
					n++;
				}
		}
	}
	return 1;
}

int qlua_getallplayers(lua_State *L) {
	int numEnts = sizeof(g_entities) / sizeof(g_entities[0]);
	int i=0;
	int n=0;
	gentity_t	*ent;

	lua_newtable(L);

	for (i = 0, ent = g_entities, n = 1;
			i < level.num_entities;
			i++, ent++) {
			if (ent->classname && ent->client) {
			lua_pushnumber(L, n);
			lua_pushentity(L,ent);
			lua_rawset(L, -3);
			n++;
		}
	}

	return 1;
}


int qlua_removeentity(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) { // && luaentity->client == NULL
		G_FreeEntity(luaentity);
	}
	return 0;
}

int qlua_entityid(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(luaentity->client != NULL) {
			lua_pushinteger(L,luaentity->s.clientNum);
		} else {
			lua_pushinteger(L,luaentity->s.number);
		}
	}
	return 1;
}

int qlua_getparent(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(luaentity->parent != NULL) {
			lua_pushentity(L,luaentity->parent);
		}
	}
	return 1;
}

int qlua_damageplayer(lua_State *L) {
	gentity_t	*targ = NULL;
	gentity_t	*inflictor = NULL;
	gentity_t	*attacker = NULL;
	int			damage = 0;
	int			df = 0;
	int			mod = 0;
	int			carg = 1;
	vec3_t		dir;
	vec3_t		point;
	qboolean	ddir = qfalse;
	qboolean	dpoint = qfalse;

	if(lua_gettop(L) > 0) {
		luaL_checktype(L,carg,LUA_TUSERDATA);
		if(lua_type(L,carg) == LUA_TUSERDATA) {targ = lua_toentity(L,carg); carg++;}
		if(lua_type(L,carg) == LUA_TNIL) carg++;

		if(lua_type(L,carg) == LUA_TUSERDATA) {inflictor = lua_toentity(L,carg); carg++;}
		if(lua_type(L,carg) == LUA_TNIL) carg++;
		
		if(lua_type(L,carg) == LUA_TUSERDATA) {attacker = lua_toentity(L,carg); carg++;}
		if(lua_type(L,carg) == LUA_TNIL) carg++;


		luaL_checkint(L,carg);
		damage = lua_tointeger(L,carg);

		if(lua_gettop(L) > carg) {
			carg++;
			if(lua_type(L,carg) == LUA_TNUMBER) {
				mod = lua_tointeger(L,carg);
			}
			carg++;
			if(lua_type(L,carg) == LUA_TVECTOR) {
				lua_tovector(L,carg,dir);
				ddir = qtrue;
			} else {
				carg--;
			}
			carg++;
			if(lua_type(L,carg) == LUA_TVECTOR) {
				lua_tovector(L,carg,point);
				dpoint = qtrue;
			} else {
				carg--;
			}
			carg++;
			if(lua_type(L,carg) == LUA_TNUMBER) {
				df = lua_tointeger(L,carg);
			}
		}

		if ( mod >= 0 && mod <= MOD_MAX ) {
			qlua_lockdamage = qtrue;
			//df |= DAMAGE_THRU_LUA;
			if(ddir && dpoint) {
				G_Damage(targ,inflictor,attacker,dir,point,damage,df,mod);
			} else {
				G_Damage(targ,inflictor,attacker,NULL,NULL,damage,df,mod);
			}
			qlua_lockdamage = qfalse;
		} else {
			lua_pushstring(L,"Invalid Argument For \"DamagePlayer\"\n (MOD out of range).\n");
			lua_error(L);
			return 1;
		}
	}
	return 0;
}

int qlua_sendtexttoplayer(lua_State *L) {
	gentity_t	*luaentity;
	const char *msg = "";
	int center = 0;
	int id = 0;

	luaL_checktype(L,1,LUA_TUSERDATA);

	if(lua_gettop(L) > 1) {
		luaentity = lua_toentity(L,1);
		msg = lua_tostring(L,2);
		center = lua_toboolean(L,3);
		if(msg && luaentity && luaentity->client) {
			id = luaentity->client->ps.clientNum;
			if(center == 1) {
				trap_SendServerCommand( id, va("cp \"%s\"", msg) );
			} else {
				trap_SendServerCommand( id, va("print \"%s\"",msg) );
			}
		}
	}
	return 0;
}

int qlua_addevent(lua_State *L) {
	gentity_t	*luaentity;
	int event = 0;
	int param = 0;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checkint(L,2);

	if(lua_gettop(L) > 1) {
		luaentity = lua_toentity(L,1);
		event = lua_tointeger(L,2);
		if(lua_gettop(L) >= 3) {
			luaL_checkint(L,3);
			param = lua_tointeger(L,3);
		}
		if(luaentity) {
			if(event >= EV_NONE && event <= EV_TAUNT_PATROL) {
				G_AddEvent(luaentity,event,param);
			}
		}
	}
	return 0;
}

int qlua_playsound(lua_State *L) {
	gentity_t	*luaentity;
	const char *file = "";
	char	buffer[MAX_QPATH];
	int index = 0;
	int channel = CHAN_AUTO;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TSTRING);

	if(lua_gettop(L) >= 2) {
		luaentity = lua_toentity(L,1);
		file = lua_tostring(L,2);
		if(luaentity) {
			if (!strstr( file, ".wav" )) {
				Com_sprintf (buffer, sizeof(buffer), "%s.wav", file );
			} else {
				Q_strncpyz( buffer, file, sizeof(buffer) );
			}

			if(lua_gettop(L) > 2) {
				channel = lua_tointeger(L,3);
				if(channel > CHAN_ANNOUNCER || channel < CHAN_AUTO) {
					channel = CHAN_AUTO;
				}
			}

			index = G_SoundIndex(buffer);
			if(index) {
				//G_AddEvent( luaentity, EV_GENERAL_SOUND, index );
				G_Sound( luaentity, channel, index );
			}
		}
	}
	return 0;
}

int qlua_setcallback(lua_State *L) {
	gentity_t	*ent;
	int	call;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);
	luaL_checktype(L,3,LUA_TFUNCTION);

	if(lua_gettop(L) >= 2) {
		ent = lua_toentity(L,1);
		call = lua_tointeger(L,2);
		if(ent) {
			switch(call) {
				case 0: ent->lua_blocked = qlua_storefunc(L,3,ent->lua_blocked); break;
				case 1: ent->lua_die = qlua_storefunc(L,3,ent->lua_die); break;
				case 2: ent->lua_pain = qlua_storefunc(L,3,ent->lua_pain); break;
				case 3: ent->lua_reached = qlua_storefunc(L,3,ent->lua_reached); break;
				case 4: ent->lua_think = qlua_storefunc(L,3,ent->lua_think); break;
				case 5: ent->lua_touch = qlua_storefunc(L,3,ent->lua_touch); break;
				case 6: ent->lua_use = qlua_storefunc(L,3,ent->lua_use); break;
			}		
		}
	}
	return 0;
}

static int qlua_setmaxhealth(lua_State *L) {
	gentity_t	*luaentity;
	int			val=0;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_toentity(L,1);
	val = lua_tointeger(L,2);
	if(luaentity != NULL && luaentity->client) {
		//luaentity->client->ps.luatest = val;
		//luaentity->client->ps.luatest2 = "Max Health:";
		//sprintf(luaentity->client->ps.luatest2,"Max-Health:");
		//Q_strncpyz(luaentity->client->ps.luatest2,"Max Health:",1024);
		//G_Printf("Sizeof String: %i\n",(sizeof(luaentity->client->ps.luatest2) / sizeof(luaentity->client->ps.luatest2[0]))*32);

		if(val <= 0 && luaentity->client->luamaxhealth != 0) {
			luaentity->client->ps.stats[STAT_MAX_HEALTH] = luaentity->client->pers.maxHealth;
			luaentity->client->luamaxhealth = 0;
		} else {
			luaentity->client->luamaxhealth = val;
		}
	}
	return 0;
}

static int qlua_getmaxhealth(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL && luaentity->client) {
		lua_pushinteger(L,luaentity->client->luamaxhealth);
		return 1;
	}
	return 0;
}

static int qlua_sendstring(lua_State *L) {
	gentity_t	*luaentity;
	const char	*str = "";

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TSTRING);

	luaentity = lua_toentity(L,1);
	str	= lua_tostring(L,2);
	if(luaentity != NULL && luaentity->client && str != NULL) {
		trap_SendServerCommand( luaentity->s.number, va("luamsg %s", str) );
	}
	return 0;
}

static int Entity_tostring (lua_State *L)
{
	gentity_t *e1 = lua_toentity(L,1);
	if(e1 != NULL) {
		lua_pushstring(L,e1->classname);
		return 1;
	}
	return 0;
}

static int Entity_equal (lua_State *L)
{
	gentity_t *e1 = lua_toentity(L,1);
	gentity_t *e2 = lua_toentity(L,2);
	if(e1 != NULL && e2 != NULL) {
		lua_pushboolean(L, (e1->s.number == e2->s.number));
	} else {
		lua_pushboolean(L, 0);
	}
  return 1;
}

static int Entity_table (lua_State *L) {
	//gentity_t *ent = lua_toentity(L,1);
	const char *in = lua_tostring(L,2);
	G_Printf("TableIn\n");
	if(in != NULL) {
		G_Printf("Getting: %s\n",in);
		lua_gettable(L,1);
		lua_pushstring(L,in);
		lua_rawget(L, -2);
		return 1;
	}
	return 0;
}

static int Entity_tableset (lua_State *L) {
	gentity_t *ent = lua_toentity(L,1);
	const char *in = lua_tostring(L,2);
	if(ent != NULL) {
		if(qlua_getstored(L,ent->lua_persistanttable)) {
			if(in != NULL) {
				lua_pushstring(L,in);
				lua_pushvalue(L,3);
				lua_rawset(L, -3);
			}
			return 1;
		}
	}
	return 0;
}

int lua_setclipmask(lua_State *L) {
	gentity_t	*luaentity;
	int mask = 0;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_toentity(L,1);
	mask	= lua_tonumber(L,2);
	if(luaentity != NULL) {
		luaentity->clipmask = mask;
	}
	return 0;
}

int lua_gettr(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L,luaentity->s.pos.trType);
		return 1;
	}
	return 0;
}

int lua_settr(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		luaentity->s.pos.trType = lua_tointeger(L,2);
	}
	return 0;
}

int lua_getnextthink(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L,luaentity->nextthink);
		return 1;
	}
	return 0;
}

int lua_setnextthink(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		luaentity->nextthink = lua_tointeger(L,2);
	}
	return 0;
}

int lua_gettrx(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushtrajectory(L,&luaentity->s.pos);
		return 1;
	}
	return 0;
}

int lua_settrx(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		luaentity->s.pos = *lua_totrajectory(L,2);
	}
	return 0;
}

int lua_getmins(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushvector(L,luaentity->r.mins);
		return 1;
	}
	return 0;
}

int lua_setmins(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TVECTOR);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_tovector(L,2,luaentity->r.mins);
	}
	return 0;
}

int lua_getmaxs(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushvector(L,luaentity->r.maxs);
		return 1;
	}
	return 0;
}

int lua_setmaxs(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TVECTOR);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_tovector(L,2,luaentity->r.maxs);
	}
	return 0;
}

int lua_settakedamage(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TBOOLEAN);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		luaentity->takedamage = lua_toboolean(L,2);
	}
	return 0;
}

int lua_setclip(lua_State *L) {
	gentity_t	*luaentity;
	int			mask = 0;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		mask = lua_tointeger(L,2);
		//luaentity->r.contents = mask;
		luaentity->clipmask = mask;
	}
	return 0;
}

int lua_setcontents(lua_State *L) {
	gentity_t	*luaentity;
	int			mask = 0;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		mask = lua_tointeger(L,2);
		luaentity->r.contents = mask;
	}
	return 0;
}

int lua_sethp(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		luaentity->health = lua_tointeger(L,2);
	}
	return 0;
}

int lua_gethp(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L,luaentity->health);
		return 1;
	}
	return 0;
}

int lua_setarmor(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL && luaentity->client) {
		luaentity->client->ps.stats[STAT_ARMOR] = lua_tointeger(L,2);
	}
	return 0;
}

int lua_getarmor(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL && luaentity->client) {
		lua_pushinteger(L,luaentity->client->ps.stats[STAT_ARMOR]);
		return 1;
	}
	return 0;
}

int qlua_setground(lua_State *L) {
	gentity_t	*luaentity;
	int ground = 0;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	ground = lua_tointeger(L,2);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		luaentity->s.groundEntityNum = ground;
	}
	return 0;
}

int qlua_getground(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L,luaentity->s.groundEntityNum);
		return 1;
	}
	return 0;
}

int qlua_getwait(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L,luaentity->wait);
		return 1;
	}
	return 0;
}

int qlua_setwait(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		luaentity->wait = lua_tonumber(L,2);
	}
	return 0;
}

int qlua_getspflags(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L,luaentity->spawnflags);
		return 1;
	}
	return 0;
}

int qlua_setspflags(lua_State *L) {
	gentity_t	*luaentity;
	int flags = 0;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		flags = lua_tointeger(L,2);
		luaentity->spawnflags = flags;
		luaentity->s.generic1 = flags;
	}
	return 0;
}

int qlua_setbounce(lua_State *L) {
	gentity_t	*luaentity;
	int flags = 0;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		luaentity->physicsBounce = lua_tonumber(L,2);
	}
	return 0;
}

int qlua_setetype(lua_State *L) {
	gentity_t	*luaentity;
	int type = 0;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_toentity(L,1);
	type = lua_tointeger(L,2);
	if(luaentity != NULL && type >= ET_GENERAL && type <= ET_EVENTS) {
		luaentity->s.eType = type;
		G_Printf("SetTypeTo: %i\n",luaentity->s.eType);
	}
	return 0;
}

int qlua_getetype(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L,luaentity->s.eType);
		return 1;
	}
	return 0;
}

int qlua_setflags(lua_State *L) {
	gentity_t	*luaentity;
	int flags = 0;
	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);
	luaentity = lua_toentity(L,1);
	flags = lua_tointeger(L,2);
	if(luaentity != NULL) {
		luaentity->flags = flags;
	}
	return 0;
}

int qlua_getflags(lua_State *L) {
	gentity_t	*luaentity;
	luaL_checktype(L,1,LUA_TUSERDATA);
	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L,luaentity->flags);
		return 1;
	}
	return 0;
}

int qlua_seteflags(lua_State *L) {
	gentity_t	*luaentity;
	int flags = 0;
	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);
	luaentity = lua_toentity(L,1);
	flags = lua_tointeger(L,2);
	if(luaentity != NULL) {
		luaentity->s.eFlags = flags;
	}
	return 0;
}

int qlua_geteflags(lua_State *L) {
	gentity_t	*luaentity;
	luaL_checktype(L,1,LUA_TUSERDATA);
	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L,luaentity->s.eFlags);
		return 1;
	}
	return 0;
}

int qlua_setsvflags(lua_State *L) {
	gentity_t	*luaentity;
	int flags = 0;
	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);
	luaentity = lua_toentity(L,1);
	flags = lua_tointeger(L,2);
	if(luaentity != NULL) {
		luaentity->r.svFlags = flags;
	}
	return 0;
}

int qlua_getsvflags(lua_State *L) {
	gentity_t	*luaentity;
	luaL_checktype(L,1,LUA_TUSERDATA);
	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L,luaentity->r.svFlags);
		return 1;
	}
	return 0;
}

int qlua_setdamage(lua_State *L) {
	gentity_t	*luaentity;
	int dmg = 0;
	int dmg2 = -1;
	int dmg3 = -1;
	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);
	luaentity = lua_toentity(L,1);
	dmg = lua_tointeger(L,2);

	if(lua_type(L,3) == LUA_TNUMBER) {
		dmg2 = lua_tointeger(L,3);
	}

	if(lua_type(L,4) == LUA_TNUMBER) {
		dmg3 = lua_tointeger(L,4);
	}


	if(luaentity != NULL) {
		if(dmg >= 0) luaentity->damage = dmg;
		if(dmg2 >= 0) luaentity->splashDamage = dmg2;
		if(dmg3 >= 0) luaentity->splashRadius = dmg3;
	}
	return 0;
}

int qlua_setowner(lua_State *L) {
	gentity_t	*luaentity;
	gentity_t	*owner;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TUSERDATA);
	
	luaentity = lua_toentity(L,1);
	owner = lua_toentity(L,2);
	
	if(luaentity != NULL && owner != NULL && owner->client != NULL) {
		luaentity->r.ownerNum = owner->s.number;
		luaentity->parent = owner;
	}
	return 0;
}

int qlua_setmod(lua_State *L) {
	gentity_t	*luaentity;
	int dmg = 0;
	int dmg2 = -1;
	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);
	luaentity = lua_toentity(L,1);
	dmg = lua_tointeger(L,2);

	if(lua_type(L,3) == LUA_TNUMBER) {
		dmg2 = lua_tointeger(L,3);
	}

	if(luaentity != NULL) {
		if(dmg >= MOD_UNKNOWN && dmg < MOD_MAX) luaentity->methodOfDeath = dmg;
		if(dmg2 >= MOD_UNKNOWN && dmg2 < MOD_MAX) luaentity->splashMethodOfDeath = dmg;
	}
	return 0;
}

int qlua_espawn(lua_State *L) {
	gentity_t	*luaentity;
	luaL_checktype(L,1,LUA_TUSERDATA);
	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		qlua_LinkEntity(luaentity);
		G_Printf("Entity Linked: [%s], type=%i, flags=%i, svflags=%i\n",
			luaentity->classname,
			luaentity->s.eType,
			luaentity->s.eFlags,
			luaentity->r.svFlags);
	}
	return 0;
}

int qlua_getspawnangle(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		lua_pushnumber(L,luaentity->angle);
		return 1;
	}
	return 0;
}

int qlua_use(lua_State *L) {
	gentity_t	*luaentity, *other = NULL, *activator;
	luaL_checktype(L,1,LUA_TUSERDATA);
	luaentity = lua_toentity(L,1);

	//bluh bluh

	if(luaentity == NULL) return 0;

	if(lua_type(L,2) == LUA_TUSERDATA) other = lua_toentity(L,2);
	if(lua_type(L,3) == LUA_TUSERDATA) activator = lua_toentity(L,3);

	if(other == NULL && activator != NULL) other = activator;
	if(other == NULL && luaentity != NULL) other = luaentity;
	if(other == NULL) return 0;

	if(activator == NULL) activator = other;

	if(luaentity != NULL) {
		if(luaentity->use != NULL) {
			luaentity->use(luaentity,other,activator);
		}
		if(qlua_getstored(L,luaentity->lua_use)) {
			lua_pushentity(L,luaentity);
			lua_pushentity(L,other);
			lua_pushentity(L,activator);
			qlua_pcall(L, 3, 0, qfalse);
		}
	}
	return 0;
}

int qlua_eventparm(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		luaentity->s.eventParm = lua_tointeger(L,2);
	}
	return 0;
}

int qlua_clientnum(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		luaentity->s.clientNum = lua_tointeger(L,2);
	}
	return 0;
}

int qlua_setanims(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		luaentity->s.legsAnim = lua_tointeger(L,2);
		if(lua_type(L,3) == LUA_TNUMBER) {
			luaentity->s.torsoAnim = lua_tointeger(L,3);
		}
	}
	return 0;
}

int qlua_setpaindebounce(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		luaentity->pain_debounce_time = lua_tointeger(L,2);
	}
	return 0;
}

int qlua_getItemIndex(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(luaentity->item != NULL) {
			lua_pushinteger(L,luaentity->item->id);
			return 1;
		}
	}
	return 0;
}

int qlua_getPredicted(lua_State *L) {
	gentity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_toentity(L,1);
	if(luaentity != NULL) {
		if(luaentity->client != NULL) {
			lua_pushinteger(L,luaentity->client->ps.clientNum);
		} else {
			lua_pushinteger(L,luaentity->s.clientNum);
		}
		return 1;
	}
	return 0;
}

static const luaL_reg Entity_methods[] = {
  {"GetInfo",		qlua_getclientinfo},
  {"SetInfo",		qlua_setclientinfo},
  {"GetPos",		qlua_getpos},
  {"SetPos",		qlua_setpos},
  {"SetPos2",		qlua_setpos2},
  {"GetAngles",		qlua_getangles},
  {"SetAngles",		qlua_setangles},
  {"GetSpawnAngle", qlua_getspawnangle},
  {"GetMuzzlePos",	qlua_getmuzzlepos},
  {"GetAimAngles",		qlua_getaimvec},
  {"SetAimAngles",		qlua_setaimvec},
  {"GetTeam",			qlua_getteam},
  {"SetTeam",			qlua_setteam},
  {"SetSpectatorType",	qlua_setspectatorstate},
  {"GetSpectatorType",	qlua_getspectatorstate},
  {"Respawn",			qlua_respawn},
  {"SetRespawnTime",	qlua_setrespawntime},
  {"GetVelocity",		qlua_getvel},
  {"SetVelocity",		qlua_setvel},
  {"GetOtherEntity",	qlua_getotherentity},
  {"GetOtherEntity2",	qlua_getotherentity2},
  {"SetOtherEntity",	qlua_setotherentity},
  {"SetOtherEntity2",	qlua_setotherentity2},
  {"GetTargetEnt",		qlua_gettargetent},
  {"GetTarget",			qlua_gettarget},
  {"SetTarget",			qlua_settarget},
  {"GetTargetName",		qlua_gettargetname},
  {"SetTargetName",		qlua_settargetname},
  {"SetWeapon",		qlua_setweapon},
  {"GiveWeapon",	qlua_giveweapon},
  {"HasWeapon",		qlua_hasweapon},
  {"HasAmmo",		qlua_hasammo},
  {"SetAmmo",		qlua_setammo},
  {"GetAmmo",		qlua_getammo},
  {"SetAnim",		qlua_setanim},
  {"SetPowerup",	qlua_setpowerup},
  {"GetPowerup",	qlua_getpowerup},
  {"GetMaxHealth",	qlua_getmaxhealth},
  {"SetMaxHealth",	qlua_setmaxhealth},
  {"RemoveWeapons", qlua_removeweapons},
  {"RemovePowerups",	qlua_removepowerups},
  {"Damage",		qlua_damageplayer},
  {"SendMessage",	qlua_sendtexttoplayer},
  {"IsPlayer",		qlua_isclient},
  {"IsBot",			qlua_isbot},
  {"IsLocal",		qlua_islocal},
  {"IsAdmin",		qlua_islocal},
  {"Classname",		qlua_getclass},
  {"Remove",		qlua_removeentity},
  {"EntIndex",		qlua_entityid},
  {"AddEvent",		qlua_addevent},
  {"PlaySound",		qlua_playsound},
  {"GetParent",		qlua_getparent},
  {"SetCallback",	qlua_setcallback},
  {"SendString",	qlua_sendstring},
  {"SetSpeed",		qlua_setspeed},
  {"GetTable",		lua_getentitytable},
  {"SetClipMask",	lua_setclipmask},
  {"GetTrType",		lua_gettr},
  {"SetTrType",		lua_settr},
  {"GetNextThink",	lua_getnextthink},
  {"SetNextThink",	lua_setnextthink},
  {"GetTrajectory",	lua_gettrx},
  {"SetTrajectory", lua_settrx},
  {"GetMins",		lua_getmins},
  {"SetMins",		lua_setmins},
  {"GetMaxs",		lua_getmaxs},
  {"SetMaxs",		lua_setmaxs},
  {"SetTakeDamage",	lua_settakedamage},
  {"SetClip",		lua_setclip},
  {"SetContents",	lua_setcontents},
  {"SetHealth",		lua_sethp},
  {"GetHealth",		lua_gethp},
  {"SetArmor",		lua_setarmor},
  {"GetArmor",		lua_getarmor},
  {"SetGroundEntity",		qlua_setground},
  {"GetGroundEntity",		qlua_getground},
  {"GetWait",		qlua_getwait},
  {"SetWait",		qlua_setwait},
  {"GetSpawnFlags", qlua_getspflags},
  {"SetSpawnFlags",	qlua_setspflags},
  {"SetBounce",		qlua_setbounce},
  {"SetType",		qlua_setetype},
  {"GetType",		qlua_getetype},
  {"SetFlags",		qlua_setflags},
  {"GetFlags",		qlua_getflags},
  {"SetEFlags",		qlua_seteflags},
  {"GetEFlags",		qlua_geteflags},
  {"SetSvFlags",	qlua_setsvflags},
  {"GetSvFlags",	qlua_getsvflags},
  {"SetDamage",		qlua_setdamage},
  {"SetOwner",		qlua_setowner},
  {"SetDeathMethod", qlua_setmod},
  {"SetEventParm",	qlua_eventparm},
  {"Spawn",			qlua_espawn},
  {"Fire",			qlua_use},
  {"SetClientNum",  qlua_clientnum},
  {"SetAnims",		qlua_setanims},
  {"SetPainDebounce", qlua_setpaindebounce},
  {"ItemIndex",		qlua_getItemIndex},
  {"GetPredicted",	qlua_getPredicted},
  {0,0}
};

static const luaL_reg Entity_meta[] = {
  {"__tostring", Entity_tostring},
  {"__eq", Entity_equal},
  {"__index", Entity_table},
  {"__newindex", Entity_tableset},
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

int qlua_createtentity (lua_State *L) {
	gentity_t	*tent;
	vec3_t	pos;
	int ev = 0;

	if(lua_gettop(L) >= 2) {
		luaL_checktype(L,1,LUA_TVECTOR);
		luaL_checktype(L,2,LUA_TNUMBER);

		lua_tovector(L,1,pos);
		ev = lua_tointeger(L,2);

		tent = G_TempEntity(pos,ev);

		if(tent != NULL) {
			lua_pushentity(L,tent);
			return 1;
		}
	}
			
	return 0;
}

int qlua_unlink(lua_State *L) {
	gentity_t *ent;
	luaL_checktype(L,1,LUA_TUSERDATA);

	ent = lua_toentity(L,1);
	if(ent != NULL) {
		qlua_UnlinkEntity(ent);
	}
	return 0;
}

int qlua_link(lua_State *L) {
	gentity_t *ent;
	luaL_checktype(L,1,LUA_TUSERDATA);

	ent = lua_toentity(L,1);
	if(ent != NULL) {
		qlua_LinkEntity(ent);
	}
	return 0;
}

int qlua_createEntity(lua_State *L) {
	gentity_t	*ent;
	const char	*classname;
	luaL_checktype(L,1,LUA_TSTRING);
	classname = lua_tostring(L,1);
	if(classname) {
		if(strlen(classname) > 200) {
			lua_pushstring(L,"Classname Too Long!\n");
			lua_error(L);
			return 1;
		}
		ent = G_Spawn();
		ent->client = NULL;
		ent->touch = 0;
		ent->pain = 0;
		ent->die = 0;
		ent->think = 0;
		ent->classname = (char*)classname;
		if(G_CallSpawn(ent,qtrue)) {
			lua_pushentity(L,ent);
			qlua_LinkEntity(ent);
			if(ent->item != NULL) {
				SaveRegisteredItems();
			}
			return 1;
		}

		VectorClear( ent->r.mins );
		VectorClear( ent->r.maxs );
		ent->s.eType = ET_LUA;
		ent->r.svFlags = SVF_BROADCAST;//SVF_BROADCAST;
		ent->s.weapon = WP_NONE;
		ent->clipmask = MASK_SHOT;
		ent->target_ent = NULL;
		ent->s.pos.trType = TR_GRAVITY;
		ent->s.pos.trTime = level.time;
		strcpy(ent->s.luaname, classname);
		ent->inuse = qtrue;
		//ent->classname = "luaentity";
		VectorCopy(ent->s.pos.trBase,ent->s.origin2); 
		qlua_LinkEntity(ent);
		//strcpy(ent->classname, classname);
		lua_pushentity(L,ent);
		return 1;
	}
	return 0;

	/*bolt->s.eType = ET_MISSILE;
	bolt->r.svFlags = SVF_USE_CURRENT_ORIGIN;
	bolt->s.weapon = WP_GRENADE_LAUNCHER;
	bolt->s.eFlags = EF_BOUNCE_HALF;
	bolt->r.ownerNum = self->s.number;
	bolt->parent = self;
	bolt->damage = 100;
	bolt->splashDamage = 100;
	bolt->splashRadius = 150;
	bolt->methodOfDeath = MOD_GRENADE;
	bolt->splashMethodOfDeath = MOD_GRENADE_SPLASH;
	bolt->clipmask = MASK_SHOT;
	bolt->target_ent = NULL;

	bolt->s.pos.trType = TR_GRAVITY;
	bolt->s.pos.trTime = level.time - MISSILE_PRESTEP_TIME;		// move a bit on the very first frame
	VectorCopy( start, bolt->s.pos.trBase );
	VectorScale( dir, 700, bolt->s.pos.trDelta );
	SnapVector( bolt->s.pos.trDelta );			// save net bandwidth

	VectorCopy (start, bolt->r.currentOrigin);

	return bolt;*/
}

int qlua_firemissile(lua_State *L) {
	const char	*classname;
	gentity_t	*self;
	gentity_t	*out;
	vec3_t v;
	
	luaL_checktype(L,1,LUA_TSTRING);
	luaL_checktype(L,2,LUA_TUSERDATA);

	classname = lua_tostring(L,1);
	self = lua_toentity(L,2);
	if(classname && self != NULL) {
		if(!strcmp("grenade",classname)) out = fire_grenade(self, v, v);
		if(!strcmp("rocket",classname)) out = fire_rocket(self, v, v);
		if(!strcmp("plasma",classname)) out = fire_plasma(self, v, v);
		if(!strcmp("bfg",classname)) out = fire_bfg(self, v, v);
		if(!strcmp("grapple",classname)) out = fire_grapple(self, v, v);
	}
	if(out != NULL) {
		//qlua_LinkEntity(out);
		lua_pushentity(L,out);
		return 1;
	}
	return 0;
}

int qlua_devent(lua_State *L) {
	gentity_t *ent;
	int ev = EV_NONE;
	int param = 0;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	ent = lua_toentity(L,1);
	ev = lua_tointeger(L,2);

	if(ev < EV_NONE || ev > EV_TAUNT_PATROL) {
		lua_pushstring(L,"Bad event number in AddEvent\n");
		lua_error(L);
		return 0;
	}

	if(lua_type(L,3) == LUA_TNUMBER) {
		param = lua_tointeger(L,3);
	}

	G_AddEvent( ent, ev, param);
	return 0;
}

void G_InitLuaEnts(lua_State *L) {
	Entity_register(L);
	lua_register(L,"CreateTempEntity",qlua_createtentity);
	//lua_register(L,"GetEntitiesByClass",qlua_getentitiesbyclass);
	//lua_register(L,"GetAllPlayers",qlua_getallplayers);
	lua_register(L,"UnlinkEntity",qlua_unlink);
	lua_register(L,"LinkEntity",qlua_link);
	lua_register(L,"CreateEntity",qlua_createEntity);
	lua_register(L,"CreateMissile",qlua_firemissile);
	lua_register(L,"AddEvent",qlua_devent);
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