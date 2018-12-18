#include "cg_local.h"

int qlua_getitemicon(lua_State *L) {
	int icon = 0;
	int size = sizeof(cg_items) / sizeof(cg_items[0]);
	luaL_checktype(L,1,LUA_TNUMBER);

	icon = lua_tointeger(L,1);

	if(icon <= 0 || icon > size) {
		lua_pushstring(L,"Item Index Out Of Bounds\n");
		lua_error(L);
		return 1;
	}
	CG_RegisterItemVisuals( icon );
	lua_pushinteger(L,cg_items[icon].icon);
	return 1;
}

int qlua_getitemmodel(lua_State *L) {
	int icon = 0;
	int size = sizeof(cg_items) / sizeof(cg_items[0]);
	luaL_checktype(L,1,LUA_TNUMBER);

	icon = lua_tointeger(L,1);

	if(icon <= 0 || icon > size) {
		lua_pushstring(L,"Item Index Out Of Bounds\n");
		lua_error(L);
		return 1;
	}
	CG_RegisterItemVisuals( icon );
	lua_pushinteger(L,cg_items[icon].models[0]);
	return 1;
}

int qlua_getitemname(lua_State *L) {
	int icon = 0;
	int size = sizeof(cg_items) / sizeof(cg_items[0]);
	luaL_checktype(L,1,LUA_TNUMBER);

	icon = lua_tointeger(L,1);

	if(icon <= 0 || icon > size) {
		lua_pushstring(L,"Item Index Out Of Bounds\n");
		lua_error(L);
		return 1;
	}
	if(bg_itemlist[icon].pickup_name != NULL) {
		lua_pushstring(L,bg_itemlist[icon].pickup_name);
	}
	return 1;
}

int qlua_getweaponicon(lua_State *L) {
	int icon = 0;
	int size = WP_NUM_WEAPONS;
	qboolean ammo = qfalse;

	luaL_checktype(L,1,LUA_TNUMBER);

	icon = lua_tointeger(L,1);

	if(icon < 0 || icon >= size) {
		lua_pushstring(L,"Weapon Index Out Of Bounds\n");
		lua_error(L);
		return 1;
	}

	if(lua_type(L,2) == LUA_TBOOLEAN && lua_toboolean(L,2) == qtrue) {
		lua_pushinteger(L,cg_weapons[ icon ].ammoIcon);
	} else {
		lua_pushinteger(L,cg_weapons[ icon ].weaponIcon);
	}
	return 1;
}

int qlua_getweaponname(lua_State *L) {
	int icon = 0;
	int size = WP_NUM_WEAPONS;
	gitem_t *item;

	luaL_checktype(L,1,LUA_TNUMBER);

	icon = lua_tointeger(L,1);

	if(icon < 0 || icon >= size) {
		lua_pushstring(L,"Weapon Index Out Of Bounds\n");
		lua_error(L);
		return 1;
	}
	item = cg_weapons[ icon ].item;

	if(item != NULL) {
		lua_pushstring(L,item->pickup_name);
	} else {
		lua_pushstring(L,"");
	}
	return 1;
}

int qlua_chardata (lua_State *L) {
	const char *str = lua_tostring(L,1);
	int ch = *str;
	int row,col;
	float frow,fcol,size;

	ch &= 255;

	row = ch>>4;
	col = ch&15;

	frow = row*0.0625;
	fcol = col*0.0625;
	size = 0.0625;

	lua_pushnumber(L,frow);
	lua_pushnumber(L,fcol);
	lua_pushnumber(L,size);

	lua_pushinteger(L,row);
	lua_pushinteger(L,col);

	return 5;
}

int qlua_lockmouse (lua_State *L) {
	luaL_checktype(L,LUA_TBOOLEAN,1);
	trap_LockMouse(lua_toboolean(L,1));
	return 0;
}

