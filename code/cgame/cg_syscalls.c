/*
===========================================================================
Copyright (C) 1999-2005 Id Software, Inc.

This file is part of Quake III Arena source code.

Quake III Arena source code is free software; you can redistribute it
and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of the License,
or (at your option) any later version.

Quake III Arena source code is distributed in the hope that it will be
useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Foobar; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
===========================================================================
*/
//
// cg_syscalls.c -- this file is only included when building a dll
// cg_syscalls.asm is included instead when building a qvm
#ifdef Q3_VM
#error "Do not use in VM build"
#endif

#include "cg_local.h"
vec4_t	lastcolor;

static int (QDECL *syscall)( int arg, ... ) = (int (QDECL *)( int, ...))-1;

void dllEntry( int (QDECL  *syscallptr)( int arg,... ) ) {
	syscall = syscallptr;
}


int PASSFLOAT( float x ) {
	float	floatTemp;
	floatTemp = x;
	return *(int *)&floatTemp;
}

void	trap_Print( const char *fmt ) {
	syscall( CG_PRINT, fmt );
}

void	trap_Error( const char *fmt ) {
	syscall( CG_ERROR, fmt );
}

int		trap_Milliseconds( void ) {
	return syscall( CG_MILLISECONDS ); 
}

void	trap_Cvar_Register( vmCvar_t *vmCvar, const char *varName, const char *defaultValue, int flags ) {
	syscall( CG_CVAR_REGISTER, vmCvar, varName, defaultValue, flags );
}

void	trap_Cvar_Update( vmCvar_t *vmCvar ) {
	syscall( CG_CVAR_UPDATE, vmCvar );
}

void	trap_Cvar_Set( const char *var_name, const char *value ) {
	syscall( CG_CVAR_SET, var_name, value );
}

void trap_Cvar_VariableStringBuffer( const char *var_name, char *buffer, int bufsize ) {
	syscall( CG_CVAR_VARIABLESTRINGBUFFER, var_name, buffer, bufsize );
}

int		trap_Argc( void ) {
	return syscall( CG_ARGC );
}

void	trap_Argv( int n, char *buffer, int bufferLength ) {
	syscall( CG_ARGV, n, buffer, bufferLength );
}

void	trap_Args( char *buffer, int bufferLength ) {
	syscall( CG_ARGS, buffer, bufferLength );
}

int		trap_FS_FOpenFile( const char *qpath, fileHandle_t *f, fsMode_t mode ) {
	return syscall( CG_FS_FOPENFILE, qpath, f, mode );
}

void	trap_FS_Read( void *buffer, int len, fileHandle_t f ) {
	syscall( CG_FS_READ, buffer, len, f );
}

void	trap_FS_Write( const void *buffer, int len, fileHandle_t f ) {
	syscall( CG_FS_WRITE, buffer, len, f );
}

int trap_FS_GetFileList(  const char *path, const char *extension, char *listbuf, int bufsize ) {
	return syscall( CG_FS_GETFILELIST, path, extension, listbuf, bufsize );
}

void	trap_FS_FCloseFile( fileHandle_t f ) {
	syscall( CG_FS_FCLOSEFILE, f );
}

int trap_FS_Seek( fileHandle_t f, long offset, int origin ) {
	return syscall( CG_FS_SEEK, f, offset, origin );
}

void	trap_SendConsoleCommand( const char *text ) {
	syscall( CG_SENDCONSOLECOMMAND, text );
}

void	trap_AddCommand( const char *cmdName ) {
	syscall( CG_ADDCOMMAND, cmdName );
}

void	trap_RemoveCommand( const char *cmdName ) {
	syscall( CG_REMOVECOMMAND, cmdName );
}

void	trap_SendClientCommand( const char *s ) {
	syscall( CG_SENDCLIENTCOMMAND, s );
}

void	trap_UpdateScreen( void ) {
	syscall( CG_UPDATESCREEN );
}

void	trap_CM_LoadMap( const char *mapname ) {
	syscall( CG_CM_LOADMAP, mapname );
}

