uniform sampler2D texture;
uniform vec3 viewPos;
uniform vec3 viewNormal;
uniform float cgtime;

varying vec2 texture_coordinate;
varying vec3 Position;
varying vec4 vertColor;
varying vec3 vpos;
varying vec3 normal;

void main()
{
	vec3 dir = normalize(viewPos - vpos);
	float dist = texture_coordinate.x*100.0 + texture_coordinate.y * 100.0;
	float d = dot(vec3(0,0,-1),normal);
	d = d + (0.33 * sin(dist + cgtime*8.0) + 0.5);	
	d *= 10.0;


	vec4 texcolor = texture2D(texture, texture_coordinate + vec2(normal.x + d/10.0,-d/10.0));
	vec4 texcolor2 = texture2D(texture, texture_coordinate * 4.2);
	vec4 color = texcolor;
		
	vec4 cx = color*d;
	vec4 cy = ((texcolor2*2.0)-1.0) / 2.0;
	cy.a = (-d + 0.2) / 1.4;
	
	cx.r = max(0,cx.r);
	cx.g = max(0,cx.g);
	cx.b = max(0,cx.b);
	cx.a = max(0,cx.a);
	
	cy.r = max(0,cy.r);
	cy.g = max(0,cy.g);
	cy.b = max(0,cy.b);
	cy.a = max(0,cy.a);
	
	
	
	gl_FragColor = (cx) * vertColor;
}