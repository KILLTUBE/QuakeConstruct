#include "cg_local.h"

void matrixMult3x3( const float *a, const float *b, float *out ) {
	int		i, j;

	for ( i = 0 ; i < 3 ; i++ ) {
		for ( j = 0 ; j < 3 ; j++ ) {
			out[ i * 3 + j ] =
				a [ i * 3 + 0 ] * b [ 0 * 3 + j ]
				+ a [ i * 3 + 1 ] * b [ 1 * 3 + j ]
				+ a [ i * 3 + 2 ] * b [ 2 * 3 + j ];
		}
	}
}

void matrixMult1x3to3x3( const float *a, const float *b, float *out ) {
	int		j;

	for ( j = 0 ; j < 3 ; j++ ) {
		out[ j ] =
			a [ 0 ] * b [ j ]
			+ a [ 1 ] * b [ 3 + j ]
			+ a [ 2 ] * b [ 6 + j ];
	}
}

vec3_t p;
vec3_t plane[3];
float pr[9] = {
	0,0,0,
	0,0,0,
	0,0,0};

void setupPlane(vec3_t pos, vec3_t axis[3]) {
	int i,j = 0;
	VectorCopy(pos,p);
/*	pr[0] = axis[1][0]; pr[1] = axis[1][1]; pr[2] = axis[1][2];
	pr[3] = axis[2][0]; pr[4] = axis[2][1]; pr[5] = axis[2][2];
	pr[6] = axis[0][0]; pr[7] = axis[0][1]; pr[8] = axis[0][2];
*/
	pr[0] = axis[1][0]; pr[1] = axis[2][0]; pr[2] = axis[0][0];
	pr[3] = axis[1][1]; pr[4] = axis[2][1]; pr[5] = axis[0][1];
	pr[6] = axis[1][2]; pr[7] = axis[2][2]; pr[8] = axis[0][2];


	//VectorCopy(axis[0],plane[0]);
	//VectorCopy(axis[1],plane[1]);
	//VectorCopy(axis[2],plane[2]);
}

void RotateFoxAxis(vec3_t v, vec3_t axis[3]) {
	int i;
	vec3_t temp,temp2;
	VectorClear(temp);
	VectorClear(temp2);
	for(i=0; i<3; i++) {
		VectorScale(axis[i], v[i], temp);
		VectorAdd(temp,temp2,temp2);
	}
	VectorCopy(temp2,v);
}

void projectRPointOnPlane(vec3_t point) {
	vec3_t temp;
	//VectorSubtract(point,p,point);
	matrixMult1x3to3x3(point,pr,temp);
	//RotateFoxAxis(point,plane);
	VectorCopy(temp,point);
}

//lua_pushlightuserdata(L,cl);
void lua_pushrefentity(lua_State *L, refEntity_t *cl) {
	refEntity_t *ent = NULL;

	if(cl == NULL) {
		lua_pushnil(L);
		return;
	}

	ent = (refEntity_t*)lua_newuserdata(L, sizeof(refEntity_t));
	memcpy(ent,cl,sizeof(refEntity_t));

	luaL_getmetatable(L, "RefEntity");
	lua_setmetatable(L, -2);
}

refEntity_t *lua_torefentity(lua_State *L, int i) {
	refEntity_t	*luaentity = NULL;

	luaL_checktype(L,i,LUA_TUSERDATA);

	luaentity = (refEntity_t *)luaL_checkudata(L, i, "RefEntity");//lua_touserdata(L, i);

	if (luaentity == NULL) luaL_typerror(L, i, "RefEntity");

	return luaentity;
}

int qlua_rpositionontag(lua_State *L) {
	refEntity_t	*ent;
	refEntity_t	*other;
	char *str;
	qboolean norot = qfalse;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TUSERDATA);
	luaL_checktype(L,3,LUA_TSTRING);

	ent = lua_torefentity(L,1);
	other = lua_torefentity(L,2);
	str = (char *)lua_tostring(L,3);

	if(lua_type(L,4) == LUA_TBOOLEAN) {
		norot = lua_toboolean(L,4);
	}

	if(norot) {
		CG_PositionEntityOnTag(ent,other,other->hModel,str);
	} else {
		CG_PositionRotatedEntityOnTag(ent,other,other->hModel,str);
	}
	return 0;
}

int qlua_rgetpos(lua_State *L) {
	refEntity_t	*luaentity;
	vec3_t		origin;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		VectorCopy(luaentity->origin, origin);
		lua_pushvector(L,origin);
		return 1;
	}
	return 0;
}

