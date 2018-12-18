#include "q_shared.h"
#include "bg_public.h"

#define MYTYPE		"vector3"

typedef struct {
	vec_t x;
	vec_t y;
	vec_t z;
} luavector_t;


/*void lua_pushvector(lua_State *L, vec3_t vec) {
	luavector_t *userdata = (luavector_t*)lua_newuserdata(L, sizeof(luavector_t));
	userdata->x = vec[0];
	userdata->y = vec[1];
	userdata->z = vec[2];

	luaL_getmetatable(L, "Vector");
	lua_setmetatable(L, -2);
}

void lua_tovector(lua_State *L, int i, vec3_t in) {
	luavector_t	*luavector;
	luaL_checktype(L,i,LUA_TUSERDATA);
	luavector = (luavector_t *)lua_touserdata(L, i);
	if (luavector == NULL) luaL_typerror(L, i, "Vector");

	in[0] = luavector->x;
	in[1] = luavector->y;
	in[2] = luavector->z;
}*/


/*WORKING SYSTEM
void lua_pushvector(lua_State *L, vec3_t vec) {
	int tableIdx;
	lua_createtable(L,3,0);

	tableIdx = lua_gettop(L);

	lua_pushstring(L, "x");
	lua_pushnumber(L,vec[0]);
	lua_settable(L, tableIdx);

	lua_pushstring(L, "y");
	lua_pushnumber(L,vec[1]);
	lua_settable(L, tableIdx);

	lua_pushstring(L, "z");
	lua_pushnumber(L,vec[2]);
	lua_settable(L, tableIdx);
}

void lua_tovector(lua_State *L, int i, vec3_t in) {
	//vec3_t	out;
	float x = -1;
	float y = -1;
	float z = -1;
	
	//G_Printf("Got A Good Table.\n");

	lua_pushstring(L,"x");
	lua_gettable(L,i);
	x = lua_tonumber(L,lua_gettop(L));

	lua_pushstring(L,"y");
	lua_gettable(L,i);
	y = lua_tonumber(L,lua_gettop(L));

	lua_pushstring(L,"z");
	lua_gettable(L,i);
	z = lua_tonumber(L,lua_gettop(L));

	//G_Printf("%i,%i,%i\n",x,y,z);


	//if(x != -1 && y != -1 && z != -1) {
		in[0] = x;
		in[1] = y;
		in[2] = z;
	//}
}*/

float *lua_getLVector(lua_State *L, int i, qboolean force) {
	if (luaL_checkudata(L,i,MYTYPE)==NULL && !force) luaL_typerror(L,i,MYTYPE);
	return lua_touserdata(L,i);
}

float *lua_pushLVector(lua_State *L) {
	float *v=lua_newuserdata(L,3*sizeof(float));
	luaL_getmetatable(L,MYTYPE);
	lua_setmetatable(L,-2);
	return v;
}

int lua_newvector(lua_State *L)
{
	float *v;
	lua_settop(L,3);
	v=lua_pushLVector(L);
	v[0]=luaL_optnumber(L,1,0);
	v[1]=luaL_optnumber(L,2,v[0]);
	v[2]=luaL_optnumber(L,3,v[1]);
	return 1;
}

void lua_pushvector(lua_State *L, vec3_t vec)
{
	float *v;
	v=lua_pushLVector(L);
	v[0]=vec[0];
	v[1]=vec[1];
	v[2]=vec[2];
}

void lua_tovector(lua_State *L, int i, vec3_t vec)
{
	float *v = lua_getLVector(L,i,qfalse);
	vec[0] = v[0];
	vec[1] = v[1];
	vec[2] = v[2];
}

void lua_tovector_forced(lua_State *L, int i, vec3_t vec)
{
	float *v = lua_getLVector(L,i,qtrue);
	vec[0] = v[0];
	vec[1] = v[1];
	vec[2] = v[2];
}

