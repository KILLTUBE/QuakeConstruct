#include "cg_local.h"
#include "cg_2d3d.h"

qboolean		tdraw = qfalse;
coordRemap_t	remap;

void PrintVector(vec3_t v, const char *str) {
	CG_Printf("    %s: %f, %f, %f\n",str,v[0],v[1],v[2]);
}

void PrintCoordRemap(coordRemap_t in) {
	CG_Printf("^2Coordinate Remap:\n");
	PrintVector(in.origin,"origin");
	PrintVector(in.right,"right");
	PrintVector(in.down,"down");
	CG_Printf("    %s: %f","rd2",in.rd2);
	CG_Printf("    %s: %f\n","dd2",in.dd2);
	PrintVector(in.rn,"rn");
	PrintVector(in.dn,"dn");
}

void BuildCoordRemap(coordRemap_t *in) {
	vec3_t rd, dd;

	VectorSubtract(in->right,in->origin,rd);
	VectorSubtract(in->down,in->origin,dd);

	VectorNormalize2(rd,in->rn);
	VectorNormalize2(dd,in->dn);

	in->rd2 = VectorLength(rd);
	in->dd2 = VectorLength(dd);

	//CG_Printf("Built Remap\n");
	//PrintCoordRemap(*in);
}

void RemapCoords(float x, float y, vec3_t v, coordRemap_t in) {
	vec3_t tmp;
	VectorMA(in.origin,((x) / 640) * in.rd2,in.rn,tmp);
	VectorMA(tmp,((y) / 480) * in.dd2,in.dn,v);
	VectorMA(v,in.depth,in.forward,v);
}

void RotatedCoords(float x, float y, float r, float ox, float oy, float ow, float oh, vec3_t v, coordRemap_t in) {
	float tx,ty;
	if(r != 0) {
		r = r / 57.3;
	}

	x *= ow/2;
	y *= oh/2;

	tx = x;
	ty = y;

	x = (cos(r)*tx) - (sin(r)*ty);
	y = (sin(r)*tx) + (cos(r)*ty);

	x = x + ox;
	y = y + oy;

	RemapCoords(x,y,v,in);
}

void DrawRotatedRect(float x, float y, float w, float h, float s, float t, float s2, float t2, float rot, qhandle_t shader) {
	vec3_t v1, v2, v3, v4;
	vec4_t lastcolor;
	if(!tdraw) {
		CG_AdjustFrom640( &x, &y, &w, &h );
		trap_R_DrawTransformPic( x, y, w, h, s, t, s2, t2, rot, shader );
	} else {
		RotatedCoords(-1,-1,rot,x,y,w,h,v1,remap);
		RotatedCoords(1,-1,rot,x,y,w,h,v2,remap);
		RotatedCoords(1,1,rot,x,y,w,h,v3,remap);
		RotatedCoords(-1,1,rot,x,y,w,h,v4,remap);

		trap_R_GetColor(lastcolor);
		RenderQuad(shader,v1,v2,v3,v4,lastcolor,s,t,s2,t2);
		remap.depth += 0.01f;
	}
}

void DrawRect(float x, float y, float w, float h, float s, float t, float s2, float t2, qhandle_t shader) {
	vec3_t v1, v2, v3, v4;
	vec4_t lastcolor;
	if(!tdraw) {
		CG_AdjustFrom640( &x, &y, &w, &h );
		trap_R_DrawStretchPic( x, y, w, h, s, t, s2, t2, shader );
	} else {
		RemapCoords(x,y,v1,remap);
		RemapCoords(x+w,y,v2,remap);
		RemapCoords(x+w,y+h,v3,remap);
		RemapCoords(x,y+h,v4,remap);

		/*CG_Printf("^2Remap Rect: ^7%f, %f, %f, %f:\n",x,y,w,h);
		PrintVector(v1,"v1");
		PrintVector(v2,"v2");
		PrintVector(v3,"v3");
		PrintVector(v4,"v4");*/

		trap_R_GetColor(lastcolor);
		RenderQuad(shader,v1,v2,v3,v4,lastcolor,s,t,s2,t2);
		remap.depth += 0.01f;
	}
}

coordRemap_t *GetCoordRemap(void) {
	return &remap;
}

void Start2D3D(vec3_t origin, vec3_t right, vec3_t down, vec3_t forward) {
	VectorCopy(origin,remap.origin);
	VectorCopy(right,remap.right);
	VectorCopy(down,remap.down);
	VectorCopy(forward,remap.forward);

	remap.depth = 0.01f;

	tdraw = qtrue;

	BuildCoordRemap(&remap);
	trap_R_Begin2D();
}

void End2D3D(void) {
	tdraw = qfalse;
	trap_R_End2D();
}