int qlua_loadskin(lua_State *L) {
	const char *filename = "";
	int out = 0;

	luaL_checkstring(L,1);
	filename = lua_tostring(L,1);
	out = trap_R_RegisterSkin( filename );

	if (!out) {
		Com_Printf( "Skin load failure: %s\n", filename );
	} else {
		lua_pushinteger(L,out);
		return 1;
	}

	return 0;
}

int qlua_createmark(lua_State *L) {
	int shader;
	vec3_t origin;
	vec3_t plane;
	float orient;
	float red;
	float green;
	float blue;
	float alpha;
	qboolean alphafade = qfalse;
	float radius;
	float time = 0;
	
	luaL_checkint(L,1);
	luaL_checktype(L,2,LUA_TVECTOR);
	luaL_checktype(L,3,LUA_TVECTOR);
	luaL_checknumber(L,4);
	luaL_checknumber(L,5);
	luaL_checknumber(L,6);
	luaL_checknumber(L,7);
	luaL_checknumber(L,8);
	luaL_checknumber(L,9);

	shader = lua_tointeger(L,1);
	lua_tovector(L,2,origin);
	lua_tovector(L,3,plane);
	orient = lua_tonumber(L,4);
	red = lua_tonumber(L,5);
	green = lua_tonumber(L,6);
	blue = lua_tonumber(L,7);
	alpha = lua_tonumber(L,8);
	radius = lua_tonumber(L,9);

	if(radius <= 0) radius = .01f;

	if(lua_type(L,10) == LUA_TBOOLEAN) {
		alphafade = lua_toboolean(L,10);
	}

	if(lua_type(L,11) == LUA_TNUMBER) {
		time = lua_tonumber(L,11);
	}

	CG_ImpactMark(shader,origin,plane,orient,red,green,blue,alpha,alphafade,radius,qfalse,time);

	return 0;
}

int qlua_clearmarks(lua_State *L) {
	CG_InitMarkPolys();
	return 0;
}

int qlua_playeranim(lua_State *L) {
	refEntity_t	*legs;
	refEntity_t	*torso;
	centity_t	*player;

	luaL_checktype(L,1,LUA_TUSERDATA);

	player = lua_toentity(L,1);
	legs = lua_torefentity(L,2);
	torso = lua_torefentity(L,3);
	if(player != NULL && legs != NULL && torso != NULL) {
		CG_PlayerAnimation(player,&legs->oldframe,&legs->frame,&legs->backlerp,&torso->oldframe,&torso->frame,&torso->backlerp);
	}
	return 0;
}

int qlua_playerangles(lua_State *L) {
	refEntity_t	*legs;
	refEntity_t	*torso;
	refEntity_t	*head;
	centity_t	*player;

	luaL_checktype(L,1,LUA_TUSERDATA);

	player = lua_toentity(L,1);
	legs = lua_torefentity(L,2);
	torso = lua_torefentity(L,3);
	head = lua_torefentity(L,4);
	if(player != NULL && legs != NULL && torso != NULL) {
		CG_PlayerAngles(player,legs->axis,torso->axis,head->axis);
	}
	return 0;
}

int qlua_playerweapon(lua_State *L) {
	refEntity_t	*parent;
	centity_t	*player;
	luaL_checktype(L,1,LUA_TUSERDATA);
	
	player = lua_toentity(L,1);
	parent = lua_torefentity(L,2);

	CG_AddPlayerWeapon( parent, NULL, player, TEAM_FREE );
	return 0;
}

