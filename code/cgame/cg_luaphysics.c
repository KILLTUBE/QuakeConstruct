#include "cg_local.h"
#include "Bullet-C-Api.h"

//plPhysicsSdkHandle sdk;
plDynamicsWorldHandle world;

float worldscale = 0.1;

int qlua_phnewmodelbody(lua_State *L) {
	int mass;
	int i,j,k;
	md3Info_t info;
	vec3_t center;
	vec3_t scale;
	qhandle_t model;
	refTri_t tris;
	plCollisionShapeHandle shape;
	plRigidBodyHandle body;

	VectorSet(scale,1,1,1);
	VectorClear(center);

	model = lua_tointeger(L,1);
	mass = lua_tointeger(L,2);
	if(IsVector(L,3)) {
		lua_tovector(L,3,scale);
	}
	if(IsVector(L,4)) {
		lua_tovector(L,4,center);
	}

	VectorScale(scale,worldscale,scale);

	if(model == 0) return 0;

	shape = plNewConvexHullShape();
	
	trap_R_ModelInfo(model,&info);

	for(i=0; i<info.numSurfaces; i++) {
		for(j=0; j<info.numTriangles[i]; j++) {
			trap_R_LerpTriangle(model,i,j,&tris,0,0,0);
			for(k=0; k<1; k++) {
				plAddVertex(shape,
					(tris.verts[k][0] - center[0])*scale[0],
					(tris.verts[k][1] - center[1])*scale[1],
					(tris.verts[k][2] - center[2])*scale[2]);
			}
		}
	}

	body = plCreateRigidBody(NULL,mass,shape);
	if(body == NULL) return 0;

	plAddRigidBody(world,body);

	lua_pushlightuserdata(L,body);

	return 1;
}

int qlua_phnewbody(lua_State *L) {
	vec3_t size;
	plCollisionShapeHandle shape;
	plRigidBodyHandle body;
	//plRigidBodyHandle *ptr;

	int mass;

	lua_tovector(L,1,size);
	mass = lua_tointeger(L,2);

	VectorScale(size,worldscale,size);

	shape = plNewBoxShape(size[0],size[1],size[2]);
	body = plCreateRigidBody(NULL,mass,shape);

	plAddRigidBody(world,body);

	lua_pushlightuserdata(L,body);
	//ptr = (plRigidBodyHandle*)lua_newuserdata(L, sizeof(plRigidBodyHandle));
	//memcpy(ptr,body,sizeof(plRigidBodyHandle));

	return 1;
}

int qlua_phremoverigidbody(lua_State *L) {
	plRigidBodyHandle body = lua_touserdata(L,1);

	if(body == NULL) return 0;

	plRemoveRigidBody(world,body);
	plDeleteRigidBody(body);
	return 0;
}

int qlua_phgetpos(lua_State *L) {
	vec3_t vec;
	plVector3 pos;
	plRigidBodyHandle body = lua_touserdata(L,1);
	if(body == NULL) return 0;

	plGetPosition(body,pos);

	vec[0] = pos[0];
	vec[1] = pos[1];
	vec[2] = pos[2];

	VectorScale(vec,1.0f/worldscale,vec);

	lua_pushvector(L,vec);
	return 1;
}

int qlua_phsetpos(lua_State *L) {
	vec3_t vec;
	plVector3 pos;
	plRigidBodyHandle body = lua_touserdata(L,1);
	lua_tovector(L,2,vec);

	VectorScale(vec,worldscale,vec);

	if(body == NULL) return 0;

	pos[0] = vec[0];
	pos[1] = vec[1];
	pos[2] = vec[2];

	plSetPosition(body,pos);
	return 0;
}

int qlua_phgetangles(lua_State *L) {
	vec3_t f,r,u;
	plQuaternion q;
	plRigidBodyHandle body = lua_touserdata(L,1);
	if(body == NULL) return 0;

	//plGetOrientation(body,q);
	plGetAxis(body,f,r,u);

//	trap_QuatToAngles(orientation,angles);

	lua_pushvector(L,f);
	lua_pushvector(L,r);
	lua_pushvector(L,u);
	return 3;
}