int qlua_rsetpos(lua_State *L) {
	refEntity_t	*luaentity;
	vec3_t		origin,vlen;
	vec3_t		temp[256];
	int			size,i,size2;
	qboolean	isNew = qfalse;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TVECTOR);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		lua_tovector(L,2,origin);

		if( origin[0] != luaentity->origin[0] ||
			origin[1] != luaentity->origin[1] ||
			origin[2] != luaentity->origin[2]) {
			isNew = qtrue;
		}

		VectorCopy( origin, luaentity->lightingOrigin );
		VectorCopy( origin, luaentity->origin );

		if(luaentity->reType == RT_TRAIL) {
			VectorSubtract(luaentity->trailVerts[0],luaentity->origin,vlen);
			luaentity->trailCoordBump -= VectorLength(vlen) / luaentity->trailCoordLength;

			size2 = sizeof(luaentity->trailVerts) / sizeof(luaentity->trailVerts[0]);
			if(luaentity->numVerts2 > size2) luaentity->numVerts2 = size2;
			if(luaentity->numVerts2 <= 1) luaentity->numVerts2 = 2;
			size = luaentity->numVerts2; //sizeof(luaentity->trailVerts) / sizeof(luaentity->trailVerts[0]);

			//Com_Printf("Shifted: %i verts\n",size);

			for(i=0; i<size; i++) {
				VectorCopy(luaentity->trailVerts[i],temp[i]);
			}

			for(i=1; i<size; i++) {
				VectorCopy(temp[i-1],luaentity->trailVerts[i]);
			}
			VectorCopy(luaentity->origin,luaentity->trailVerts[0]);
		}
	}
	return 0;
}

int qlua_rgetpos2(lua_State *L) {
	refEntity_t	*luaentity;
	vec3_t		origin;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		VectorCopy(luaentity->oldorigin, origin);
		lua_pushvector(L,origin);
		return 1;
	}
	return 0;
}

int qlua_rsetpos2(lua_State *L) {
	refEntity_t	*luaentity;
	vec3_t		origin;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TVECTOR);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		lua_tovector(L,2,origin);
		VectorCopy( origin, luaentity->oldorigin );
	}
	return 0;
}

int qlua_rgetangles(lua_State *L) {
	refEntity_t	*luaentity;
	vec3_t	angles;
	vec3_t	angles2;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		vectoangles(luaentity->axis[0],angles);
		vectoangles(luaentity->axis[1],angles2);
		angles[2] = angles2[0];
		lua_pushvector(L,angles);
		return 1;
		//lua_pushvector(L,luaentity->axis[0]);
		//lua_pushvector(L,luaentity->axis[1]);
		//lua_pushvector(L,luaentity->axis[2]);
		//return 3;
	}
	return 0;
}

int qlua_rgetaxis(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		lua_pushvector(L,luaentity->axis[0]);
		lua_pushvector(L,luaentity->axis[1]);
		lua_pushvector(L,luaentity->axis[2]);
		return 3;
	}
	return 0;
}

int qlua_rsetaxis(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TUSERDATA);
	luaL_checktype(L,3,LUA_TUSERDATA);
	luaL_checktype(L,4,LUA_TUSERDATA);

	if(IsVector(L,2) && IsVector(L,3) && IsVector(L,4)) {
		luaentity = lua_torefentity(L,1);
		if(luaentity != NULL) {
			lua_tovector(L,2,luaentity->axis[0]);
			lua_tovector(L,3,luaentity->axis[1]);
			lua_tovector(L,4,luaentity->axis[2]);
		}
	}
	return 0;
}

int qlua_rrotatearound(lua_State *L) {
	refEntity_t	*luaentity;
	vec3_t axis[3];
	vec3_t ang;

	luaL_checktype(L,1,LUA_TUSERDATA);
	if(!lua_type(L,2) == LUA_TVECTOR) return 0;
	if(!IsVector(L,2)) return 0;

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		lua_tovector(L,2,ang);
		VectorCopy(luaentity->axis[2],axis[0]);
		VectorCopy(luaentity->axis[0],axis[1]);
		VectorCopy(luaentity->axis[1],axis[2]);
		RotateAroundDirection(axis,ang[0]);
		VectorCopy(axis[0],luaentity->axis[2]);
		VectorCopy(axis[1],luaentity->axis[0]);
		VectorCopy(axis[2],luaentity->axis[1]);

		/*VectorCopy(luaentity->axis[0],axis[0]);
		VectorCopy(luaentity->axis[1],axis[1]);
		VectorCopy(luaentity->axis[2],axis[2]);
		RotateAroundDirection(axis,ang[2]);
		VectorCopy(axis[0],luaentity->axis[0]);
		VectorCopy(axis[1],luaentity->axis[1]);
		VectorCopy(axis[2],luaentity->axis[2]);

		VectorCopy(luaentity->axis[1],axis[0]);
		VectorCopy(luaentity->axis[2],axis[1]);
		VectorCopy(luaentity->axis[0],axis[2]);
		RotateAroundDirection(axis,ang[1]);
		VectorCopy(axis[0],luaentity->axis[1]);
		VectorCopy(axis[1],luaentity->axis[2]);
		VectorCopy(axis[2],luaentity->axis[0]);*/
	}
	return 0;
}

