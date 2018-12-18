#include <windows.h>
#include "g_local.h"
#include "../lua-src/lfs.c"
#include "../lua-src/md5.c"

lua_State *L;

int samey = 0;
char *samey2 = "";

qboolean limited = qfalse;

int qlua_ticks(lua_State *L) {
	LARGE_INTEGER tick;   // A point in time

	// what time is it?
	QueryPerformanceCounter(&tick);

	lua_pushnumber(L,tick.QuadPart);
	return 1;
}

int qlua_ticksPerSecond(lua_State *L) {
	LARGE_INTEGER ticksPerSecond;

	// get the high resolution counter's accuracy
	QueryPerformanceFrequency(&ticksPerSecond);

	lua_pushnumber(L,ticksPerSecond.QuadPart);
	return 1;
}

void qlua_clearfunc(lua_State *L, int ref) {
	if(ref != 0) {
		lua_unref(L,ref);
	}
}

int qlua_storefunc(lua_State *L, int i, int ref) {
	if(lua_type(L,i) == LUA_TFUNCTION || lua_type(L,i) == LUA_TTABLE) {
		if(ref != 0) lua_unref(L,ref);
		ref = luaL_ref(L, LUA_REGISTRYINDEX);
	}
	return ref;
}

int qlua_storefunconce(lua_State *L, int i, int ref) {
	if(lua_type(L,i) == LUA_TFUNCTION || lua_type(L,i) == LUA_TTABLE) {
		if(ref == 0) {
			G_Printf("Ref Complete\n");
			ref = luaL_ref(L, LUA_REGISTRYINDEX);
		} else {
			G_Printf("Already Stored In Lua\n");
		}
	}
	return ref;
}

qboolean qlua_getstored(lua_State *L, int ref) {
	if(ref != 0) {
		lua_rawgeti(L, LUA_REGISTRYINDEX, ref);
		return qtrue;
	}
	return qfalse;
}

int message(lua_State *L) {
	const char *msg = "";

	if(lua_gettop(L) > 0) {
		msg = lua_tostring(L,1);
		if(msg) {
			G_Printf(msg);
		}
	}
	return 0;
}

int messageAllPlayers(lua_State *L) {
	const char *msg = "";
	qboolean center = 0;

	if(lua_gettop(L) > 0) {
		msg = lua_tostring(L,1);
		center = lua_toboolean(L,2);
		if(msg) {
			if(!center) {
				trap_SendServerCommand( -1, va("print \"%s\"", msg) );
			} else {
				trap_SendServerCommand( -1, va("cp \"%s\"",msg) );
			}
		}
	}
	return 0;
}

int bitwiseAnd(lua_State *L) {
	int a,b;
	if(lua_gettop(L) == 2) {
		a = lua_tointeger(L,1);
		b = lua_tointeger(L,2);
		lua_pushinteger(L,a & b);
		return 1;
	}
	return 0;
}

int bitwiseOr(lua_State *L) {
	int a,b;
	if(lua_gettop(L) == 2) {
		a = lua_tointeger(L,1);
		b = lua_tointeger(L,2);
		lua_pushinteger(L,a | b);
		return 1;
	}
	return 0;
}

int bitwiseShift(lua_State *L) {
	int a,b;
	if(lua_gettop(L) == 2) {
		a = lua_tointeger(L,1);
		b = lua_tointeger(L,2);
		if(b > 0) {
			lua_pushinteger(L,a >> b);
		} else if(b < 0) {
			b = -b;
			lua_pushinteger(L,a << b);
		} else {
			lua_pushinteger(L,a);
		}
		return 1;
	}
	return 0;
}

int bitwiseXor(lua_State *L) {
	int a,b;
	if(lua_gettop(L) == 2) {
		a = lua_tointeger(L,1);
		b = lua_tointeger(L,2);
		lua_pushinteger(L,a ^ b);
		return 1;
	}
	return 0;
}