int qlua_playerhand(lua_State *L) {
	refEntity_t	hand;
	vec3_t		angles;
	clientInfo_t	*ci;
	centity_t	*cent = &cg.predictedPlayerEntity;
	float		fovOffset;
	weaponInfo_t	*weapon;
	playerState_t	*ps = &cg.predictedPlayerState;

	if ( cg_fov.integer > 90 ) {
		fovOffset = -0.2 * ( cg_fov.integer - 90 );
	} else {
		fovOffset = 0;
	}

	CG_RegisterWeapon( ps->weapon );
	weapon = &cg_weapons[ ps->weapon ];

	memset (&hand, 0, sizeof(hand));

	// set up gun position
	CG_CalculateWeaponPosition( hand.origin, angles );

	VectorMA( hand.origin, cg_gun_x.value, cg.refdef.viewaxis[0], hand.origin );
	VectorMA( hand.origin, cg_gun_y.value, cg.refdef.viewaxis[1], hand.origin );
	VectorMA( hand.origin, (cg_gun_z.value+fovOffset), cg.refdef.viewaxis[2], hand.origin );

	AnglesToAxis( angles, hand.axis );

	// map torso animations to weapon animations
	if ( cg_gun_frame.integer ) {
		// development tool
		hand.frame = hand.oldframe = cg_gun_frame.integer;
		hand.backlerp = 0;
	} else {
		// get clientinfo for animation map
		ci = &cgs.clientinfo[ cent->currentState.clientNum ];
		hand.frame = CG_MapTorsoToWeaponFrame( ci, cent->pe.torso.frame );
		hand.oldframe = CG_MapTorsoToWeaponFrame( ci, cent->pe.torso.oldFrame );
		hand.backlerp = cent->pe.torso.backlerp;
	}

	hand.hModel = weapon->handsModel;
	hand.renderfx = RF_DEPTHHACK | RF_FIRST_PERSON | RF_MINLIGHT;

	lua_pushrefentity(L,&hand);

	return 1;
}

int items_size() {
	gitem_t	*it;
	int size = 0;
	
	for ( it = bg_itemlist + 1 ; it->classname ; it++) {
		size = size + 1;
	}
	return size;
}

int qlua_numitems(lua_State *L) {
	lua_pushinteger(L,items_size());
	return 1;
}

int qlua_itemInfo(lua_State *L) {
	int icon = 0;
	int size = sizeof(cg_items) / sizeof(cg_items[0]);
	itemInfo_t item;
	gitem_t item2;

	luaL_checktype(L,1,LUA_TNUMBER);

	icon = lua_tointeger(L,1);

	if(icon <= 0 || icon > size || icon > items_size()) {
		lua_pushstring(L,"Item Index Out Of Bounds\n");
		lua_error(L);
		return 1;
	}

	item = cg_items[icon];
	item2 = bg_itemlist[icon];

	CG_RegisterItemVisuals( icon );
	lua_newtable(L);

	setTableTable(L,"models",item.models,4);
	setTableInt(L,"icon",item.icon);
	setTableBoolean(L,"registered",item.registered);
	setTableString(L,"classname",item2.classname);
	setTableInt(L,"tag",item2.giTag);
	setTableInt(L,"type",item2.giType);
	setTableString(L,"pickupsound",item2.pickup_sound);
	setTableString(L,"pickupname",item2.pickup_name);
	setTableInt(L,"quantity",item2.quantity);

	return 1;
}