int qlua_rsetangles(lua_State *L) {
	refEntity_t	*luaentity;
	vec3_t angles;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TVECTOR);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		lua_tovector(L,2,angles);
		AnglesToAxis( angles, luaentity->axis );
	}
	return 0;
}

int qlua_rsetshader(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		luaentity->customShader = lua_tointeger(L,2);
	}
	return 0;
}

int qlua_rgetshader(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L,luaentity->customShader);
		return 1;
	}
	return 0;
}

int qlua_rsetmodel(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		luaentity->hModel = lua_tointeger(L,2);
	}
	return 0;
}

int qlua_rgetmodel(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L,luaentity->hModel);
		return 1;
	}
	return 0;
}

int qlua_rsettype(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		if(lua_tointeger(L,2) < 0 || lua_tointeger(L,2) >= RT_MAX_REF_ENTITY_TYPE) {
			lua_pushstring(L,"Index out of range (Render Type).");
			lua_error(L);
			return 1;
		}
		luaentity->reType = lua_tointeger(L,2);
	}
	return 0;
}

int qlua_rgettype(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L,luaentity->reType);
		return 1;
	}
	return 0;
}

int qlua_rsetradius(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		luaentity->radius = lua_tonumber(L,2);
	}
	return 0;
}

int qlua_rgetradius(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		lua_pushnumber(L,luaentity->radius);
		return 1;
	}
	return 0;
}

int qlua_rsetskin(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL && lua_tointeger(L,2) > -1) {
		luaentity->customSkin = lua_tointeger(L,2);
	}
	return 0;
}

int qlua_rgetskin(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L,luaentity->customSkin);
		return 1;
	}
	return 0;
}

int qlua_rsetoldframe(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL && lua_tointeger(L,2) > -1) {
		luaentity->oldframe = lua_tointeger(L,2);
	}
	return 0;
}

int qlua_rgetoldframe(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L,luaentity->oldframe);
		return 1;
	}
	return 0;
}

int qlua_rsetframe(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL && lua_tointeger(L,2) > -1) {
		luaentity->frame = lua_tointeger(L,2);
	}
	return 0;
}

int qlua_rgetframe(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L,luaentity->frame);
		return 1;
	}
	return 0;
}

int qlua_rsetlerp(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL && lua_tointeger(L,2) > -1) {
		luaentity->backlerp = lua_tonumber(L,2);
	}
	return 0;
}

int qlua_rgetlerp(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		lua_pushnumber(L,luaentity->backlerp);
		return 1;
	}
	return 0;
}

int qlua_rsetscale(lua_State *L) {
	refEntity_t	*luaentity;
	vec3_t in;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TVECTOR);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		lua_tovector(L,2,in);
		VectorCopy(in,luaentity->lua_scale);
		VectorScale(luaentity->axis[0],in[0],luaentity->axis[0]);
		VectorScale(luaentity->axis[1],in[1],luaentity->axis[1]);
		VectorScale(luaentity->axis[2],in[2],luaentity->axis[2]);
		return 1;
	}
	return 0;	
}

int qlua_rsetrotation(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		luaentity->rotation = lua_tonumber(L,2);
		return 1;
	}
	return 0;	
}

int qlua_rsetcolor(lua_State *L) {
	int err = 0;
	refEntity_t	*luaentity;
	vec4_t	color;
	
	VectorClear(color);

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaentity = lua_torefentity(L,1);
	qlua_toColor(L,2,color,qfalse);

	if(luaentity != NULL) {
		luaentity->shaderRGBA[0] = (int)(color[0]*255);
		luaentity->shaderRGBA[1] = (int)(color[1]*255);
		luaentity->shaderRGBA[2] = (int)(color[2]*255);
		luaentity->shaderRGBA[3] = (int)(color[3]*255);
	}

	return 0;
}