void error (lua_State *L, const char *fmt, ...) {
	va_list		argptr;
	char		text[4096];

	va_start (argptr, fmt);
	vsprintf (text, fmt, argptr);
	va_end (argptr);

	if(samey2 == text) {
		samey++;
	} else {
		samey2 = text;
		samey = 0;
	}

	if(samey < 3) {
		G_Printf( "%s%s%s\n",S_COLOR_RED,"SV_LUA_ERROR: ",text );
	}
}

void qlua_gethook(lua_State *L, const char *hook) {
	if(hook != NULL) {
		lua_getglobal(L, "CallHook");
		lua_pushstring(L, hook);
	}
}

void qlua_pcall(lua_State *L, int nargs, int nresults, qboolean washook) {
	if(washook) nargs++;
	if(lua_pcall(L,nargs,nresults,0) != 0) 
		error(L, lua_tostring(L, -1));
}

int qlua_runstr(lua_State *L) {
	const char *str = "";

	if(lua_gettop(L) > 0) {
		if(lua_type(L,1) == LUA_TSTRING) {
			str = lua_tostring(L,1);

			if(luaL_loadstring(L,str) || lua_pcall(L, 0, 0, 0)) {
				lua_error(L);
				return 1;
			}
		}
	}
	return 0;
}

qboolean FS_doScript( const char *filename ) {
	if(limited) return qtrue;

	qlua_gethook(L,"PreScriptLoaded");
	lua_pushstring(L,filename);
	qlua_pcall(L,1,1,qtrue);
	if(lua_isboolean(L,-1) && lua_toboolean(L,-1) == qtrue) {
		qlua_gethook(L,"ScriptLoadError");
		lua_pushstring(L,filename);
		lua_pushstring(L,"Blocked");
		qlua_pcall(L,2,0,qtrue);
		return qfalse;
	}

	if(luaL_loadfile(L,filename) || lua_pcall(L, 0, 0, 0)) {
		qlua_gethook(L,"ScriptLoadError");
		lua_pushstring(L,filename);
		lua_pushstring(L,lua_tostring(L,-1));
		qlua_pcall(L,2,0,qtrue);
		return qfalse;
	}

	qlua_gethook(L,"ScriptLoaded");
	lua_pushstring(L,filename);
	qlua_pcall(L,1,0,qtrue);
	/*char		text[20000];
	fileHandle_t	f;
	int			len;

	

	len = trap_FS_FOpenFile( filename, &f, FS_READ );
	if ( len <= 0 ) {
		G_Printf( "^1Unable to find file %s.\n", filename );
		return qfalse;
	}
	if ( len >= sizeof( text ) - 1 ) {
		G_Printf( "^1File %s is too long.\n", filename );
		return qfalse;
	}
	trap_FS_Read( text, len, f );
	text[len] = 0;
	trap_FS_FCloseFile( f );

	if(luaL_loadstring(L,text) || lua_pcall(L, 0, 0, 0)) {
        error(L, lua_tostring(L, -1));
	}*/

	return qtrue;
}

int qlua_includefile(lua_State *L) {
	const char *filename = "";

	luaL_checktype(L,1,LUA_TSTRING);

	lua_pushboolean(L,1);
	lua_setglobal(L,"SERVER");
	lua_pushboolean(L,0);
	lua_setglobal(L,"CLIENT");

	if(lua_gettop(L) > 0) {
		filename = lua_tostring(L,1);

		if(!FS_doScript(filename)) {
			lua_error(L);
			return 1;
		}
	}
	return 0;
}

/*
int qlua_md5(lua_State *L) {
	char *out = "";
	const char *in = "";
	int size = 16;

	luaL_checkstring(L,1);
	in = lua_tostring(L,1);

	if(lua_type(L,2) == LUA_TNUMBER) {
		size = lua_tointeger(L,2);
		if(size < 16) size = 16;
	}
	
	md5(in,size,out);

	lua_pushstring(L,out);
	return 1;
}*/

