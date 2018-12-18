#include "cg_local.h"
#include "cg_2d3d.h"

qboolean		maskOn = qfalse;

static float	s_flipMatrix[16] = {
	// convert from our coordinate system (looking down X)
	// to OpenGL's coordinate system (looking down -Z)
	0, 0, -1, 0,
	-1, 0, 0, 0,
	0, 1, 0, 0,
	0, 0, 0, 1
};

int matrixPos(int r, int c) {
        return ((r*4)+1*c+1)-1;         
}

float mrowcol(int p, float *m1, float *m2) {
        int c = p % 4;
        int r = p / 4;
        float mv = 0;
        int i=0;
        for(i=0; i<4; i++) {
                int p1 = matrixPos(r,i);
                int p2 = matrixPos(i,c);
                mv += m1[p1] * m2[p2];
        }
        return mv;
}

void quickMultiply1x4by4x4(float *mat1, float *mat2, float *out) {
        int i,j;
        for(i=0; i<4; i++) {
                for(j=0; j<4; j++) {
                        int rc = (j*4) + i;
                        out[i] += mat1[j] * mat2[rc];
                }
        }       
}

void quickMultiply4x4(float *mat1, float *mat2, float *out) {
        int i;
        for(i=0; i<16; i++) {
                out[i] = mrowcol(i,mat1,mat2);
        }
}

int qlua_start3D(lua_State *L) {
	vec3_t origin,right,down,forward;

	VectorClear(forward);

	luaL_checktype(L,1,LUA_TVECTOR);
	luaL_checktype(L,2,LUA_TVECTOR);
	luaL_checktype(L,3,LUA_TVECTOR);

	lua_tovector(L,1,origin);
	lua_tovector(L,2,right);
	lua_tovector(L,3,down);
	
	if(lua_type(L,4) == LUA_TVECTOR) {
		lua_tovector(L,4,forward);
	}

	Start2D3D(origin,right,down,forward);

	return 0;
}

int qlua_end3D(lua_State *L) {
	End2D3D();
	return 0;
}

int qlua_get3DCoord(lua_State *L) {
	vec3_t v;
	luaL_checknumber(L,1);
	luaL_checknumber(L,2);

	RemapCoords(lua_tonumber(L,1),lua_tonumber(L,2),v,*GetCoordRemap());

	lua_pushvector(L,v);
	return 1;
}

int qlua_setcolor(lua_State *L) {
	vec4_t	color;
	
	VectorClear(color);

	qlua_toColor(L,1,color,qfalse);

	trap_R_SetColor(color);

	return 0;
}

int qlua_maskrect(lua_State *L) {
	float x,y,w,h;

	luaL_checktype(L,1,LUA_TNUMBER);
	luaL_checktype(L,2,LUA_TNUMBER);
	luaL_checktype(L,3,LUA_TNUMBER);
	luaL_checktype(L,4,LUA_TNUMBER);

	x = lua_tonumber(L,1);
	y = lua_tonumber(L,2);
	w = lua_tonumber(L,3);
	h = lua_tonumber(L,4);

	x *= cgs.screenXScale;
	y *= cgs.screenYScale;
	w *= cgs.screenXScale;
	h *= cgs.screenYScale;

	trap_R_BeginMask(x,y,w,h);
	maskOn = qtrue;
	return 0;
}

int qlua_endmask(lua_State *L) {
	trap_R_EndMask();
	maskOn = qfalse;
	return 0;
}

float quickfloat(lua_State *L, int i, float def) {
	if(lua_type(L,i) == LUA_TNUMBER) def = lua_tonumber(L,i);
	return def;
}

float pullfloat1(lua_State *L, int i, float def, int m) {
	float v = def;
	lua_pushinteger(L,i);
	lua_gettable(L,m);
	if(lua_type(L,lua_gettop(L)) == LUA_TNUMBER) {
		v = lua_tonumber(L,lua_gettop(L));
	}
	return v;
}

float pullint1(lua_State *L, int i, int def, int m) {
	int v = def;
	lua_pushinteger(L,i);
	lua_gettable(L,m);
	if(lua_type(L,lua_gettop(L)) == LUA_TNUMBER) {
		v = lua_tointeger(L,lua_gettop(L));
	}
	return v;
}