int qlua_rgetcolor(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaentity = lua_torefentity(L,1);

	if(luaentity != NULL) {
		lua_pushinteger(L,(int)luaentity->shaderRGBA[0]);
		lua_pushinteger(L,(int)luaentity->shaderRGBA[1]);
		lua_pushinteger(L,(int)luaentity->shaderRGBA[2]);
		lua_pushinteger(L,(int)luaentity->shaderRGBA[3]);
		return 4;
	}

	return 0;
}

int qlua_rrender(lua_State *L) {
	refEntity_t	*e;
	refTri_t	tris;
	vec3_t		temp;
	vec4_t		color;
	int i=0,j=0,k=0,x,size;

	luaL_checktype(L,1,LUA_TUSERDATA);

	color[0] = 1;
	color[1] = 1;
	color[2] = 1;
	color[3] = 1;

	e = lua_torefentity(L,1);
	if(e != NULL) {
		trap_R_AddRefEntityToScene( e );
		if(e->ndecals == 0) return 0;
		for(i=0; i<e->ndecals; i++) {
			//if(e->decals[i].tris[0] != NULL) {
				size = e->decals[i].num;
				//CG_Printf("Render Decal %i,%i\n",i,size);
				for(j=0; j<size; j++) {
					if(trap_R_LerpTriangle( e->hModel, e->decals[i].tris[j].surface, e->decals[i].tris[j].triangle, &tris, e->oldframe, e->frame, 1.0 - e->backlerp )) {
						for(k=0; k<3; k++) {
							VectorCopy(e->origin,temp);
							for (x=0; x<3; x++ ) {
								VectorMA( temp, tris.verts[k][x], e->axis[x], temp );
							}
							VectorCopy(temp,tris.verts[k]);
						}
						RenderTriangle(
							e->decals[i].shader, 
							tris.verts[0], 
							tris.verts[1],
							tris.verts[2],
							color, 
							e->decals[i].tris[j].verts[0].st[0],
							e->decals[i].tris[j].verts[0].st[1],
							e->decals[i].tris[j].verts[1].st[0],
							e->decals[i].tris[j].verts[1].st[1],
							e->decals[i].tris[j].verts[2].st[0],
							e->decals[i].tris[j].verts[2].st[1]);
					}
				}
			}
		}
	return 0;
}

int qlua_rrenderfx(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		if(lua_tointeger(L,2) < 1 || lua_tointeger(L,2) >= 512) {
			lua_pushstring(L,"Index out of range (Render Fx).");
			lua_error(L);
			return 1;
		}
		luaentity->renderfx |= lua_tointeger(L,2);
	}
	return 0;
}

int qlua_rsetalways(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TBOOLEAN);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		luaentity->alwaysRender = lua_toboolean(L,2);
		return 1;
	}
	return 0;	
}

int qlua_rsettime(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		luaentity->shaderTime = lua_tonumber(L,2) / 1000.0f;
	}
	return 0;
}

int qlua_rsettraillength(lua_State *L) {
	refEntity_t	*luaentity;
	int count = 0;
	int size2 = 0;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		count = lua_tointeger(L,2);
		size2 = sizeof(luaentity->trailVerts) / sizeof(luaentity->trailVerts[0]);
		if(count > size2) {
			count = size2;
		} else if (count <= 1) {
			count = 2;
		}
		luaentity->numVerts2 = count;
	}
	return 0;
}

int qlua_rgettraillength(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L,luaentity->numVerts2);
		return 1;
	}
	return 0;
}

int qlua_rsettrailfade(lua_State *L) {
	refEntity_t	*luaentity;
	int count = 0;
	int size2 = 0;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		count = lua_tointeger(L,2);
		if(count >= FT_MAX_TRAILFADE_TYPE) {
			count = FT_MAX_TRAILFADE_TYPE-1;
		} else if (count < 0) {
			count = 0;
		}
		luaentity->tfade = count;
	}
	return 0;
}

int qlua_rgettrailfade(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L,luaentity->tfade);
		return 1;
	}
	return 0;
}

int qlua_rsettrailstaticmap(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TBOOLEAN);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		luaentity->staticMap = lua_toboolean(L,2);
	}
	return 0;
}

int qlua_rsettrailmaplength(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		luaentity->trailCoordLength = lua_tonumber(L,2);
		if(luaentity->trailCoordLength <= 0) {
			luaentity->trailCoordLength = .1f;
		}
		return 1;
	}
	return 0;
}

int qlua_rgettrailstaticmap(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		lua_pushboolean(L,luaentity->staticMap);
		return 1;
	}
	return 0;
}

