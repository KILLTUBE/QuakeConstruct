uniform float cgtime;
uniform vec3 viewPos;
uniform vec3 viewNormal;

varying vec2 texture_coordinate; 
varying vec3 Position;
varying vec4 vertColor;


void main()
{
	vec4 vpos = gl_Vertex;
	vec3 nm = gl_NormalMatrix * gl_Normal;
	
	float cgt = cgtime * 410.0;
	float tsin = sin((cgt + vpos.x*150.0)/100.0)*15.0;
	float tcos = cos((cgt + vpos.y*150.0)/100.0)*15.0;
	vpos.z += (tsin + tcos)/20.0;
	
	gl_Position = (gl_ModelViewProjectionMatrix * vpos);
	Position = gl_Position.xyz;
	
	vertColor = gl_Color;
	
	texture_coordinate = vec2(gl_MultiTexCoord0);
}