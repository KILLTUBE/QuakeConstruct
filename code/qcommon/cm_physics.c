#include "cm_local.h"
#include "Bullet-C-Api.h"

plPhysicsSdkHandle sdk = NULL;
plDynamicsWorldHandle world = NULL;

void CM_InitPhysics()
{
	clipHandle_t clip;
	cmodel_t *cmodel;
	cLeaf_t leaf;
	int j,k,i;
	int			brushnum;
	cbrush_t	*brush;
	cbrushside_t	*side;
	plPlane		planes[32];
	plCollisionShapeHandle shape;
	plRigidBodyHandle body;
	plVector3	pos;

	if(world != NULL) CM_ShutdownPhysics();

	sdk = plNewBulletSdk();
	world = plCreateDynamicsWorld(sdk);

	clip = CM_InlineModel(0);
	cmodel = CM_ClipHandleToModel(clip);

	//leaf = cmodel->leaf;
	Com_Printf("Init Physics: %i leafs. \n",cm.numLeafs);

	for (j=0; j<cm.numLeafs; j++) {
		leaf = cm.leafs[j];

		Com_Printf("\n----\n--------ADDING BRUSHES[(%i) %i/%i]--------\n----\n", leaf.numLeafBrushes, j, cm.numLeafs);

		for (k=0 ; k<leaf.numLeafBrushes ; k++) {
			brushnum = cm.leafbrushes[leaf.firstLeafBrush+k];
			brush = &cm.brushes[brushnum];
		
			if(brush->numsides > 32) {
				Com_Error(ERR_DROP, "Brush #Sides Out Of Range %i\n", brush->numsides);
			}
			for (i=0; i<brush->numsides; i++) {
				side = brush->sides+i;
				planes[i][0] = side->plane->normal[0];
				planes[i][1] = side->plane->normal[1];
				planes[i][2] = side->plane->normal[2];
				planes[i][3] = side->plane->dist;
			}
			shape = plNewConvexHullShape();
			plInitBrush(shape,planes,brush->numsides,0.1f);

			body = plCreateRigidBody(NULL,0,shape);

			if(body == NULL) {
				Com_Error(ERR_DROP, "Unable to create shape for brush: %i,%i\n", k,i);
				return;
			}

			pos[0] = 0;
			pos[1] = 0;
			pos[2] = 0;
			plSetPosition(body, pos);
			plSetRestitution(body, 1);

			//Com_Printf("Added Brush: %i\n",k);

			plAddRigidBody(world,body);
		}
	}
}

void CM_ShutdownPhysics()
{
	if(world != NULL && sdk != NULL) {
		plDeleteDynamicsWorld(world);
		plDeletePhysicsSdk(sdk);
		world = NULL;
		sdk = NULL;
	}
}

void CM_SimulatePhysics(float step) {
	if(world != NULL && sdk != NULL) {
		plStepSimulation(world,step);
	}
}

qhandle_t CM_GetPhysicsWorld()
{
	return world;
}