int		trap_CM_NumInlineModels( void ) {
	return syscall( CG_CM_NUMINLINEMODELS );
}

clipHandle_t trap_CM_InlineModel( int index ) {
	return syscall( CG_CM_INLINEMODEL, index );
}

clipHandle_t trap_CM_TempBoxModel( const vec3_t mins, const vec3_t maxs ) {
	return syscall( CG_CM_TEMPBOXMODEL, mins, maxs );
}

clipHandle_t trap_CM_TempCapsuleModel( const vec3_t mins, const vec3_t maxs ) {
	return syscall( CG_CM_TEMPCAPSULEMODEL, mins, maxs );
}

int		trap_CM_PointContents( const vec3_t p, clipHandle_t model ) {
	return syscall( CG_CM_POINTCONTENTS, p, model );
}

int		trap_CM_TransformedPointContents( const vec3_t p, clipHandle_t model, const vec3_t origin, const vec3_t angles ) {
	return syscall( CG_CM_TRANSFORMEDPOINTCONTENTS, p, model, origin, angles );
}

void	trap_CM_BoxTrace( trace_t *results, const vec3_t start, const vec3_t end,
						  const vec3_t mins, const vec3_t maxs,
						  clipHandle_t model, int brushmask ) {
	syscall( CG_CM_BOXTRACE, results, start, end, mins, maxs, model, brushmask );
}

void	trap_CM_CapsuleTrace( trace_t *results, const vec3_t start, const vec3_t end,
						  const vec3_t mins, const vec3_t maxs,
						  clipHandle_t model, int brushmask ) {
	syscall( CG_CM_CAPSULETRACE, results, start, end, mins, maxs, model, brushmask );
}

void	trap_CM_TransformedBoxTrace( trace_t *results, const vec3_t start, const vec3_t end,
						  const vec3_t mins, const vec3_t maxs,
						  clipHandle_t model, int brushmask,
						  const vec3_t origin, const vec3_t angles ) {
	syscall( CG_CM_TRANSFORMEDBOXTRACE, results, start, end, mins, maxs, model, brushmask, origin, angles );
}

void	trap_CM_TransformedCapsuleTrace( trace_t *results, const vec3_t start, const vec3_t end,
						  const vec3_t mins, const vec3_t maxs,
						  clipHandle_t model, int brushmask,
						  const vec3_t origin, const vec3_t angles ) {
	syscall( CG_CM_TRANSFORMEDCAPSULETRACE, results, start, end, mins, maxs, model, brushmask, origin, angles );
}

int		trap_CM_MarkFragments( int numPoints, const vec3_t *points, 
				const vec3_t projection,
				int maxPoints, vec3_t pointBuffer,
				int maxFragments, markFragment_t *fragmentBuffer ) {
	return syscall( CG_CM_MARKFRAGMENTS, numPoints, points, projection, maxPoints, pointBuffer, maxFragments, fragmentBuffer );
}

void	trap_S_StartSound( vec3_t origin, int entityNum, int entchannel, sfxHandle_t sfx ) {
	lua_State *L = GetClientLuaState();
	if(L != NULL && sfx != 0) {
		qlua_gethook(L,"AllowGameSound");
		lua_pushinteger(L,sfx);
		qlua_pcall(L,1,1,qtrue);
		if(lua_type(L,-1) == LUA_TBOOLEAN && lua_toboolean(L,-1) == qfalse) {
			lua_pop(L,1);
			return;
		}
	}
	syscall( CG_S_STARTSOUND, origin, entityNum, entchannel, sfx );
}

void	trap_S_StartSoundLua( vec3_t origin, int entityNum, int entchannel, sfxHandle_t sfx ) {
	syscall( CG_S_STARTSOUND, origin, entityNum, entchannel, sfx );
}

void	trap_S_StartLocalSound( sfxHandle_t sfx, int channelNum ) {
	syscall( CG_S_STARTLOCALSOUND, sfx, channelNum );
}

