typedef struct {
	vec3_t		origin;
	vec3_t		right;
	vec3_t		down;
	vec3_t		forward;
	vec3_t		rn, dn;
	float		rd2, dd2, depth;
} coordRemap_t;

coordRemap_t *GetCoordRemap(void);
void BuildCoordRemap(coordRemap_t *in);
void RemapCoords(float x, float y, vec3_t v, coordRemap_t in);
void RotatedCoords(float x, float y, float r, float ox, float oy, float ow, float oh, vec3_t v, coordRemap_t in);
void DrawRotatedRect(float x, float y, float w, float h, float s, float t, float s2, float t2, float rot, qhandle_t shader);
void DrawRect(float x, float y, float w, float h, float s, float t, float s2, float t2, qhandle_t shader);
void Start2D3D(vec3_t origin, vec3_t right, vec3_t down, vec3_t forward);
void End2D3D(void);