void adjustColor2(vec4_t color, float amt) {
	vec4_t color2;

	color2[0] = (color[0] + amt);
	color2[1] = (color[1] + amt);
	color2[2] = (color[2] + amt);
	color2[3] = color[3];
	
	checkColor(color2,qtrue);
	trap_R_SetColor(color2);
}

int qlua_beveledRect(lua_State *L) {
	float x,y,w,h,factor,inset;
	vec4_t	color;

	qhandle_t shader = cgs.media.whiteShader;

	luaL_checktype(L,1,LUA_TNUMBER);
	luaL_checktype(L,2,LUA_TNUMBER);
	luaL_checktype(L,3,LUA_TNUMBER);
	luaL_checktype(L,4,LUA_TNUMBER);
	
	luaL_checktype(L,5,LUA_TNUMBER);
	luaL_checktype(L,6,LUA_TNUMBER);
	luaL_checktype(L,7,LUA_TNUMBER);
	luaL_checktype(L,8,LUA_TNUMBER);
	luaL_checktype(L,9,LUA_TNUMBER);

	x = lua_tonumber(L,1);
	y = lua_tonumber(L,2);
	w = lua_tonumber(L,3);
	h = lua_tonumber(L,4);

	qlua_toColor(L,5,color,qfalse);

	factor = lua_tonumber(L,9);

	inset = 2;
	if(lua_type(L,10) == LUA_TNUMBER) {
		inset = lua_tonumber(L,10);
	}

	DrawRect( x, y, w, h, 0, 0, 1, 1, shader );

	adjustColor2(color,2*factor);
	DrawRect( x, y, w, inset, 0, 0, 1, 1, shader );

	adjustColor2(color,1*factor);
	DrawRect( x, y, inset, h, 0, 0, 1, 1, shader );

	adjustColor2(color,-1*factor);
	DrawRect( x+(w-inset), y, inset, h, 0, 0, 1, 1, shader );

	adjustColor2(color,-2*factor);
	DrawRect( x, y+(h-inset), w, inset, 0, 0, 1, 1, shader );
	return 0;
}


int qlua_rect(lua_State *L) {
	float x,y,w,h,s,t,s2,t2;

	qhandle_t shader = cgs.media.whiteShader;

	luaL_checktype(L,1,LUA_TNUMBER);
	luaL_checktype(L,2,LUA_TNUMBER);
	luaL_checktype(L,3,LUA_TNUMBER);
	luaL_checktype(L,4,LUA_TNUMBER);

	x = lua_tonumber(L,1);
	y = lua_tonumber(L,2);
	w = lua_tonumber(L,3);
	h = lua_tonumber(L,4);

	if(lua_type(L,5) == LUA_TNUMBER) {
		shader = lua_tointeger(L,5);
	}
	
	s = quickfloat(L,6,0);
	t = quickfloat(L,7,0);
	s2 = quickfloat(L,8,1);
	t2 = quickfloat(L,9,1);

	DrawRect( x, y, w, h, s, t, s2, t2, shader );

	return 0;
}

void adjustVector(vec3_t v) {
	v[0] *= cgs.screenXScale;
	v[1] *= cgs.screenYScale;
}

int qlua_quad(lua_State *L) {
	float s,t,s2,t2;
	vec3_t v1,v2,v3,v4;

	qhandle_t shader = cgs.media.whiteShader;

	luaL_checktype(L,1,LUA_TVECTOR);
	luaL_checktype(L,2,LUA_TVECTOR);
	luaL_checktype(L,3,LUA_TVECTOR);
	luaL_checktype(L,4,LUA_TVECTOR);

	lua_tovector(L,1,v1);
	lua_tovector(L,2,v2);
	lua_tovector(L,3,v3);
	lua_tovector(L,4,v4);

	adjustVector(v1);
	adjustVector(v2);
	adjustVector(v3);
	adjustVector(v4);

	if(lua_type(L,5) == LUA_TNUMBER) {
		shader = lua_tointeger(L,5);
	}
	
	s = quickfloat(L,6,0);
	t = quickfloat(L,7,0);
	s2 = quickfloat(L,8,1);
	t2 = quickfloat(L,9,1);

	trap_R_DrawQuadPic( v1[0], v1[1], 
						v4[0], v4[1],
						v3[0], v3[1],
						v2[0], v2[1], s, t, s2, t2, shader );

	return 0;
}

