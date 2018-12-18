#include "cg_gui.h"

void lua_pushpanel(lua_State *L, panel_t *panel) {
	panel_t *userdata = (panel_t*) lua_newuserdata(L, sizeof(panel_t));
	*userdata = *panel;

	luaL_getmetatable(L, "Panel");
	lua_setmetatable(L, -2);
}

panel_t *lua_topanel(lua_State *L, int i) {
	panel_t	*luapanel;
	luaL_checktype(L,i,LUA_TUSERDATA);
	luapanel = (panel_t *)luaL_checkudata(L, i, "Panel");
	if (luapanel == NULL) luaL_typerror(L, i, "Panel");

	if (luapanel->parent != NULL) {
		luapanel = luapanel->parent->children[luapanel->depth];
	}
	if (luapanel != NULL && luapanel->removed != qtrue) {
		return luapanel;
	} else {
		luaL_typerror(L, i, "Panel");
		return NULL;
	}
}

static int Panel_remove(lua_State *L) {
	panel_t *panel = lua_topanel(L,1);

	if(panel != NULL && strcmp(panel->classname,"base") && !panel->noGC) {
		//UI_RemovePanel(panel);
		CG_Printf("Remove Panel: %s[%i]\n", panel->classname, panel->persistantID);
	}

	return 0;
}

static int Panel_tostring (lua_State *L)
{
  lua_pushfstring(L, "Panel: %p", lua_touserdata(L, 1));
  return 1;
}

static int Panel_equal (lua_State *L)
{
	panel_t *p1 = lua_topanel(L,1);
	panel_t *p2 = lua_topanel(L,2);
	if(p1 != NULL && p2 != NULL) {
		lua_pushboolean(L, (p1->persistantID == p2->persistantID));
	} else {
		lua_pushboolean(L, 0);
	}
  return 1;
}

int	pget_localpos(lua_State *L) {
	panel_t *panel = lua_topanel(L,1);
	vec3_t pos;

	if(panel != NULL) {
		UI_GetLocalPosition(panel,pos);

		lua_pushnumber(L,pos[0]);
		lua_pushnumber(L,pos[1]);

		return 2;
	}
	return 0;
}

int	pget_pos(lua_State *L) {
	panel_t *panel = lua_topanel(L,1);

	if(panel != NULL) {
		lua_pushnumber(L,panel->x);
		lua_pushnumber(L,panel->y);

		return 2;
	}
	return 0;
}

int	pset_pos(lua_State *L) {
	panel_t *panel = lua_topanel(L,1);

	luaL_checktype(L,2,LUA_TNUMBER);
	luaL_checktype(L,3,LUA_TNUMBER);

	if(panel != NULL) {
		if(!strcmp(panel->classname,"base")) return 0;
		panel->x = lua_tonumber(L,2);
		panel->y = lua_tonumber(L,3);
	}

	return 0;
}

int	pget_size(lua_State *L) {
	panel_t *panel = lua_topanel(L,1);

	if(panel != NULL) {
		lua_pushnumber(L,panel->w);
		lua_pushnumber(L,panel->h);
		return 2;
	}
	return 0;
}

int	pset_size(lua_State *L) {
	panel_t *panel = lua_topanel(L,1);

	luaL_checktype(L,2,LUA_TNUMBER);
	luaL_checktype(L,3,LUA_TNUMBER);

	if(panel != NULL) {
		if(!strcmp(panel->classname,"base")) return 0;
		panel->w = lua_tonumber(L,2);
		panel->h = lua_tonumber(L,3);
	}

	//CG_Printf("Set Size To: %f, %f\n",panel->w,panel->h);

	return 0;
}

int pget_fgcolor(lua_State *L) {
	panel_t *panel = lua_topanel(L,1);
	if(panel != NULL) {
		qlua_pushColor(L,panel->fgcolor);
		return 4;
	}
	return 0;
}

int pset_fgcolor(lua_State *L) {
	panel_t *panel = lua_topanel(L,1);
	if(panel != NULL) {
		if(!strcmp(panel->classname,"base")) return 0;
		qlua_toColor(L,2,panel->fgcolor,qfalse);
	}
	return 0;
}

int pget_bgcolor(lua_State *L) {
	panel_t *panel = lua_topanel(L,1);
	if(panel != NULL) {
		qlua_pushColor(L,panel->bgcolor);
		return 4;
	}
	return 0;
}

int pset_bgcolor(lua_State *L) {
	panel_t *panel = lua_topanel(L,1);
	if(panel != NULL) {
		if(!strcmp(panel->classname,"base")) return 0;
		qlua_toColor(L,2,panel->bgcolor,qfalse);
	}
	return 0;
}

int pget_parent(lua_State *L) {
	panel_t *panel = lua_topanel(L,1);

	if(panel != NULL && panel->parent != NULL) {
		lua_pushpanel(L,panel->parent);
		return 1;
	}

	return 0;
}

int pget_children(lua_State *L) {
	panel_t *panel = lua_topanel(L,1);
	int i;
	int i2 = 0;

	lua_newtable(L);
	if(panel != NULL && panel->num_panels > 0) {
		for(i=0;i<panel->num_panels;i++) {
			if(panel->children[i] != NULL) {
				lua_pushinteger(L,++i2);
				lua_pushpanel(L,panel->children[i]);
				lua_rawset(L,-3);
			}
		}
	}

	return 1;
}


