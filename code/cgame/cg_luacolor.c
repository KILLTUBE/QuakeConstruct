#include "cg_local.h"

void checkColor(vec4_t color, qboolean strict) {
	int i=0;
	for(i=0;i<4;i++) {
		if(!strict) {
			if(color[i] > 1) color[i] = color[i] / 255;
		}
		if(color[i] > 1) color[i] = 1;
		if(color[i] < 0) color[i] = 0;
	}
}

void qlua_toColor(lua_State *L, int idx, vec4_t color, qboolean strict) {
	int i=0;
	for(i=0;i<4;i++) {
		color[i] = luaL_optnumber(L,i+idx,0);
	}
	checkColor(color,strict);
}

void qlua_pushColor(lua_State *L, vec4_t color) {
	lua_pushnumber(L,color[0]);
	lua_pushnumber(L,color[1]);
	lua_pushnumber(L,color[2]);
	lua_pushnumber(L,color[3]);
}

void adjustColor(vec4_t color, float amt) {
	color[0] = (color[0] + amt);
	color[1] = (color[1] + amt);
	color[2] = (color[2] + amt);
	color[3] = color[3];
	
	checkColor(color,qtrue);
}