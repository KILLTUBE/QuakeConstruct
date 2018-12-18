#include "q_shared.h"

#ifdef GAME
	#include "../game/g_local.h"
#else
	#include "../cgame/cg_local.h"
#endif

void lua_pushwarper(lua_State *L, coordwarp_t *warp) {
	coordwarp_t *warp2 = NULL;

	warp2 = (coordwarp_t*)lua_newuserdata(L, sizeof(coordwarp_t));
	memcpy(warp2,warp,sizeof(coordwarp_t));

	luaL_getmetatable(L, "Warper");
	lua_setmetatable(L, -2);
}

coordwarp_t *lua_towarper(lua_State *L, int i) {
	coordwarp_t	*warp;
	luaL_checktype(L,i,LUA_TUSERDATA);
	warp = (coordwarp_t *)luaL_checkudata(L, i, "Warper");

	if (warp == NULL) luaL_typerror(L, i, "Warper");

	return warp;
}

void multMat4(float *srcMat, float *dstMat, float *resMat) {
    int r,ri,c;
	for (r = 0; r < 4; r++) {
        ri = r * 4;
        for (c = 0; c < 4; c++) {
	    resMat[ri + c] = (srcMat[ri    ] * dstMat[c     ] +
			        srcMat[ri + 1] * dstMat[c +  4] +
			        srcMat[ri + 2] * dstMat[c +  8] +
			        srcMat[ri + 3] * dstMat[c + 12]);
		}
	}
}

void computeSquareToQuad(	float x0,
							float y0, 
							float x1, 
							float y1, 
							float x2,
							float y2, 
							float x3, 
							float y3,
							float *mat) {

    float dx1 = x1 - x2, 	dy1 = y1 - y2;
    float dx2 = x3 - x2, 	dy2 = y3 - y2;
    float sx = x0 - x1 + x2 - x3;
    float sy = y0 - y1 + y2 - y3;
    float g = (sx * dy2 - dx2 * sy) / (dx1 * dy2 - dx2 * dy1);
    float h = (dx1 * sy - sx * dy1) / (dx1 * dy2 - dx2 * dy1);
    float a = x1 - x0 + g * x1;
    float b = x3 - x0 + h * x3;
    float c = x0;
    float d = y1 - y0 + g * y1;
    float e = y3 - y0 + h * y3;
    float f = y0;

    mat[ 0] = a;	mat[ 1] = d;	mat[ 2] = 0;	mat[ 3] = g;
    mat[ 4] = b;	mat[ 5] = e;	mat[ 6] = 0;	mat[ 7] = h;
    mat[ 8] = 0;	mat[ 9] = 0;	mat[10] = 1;	mat[11] = 0;
    mat[12] = c;	mat[13] = f;	mat[14] = 0;	mat[15] = 1;
}

void computeQuadToSquare(	float x0,
							float y0, 
							float x1, 
							float y1, 
							float x2,
							float y2, 
							float x3, 
							float y3,
							float *mat) {

	float a,b,c,d,e,f,g,h,A,B,C,D,E,F,G,H,I,idet;

    computeSquareToQuad(x0,y0,x1,y1,x2,y2,x3,y3, mat);

    // invert through adjoint

    a = mat[ 0],	d = mat[ 1],  g = mat[ 3];
    b = mat[ 4],	e = mat[ 5],  h = mat[ 7];
    c = mat[12],	f = mat[13];

    A =     e - f * h;
    B = c * h - b;
    C = b * f - c * e;
    D = f * g - d;
    E =     a - c * g;
    F = c * d - a * f;
    G = d * h - e * g;
    H = b * g - a * h;
    I = a * e - b * d;

    // Probably unnecessary since 'I' is also scaled by the determinant,
    //   and 'I' scales the homogeneous coordinate, which, in turn,
    //   scales the X,Y coordinates.
    // Determinant  =   a * (e - f * h) + b * (f * g - d) + c * (d * h - e * g);
    idet = 1.0f / (a * A           + b * D           + c * G);

    mat[ 0] = A * idet;	mat[ 1] = D * idet;	mat[ 2] = 0;	mat[ 3] = G * idet;
    mat[ 4] = B * idet;	mat[ 5] = E * idet;	mat[ 6] = 0;	mat[ 7] = H * idet;
    mat[ 8] = 0       ;	mat[ 9] = 0       ;	mat[10] = 1;	mat[11] = 0       ;
    mat[12] = C * idet;	mat[13] = F * idet;	mat[14] = 0;	mat[15] = I * idet;
}

