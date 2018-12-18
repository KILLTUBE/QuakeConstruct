#include "cg_local.h"

#define	PANEL_ARRAY_SIZE 128

typedef struct panel_s {
	struct panel_s		*parent;
	struct panel_s		*children[PANEL_ARRAY_SIZE];
	int			num_panels;

	float		x,y,w,h;
	int			depth;
	int			persistantID;
	char		classname[128];

	int			lua_table;

	vec4_t		bgcolor, fgcolor;

	/*int			lua_draw;
	int			lua_think;*/
	
	qboolean	visible;
	qboolean	enabled;
	qboolean	removed;
	qboolean	noGC;
	qboolean	mouseover;
	qboolean	mousedown;
	qboolean	nodraw;
} panel_t;

typedef enum {
	UIM_PRESS,
	UIM_RELEASE,
	UIM_MOVE,
} ui_mouseevent_t;

void lua_pushpanel(lua_State *L, panel_t *panel);
panel_t *lua_topanel(lua_State *L, int i);
int Panel_register (lua_State *L);
void UI_FocusPanel(panel_t *panel);
void UI_RemovePanel(panel_t *panel);
void UI_GetLocalPosition(panel_t *panel, vec3_t vec);
panel_t *UI_GetPanelByID(int id);
panel_t *UI_GetBasePanel();
qboolean UI_InsidePanel(panel_t *panel, float x, float y);