void	trap_S_ClearLoopingSounds( qboolean killall ) {
	syscall( CG_S_CLEARLOOPINGSOUNDS, killall );
}

void	trap_S_AddLoopingSound( int entityNum, const vec3_t origin, const vec3_t velocity, sfxHandle_t sfx ) {
	lua_State *L = GetClientLuaState();
	if(L != NULL && sfx != 0) {
		qlua_gethook(L,"AllowGameSound");
		lua_pushinteger(L,sfx);
		qlua_pcall(L,1,1,qtrue);
		if(lua_type(L,-1) == LUA_TBOOLEAN && lua_toboolean(L,-1) == qfalse) {
			lua_pop(L,1);
			return;
		}
	}
	syscall( CG_S_ADDLOOPINGSOUND, entityNum, origin, velocity, sfx );
}

void	trap_S_AddLoopingSoundLua( int entityNum, const vec3_t origin, const vec3_t velocity, sfxHandle_t sfx ) {
	syscall( CG_S_ADDREALLOOPINGSOUND, entityNum, origin, velocity, sfx );
}

void	trap_S_AddRealLoopingSound( int entityNum, const vec3_t origin, const vec3_t velocity, sfxHandle_t sfx ) {
	lua_State *L = GetClientLuaState();
	if(L != NULL && sfx != 0) {
		qlua_gethook(L,"AllowGameSound");
		lua_pushinteger(L,sfx);
		qlua_pcall(L,1,1,qtrue);
		if(lua_type(L,-1) == LUA_TBOOLEAN && lua_toboolean(L,-1) == qfalse) {
			lua_pop(L,1);
			return;
		}
	}
	syscall( CG_S_ADDREALLOOPINGSOUND, entityNum, origin, velocity, sfx );
}

void	trap_S_StopLoopingSound( int entityNum ) {
	syscall( CG_S_STOPLOOPINGSOUND, entityNum );
}

void	trap_S_UpdateEntityPosition( int entityNum, const vec3_t origin ) {
	syscall( CG_S_UPDATEENTITYPOSITION, entityNum, origin );
}

void	trap_S_Respatialize( int entityNum, const vec3_t origin, vec3_t axis[3], int inwater ) {
	syscall( CG_S_RESPATIALIZE, entityNum, origin, axis, inwater );
}

sfxHandle_t	trap_S_RegisterSound( const char *sample, qboolean compressed ) {
	int load = syscall( CG_S_REGISTERSOUND, sample, compressed );
	lua_State *L = GetClientLuaState();
	if(L != NULL) {
		qlua_gethook(L,"SoundLoaded");
		lua_pushstring(L,sample);
		lua_pushinteger(L,load);
		lua_pushboolean(L,compressed);
		qlua_pcall(L,3,0,qtrue);
	}
	return load;
}

void	trap_S_StartBackgroundTrack( const char *intro, const char *loop ) {
	syscall( CG_S_STARTBACKGROUNDTRACK, intro, loop );
}

void	trap_R_LoadWorldMap( const char *mapname ) {
	syscall( CG_R_LOADWORLDMAP, mapname );
}

void	trap_SetUserCommand( usercmd_t *cmd ) {
	syscall( CG_SET_USERCMD, cmd );
}

void	trap_EnableCommandOverride( qboolean b ) {
	syscall( CG_ENABLE_COMMAND_OVERRIDE, b );
}

void	trap_R_SetupRenderTarget( int index, int width, int height ) {
	syscall( CG_R_SETUPRT, index, width, height );
}

void	trap_R_GetPixel( int x, int y, int *r, int *g, int *b ) {
	syscall( CG_R_GETPIXEL, x, y, r, g, b );
}

void	trap_R_ToScreen( float *x, float *y, float *z, refdef_t ref ) {
	syscall( CG_R_TOSCREEN, x, y, z, &ref );
}

void	trap_AnglesToQuat( float *angles, float *quat ) {
	syscall( CG_ANGLES_TO_QUAT, angles, quat );
}

void	trap_QuatToAngles( float *quat, float *angles ) {
	syscall( CG_QUAT_TO_ANGLES, quat, angles );
}