int qlua_phsetangles(lua_State *L) {
	vec3_t angles;

	plQuaternion orientation;
	plRigidBodyHandle body = lua_touserdata(L,1);
	if(body == NULL) return 0;

	VectorClear(angles);
	lua_tovector(L,2,angles);

	trap_AnglesToQuat(angles,orientation);

	plSetOrientation(body,orientation);

	return 0;
}

int qlua_phapplyimpulse(lua_State *L) {
	vec3_t relpos;
	vec3_t impulse;
	plRigidBodyHandle body = lua_touserdata(L,1);
	if(body == NULL) return 0;

	VectorClear(relpos);

	if(!IsVector(L,2)) return 0;
	lua_tovector(L,2,impulse);
	if(IsVector(L,3)) {
		lua_tovector(L,3,relpos);
	}

	plApplyImpulse(body,impulse,relpos);
	return 0;
}

int qlua_phapplytorque(lua_State *L) {
	vec3_t torque;
	plRigidBodyHandle body = lua_touserdata(L,1);
	if(body == NULL) return 0;

	if(!IsVector(L,2)) return 0;
	lua_tovector(L,2,torque);

	plApplyTorque(body,torque);
	return 0;
}

int qlua_phtraceline(lua_State *L) {
	float fraction;
	vec3_t start,end;
	vec3_t rpos,rnormal;
	plRigidBodyHandle body = NULL;
	
	lua_tovector(L,1,start);
	lua_tovector(L,2,end);

	VectorScale(start,worldscale,start);
	VectorScale(end,worldscale,end);
	
	plRayTrace(world,start,end,rpos,rnormal,&body,&fraction);

	VectorScale(rpos,1.0f/worldscale,rpos);

	lua_pushvector(L,rpos);
	lua_pushvector(L,rnormal);
	if(body != NULL) {
		lua_pushlightuserdata(L,body);
		return 3;
	}
	return 2;
}

int qlua_phsimulate(lua_State *L) {
	float step;

	step = lua_tonumber(L,1);

	//plStepSimulation(world,step);

	return 0;
}

int qlua_phworldscale(lua_State *L) {
	vec3_t grav;
	worldscale = lua_tonumber(L,1);

	grav[0] = 0.0f;
	grav[1] = 0.0f;
	grav[2] = -DEFAULT_GRAVITY * worldscale;

	plSetGravity(world,grav);
	return 0;
}

int qlua_phsetrestitution(lua_State *L) {
	float r;
	plRigidBodyHandle body = lua_touserdata(L,1);
	if(body == NULL) return 0;

	luaL_checknumber(L,2);
	r = lua_tonumber(L,2);

	plSetRestitution(body,r);
	return 0;
}

int qlua_phgetworldscale(lua_State *L) {
	lua_pushnumber(L,worldscale);
	return 1;
}

static const luaL_reg Physics_methods[] = {
  {"ApplyImpulse",		qlua_phapplyimpulse},
  {"ApplyTorque",		qlua_phapplytorque},
  {"TraceLine",			qlua_phtraceline},
  {"SetAngles",			qlua_phsetangles},
  {"GetAngles",			qlua_phgetangles},
  {"SetPos",			qlua_phsetpos},
  {"GetPos",			qlua_phgetpos},
  {"SetRestitution",	qlua_phsetrestitution},
  {"NewBoxRigidBody",	qlua_phnewbody},
  {"NewModelRigidBody",	qlua_phnewmodelbody},
  {"RemoveRigidBody",	qlua_phremoverigidbody},
  {"Simulate",			qlua_phsimulate},
  {"SetWorldScale",		qlua_phworldscale},
  {"GetWorldScale",		qlua_phgetworldscale},
  {0,0}
};

void CG_InitLuaPhysics(lua_State *L) {
	plVector3 grav;
/*
	sdk = plNewBulletSdk();
	world = plCreateDynamicsWorld(sdk);
*/

	world = (plDynamicsWorldHandle) trap_CM_GetPhysicsWorld();
	if(world != NULL) {
		grav[0] = 0.0f;
		grav[1] = 0.0f;
		grav[2] = -DEFAULT_GRAVITY * worldscale;

		plSetGravity(world,grav);

		luaL_openlib(L, "phys", Physics_methods, 0);
	}
}

void CG_ShutdownLuaPhysics() {
/*	if(world != NULL && sdk != NULL) {
		plDeleteDynamicsWorld(world);
		plDeletePhysicsSdk(sdk);
	}
*/
}