int qlua_line(lua_State *L) {
	float x1,y1,x2,y2,w,s,t,s2,t2;
	float dx,dy,cx,cy,rot;

	qhandle_t shader = cgs.media.whiteShader;

	luaL_checktype(L,1,LUA_TNUMBER);
	luaL_checktype(L,2,LUA_TNUMBER);
	luaL_checktype(L,3,LUA_TNUMBER);
	luaL_checktype(L,4,LUA_TNUMBER);

	x1 = lua_tonumber(L,1);
	y1 = lua_tonumber(L,2);
	x2 = lua_tonumber(L,3);
	y2 = lua_tonumber(L,4);

	if(lua_type(L,5) == LUA_TNUMBER) {
		shader = lua_tointeger(L,5);
	}

	w = quickfloat(L,6,1);
	s = quickfloat(L,7,0);
	t = quickfloat(L,8,0);
	s2 = quickfloat(L,9,1);
	t2 = quickfloat(L,10,1);

	//CG_AdjustFrom640( &x1, &y1, &x2, &y2 );

	dx = x2 - x1;
	dy = y2 - y1;
	cx = x1 + dx/2;
	cy = y1 + dy/2;
	rot = atan2(dy,dx)*57.3;

	DrawRotatedRect( cx, cy, sqrt(dx*dx + dy*dy), w, s, t, s2, t2, rot, shader );

	return 0;
}

int qlua_rectrotated(lua_State *L) {
	float x,y,w,h,s,t,s2,t2,r;

	qhandle_t shader = cgs.media.whiteShader;

	luaL_checktype(L,1,LUA_TNUMBER);
	luaL_checktype(L,2,LUA_TNUMBER);
	luaL_checktype(L,3,LUA_TNUMBER);
	luaL_checktype(L,4,LUA_TNUMBER);

	x = lua_tonumber(L,1);
	y = lua_tonumber(L,2);
	w = lua_tonumber(L,3);
	h = lua_tonumber(L,4);

	if(lua_type(L,5) == LUA_TNUMBER) {
		shader = lua_tointeger(L,5);
	}
	
	r = quickfloat(L,6,0);
	s = quickfloat(L,7,0);
	t = quickfloat(L,8,0);
	s2 = quickfloat(L,9,1);
	t2 = quickfloat(L,10,1);

	//CG_AdjustFrom640( &x, &y, &w, &h );
	DrawRotatedRect( x, y, w, h, s, t, s2, t2, r, shader );

	return 0;
}

int qlua_text(lua_State *L) {
	int x,y;
	int w=CHAR_WIDTH,h=CHAR_HEIGHT;
	float size = 0;
	const char *text = "text";
	vec4_t	lastcolor;

	luaL_checktype(L,1,LUA_TNUMBER);
	luaL_checktype(L,2,LUA_TNUMBER);
	luaL_checktype(L,3,LUA_TSTRING);

	x = lua_tointeger(L,1);
	y = lua_tointeger(L,2);
	text = lua_tostring(L,3);
	if(lua_type(L,4) == LUA_TNUMBER) {w = lua_tointeger(L,4);}
	if(lua_type(L,5) == LUA_TNUMBER) {h = lua_tointeger(L,5);}

	trap_R_GetColor(lastcolor);
	CG_DrawStringExt(x, y, text, lastcolor, qfalse, qfalse, w, h, 0 );

	return 0;
}

int qlua_text2width(lua_State *L) {
	const char *text = "text";
	int width = 0;
	
	luaL_checktype(L,1,LUA_TSTRING);
	text = lua_tostring(L,1);

	width = UI_ProportionalStringWidth( text );
	lua_pushinteger(L,width);
	return 1;
}