qhandle_t trap_R_RegisterModel( const char *name ) {
	int load = syscall( CG_R_REGISTERMODEL, name );
	lua_State *L = GetClientLuaState();
	if(L != NULL) {
		qlua_gethook(L,"ModelLoaded");
		lua_pushstring(L,name);
		lua_pushinteger(L,load);
		qlua_pcall(L,2,0,qtrue);
	}
	return load;
}

qhandle_t trap_R_RegisterSkin( const char *name ) {
	return syscall( CG_R_REGISTERSKIN, name );
}

qhandle_t trap_R_RegisterShader( const char *name ) {
	int load = syscall( CG_R_REGISTERSHADER, name );
	lua_State *L = GetClientLuaState();
	if(L != NULL) {
		qlua_gethook(L,"ShaderLoaded");
		lua_pushstring(L,name);
		lua_pushinteger(L,load);
		lua_pushboolean(L,qfalse);
		qlua_pcall(L,3,0,qtrue);
	}
	return load;
}

qhandle_t trap_R_RegisterShaderNoMip( const char *name ) {
	int load = syscall( CG_R_REGISTERSHADERNOMIP, name );
	lua_State *L = GetClientLuaState();
	if(L != NULL) {
		qlua_gethook(L,"ShaderLoaded");
		lua_pushstring(L,name);
		lua_pushinteger(L,load);
		lua_pushboolean(L,qtrue);
		qlua_pcall(L,3,0,qtrue);
	}
	return load;
}

qhandle_t trap_R_CreateShader( const char *name, char *data ) {
	int load = syscall( CG_R_CREATESHADER, name, data );
	return load;
}

void trap_R_RegisterFont(const char *fontName, int pointSize, fontInfo_t *font) {
	syscall(CG_R_REGISTERFONT, fontName, pointSize, font );
}

void	trap_R_ClearScene( void ) {
	syscall( CG_R_CLEARSCENE );
}

void	trap_R_AddRefEntityToScene( const refEntity_t *e ) {
	//I'm going to intercept this at the client game level, until I fix it in the renderer.
	//-Hxrmn
	polyVert_t  temp[1024];
	vec3_t		tempAxis[3];
	int i=0;
	int v=0;

	if(e->reType == RT_POLY) {
		for ( i=0; i<e->numVerts; i++ ) {
			temp[i].modulate[0] = e->shaderRGBA[0];
			temp[i].modulate[1] = e->shaderRGBA[1];
			temp[i].modulate[2] = e->shaderRGBA[2];
			temp[i].modulate[3] = e->shaderRGBA[3];

			VectorClear(temp[i].xyz);

			for ( v=0; v<3; v++ ) {
				VectorScale(e->axis[v],e->verts[i].xyz[v],tempAxis[v]);
			}
			
			v=0;
			for ( v=0; v<3; v++ ) {
				VectorAdd(tempAxis[v],temp[i].xyz,temp[i].xyz);
			}
			VectorAdd(temp[i].xyz,e->origin,temp[i].xyz);

			temp[i].st[0] = e->verts[i].st[0];
			temp[i].st[1] = e->verts[i].st[1];
		}
		syscall( CG_R_ADDPOLYTOSCENE, e->customShader, e->numVerts, temp );
	} else {
		syscall( CG_R_ADDREFENTITYTOSCENE, e );
	}
}

void	trap_R_AddPolyToScene( qhandle_t hShader , int numVerts, const polyVert_t *verts ) {
	syscall( CG_R_ADDPOLYTOSCENE, hShader, numVerts, verts );
}

void	trap_R_AddPolysToScene( qhandle_t hShader , int numVerts, const polyVert_t *verts, int num ) {
	syscall( CG_R_ADDPOLYSTOSCENE, hShader, numVerts, verts, num );
}

int		trap_R_LightForPoint( vec3_t point, vec3_t ambientLight, vec3_t directedLight, vec3_t lightDir ) {
	return syscall( CG_R_LIGHTFORPOINT, point, ambientLight, directedLight, lightDir );
}