static int Lget(lua_State *L)
{
	float *v=lua_getLVector(L,1,qfalse);
	const char* i=luaL_checkstring(L,2);
		switch (*i) {
			case '1': case 'x': case 'p': case 'u': lua_pushnumber(L,v[0]); break;
			case '2': case 'y': case 'v': lua_pushnumber(L,v[1]); break;
			case '3': case 'z': case 'r': lua_pushnumber(L,v[2]); break;
			default: lua_pushnil(L); break;
		}
	return 1;
}

static int Lset(lua_State *L) {
	float *v=lua_getLVector(L,1,qfalse);
	const char* i=luaL_checkstring(L,2);
	float t=luaL_checknumber(L,3);
		switch (*i) {
			case '1': case 'x': case 'p': case 'u': v[0]=t; break;
			case '2': case 'y': case 'v': v[1]=t; break;
			case '3': case 'z': case 'r': v[2]=t; break;
			default: break;
		}
	return 1;
}

static int Vector_tostring (lua_State *L)
{
	vec3_t v1;

	lua_tovector(L,1,v1);
	lua_pushfstring(L,"%f, %f, %f",v1[0],v1[1],v1[2]);
	return 1;
}

static int Vector_equal (lua_State *L)
{
	vec3_t v1;
	vec3_t v2;

	lua_tovector(L,1,v1);
	lua_tovector(L,2,v2);

	if(v1 != NULL && v2 != NULL) {
		lua_pushboolean(L, (v1[0] == v2[0] && v1[1] == v2[1] && v1[2] == v2[2]));
	} else {
		lua_pushboolean(L, 0);
	}
  return 1;
}

static int Vector_add (lua_State *L) {
	vec3_t v1,v2,out;
	float n = 0;

	lua_tovector(L,1,v1);

	if(lua_type(L,2) == LUA_TNUMBER) {
		n = lua_tonumber(L,2);
		out[0] = v1[0] + n;
		out[1] = v1[1] + n;
		out[2] = v1[2] + n;
	} else {
		lua_tovector(L,2,v2);
		if(v1 != NULL && v2 != NULL) {
			VectorAdd(v1,v2,out);
		} else {
			return 0;
		}
	}
	lua_pushvector(L,out);
	return 1;
}

static int Vector_sub (lua_State *L) {
	vec3_t v1,v2,out;
	float n = 0;

	lua_tovector(L,1,v1);

	if(lua_type(L,2) == LUA_TNUMBER) {
		n = lua_tonumber(L,2);
		out[0] = v1[0] - n;
		out[1] = v1[1] - n;
		out[2] = v1[2] - n;
	} else {
		lua_tovector(L,2,v2);
		if(v1 != NULL && v2 != NULL) {
			VectorSubtract(v1,v2,out);
		} else {
			return 0;
		}
	}
	lua_pushvector(L,out);
	return 1;
}

static int Vector_mul (lua_State *L) {
	vec3_t v1,v2,out;
	float n = 0;

	lua_tovector(L,1,v1);

	if(lua_type(L,2) == LUA_TNUMBER) {
		n = lua_tonumber(L,2);
		out[0] = v1[0] * n;
		out[1] = v1[1] * n;
		out[2] = v1[2] * n;
	} else {
		lua_tovector(L,2,v2);
		if(v1 != NULL && v2 != NULL) {
			out[0] = v1[0] * v2[0];
			out[1] = v1[1] * v2[1];
			out[2] = v1[2] * v2[2];
		} else {
			return 0;
		}
	}
	lua_pushvector(L,out);
	return 1;
}

static int Vector_div (lua_State *L) {
	vec3_t v1,v2,out;
	float n = 0;

	lua_tovector(L,1,v1);

	if(lua_type(L,2) == LUA_TNUMBER) {
		n = lua_tonumber(L,2);
		out[0] = v1[0] / n;
		out[1] = v1[1] / n;
		out[2] = v1[2] / n;
	} else {
		lua_tovector(L,2,v2);
		if(v1 != NULL && v2 != NULL) {
			out[0] = v1[0] / v2[0];
			out[1] = v1[1] / v2[1];
			out[2] = v1[2] / v2[2];
		} else {
			return 0;
		}
	}
	lua_pushvector(L,out);
	return 1;
}