int qlua_text2(lua_State *L) {
	int x,y;
	float size = 1;
	const char *text = "text";
	qboolean glow = qfalse;
	vec4_t	lastcolor;

	luaL_checktype(L,1,LUA_TNUMBER);
	luaL_checktype(L,2,LUA_TNUMBER);
	luaL_checktype(L,3,LUA_TSTRING);

	x = lua_tointeger(L,1);
	y = lua_tointeger(L,2);
	text = lua_tostring(L,3);
	if(lua_type(L,4) == LUA_TNUMBER) size = lua_tonumber(L,4);
	if(lua_gettop(L) >= 5 && lua_type(L,5) == LUA_TBOOLEAN) {
		glow = lua_toboolean(L,5);
	}

	trap_R_GetColor(lastcolor);
	if(glow) {
		UI_DrawProportionalString2(x, y, text, lastcolor, size, cgs.media.charsetPropGlow);
	} else {
		UI_DrawProportionalString2(x, y, text, lastcolor, size, cgs.media.charsetProp);
	}

	return 0;
}

int qlua_getpixel(lua_State *L) {
	int x,y,r,g,b;

	luaL_checkinteger(L,1);
	luaL_checkinteger(L,2);

	x = lua_tointeger(L,1);
	y = lua_tointeger(L,2);

	x *= cgs.screenXScale;
	y *= cgs.screenYScale;

	trap_R_GetPixel( x, y, &r, &g, &b );
	lua_pushinteger(L,r);
	lua_pushinteger(L,g);
	lua_pushinteger(L,b);
	return 3;
}

int qlua_vectorToScreen(lua_State *L) {
	vec3_t v,origin,v2;
	refdef_t		refdef;
	int				view[4];
	float			vout[4];
	float			voutm[4];
	float			temp[16];
	float			temp2[16];
	float			temp3[16];
	float			modelMatrix[16];
	float			perspectiveMatrix[16];
	float			xmin, xmax, ymin, ymax;
	float			width, height, depth;
	float			zNear, zFar;

	luaL_checktype(L,1,LUA_TVECTOR);
	lua_tovector(L,1,v);
	if(lua_type(L,2) == LUA_TTABLE) {
		lua_torefdef(L, 2, &refdef, qtrue);
	} else {
		refdef = cg.refdef;
	}
	VectorCopy(refdef.vieworg,origin);


	modelMatrix[0] = refdef.viewaxis[0][0];
	modelMatrix[4] = refdef.viewaxis[0][1];
	modelMatrix[8] = refdef.viewaxis[0][2];
	modelMatrix[12] = -origin[0] * modelMatrix[0] + -origin[1] * modelMatrix[4] + -origin[2] * modelMatrix[8];

	modelMatrix[1] = refdef.viewaxis[1][0];
	modelMatrix[5] = refdef.viewaxis[1][1];
	modelMatrix[9] = refdef.viewaxis[1][2];
	modelMatrix[13] = -origin[0] * modelMatrix[1] + -origin[1] * modelMatrix[5] + -origin[2] * modelMatrix[9];

	modelMatrix[2] = refdef.viewaxis[2][0];
	modelMatrix[6] = refdef.viewaxis[2][1];
	modelMatrix[10] = refdef.viewaxis[2][2];
	modelMatrix[14] = -origin[0] * modelMatrix[2] + -origin[1] * modelMatrix[6] + -origin[2] * modelMatrix[10];

	modelMatrix[3] = 0;
	modelMatrix[7] = 0;
	modelMatrix[11] = 0;
	modelMatrix[15] = 1;

	zNear = 4;
	zFar = 2048;

	ymax = zNear * tan( refdef.fov_y * M_PI / 360.0f );
	ymin = -ymax;

	xmax = zNear * tan( refdef.fov_x * M_PI / 360.0f );
	xmin = -xmax;

	width = xmax - xmin;
	height = ymax - ymin;
	depth = zFar - zNear;

	perspectiveMatrix[0] = 2 * zNear / width;
	perspectiveMatrix[4] = 0;
	perspectiveMatrix[8] = ( xmax + xmin ) / width;	// normally 0
	perspectiveMatrix[12] = 0;

	perspectiveMatrix[1] = 0;
	perspectiveMatrix[5] = 2 * zNear / height;
	perspectiveMatrix[9] = ( ymax + ymin ) / height;	// normally 0
	perspectiveMatrix[13] = 0;

	perspectiveMatrix[2] = 0;
	perspectiveMatrix[6] = 0;
	perspectiveMatrix[10] = -( zFar + zNear ) / depth;
	perspectiveMatrix[14] = -2 * zFar * zNear / depth;

	perspectiveMatrix[3] = 0;
	perspectiveMatrix[7] = 0;
	perspectiveMatrix[11] = -1;
	perspectiveMatrix[15] = 0;

	voutm[0] = v[0];
	voutm[1] = v[1];
	voutm[2] = v[2];
	voutm[3] = 1;

	view[0] = refdef.x;
	view[1] = refdef.y;
	view[2] = refdef.width;
	view[3] = refdef.height;

	quickMultiply4x4(modelMatrix,s_flipMatrix,temp);
	quickMultiply4x4(temp,perspectiveMatrix,temp2);
	quickMultiply4x4(temp,temp2,temp3);
	quickMultiply1x4by4x4(voutm,temp3,vout);

		vout[0] /= vout[3];
		vout[1] /= vout[3];
		vout[2] /= vout[3];
		
		vout[0] = view[0] + (view[2] * (vout[0] + 1)) / 2;
		vout[1] = view[1] + (view[3] * (vout[1] + 1)) / 2;
		vout[2] = (vout[2] + 1) / 2;

	v2[0] = vout[0];
	v2[1] = vout[1];
	v2[2] = vout[2];

	lua_pushvector(L,v2);

	return 1;
}