int qlua_md5 (lua_State *L) {
  char buff[16];
  size_t l;
  const char *message = luaL_checklstring(L, 1, &l);
  md5(message, l, buff);
  lua_pushlstring(L, buff, 16L);
  return 1;
}

int qlua_getcvar(lua_State *L) {
	const char *name = "";
	char output[MAX_STRING_CHARS];

	luaL_checkstring(L,1);
	name = lua_tostring(L,1);

	trap_Cvar_VariableStringBuffer(name,output,sizeof(output));
	
	lua_pushstring(L,output);
	lua_pushinteger(L,trap_Cvar_VariableIntegerValue( name ));

	return 2;
}

int qlua_setcvar(lua_State *L) {
	const char *name = "";
	const char *value = "";

	luaL_checkstring(L,1);
	name = lua_tostring(L,1);

	luaL_checkstring(L,2);
	value = lua_tostring(L,2);

	trap_Cvar_Set( name, value );
	return 0;
}

int SendTest(lua_State *L) {
	msg_t msg;

	luaL_checkint(L,1);

	trap_N_CreateMessage(&msg, 0);
	trap_N_WriteLong(&msg,lua_tointeger(L,1));
	trap_N_SendMessage(&msg, 0);
	
	return 0;
}

int qlimit(lua_State *L) {
	limited = qtrue;
	return 0;
}

void CloseServerLua( void ) {
	if(L != NULL) {
		qlua_gethook(L,"Shutdown");
		qlua_pcall(L,0,0,qtrue);
		lua_close(L);

		G_Printf("----ServerSide Lua ShutDown-----!\n");

		L = NULL;
	}
}

int qclose(lua_State *L) {
	CloseServerLua();
	return 0;
}

void SetGlobal(const char *n, int v) {
	lua_pushinteger(L,v);
	lua_setglobal(L,n);
}

