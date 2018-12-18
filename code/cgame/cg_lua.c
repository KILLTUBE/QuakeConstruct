#include <windows.h>
#include "cg_local.h"
#include "../lua-src/lfs.c"
#include "../lua-src/md5.c"

lua_State *L;

int samey = 0;
char *samey2 = "";
qboolean ready = qfalse;

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

int qlua_packRead(lua_State *L) {
	int			len;
	char		text[20000];
	const char	*filename;
	fileHandle_t	f;

	luaL_checktype(L,1,LUA_TSTRING);

	filename = lua_tostring(L,1);

	len = trap_FS_FOpenFile( filename, &f, FS_READ );
	if ( len <= 0 ) {
		//CG_Printf( "File %s was empty\n", filename );
		return 0;
	}
	if ( len >= sizeof( text ) - 1 ) {
		CG_Printf( "File %s too long\n", filename );
		return 0;
	}
	trap_FS_Read( text, len, f );
	text[len] = 0;
	trap_FS_FCloseFile( f );

	lua_pushstring(L,text);

	return 1;
}

int qlua_packList(lua_State *L) {
	int		numfiles;
	char	filelist[8192];
	char*	fileptr;
	int		i;
	int		filelen;
	const char *path = "";
	const char *ext = "";

	luaL_checkstring(L,1);
	luaL_checkstring(L,2);

	path = lua_tostring(L,1);
	ext = lua_tostring(L,2);

	lua_newtable(L);
	numfiles = trap_FS_GetFileList( path, ext, filelist, 8192 );
	fileptr  = filelist;
	for (i=0; i<numfiles; i++,fileptr+=filelen+1)
	{
		filelen = strlen(fileptr);

		lua_pushinteger(L, i);
		lua_pushstring(L, fileptr);
		lua_rawset(L, -3);
	}

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
			CG_Printf(msg);
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
		CG_Printf( "%s%s%s\n",S_COLOR_RED,"CL_LUA_ERROR: ",text );
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

	lua_pushboolean(L,0);
	lua_setglobal(L,"SERVER");
	lua_pushboolean(L,1);
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

int qlua_sendstring(lua_State *L) {
	const char *str = "";

	luaL_checkstring(L,1);
	str = lua_tostring(L,1);
	trap_SendClientCommand( va("luamsg %s",str) );

	return 0;
}

int qlua_concommand(lua_State *L) {
	const char *str = "";

	luaL_checkstring(L,1);
	str = lua_tostring(L,1);

	if(Q_stricmp(str,"luamsg") != 0) {
		//trap_SendClientCommand( str );
		trap_SendConsoleCommand( va("cmd %s \n", str) );
	} else {
		CG_Printf("^1Cannot Use This As A Console Command.\n");
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

int qlua_servertime (lua_State *L) {
	if(cg.snap != NULL && cg.snap->serverTime) {
		lua_pushinteger(L,cg.snap->serverTime);
	} else {
		lua_pushinteger(L,0);
	}
	return 1;
}

int qlimit(lua_State *L) {
	limited = qtrue;
	return 0;
}

int qprof_tabletest(lua_State *L) {
	int size = 0;
	int i = 0;
	int v = 0;

	luaL_checktype(L,1,LUA_TTABLE);
	size = luaL_getn(L,1);

	for(i=0;i<size;i++) {
		lua_pushinteger(L,i+1);
		lua_gettable(L,1);
		
		if(lua_type(L,lua_gettop(L)) == LUA_TNUMBER) {
			v = lua_tointeger(L,lua_gettop(L));
		}
	}

	lua_pushinteger(L,v);
	return 1;
}

int qprof_argtest(lua_State *L) {
	int size = 0;
	int i = 0;
	int v = 0;

	luaL_checktype(L,1,LUA_TNUMBER);
	size = lua_tointeger(L,1);

	for(i=0;i<size;i++) {
		if(lua_type(L,i) == LUA_TNUMBER) {
			v = lua_tointeger(L,i+2);
		}
	}

	lua_pushinteger(L,v);
	return 1;
}

int qprof_functest(lua_State *L) {
	int v = 0;

	luaL_checktype(L,1,LUA_TNUMBER);
	v = lua_tointeger(L,1);

	lua_pushinteger(L,v);

	return 1;
}

void CloseClientLua( void ) {
	if(L != NULL) {
		CG_CloseLuaView();
		ready = qfalse;
		qlua_gethook(L,"Shutdown");
		qlua_pcall(L,0,0,qtrue);
		lua_close(L);

		CG_Printf("----ClientSide Lua ShutDown-----!\n");

		L = NULL;
	}
}

int replay(lua_State *L) {
	playReplay();
	return 0;
}

int qclose(lua_State *L) {
	CloseClientLua();
	return 0;
}

int qsetprimed(lua_State *L) {
	trap_N_SetPrimed();
	return 0;
}

void SetGlobal(const char *n, int v) {
	lua_pushinteger(L,v);
	lua_setglobal(L,n);
}

void InitClientLua( int restart ) {
	CloseClientLua();
	L = lua_open();

	CG_Printf("-----Initializing ClientSide Lua-----\n");

	SetGlobal("ENTITYNUM_NONE",ENTITYNUM_NONE);
	SetGlobal("ENTITYNUM_WORLD",ENTITYNUM_WORLD);
	
	SetGlobal("MASK_ALL",MASK_ALL);
	SetGlobal("MASK_SOLID",MASK_SOLID);
	SetGlobal("MASK_PLAYERSOLID",MASK_PLAYERSOLID);
	SetGlobal("MASK_DEADSOLID",MASK_DEADSOLID);
	SetGlobal("MASK_WATER",MASK_WATER);
	SetGlobal("MASK_OPAQUE",MASK_OPAQUE);
	SetGlobal("MASK_SHOT",MASK_SHOT);
	SetGlobal("LOCALENT_DT",0);

	lua_pushboolean(L,0);
	lua_setglobal(L,"SERVER");
	lua_pushboolean(L,1);
	lua_setglobal(L,"CLIENT");
	lua_pushboolean(L,restart);
	lua_setglobal(L,"RESTARTED");

	luaL_openlibs(L);
	luaopen_lfs(L);

	lua_register(L,"ticks",qlua_ticks);
	lua_register(L,"ticksPerSecond",qlua_ticksPerSecond);

	lua_register(L,"packList",qlua_packList);
	lua_register(L,"packRead",qlua_packRead);
	lua_register(L,"print",message);
	lua_register(L,"bitAnd",bitwiseAnd);
	lua_register(L,"bitOr",bitwiseOr);
	lua_register(L,"bitXor",bitwiseXor);
	lua_register(L,"bitShift",bitwiseShift);
	lua_register(L,"include",qlua_includefile);
	lua_register(L,"runString",qlua_runstr);
	lua_register(L,"SendString",qlua_sendstring);
	lua_register(L,"ConsoleCommand",qlua_concommand);
	lua_register(L,"MD5",qlua_md5);
	lua_register(L,"ServerTime",qlua_servertime);
	lua_register(L,"_qlimit",qlimit);
	lua_register(L,"_profTable",qprof_tabletest);
	lua_register(L,"_profArgs",qprof_argtest);
	lua_register(L,"_profFunc",qprof_functest);
	lua_register(L,"startReplay",replay);
	lua_register(L,"_setprimed",qsetprimed);

	CG_Printf("----------------Done-----------------\n");
	ready = qtrue;
}

void DoLuaInit( void ) {
	//C:/Quake3/luamod_src/code/debug
	//if(luaL_loadfile(L,"lua/init.lua") || lua_pcall(L, 0, 0, 0)) {
    //    error(L, lua_tostring(L, -1));
	//}
	if(!FS_doScript("lua/cl_init.lua")) {
		error(L, lua_tostring(L, -1));
	}
}

void DoLuaIncludes( void ) {
	limited = qfalse;
	//C:/Quake3/luamod_src/code/debug
	//if(luaL_loadfile(L,"lua/includes/init.lua") || lua_pcall(L, 0, 0, 0)) {
    //    error(L, lua_tostring(L, -1));
	//}

	if(cg_compiled.integer) {
		lua_pushboolean(L,1);
		lua_setglobal(L,"COMPILED");

		if(!FS_doScript("lua/includes/compiled/cl_init.luc")) {
			error(L, lua_tostring(L, -1));
		}
	} else {
		if(!FS_doScript("lua/includes/cl_init.lua")) {
			error(L, lua_tostring(L, -1));
		}
	}
}

lua_State *GetClientLuaState( void ) {
	if(ready == qfalse) return NULL;
	return L;
}