int qlua_rgettrailmaplength(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		lua_pushnumber(L,luaentity->trailCoordLength);
		return 1;
	}
	return 0;
}

int qlua_rgetinfo(lua_State *L) {
	refEntity_t	*luaentity;
	md3Info_t	info;
	int			i;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		trap_R_ModelInfo(luaentity->hModel, &info);
		lua_newtable(L);
		for(i=0; i<info.numSurfaces; i++) {
			lua_pushinteger(L, i+1);
			lua_pushinteger(L, info.numTriangles[i]);
			lua_rawset(L, -3);
		}
		return 1;
	}
	return 0;
}

int qlua_rlerptriangle(lua_State *L) {
	refEntity_t	*luaentity;
	refTri_t	tris;
	vec3_t		v1,v2,normal,temp;
	int			i, x, surfID, id;
	qboolean	raw = qfalse;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TNUMBER);
	luaL_checktype(L,3,LUA_TNUMBER);

	luaentity = lua_torefentity(L,1);
	surfID = lua_tointeger(L,2)-1;
	if(surfID < 0) return 0;

	id = lua_tointeger(L,3)-1;
	if(id < 0) return 0;

	if(lua_gettop(L) > 3) raw = lua_toboolean(L,4);
	if(luaentity != NULL) {
		if(trap_R_LerpTriangle( luaentity->hModel, surfID, id, &tris, luaentity->oldframe, luaentity->frame, 1.0 - luaentity->backlerp )) {
			lua_newtable(L);
			for(i=0; i<3; i++) {
				lua_pushinteger(L, i+1);

				if(!raw) {
					VectorCopy(luaentity->origin,temp);
					for (x=0; x<3; x++ ) {
						VectorMA( temp, tris.verts[i][x], luaentity->axis[x], temp );
					}
					VectorCopy(temp,tris.verts[i]);
				}
				lua_pushvector(L, temp);
				lua_rawset(L, -3);
			}

			VectorSubtract(tris.verts[1],tris.verts[0],v1);
			VectorSubtract(tris.verts[2],tris.verts[0],v2);
			VectorNormalize(v1);
			VectorNormalize(v2);
			CrossProduct(v2,v1,normal);

			lua_pushvector(L,normal);

			return 2;
		}
	}
	return 0;
}

int qlua_rgetdecal(lua_State *L) {
	int i,j,k,x;
	qboolean d = qfalse;
	float size,s2,ts2,tt2;
	refEntity_t	*luaentity;
	vec3_t temp,v1,v2;
	vec3_t pos;
	vec3_t normal,tnormal;
	vec3_t axis[3];
	//vec3_t cmpv;
	refTri_t	tris;
	refTri_t	tris2;
	float map[3][2];
	md3Info_t	info;
	int top0,top1,top2,top3;
	int alloc = 0;
	qboolean filter = qtrue;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TVECTOR);
	luaL_checktype(L,3,LUA_TVECTOR);
	luaL_checktype(L,4,LUA_TVECTOR);
	luaL_checktype(L,5,LUA_TVECTOR);
	luaL_checktype(L,6,LUA_TNUMBER);
	//luaL_checktype(L,7,LUA_TVECTOR);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		lua_tovector(L,2,pos);
		lua_tovector(L,3,axis[0]);
		lua_tovector(L,4,axis[1]);
		lua_tovector(L,5,axis[2]);
		size = lua_tonumber(L,6); s2 = size; //2;
		trap_R_ModelInfo(luaentity->hModel, &info);
		if(lua_type(L,7) == LUA_TBOOLEAN) {
			filter = lua_toboolean(L,7);
		}
		//lua_tovector(L,7,cmpv);

		setupPlane(pos,axis);

		//CG_Printf("Projecting Verts To Size: %f\n",s2);

		lua_newtable(L);
		top0 = lua_gettop(L);
		for(i=0; i<info.numSurfaces; i++) {
			for(j=0; j<info.numTriangles[i]; j++) {
				if(trap_R_LerpTriangle( luaentity->hModel, i, j, &tris, luaentity->oldframe, luaentity->frame, 1.0 - luaentity->backlerp )) {
					d = qfalse;

					for(k=0; k<3; k++) {
						VectorCopy(luaentity->origin,temp);
						for (x=0; x<3; x++ ) {
							VectorMA( temp, tris.verts[k][x], luaentity->axis[x], temp );
						}
						VectorCopy(temp,tris2.verts[k]);
						VectorCopy(temp,tris.verts[k]);
						VectorSubtract(tris.verts[k],p,tris.verts[k]);
						projectRPointOnPlane(tris.verts[k]);
						ts2 = tris.verts[k][0]/s2;
						tt2 = tris.verts[k][1]/s2;
						map[k][0] = (ts2/size)+.5;
						map[k][1] = (tt2/size)+.5;
						if(ts2 > -1 && ts2 < 1 && tt2 > -1 && tt2 < 1) {
							d = qtrue;
						}
					}

					VectorSubtract(tris2.verts[1],tris2.verts[0],v1);
					VectorSubtract(tris2.verts[2],tris2.verts[0],v2);
					VectorNormalize(v1);
					VectorNormalize(v2);
					CrossProduct(v2,v1,tnormal);

					if(d) {
						if(alloc < 512) {
							if(DotProduct(axis[0],tnormal) <= .2 || filter == qfalse) {
								lua_pushinteger(L, alloc+1);
								lua_newtable(L);
								top1 = lua_gettop(L);

								lua_pushstring(L,"verts");
								lua_newtable(L);
								top2 = lua_gettop(L);
								for(k=0; k<3; k++) {
									lua_pushinteger(L,k+1);
										lua_newtable(L);
										top3 = lua_gettop(L);

										lua_pushstring(L,"s");
										lua_pushnumber(L,map[k][0]);
										lua_settable(L,top3);

										lua_pushstring(L,"t");
										lua_pushnumber(L,map[k][1]);
										lua_settable(L,top3);
									lua_settable(L,top2);
								}
								lua_settable(L,top1);

								lua_pushstring(L,"surface");
								lua_pushinteger(L,i);
								lua_settable(L,top1);

								lua_pushstring(L,"triangle");
								lua_pushinteger(L,j);
								lua_settable(L,top1);

								lua_settable(L,top0);
								alloc++;
							}
						} else {
							break;
						}
					}
				} else {
					CG_Printf("Lerp Tris Fail: %i,%i\n",i,j);
				}
			}
		}
	}
	return 1;
}