static int Vector_metatest (lua_State *L)
{
	vec3_t v1;

	lua_tovector(L,1,v1);
	lua_pushfstring(L,"THIS IS A METAFUNCTION: %f, %f, %f",v1[0],v1[1],v1[2]);
	return 1;
}

static const luaL_reg Vector_methods[] = {
  { "MetaTest",		Vector_metatest },
  {0,0}
};


static const luaL_reg Vector_meta[] = {
  { "__index",		Lget			},
  { "__newindex",	Lset			},
  { "__tostring",	Vector_tostring	},
  { "__eq",			Vector_equal	},
  { "__add",		Vector_add		},
  { "__sub",		Vector_sub		},
  { "__mul",		Vector_mul		},
  { "__div",		Vector_div		},
  {0,0}
};

int Vector_register (lua_State *L) {
	luaL_openlib(L, MYTYPE, Vector_methods, 0);
	luaL_newmetatable(L,MYTYPE);
	luaL_openlib(L, NULL,Vector_meta,0);
	lua_register(L,"Vector",lua_newvector);

	return 1;
}

int qlua_VectorToAngles(lua_State *L) {
	vec3_t v,angles;
	lua_tovector(L,1,v);

	vectoangles(v,angles);
	lua_pushvector(L,angles);
	return 1;
}

int qlua_AngleVectors(lua_State *L) {
	vec3_t v,f,r,u;
	
	lua_tovector(L,1,v);

	v[0] = AngleMod(v[0]);
	v[1] = AngleMod(v[1]);
	v[2] = AngleMod(v[2]);

	AngleVectors(v,f,r,u);
	lua_pushvector(L,f);
	lua_pushvector(L,r);
	lua_pushvector(L,u);
	return 3;
}

int qlua_VectorNormalize(lua_State *L) {
	vec3_t v;
	int	len = 0;
	lua_tovector(L,1,v);
	len = VectorNormalize(v);
	lua_pushvector(L,v);
	lua_pushinteger(L,len);
	return 2;
}

int qlua_VectorLength(lua_State *L) {
	vec3_t v;
	float len = 0;
	lua_tovector(L,1,v);
	len = sqrt(v[0]*v[0] + v[1]*v[1] + v[2]*v[2]);
	lua_pushnumber(L,len);
	return 1;
}

int qlua_VectorForward(lua_State *L) {
	vec3_t v;
	vec3_t f,r,u;
	lua_tovector(L,1,v);
	AngleVectors(v,f,r,u);
	lua_pushvector(L,f);
	return 1;
}

int qlua_VectorRight(lua_State *L) {
	vec3_t v;
	vec3_t axis[3];
	lua_tovector(L,1,v);
	AnglesToAxis(v,axis);
	lua_pushvector(L,axis[0]);
	return 1;
}

int qlua_VectorUp(lua_State *L) {
	vec3_t v;
	vec3_t axis[3];
	lua_tovector(L,1,v);
	AnglesToAxis(v,axis);
	lua_pushvector(L,axis[2]);
	return 1;
}

int qlua_DotProduct(lua_State *L) {
	vec3_t dst,src;
	lua_tovector(L,1,src);
	lua_tovector(L,2,dst);
	lua_pushnumber(L,DotProduct(src,dst));
	return 1;
}

int qlua_CrossProduct(lua_State *L) {
	vec3_t a,b,c;
	lua_tovector(L,1,a);
	lua_tovector(L,2,b);
	CrossProduct(a,b,c);
	lua_pushvector(L,c);
	return 1;
}

int qlua_ByteToDir(lua_State *L) {
	vec3_t dir;
	luaL_checkint(L,1);
	
	ByteToDir(lua_tointeger(L,1),dir);
	lua_pushvector(L,dir);
	return 1;
}

int qlua_DirToByte(lua_State *L) {
	vec3_t dir;
	lua_tovector(L,1,dir);
	lua_pushinteger(L,DirToByte(dir));
	return 1;
}

void lerpVector(vec3_t v1, vec3_t v2, vec3_t out, float t) {
	vec3_t temp;
	VectorSubtract(v2,v1,temp);
	VectorMA(v1,t,temp,out);
}