int qlua_customscale(lua_State *L) {
	DRAW_CUSTOMSCALE_X = lua_tonumber(L,1);
	DRAW_CUSTOMSCALE_Y = lua_tonumber(L,2);
	return 0;
}

int qlua_customoffset(lua_State *L) {
	DRAW_CUSTOMOFFSET_X = lua_tonumber(L,1);
	DRAW_CUSTOMOFFSET_Y = lua_tonumber(L,2);
	return 0;
}

static const luaL_reg Draw_methods[] = {
  {"SetColor",		qlua_setcolor},
  {"Rect",			qlua_rect},
  {"Line",			qlua_line},
  {"Quad",			qlua_quad},
  {"RectRotated",	qlua_rectrotated},
  {"BeveledRect",	qlua_beveledRect},
  {"Text",			qlua_text},
  {"Text2",			qlua_text2},
  {"Text2Width",	qlua_text2width},
  {"EndMask",		qlua_endmask},
  {"MaskRect",		qlua_maskrect},
  {"Start3D",		qlua_start3D},
  {"End3D",			qlua_end3D},
  {"Get3DCoord",	qlua_get3DCoord},
  {"GetPixel",		qlua_getpixel},
  {"VectorToScreen",qlua_vectorToScreen},
  {"CustomScale",	qlua_customscale},
  {"CustomOffset",	qlua_customoffset},
  {0,0}
};

int qlua_loadshader(lua_State *L) {
	const char *shader;
	qboolean	nomip;

	if(lua_type(L,1) == LUA_TSTRING) {
		if(lua_type(L,2) == LUA_TBOOLEAN) nomip = lua_toboolean(L,2);
		shader = lua_tostring(L,1);
		if(nomip) {
			lua_pushinteger(L,trap_R_RegisterShader( shader ));
		} else {
			lua_pushinteger(L,trap_R_RegisterShaderNoMip( shader ));
		}
		return 1;
	}
	return 0;
}

int qlua_createshader(lua_State *L) {
	const char *shader;
	char *data;

	if(lua_type(L,1) == LUA_TSTRING) {
		shader = lua_tostring(L,1);
		data = (char*) lua_tostring(L,2);
		lua_pushinteger(L,trap_R_CreateShader( shader, data ));
		return 1;
	}
	return 0;
}

void CG_KillMasks() {
	trap_R_EndMask();
	maskOn = qfalse;
}

void CG_InitLua2D(lua_State *L) {
	luaL_openlib(L, "draw", Draw_methods, 0);
	lua_register(L, "__loadshader", qlua_loadshader);
	lua_register(L, "CreateShader", qlua_createshader);
}