void	trap_R_AddLightToScene( const vec3_t org, float intensity, float r, float g, float b ) {
	syscall( CG_R_ADDLIGHTTOSCENE, org, PASSFLOAT(intensity), PASSFLOAT(r), PASSFLOAT(g), PASSFLOAT(b) );
}

void	trap_R_AddAdditiveLightToScene( const vec3_t org, float intensity, float r, float g, float b ) {
	syscall( CG_R_ADDADDITIVELIGHTTOSCENE, org, PASSFLOAT(intensity), PASSFLOAT(r), PASSFLOAT(g), PASSFLOAT(b) );
}

void	trap_R_RenderScene( const refdef_t *fd ) {
	syscall( CG_R_RENDERSCENE, fd );
}

void	trap_R_GetColor( vec4_t color ) {
	color[0] = lastcolor[0];
	color[1] = lastcolor[1];
	color[2] = lastcolor[2];
	color[3] = lastcolor[3];
}

void	trap_R_SetColor( const float *rgba ) {
	//int s, i;
	if(rgba != NULL) {
		/*s = sizeof(rgba) / sizeof(float);
		if(s < 4) CG_Printf("Odd Size %i\n",s);
		if(s > 4) s = 4;
		for(i=0; i<s; i++) {
			lastcolor[i] = rgba[i];
		}*/
		lastcolor[0] = rgba[0];
		lastcolor[1] = rgba[1];
		lastcolor[2] = rgba[2];
		lastcolor[3] = rgba[3];
	} else {
		lastcolor[0] = lastcolor[1] = lastcolor[2] = lastcolor[3] = 1;
	}
	syscall( CG_R_SETCOLOR, rgba );
}

void	trap_R_ForceRenderCommands() {
	syscall( CG_R_ForceRenderCommands );
}

void	trap_R_UpdateRenderTarget(int rt) {
	syscall( CG_R_UpdateRenderTarget, rt );
}

void	trap_R_DrawStretchPic( float x, float y, float w, float h, 
							   float s1, float t1, float s2, float t2, qhandle_t hShader ) {
	syscall( CG_R_DRAWSTRETCHPIC, PASSFLOAT(x), PASSFLOAT(y), PASSFLOAT(w), PASSFLOAT(h), PASSFLOAT(s1), PASSFLOAT(t1), PASSFLOAT(s2), PASSFLOAT(t2), hShader );
}

void	trap_R_DrawTransformPic( float x, float y, float w, float h, 
							   float s1, float t1, float s2, float t2, float r, qhandle_t hShader ) {
	syscall( CG_R_DRAWTRANSFORMPIC, PASSFLOAT(x), PASSFLOAT(y), PASSFLOAT(w), PASSFLOAT(h), PASSFLOAT(s1), PASSFLOAT(t1), PASSFLOAT(s2), PASSFLOAT(t2), PASSFLOAT(r), hShader );
}

void	trap_R_DrawQuadPic( float x0, float y0, float x1, float y1, float x2, float y2, float x3, float y3, 
						   float s1, float t1, float s2, float t2, qhandle_t hShader ) {
	syscall( CG_R_DRAWQUADPIC, PASSFLOAT(x0), PASSFLOAT(y0), PASSFLOAT(x1), PASSFLOAT(y1), PASSFLOAT(x2), PASSFLOAT(y2), PASSFLOAT(x3), PASSFLOAT(y3), PASSFLOAT(s1), PASSFLOAT(t1), PASSFLOAT(s2), PASSFLOAT(t2), hShader );
}

void	trap_R_ModelBounds( clipHandle_t model, vec3_t mins, vec3_t maxs ) {
	syscall( CG_R_MODELBOUNDS, model, mins, maxs );
}

int		trap_R_LerpTag( orientation_t *tag, clipHandle_t mod, int startFrame, int endFrame, 
					   float frac, const char *tagName ) {
	return syscall( CG_R_LERPTAG, tag, mod, startFrame, endFrame, PASSFLOAT(frac), tagName );
}

