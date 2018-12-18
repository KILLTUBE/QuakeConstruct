#include "cg_local.h"

void lua_pushsfx(lua_State *L, sfxHandle_t *sfx) {
	lua_pushlightuserdata(L,sfx);
}

sfxHandle_t *lua_tosfx(lua_State *L, int i) {
	return lua_touserdata(L,i);
}

void CG_InitHandles(lua_State *L) {

}