int qlua_rdecal(lua_State *L) {
	int i,j,k,x;
	int alloc = 0;
	qboolean d = qfalse;
	float size,s2,ts2,tt2;
	refTriMap_t maptris[64];
	refEntity_t	*luaentity;
	refTri_t	tris;
	vec3_t temp,v1,v2;
	vec3_t pos;
	vec3_t normal,tnormal;
	vec3_t axis[3];
	float map[3][2];
	qhandle_t	shader;
	md3Info_t	info;

	luaL_checktype(L,1,LUA_TUSERDATA);
	luaL_checktype(L,2,LUA_TVECTOR);
	luaL_checktype(L,3,LUA_TVECTOR);
	luaL_checktype(L,4,LUA_TVECTOR);
	luaL_checktype(L,5,LUA_TVECTOR);
	luaL_checktype(L,6,LUA_TNUMBER);
	luaL_checktype(L,7,LUA_TNUMBER);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		lua_tovector(L,2,pos);
		lua_tovector(L,3,axis[0]);
		lua_tovector(L,4,axis[1]);
		lua_tovector(L,5,axis[2]);
		size = lua_tonumber(L,6); s2 = size/2;
		shader = lua_tointeger(L,7);
		trap_R_ModelInfo(luaentity->hModel, &info);

		//VectorCopy(normal,axis[0]);
		//PerpendicularVector(axis[1],axis[0]);
		//CrossProduct(axis[0],axis[1],axis[2]);

		setupPlane(pos,axis);

		CG_Printf("Projecting Verts To Size: %f\n",s2);

		for(i=0; i<info.numSurfaces; i++) {
			for(j=0; j<info.numTriangles[i]; j++) {
				if(trap_R_LerpTriangle( luaentity->hModel, i, j, &tris, luaentity->oldframe, luaentity->frame, 1.0 - luaentity->backlerp )) {
					//lua_newtable(L);
					d = qfalse;

					VectorSubtract(tris.verts[1],tris.verts[0],v1);
					VectorSubtract(tris.verts[2],tris.verts[0],v2);
					VectorNormalize(v1);
					VectorNormalize(v2);
					CrossProduct(v2,v1,tnormal);

					for(k=0; k<3; k++) {
						//CG_Printf("[%f,%f,%f]A\n",tris.verts[k][0],tris.verts[k][1],tris.verts[k][2]);
						VectorCopy(luaentity->origin,temp);
						for (x=0; x<3; x++ ) {
							VectorMA( temp, tris.verts[k][x], luaentity->axis[x], temp );
						}
						VectorCopy(temp,tris.verts[k]);

						VectorSubtract(tris.verts[k],p,tris.verts[k]);

						//CG_Printf("[%f,%f,%f]B\n",tris.verts[k][0],tris.verts[k][1],tris.verts[k][2]);
						projectRPointOnPlane(tris.verts[k]);
						ts2 = tris.verts[k][0]/s2;
						tt2 = tris.verts[k][1]/s2;
						map[k][0] = (ts2/size)+.5;
						map[k][1] = (tt2/size)+.5;

						if(ts2 > -1 && ts2 < 1 && tt2 > -1 && tt2 < 1) {
							d = qtrue;
							//CG_Printf("[%i, %i, %i] {%f,%f}\n",i,j,k,ts2,tt2);
							//CG_Printf("DRAW\n");
						}
					}

					if(d) {
						if(alloc < 64) {
							if(DotProduct(axis[0],tnormal) <= .2) {
								for(k=0; k<3; k++) {
									maptris[alloc].verts[k].st[0] = map[k][0];
									maptris[alloc].verts[k].st[1] = map[k][1];
								}
								maptris[alloc].surface = i;
								maptris[alloc].triangle = j;
								alloc++;
							}
						} else {
							break;
						}
					};
				}
			}
		}

		if(alloc > 0) {
			if(luaentity->ndecals < 32) {
				CG_Printf("Added Decal With %i tris\n", alloc);
				//memset(luaentity->decals[luaentity->ndecals].tris, 0, sizeof(refTriMap_t) * alloc);
				
				luaentity->decals[luaentity->ndecals].tris = malloc(sizeof(refTriMap_t) * alloc);
				//memcpy(luaentity->decals[luaentity->ndecals].tris, maptris, sizeof(refTriMap_t) * alloc);
				for(i=0; i<alloc; i++) {
					luaentity->decals[luaentity->ndecals].tris[i].surface = maptris[i].surface;
					luaentity->decals[luaentity->ndecals].tris[i].triangle = maptris[i].triangle;
					for(j=0; j<3; j++) {
						luaentity->decals[luaentity->ndecals].tris[i].verts[j].st[0] = maptris[i].verts[j].st[0];
						luaentity->decals[luaentity->ndecals].tris[i].verts[j].st[1] = maptris[i].verts[j].st[1];
					}
				}
				
				luaentity->decals[luaentity->ndecals].num = alloc;
				luaentity->decals[luaentity->ndecals].shader = shader;
				luaentity->ndecals++;
			}
		}
	}

	return 0;
}