int qlua_weaponinfo(lua_State *L) {
	weaponInfo_t	*weapon;
	gitem_t *item;
	int id = lua_tointeger(L,1);

	if(id < WP_NONE || id >= WP_NUM_WEAPONS) {
		lua_pushstring(L,"Weapon out of bounds.");
		lua_error(L);
		return 1;
	}
	CG_RegisterWeapon( id );
	weapon = &cg_weapons[ id ];

	item = weapon->item;

	lua_newtable(L);
	
	setTableInt(L,"ammoIcon",weapon->ammoIcon);
	setTableInt(L,"ammoModel",weapon->ammoModel);
	setTableInt(L,"barrelModel",weapon->barrelModel);
	setTableInt(L,"firingSound",weapon->firingSound);
	setTableFloat(L,"flashDlight",weapon->flashDlight);
	setTableVector(L,"flashDlightColor",weapon->flashDlightColor);
	setTableInt(L,"flashModel",weapon->flashModel);
	setTableTable(L,"flashSound",weapon->flashSound,4);
	setTableInt(L,"handsModel",weapon->handsModel);
	setTableBoolean(L,"loopFireSound",weapon->loopFireSound);
	setTableFloat(L,"missileDlight",weapon->missileDlight);
	setTableVector(L,"missileDlightColor",weapon->missileDlightColor);
	setTableInt(L,"missileModel",weapon->missileModel);
	setTableInt(L,"missileRenderfx",weapon->missileRenderfx);
	setTableInt(L,"missileSound",weapon->missileSound);
	setTableInt(L,"readySound",weapon->readySound);
	setTableBoolean(L,"registered",weapon->registered);
	setTableFloat(L,"trailRadius",weapon->trailRadius);
	setTableInt(L,"weaponIcon",weapon->weaponIcon);
	setTableVector(L,"weaponMidpoint",weapon->weaponMidpoint);
	setTableInt(L,"weaponModel",weapon->weaponModel);
	setTableFloat(L,"wiTrailTime",weapon->wiTrailTime);
	setTableInt(L,"weaponState",cg.predictedPlayerState.weaponstate);
	setTableInt(L,"weaponTime",cg.predictedPlayerState.weaponTime);
	if(item != NULL) {
		setTableInt(L,"item",item->id);
	} else {
		setTableInt(L,"item",0);
	}

	return 1;
}

int qlua_localpos(lua_State *L) {
	lua_pushvector(L,cg.predictedPlayerEntity.lerpOrigin);
	return 1;
}

int qlua_localang(lua_State *L) {
	lua_pushvector(L,cg.predictedPlayerEntity.lerpAngles);
	return 1;
}

int qlua_isUI(lua_State *L) {
	lua_pushboolean(L,trap_IsUI());
	return 1;
}

int qlua_barrelSpin(lua_State *L) {
	centity_t *cent = lua_toentity(L,1);

	lua_pushnumber(L,CG_MachinegunSpinAngle(cent));
	return 1;
}

int qlua_clearimage(lua_State *L) {
	const char *file;

	luaL_checktype(L,1,LUA_TSTRING);
	file = lua_tostring(L,1);

	if(file == NULL) {
		lua_pushstring(L,"ClearImage Failed, NULL STRING\n");
		lua_error(L);
		return 1;
	}

	trap_R_ClearImage(file);
	return 0;
}

int qlua_screenshot(lua_State *L) {
	float x,y,w,h;
	char *file;

	luaL_checktype(L,1,LUA_TNUMBER);
	luaL_checktype(L,2,LUA_TNUMBER);
	luaL_checktype(L,3,LUA_TNUMBER);
	luaL_checktype(L,4,LUA_TNUMBER);
	luaL_checktype(L,5,LUA_TSTRING);

	x = lua_tonumber(L,1);
	y = lua_tonumber(L,2);
	w = lua_tonumber(L,3);
	h = lua_tonumber(L,4);
	file = (char*) lua_tostring(L,5);

	if(w < 0) w = 0;
	if(h < 0) h = 0;

	CG_AdjustFrom640( &x, &y, &w, &h );

	if(file == NULL) {
		lua_pushstring(L,"Screenshot Failed, NULL STRING\n");
		lua_error(L);
		return 1;
	}

	trap_R_Screenshot((int)x,(int)y,(int)w,(int)h,file);
	return 0;
}

int qlua_cvar(lua_State *L) {
	luaL_checktype(L,1,LUA_TSTRING);
	luaL_checktype(L,2,LUA_TSTRING);

	trap_Cvar_Set(lua_tostring(L,1), lua_tostring(L,2));
	return 0;
}

int qlua_getscores(lua_State *L) {
	trap_SendClientCommand( "score" );
	return 0;
}

int qlua_getclientinfo2(lua_State *L) {
	int client = luaL_checkint(L,1);
	clientInfo_t *ci;
	if(client >= 0 && client <= MAX_CLIENTS) {
		ci = &cgs.clientinfo[ client ];
		if(ci != NULL) {
			CG_PushClientInfoTab(L,ci);
			return 1;
		}
	}
	return 0;
}