int pget_index(lua_State *L) {
	panel_t *panel = lua_topanel(L,1);

	if(panel != NULL) {
		lua_pushinteger(L,panel->persistantID);
		return 1;
	}

	return 0;
}

int pget_depth(lua_State *L) {
	panel_t *panel = lua_topanel(L,1);

	if(panel != NULL) {
		lua_pushinteger(L,panel->depth);
		return 1;
	}

	return 0;
}

int pget_classname(lua_State *L) {
	panel_t *panel = lua_topanel(L,1);

	if(panel != NULL && panel->classname != NULL) {
		lua_pushstring(L,panel->classname);
		return 1;
	}

	return 0;
}

int pcmd_remove(lua_State *L) {
	panel_t *panel = lua_topanel(L,1);
	
	if(panel != NULL) {
		if(!strcmp(panel->classname,"base")) return 0;
		UI_RemovePanel(panel);
	}
	
	return 0;
}

int pmousedown(lua_State *L) {
	panel_t *panel = lua_topanel(L,1);

	if(panel != NULL) {
		lua_pushboolean(L,panel->mousedown);
		return 1;
	}
	return 0;
}

int pmouseover(lua_State *L) {
	panel_t *panel = lua_topanel(L,1);

	if(panel != NULL) {
		lua_pushboolean(L,panel->mouseover);
		return 1;
	}
	return 0;
}

int pset_visible(lua_State *L) {
	panel_t *panel = lua_topanel(L,1);

	if(panel != NULL && panel->parent != NULL) {
		panel->visible = lua_toboolean(L,2);
	}

	return 0;
}

int pisontop(lua_State *L) {
	panel_t *panel = lua_topanel(L,1);

	if(panel != NULL && panel->parent != NULL) {
		lua_pushboolean(L,((panel->parent->num_panels-1) == panel->depth));
		return 1;
	}

	return 0;
}

int pisvisible(lua_State *L) {
	panel_t *panel = lua_topanel(L,1);

	if(panel != NULL) {
		lua_pushboolean(L,panel->visible);
		return 1;
	}

	return 0;
}

int pfocus(lua_State *L) {
	panel_t *panel = lua_topanel(L,1);

	if(panel != NULL && panel->parent != NULL) {
		if(!strcmp(panel->classname,"base")) return 0;
		UI_FocusPanel(panel);
	}

	return 0;
}

static const luaL_reg Panel_methods[] = {
  {"GetRasterPos",	pget_localpos},
  {"GetPos",		pget_pos},
  {"SetPos",		pset_pos},
  {"GetSize",		pget_size},
  {"SetSize",		pset_size},
  {"GetFGColor",	pget_fgcolor},
  {"SetFGColor",	pset_fgcolor},
  {"GetBGColor",	pget_bgcolor},
  {"SetBGColor",	pset_bgcolor},
  {"GetParent",		pget_parent},
  {"GetChildren",	pget_children},
  {"SetVisible",	pset_visible},
  {"Index",			pget_index},
  {"Depth",			pget_depth},
  {"Classname",		pget_classname},
  {"Remove",		pcmd_remove},
  {"MouseDown",		pmousedown},
  {"MouseOver",		pmouseover},
  {"IsOnTop",		pisontop},
  {"IsVisible",		pisvisible},
  {"Focus",			pfocus},
  {0,0}
};

int Panel_index(lua_State *L) {
	panel_t	*panel = lua_topanel(L,1);
	const char *str = luaL_checkstring(L,2);
	int size = sizeof(Panel_methods) / sizeof(luaL_reg);
	int i;

	for(i=0; i<size; i++) {
		if(Panel_methods[i].name != NULL && Panel_methods[i].func != NULL) {
			if(!strcmp(Panel_methods[i].name,str)) {
				lua_pushcclosure(L,Panel_methods[i].func,1);
				return 1;
			}
		}
	}

	qlua_getstored(L,panel->lua_table);
	lua_pushstring(L,str);
	lua_gettable(L,-2);

	return 1;
}

int Panel_newindex(lua_State *L) {
	panel_t	*panel = lua_topanel(L,1);
	const char *str = luaL_checkstring(L,2);
	int size = sizeof(Panel_methods) / sizeof(luaL_reg);
	int i;

	for(i=0; i<size; i++) {
		if(Panel_methods[i].name != NULL && Panel_methods[i].func != NULL) {
			if(!strcmp(Panel_methods[i].name,str)) {
				CG_Printf("^1%s:%s Is Write-Protected!\n", panel->classname, str);
				return 0;
			}
		}
	}

	qlua_getstored(L,panel->lua_table);
	lua_pushstring(L, str);
	lua_pushvalue(L,3);
	lua_rawset(L, -3);

	return 0;
}

static const luaL_reg Panel_meta[] = {
  {"__tostring", Panel_tostring},
  {"__eq", Panel_equal},
  {"__index", Panel_index},
  {"__newindex", Panel_newindex},
  //{"__gc", Panel_remove}, -doesn't work right :(
  {0, 0}
};

int Panel_register (lua_State *L) {
	luaL_openlib(L, "Panel", Panel_methods, 0);

	luaL_newmetatable(L, "Panel");

	luaL_openlib(L, 0, Panel_meta, 0);
	/*lua_pushliteral(L, "__index");
	lua_pushvalue(L, -3);
	lua_rawset(L, -3);*/
	lua_pushliteral(L, "__metatable");
	lua_pushvalue(L, -3);
	lua_rawset(L, -3);

	lua_setglobal(L,"M_Panel");

	lua_pop(L, 1);
	return 1;
}