int		trap_R_LerpTriangle( clipHandle_t handle, int surfID, int id, refTri_t *tris, int startFrame, int endFrame, float frac ) {
	return syscall( CG_R_LERPTRIANGLE, handle, surfID, id, tris, startFrame, endFrame, PASSFLOAT(frac) );
}

void	trap_R_ModelInfo( clipHandle_t mod, md3Info_t *info ) {
	syscall( CG_R_MODELINFO, mod, info );
}



void	trap_R_RemapShader( const char *oldShader, const char *newShader, const char *timeOffset ) {
	syscall( CG_R_REMAP_SHADER, oldShader, newShader, timeOffset );
}

//Mask Functions
void	trap_R_BeginMask( float x, float y, float w, float h ) {
	syscall( CG_R_BEGINMASK, PASSFLOAT(x), PASSFLOAT(y), PASSFLOAT(w), PASSFLOAT(h) );
}

void	trap_R_EndMask( void ) {
	syscall( CG_R_ENDMASK );
}

//Coordinate Functions
void	trap_R_Begin2D( void ) {
	syscall( CG_R_BEGIN2D );
}

void	trap_R_End2D( void ) {
	syscall( CG_R_END2D );
}

void		trap_GetGlconfig( glconfig_t *glconfig ) {
	syscall( CG_GETGLCONFIG, glconfig );
}

void		trap_GetGameState( gameState_t *gamestate ) {
	syscall( CG_GETGAMESTATE, gamestate );
}

void		trap_GetCurrentSnapshotNumber( int *snapshotNumber, int *serverTime ) {
	syscall( CG_GETCURRENTSNAPSHOTNUMBER, snapshotNumber, serverTime );
}

qboolean	trap_GetSnapshot( int snapshotNumber, snapshot_t *snapshot ) {
	return syscall( CG_GETSNAPSHOT, snapshotNumber, snapshot );
}

qboolean	trap_GetServerCommand( int serverCommandNumber ) {
	return syscall( CG_GETSERVERCOMMAND, serverCommandNumber );
}

int			trap_GetCurrentCmdNumber( void ) {
	return syscall( CG_GETCURRENTCMDNUMBER );
}

qboolean	trap_GetUserCmd( int cmdNumber, usercmd_t *ucmd ) {
	return syscall( CG_GETUSERCMD, cmdNumber, ucmd );
}

void		trap_GetCurrentUserCommand(usercmd_t *ucmd) {
	syscall( CG_GETCURRENTUSERCMD, ucmd );
}

void		trap_SetUserCmdValue( int stateValue, float sensitivityScale ) {
	syscall( CG_SETUSERCMDVALUE, stateValue, PASSFLOAT(sensitivityScale) );
}

void		testPrintInt( char *string, int i ) {
	syscall( CG_TESTPRINTINT, string, i );
}

void		testPrintFloat( char *string, float f ) {
	syscall( CG_TESTPRINTFLOAT, string, PASSFLOAT(f) );
}

int trap_MemoryRemaining( void ) {
	return syscall( CG_MEMORY_REMAINING );
}

qboolean trap_Key_IsDown( int keynum ) {
	return syscall( CG_KEY_ISDOWN, keynum );
}

int trap_Key_GetCatcher( void ) {
	return syscall( CG_KEY_GETCATCHER );
}

void trap_Key_SetCatcher( int catcher ) {
	syscall( CG_KEY_SETCATCHER, catcher );
}

int trap_Key_GetKey( const char *binding ) {
	return syscall( CG_KEY_GETKEY, binding );
}

int trap_PC_AddGlobalDefine( char *define ) {
	return syscall( CG_PC_ADD_GLOBAL_DEFINE, define );
}

int trap_PC_LoadSource( const char *filename ) {
	return syscall( CG_PC_LOAD_SOURCE, filename );
}

int trap_PC_FreeSource( int handle ) {
	return syscall( CG_PC_FREE_SOURCE, handle );
}