int qlua_rcleardecals(lua_State *L) {
	refEntity_t	*luaentity;
	int n = 0;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		if(lua_type(L,2) == LUA_TNUMBER) {
			n = lua_tointeger(L,2);
			if(n < 0) n = 0;
			luaentity->ndecals -= n;
			if(luaentity->ndecals < 0) luaentity->ndecals = 0;
		} else {
			luaentity->ndecals = 0;
		}
	}

	return 0;
}

int qlua_rsetrenderfx(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		luaentity->renderfx = luaL_optint(L,2,luaentity->renderfx);
	}
	return 0;
}

int qlua_rgetrenderfx(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		lua_pushinteger(L,luaentity->renderfx);
		return 1;
	}
	return 0;
}

int qlua_rsetlightingorigin(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		lua_tovector(L,2,luaentity->lightingOrigin);
	}
	return 0;
}

int qlua_rgetlightingorigin(lua_State *L) {
	refEntity_t	*luaentity;

	luaL_checktype(L,1,LUA_TUSERDATA);

	luaentity = lua_torefentity(L,1);
	if(luaentity != NULL) {
		lua_pushvector(L,luaentity->lightingOrigin);
		return 1;
	}
	return 0;
}

static int Entity_tostring (lua_State *L)
{
  lua_pushfstring(L, "RefEntity: %p", lua_touserdata(L, 1));
  return 1;
}

static int Entity_equal (lua_State *L)
{
	centity_t *e1 = lua_toentity(L,1);
	centity_t *e2 = lua_toentity(L,2);
	if(e1 != NULL && e2 != NULL) {
		lua_pushboolean(L, (e1->currentState.number == e2->currentState.number));
	} else {
		lua_pushboolean(L, 0);
	}
  return 1;
}