void InitServerLua( int restart ) {
	CloseServerLua();
	L = lua_open();

	G_Printf("-----Initializing ServerSide Lua-----\n");

	SetGlobal("ENTITYNUM_NONE",ENTITYNUM_NONE);
	SetGlobal("ENTITYNUM_WORLD",ENTITYNUM_WORLD);
	
	SetGlobal("MASK_ALL",MASK_ALL);
	SetGlobal("MASK_SOLID",MASK_SOLID);
	SetGlobal("MASK_PLAYERSOLID",MASK_PLAYERSOLID);
	SetGlobal("MASK_DEADSOLID",MASK_DEADSOLID);
	SetGlobal("MASK_WATER",MASK_WATER);
	SetGlobal("MASK_OPAQUE",MASK_OPAQUE);
	SetGlobal("MASK_SHOT",MASK_SHOT);

	lua_pushboolean(L,1);
	lua_setglobal(L,"SERVER");
	lua_pushboolean(L,0);
	lua_setglobal(L,"CLIENT");
	lua_pushboolean(L,restart);
	lua_setglobal(L,"RESTARTED");

	luaL_openlibs(L);
	luaopen_lfs(L);

	lua_register(L,"ticks",qlua_ticks);
	lua_register(L,"ticksPerSecond",qlua_ticksPerSecond);

	lua_register(L,"print",message);
	lua_register(L,"sendToAll",messageAllPlayers);
	lua_register(L,"bitAnd",bitwiseAnd);
	lua_register(L,"bitOr",bitwiseOr);
	lua_register(L,"bitXor",bitwiseXor);
	lua_register(L,"bitShift",bitwiseShift);
	lua_register(L,"include",qlua_includefile);
	lua_register(L,"runString",qlua_runstr);
	lua_register(L,"MD5",qlua_md5);
	lua_register(L,"SendTest",SendTest);
	lua_register(L,"GetCvar",qlua_getcvar);
	lua_register(L,"SetCvar",qlua_setcvar);
	lua_register(L,"_qlimit",qlimit);

	/*G_Printf("CONTENTS_AREAPORTAL = %i\n",CONTENTS_AREAPORTAL);
	G_Printf("CONTENTS_BODY = %i\n",CONTENTS_BODY);
	G_Printf("CONTENTS_BOTCLIP = %i\n",CONTENTS_BOTCLIP);
	G_Printf("CONTENTS_CLUSTERPORTAL = %i\n",CONTENTS_CLUSTERPORTAL);
	G_Printf("CONTENTS_CORPSE = %i\n",CONTENTS_CORPSE);
	G_Printf("CONTENTS_DETAIL = %i\n",CONTENTS_DETAIL);
	G_Printf("CONTENTS_DONOTENTER = %i\n",CONTENTS_DONOTENTER);
	G_Printf("CONTENTS_FOG = %i\n",CONTENTS_FOG);
	G_Printf("CONTENTS_JUMPPAD = %i\n",CONTENTS_JUMPPAD);
	G_Printf("CONTENTS_LAVA = %i\n",CONTENTS_LAVA);
	G_Printf("CONTENTS_MONSTERCLIP = %i\n",CONTENTS_MONSTERCLIP);
	G_Printf("CONTENTS_MOVER = %i\n",CONTENTS_MOVER);
	G_Printf("CONTENTS_NOBOTCLIP = %i\n",CONTENTS_NOBOTCLIP);
	G_Printf("CONTENTS_NODE = %i\n",CONTENTS_NODE);
	G_Printf("CONTENTS_NODROP = %i\n",CONTENTS_NODROP);
	G_Printf("CONTENTS_NOTTEAM1 = %i\n",CONTENTS_NOTTEAM1);
	G_Printf("CONTENTS_NOTTEAM2 = %i\n",CONTENTS_NOTTEAM2);
	G_Printf("CONTENTS_ORIGIN = %i\n",CONTENTS_ORIGIN);
	G_Printf("CONTENTS_PLAYERCLIP = %i\n",CONTENTS_PLAYERCLIP);
	G_Printf("CONTENTS_SLIME = %i\n",CONTENTS_SLIME);
	G_Printf("CONTENTS_SOLID = %i\n",CONTENTS_SOLID);
	G_Printf("CONTENTS_STRUCTURAL = %i\n",CONTENTS_STRUCTURAL);
	G_Printf("CONTENTS_TELEPORTER = %i\n",CONTENTS_TELEPORTER);
	G_Printf("CONTENTS_TRANSLUCENT = %i\n",CONTENTS_TRANSLUCENT);
	G_Printf("CONTENTS_TRIGGER = %i\n",CONTENTS_TRIGGER);
	G_Printf("CONTENTS_WATER = %i\n",CONTENTS_WATER);*/

	//G_Printf("----------------Done-----------------\n");
}

void DoLuaInit( void ) {
	//C:/Quake3/luamod_src/code/debug
	//if(luaL_loadfile(L,"lua/init.lua") || lua_pcall(L, 0, 0, 0)) {
    //    error(L, lua_tostring(L, -1));
	//}
	if(!FS_doScript("lua/init.lua")) {
		error(L, lua_tostring(L, -1));
	}
}

void DoLuaIncludes( void ) {
	limited = qfalse;
	//C:/Quake3/luamod_src/code/debug
	//if(luaL_loadfile(L,"lua/includes/init.lua") || lua_pcall(L, 0, 0, 0)) {
    //    error(L, lua_tostring(L, -1));
	//}

	if(g_compiled.integer) {
		lua_pushboolean(L,1);
		lua_setglobal(L,"COMPILED");

		if(!FS_doScript("lua/includes/compiled/init.luc")) {
			error(L, lua_tostring(L, -1));
		}
	} else {
		if(!FS_doScript("lua/includes/init.lua")) {
			error(L, lua_tostring(L, -1));
		}
	}
}

lua_State *GetServerLuaState( void ) {
	return L;
}