void computeWarp(coordwarp_t *warp) {
	computeQuadToSquare(	warp->src[0][0],warp->src[0][1],
						    warp->src[1][0],warp->src[1][1],
						    warp->src[2][0],warp->src[2][1],
						    warp->src[3][0],warp->src[3][1],
							warp->srcMat);
    computeSquareToQuad(	warp->dst[0][0],warp->dst[0][1],
						    warp->dst[1][0],warp->dst[1][1],
						    warp->dst[2][0],warp->dst[2][1],
						    warp->dst[3][0],warp->dst[3][1],
							warp->dstMat);
	multMat4(warp->srcMat, warp->dstMat, warp->warpMat);
    warp->dirty = qfalse;
}

int qlua_warp_identity(lua_State *L) {
	coordwarp_t *warp = lua_towarper(L,1);

	warp->dst[0][0] = warp->src[0][0] = 0; warp->dst[0][1] = warp->src[0][1] = 0;
	warp->dst[0][0] = warp->src[0][0] = 1; warp->dst[0][1] = warp->src[0][1] = 0;
	warp->dst[0][0] = warp->src[0][0] = 0; warp->dst[0][1] = warp->src[0][1] = 1;
	warp->dst[0][0] = warp->src[0][0] = 1; warp->dst[0][1] = warp->src[0][1] = 1;
	
	computeWarp(warp);
	return 0;
}

int qlua_warp_src(lua_State *L) {
	coordwarp_t *warp = lua_towarper(L,1);

	lua_tovector(L,2,warp->src[0]);
	lua_tovector(L,3,warp->src[1]);
	lua_tovector(L,4,warp->src[2]);
	lua_tovector(L,5,warp->src[3]);
    warp->dirty = qtrue;

	return 0;
}

int qlua_warp_dst(lua_State *L) {
	coordwarp_t *warp = lua_towarper(L,1);

	lua_tovector(L,2,warp->dst[0]);
	lua_tovector(L,3,warp->dst[1]);
	lua_tovector(L,4,warp->dst[2]);
	lua_tovector(L,5,warp->dst[3]);
    warp->dirty = qtrue;

	return 0;
}

int qlua_warp(lua_State *L) {
	coordwarp_t *warp = lua_towarper(L,1);
	vec3_t  dst,in;
    float result[4];
	float *mat = warp->warpMat;
    float z = 0;
	float srcX, srcY;

	lua_tovector(L,2,in);
	
	srcX = in[0];
	srcY = in[1];

	if (warp->dirty) {
		computeWarp(warp);
		mat = warp->warpMat;
	}

    result[0] = (float)(srcX * mat[0] + srcY*mat[4] + z*mat[8] + 1*mat[12]);
    result[1] = (float)(srcX * mat[1] + srcY*mat[5] + z*mat[9] + 1*mat[13]);
    result[2] = (float)(srcX * mat[2] + srcY*mat[6] + z*mat[10] + 1*mat[14]);
    result[3] = (float)(srcX * mat[3] + srcY*mat[7] + z*mat[11] + 1*mat[15]);        
    dst[0] = result[0]/result[3];
	dst[1] = result[1]/result[3];
	dst[2] = 0;

	lua_pushvector(L,dst);

	return 1;
}

int qlua_warp_make(lua_State *L) {
	coordwarp_t warp;

	lua_pushwarper(L,&warp);

	return 1;
}

static const luaL_reg Warp_methods[] = {
  {"SetIdentity",	qlua_warp_identity},
  {"SetSource",		qlua_warp_src},
  {"SetDest",		qlua_warp_dst},
  {"Warp",			qlua_warp},
  {0,0}
};

static const luaL_reg Warp_meta[] = {
  {0, 0}
};

int Warp_register (lua_State *L) {
	luaL_openlib(L, "Warper", Warp_methods, 0);

	luaL_newmetatable(L, "Warper");

	luaL_openlib(L, 0, Warp_meta, 0);
	lua_pushliteral(L, "__index");
	lua_pushvalue(L, -3);
	lua_rawset(L, -3);
	lua_pushliteral(L, "__metatable");
	lua_pushvalue(L, -3);
	lua_rawset(L, -3);

	lua_setglobal(L,"M_Warper");

	lua_pop(L, 1);
	return 1;
}

static const luaL_reg Math_methods[] = {
  {"Warper",		qlua_warp_make},
  {0,0}
};

void BG_InitLuaMath(lua_State *L) {
	luaL_openlib(L, "qmath", Math_methods, 0);
	Warp_register(L);
}