int trap_PC_ReadToken( int handle, pc_token_t *pc_token ) {
	return syscall( CG_PC_READ_TOKEN, handle, pc_token );
}

int trap_PC_SourceFileAndLine( int handle, char *filename, int *line ) {
	return syscall( CG_PC_SOURCE_FILE_AND_LINE, handle, filename, line );
}

void	trap_S_StopBackgroundTrack( void ) {
	syscall( CG_S_STOPBACKGROUNDTRACK );
}

int trap_RealTime(qtime_t *qtime) {
	return syscall( CG_REAL_TIME, qtime );
}

void trap_SnapVector( float *v ) {
	syscall( CG_SNAPVECTOR, v );
}

// this returns a handle.  arg0 is the name in the format "idlogo.roq", set arg1 to NULL, alteredstates to qfalse (do not alter gamestate)
int trap_CIN_PlayCinematic( const char *arg0, int xpos, int ypos, int width, int height, int bits) {
  return syscall(CG_CIN_PLAYCINEMATIC, arg0, xpos, ypos, width, height, bits);
}
 
// stops playing the cinematic and ends it.  should always return FMV_EOF
// cinematics must be stopped in reverse order of when they are started
e_status trap_CIN_StopCinematic(int handle) {
  return syscall(CG_CIN_STOPCINEMATIC, handle);
}


// will run a frame of the cinematic but will not draw it.  Will return FMV_EOF if the end of the cinematic has been reached.
e_status trap_CIN_RunCinematic (int handle) {
  return syscall(CG_CIN_RUNCINEMATIC, handle);
}
 

// draws the current frame
void trap_CIN_DrawCinematic (int handle) {
  syscall(CG_CIN_DRAWCINEMATIC, handle);
}
 

// allows you to resize the animation dynamically
void trap_CIN_SetExtents (int handle, int x, int y, int w, int h) {
  syscall(CG_CIN_SETEXTENTS, handle, x, y, w, h);
}

/*
qboolean trap_loadCamera( const char *name ) {
	return syscall( CG_LOADCAMERA, name );
}

void trap_startCamera(int time) {
	syscall(CG_STARTCAMERA, time);
}

qboolean trap_getCameraInfo( int time, vec3_t *origin, vec3_t *angles) {
	return syscall( CG_GETCAMERAINFO, time, origin, angles );
}
*/

qboolean trap_GetEntityToken( char *buffer, int bufferSize ) {
	return syscall( CG_GET_ENTITY_TOKEN, buffer, bufferSize );
}

qboolean trap_R_inPVS( const vec3_t p1, const vec3_t p2 ) {
	return syscall( CG_R_INPVS, p1, p2 );
}

void trap_LockMouse( qboolean lock ) {
	syscall( CG_LOCKMOUSE, lock );
}

int trap_N_ReadByte() {
	return syscall( CG_N_READBYTE );
}

int trap_N_ReadShort() {
	return syscall( CG_N_READSHORT );
}

int trap_N_ReadLong() {
	return syscall( CG_N_READLONG );
}

char *trap_N_ReadString() {
	static char str[MAX_STRING_CHARS];
	//char * str = (char*)calloc(MAX_STRING_CHARS, sizeof(char));
	syscall( CG_N_READSTRING, str, MAX_STRING_CHARS * sizeof(char) );
	return str;
}

float trap_N_ReadFloat() {
	float f;
	syscall( CG_N_READFLOAT, &f );
	return f;
}

float trap_N_ReadBits(int n) {
	return syscall( CG_N_READBITS, n );
}

int	trap_IsUI() {
	return syscall(CG_ISUI);
}

void trap_R_Screenshot(int x, int y, int w, int h, char *file) {
	syscall(CG_SCREENSHOT, x, y, w, h, file);
}

void trap_R_ClearImage(const char *file) {
	syscall(CG_CLEARIMAGE, file);
}

qhandle_t trap_CM_GetPhysicsWorld() {
	return syscall(CG_CM_GETPHYSICSWORLD);
}

void trap_N_SetPrimed() {
	syscall(CG_SETPRIMED);
}