void interpolateSpline(vec3_t verts[],luavector_t *out,int count,float lerp) {
	vec3_t lerped[1024];
	int i = 0;
	if(count > 1) {
		for(i=0;i<count-1;i++) {
			lerpVector(verts[i], verts[i+1], lerped[i], lerp);
		}
		interpolateSpline(lerped, out, count-1, lerp);
	} else if(count > 0) {
		out->x = verts[0][0];
		out->y = verts[0][1];
		out->z = verts[0][2];
	}
}

int qlua_vspline(lua_State *L) {
	int size = 0;
	int i = 0;
	int idx = 0;
	float t = 0;
	vec3_t verts[1024];
	vec3_t vout;
	luavector_t out;

	memset(&out,0,sizeof(out));

	luaL_checktype(L,1,LUA_TTABLE);
	luaL_checktype(L,2,LUA_TNUMBER);

	t = lua_tonumber(L,2);

	VectorClear(vout);

	size = luaL_getn(L,1);
	if(size > 1024) {
		lua_pushvector(L,vout);
		return 0;
	}
	if(size < 1) {
		lua_pushvector(L,vout);
		return 1;
	}

	for(i=0;i<size;i++) {
		qlua_pullvector_i(L,i+1,verts[i],qfalse,1);
	}

	interpolateSpline(verts,&out,size,t);

	vout[0] = out.x;
	vout[1] = out.y;
	vout[2] = out.z;

	lua_pushvector(L,vout);
	
	return 1;
}

int qlua_vrotate(lua_State *L) {
	vec3_t dst,dir,point;
	float deg = 0;
	lua_tovector(L,1,dir);
	lua_tovector(L,2,point);
	deg = lua_tonumber(L,3);

	RotatePointAroundVector(dst,dir,point,deg);

	lua_pushvector(L,dst);
	return 1;
}

int qlua_vproject(lua_State *L) {
	vec3_t dst,src,plane;

	luaL_checktype(L,1,LUA_TVECTOR);
	luaL_checktype(L,2,LUA_TVECTOR);
	
	lua_tovector(L,1,src);
	lua_tovector(L,2,plane);

	ProjectPointOnPlane(dst,src,plane);

	lua_pushvector(L,dst);
	return 1;
}

int qlua_vperpendicular(lua_State *L) {
	vec3_t a,b;
	lua_tovector(L,1,a);
	PerpendicularVector(b,a);
	lua_pushvector(L,b);
	return 1;
}

void BG_InitLuaVector(lua_State *L) {
	lua_register(L,"VectorToAngles",qlua_VectorToAngles);
	lua_register(L,"VectorNormalize",qlua_VectorNormalize);
	lua_register(L,"VectorLength",qlua_VectorLength);
	lua_register(L,"VectorForward",qlua_VectorForward);
	lua_register(L,"VectorRight",qlua_VectorRight);
	lua_register(L,"VectorUp",qlua_VectorUp);
	lua_register(L,"AngleVectors",qlua_AngleVectors);
	lua_register(L,"DotProduct",qlua_DotProduct);
	lua_register(L,"CrossProduct",qlua_CrossProduct);
	lua_register(L,"ByteToDir",qlua_ByteToDir);
	lua_register(L,"DirToByte",qlua_DirToByte);
	lua_register(L,"VectorSpline",qlua_vspline);
	lua_register(L,"RotatePointAroundVector",qlua_vrotate);
	lua_register(L,"ProjectPointOnPlane",qlua_vproject);
	lua_register(L,"PerpendicularVector",qlua_vperpendicular);

	Vector_register(L);
}

qboolean IsVector(lua_State *L, int i) {
	void *p = lua_touserdata(L, i);
	if (p != NULL) {  /* value is a userdata? */
		if (lua_getmetatable(L, i)) {  /* does it have a metatable? */
			lua_getfield(L, LUA_REGISTRYINDEX, MYTYPE);  /* get correct metatable */
			if (lua_rawequal(L, -1, -2)) {  /* does it have the correct mt? */
				lua_pop(L, 2);  /* remove both metatables */
				return qtrue;
			}
		}
	}
	return qfalse;
}