int qlua_pointcontents(lua_State *L) {
	vec3_t point;
	int pass = -1;
	int contents;

	//luaL_checkudata(L,1,"Vector");
	if(lua_type(L,1) != LUA_TUSERDATA) return 0;

	lua_tovector(L,1,point);

	if(lua_type(L,2) == LUA_TNUMBER) {
		pass = lua_tonumber(L,2);
	}
	contents = CG_PointContents(point,pass);

	lua_pushinteger(L,contents);
	return 1;
}

int qlua_enableCP(lua_State *L) {
	luaL_checktype(L,1,LUA_TBOOLEAN);

	CG_EnableObituaryCP(lua_toboolean(L,1));
	return 0;
}

int qlua_getviewheight(lua_State *L) {
	lua_pushinteger(L,cg.predictedPlayerState.viewheight);
	return 1;
}

int qlua_registerweapon(lua_State *L) {
	return 0;
}

int qlua_registeritem(lua_State *L) {
	return 0;
}

int qlua_updateitems(lua_State *L) {
	char		items[MAX_ITEMS+1];
	int i;
	strcpy( items, CG_ConfigString( CS_ITEMS) );

	for ( i = 1 ; i < bg_numItems ; i++ ) {
		if ( items[ i ] == '1' || cg_buildScript.integer ) {
			//CG_LoadingItem( i );
			CG_RegisterItemVisuals( i );
		}
	}
	return 0;
}

int qlua_loadingstring(lua_State *L) {
	luaL_checkstring(L,1);
	CG_LoadingString(lua_tostring(L,1));
	return 0;
}

int qlua_setweaponselect(lua_State *L) {
	int w = luaL_optinteger(L,1,cg.weaponSelect);
	cg.weaponSelect = w;
	cg.weaponSelectTime = cg.time;
	return 0;
}

static const luaL_reg Util_methods[] = {
  {"GetNumItems",		qlua_numitems},
  {"GetItemIcon",		qlua_getitemicon},
  {"GetItemModel",		qlua_getitemmodel},
  {"GetItemName",		qlua_getitemname},
  {"GetWeaponIcon",		qlua_getweaponicon},
  {"GetWeaponName",		qlua_getweaponname},
  {"LockMouse",			qlua_lockmouse},
  {"LoadSkin",			qlua_loadskin},
  {"CreateMark",		qlua_createmark},
  {"ClearMarks",		qlua_clearmarks},
  {"AnimatePlayer",		qlua_playeranim},
  {"AnglePlayer",		qlua_playerangles},
  {"PlayerWeapon",		qlua_playerweapon},
  {"Hand",				qlua_playerhand},
  {"WeaponInfo",		qlua_weaponinfo},
  {"ItemInfo",			qlua_itemInfo},
  {"BarrelAngle",		qlua_barrelSpin},
  {"LocalPos",			qlua_localpos},
  {"LocalAngles",		qlua_localang},
  {"CharData",			qlua_chardata},
  {"IsUI",				qlua_isUI},
  {"Screenshot",		qlua_screenshot},
  {"ClearImage",		qlua_clearimage},
  {"GetScores",			qlua_getscores},
  {"GetClientInfo",		qlua_getclientinfo2},
  {"GetPointContents",	qlua_pointcontents},
  {"SetCvar",			qlua_cvar},
  {"EnableCenterPrint",	qlua_enableCP},
  {"GetViewHeight",		qlua_getviewheight},
  {"RegisterWeapon",	qlua_registerweapon},
  {"RegisterItem",		qlua_registeritem},
  {"UpdateItems",		qlua_updateitems},
  {"LoadingString",		qlua_loadingstring},
  {"SetWeaponSelect",	qlua_setweaponselect},
  {0,0}
};

void CG_InitLuaUtil(lua_State *L) {
	luaL_openlib(L, "util", Util_methods, 0);
}