static const luaL_reg REntity_methods[] = {
  {"AddRenderFx",		qlua_rrenderfx},
  {"SetLightingOrigin",		qlua_rsetlightingorigin},
  {"GetLightingOrigin",		qlua_rgetlightingorigin},
  {"SetRenderFx",		qlua_rsetrenderfx},
  {"GetRenderFx",		qlua_rgetrenderfx},
  {"GetPos",			qlua_rgetpos},
  {"SetPos",			qlua_rsetpos},
  {"GetPos2",			qlua_rgetpos2},
  {"SetPos2",			qlua_rsetpos2},
  {"GetAxis",			qlua_rgetaxis},
  {"SetAxis",			qlua_rsetaxis},
  {"RotateAroundAxis",	qlua_rrotatearound},
  {"GetAngles",			qlua_rgetangles},
  {"SetAngles",			qlua_rsetangles},
  {"SetShader",			qlua_rsetshader},
  {"GetShader",			qlua_rgetshader},
  {"SetModel",			qlua_rsetmodel},
  {"GetModel",			qlua_rgetmodel},
  {"SetSkin",			qlua_rsetskin},
  {"GetSkin",			qlua_rgetskin},
  {"SetType",			qlua_rsettype},
  {"GetType",			qlua_rgettype},
  {"SetRadius",			qlua_rsetradius},
  {"GetRadius",			qlua_rgetradius},
  {"SetFrame",			qlua_rsetframe},
  {"GetFrame",			qlua_rgetframe},
  {"SetOldFrame",		qlua_rsetoldframe},
  {"GetOldFrame",		qlua_rgetoldframe},
  {"SetLerp",			qlua_rsetlerp},
  {"GetLerp",			qlua_rgetlerp},
  {"SetColor",			qlua_rsetcolor},
  {"GetColor",			qlua_rgetcolor},
  {"SetRotation",		qlua_rsetrotation},
  {"SetTime",			qlua_rsettime},
  {"Scale",				qlua_rsetscale},
  {"Render",			qlua_rrender},
  {"AlwaysRender",		qlua_rsetalways},
  {"PositionOnTag",		qlua_rpositionontag},
  {"SetTrailLength",	qlua_rsettraillength},
  {"GetTrailLength",	qlua_rgettraillength},
  {"SetTrailFade",		qlua_rsettrailfade},
  {"GetTrailFade",		qlua_rgettrailfade},
  {"SetTrailStaticMap", qlua_rsettrailstaticmap},
  {"SetTrailMapLength",	qlua_rsettrailmaplength},
  {"GetTrailStaticMap", qlua_rgettrailstaticmap},
  {"GetTrailMapLength",	qlua_rgettrailmaplength},
  {"GetInfo",			qlua_rgetinfo},
  {"LerpTriangle",		qlua_rlerptriangle},
  //{"AddDecal",		qlua_rdecal},
  {"GetDecal",			qlua_rgetdecal},
  //{"ClearDecals",		qlua_rcleardecals},
  {0,0}
};

static const luaL_reg REntity_meta[] = {
  {"__tostring", Entity_tostring},
  {"__eq", Entity_equal},
  {0, 0}
};

int REntity_register (lua_State *L) {
	luaL_openlib(L, "RefEntity", REntity_methods, 0);

	luaL_newmetatable(L, "RefEntity");

	luaL_openlib(L, 0, REntity_meta, 0);
	lua_pushliteral(L, "__index");
	lua_pushvalue(L, -3);
	lua_rawset(L, -3);
	lua_pushliteral(L, "__metatable");
	lua_pushvalue(L, -3);
	lua_rawset(L, -3);

	lua_setglobal(L,"M_RefEntity");

	lua_pop(L, 1);
	return 1;
}

int qlua_createrefentity (lua_State *L) {
	refEntity_t		ent;
	refEntity_t		*ent2;
	
	if(lua_type(L,1) == LUA_TUSERDATA) {
		ent2 = lua_torefentity(L,1);
		if(ent2 != NULL) {
			memcpy(&ent,ent2,sizeof(refEntity_t));
			lua_pushrefentity(L,&ent);
			return 1;
		}
	}

	memset( &ent, 0, sizeof( ent ) );

	AxisClear( ent.axis );
	ent.lua_scale[0] = 1;
	ent.lua_scale[1] = 1;
	ent.lua_scale[2] = 1;

	ent.trailCoordLength = 1000;

	lua_pushrefentity(L,&ent);
	return 1;
}

void CG_InitLuaREnts(lua_State *L) {
	REntity_register(L);
	//lua_register(L,"GetEntitiesByClass",qlua_getentitiesbyclass);
	//lua_register(L,"GetAllPlayers",qlua_getallplayers);
	lua_register(L,"RefEntity",qlua_createrefentity);
}