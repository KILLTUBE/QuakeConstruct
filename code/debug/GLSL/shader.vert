uniform float cgtime;
uniform vec3 viewPos;
uniform vec3 viewNormal;

varying vec2 texture_coordinate; 
varying vec3 Position;
varying vec4 vertColor;
varying vec3 vertNormal;
varying vec3 vertNormalXform;

void main()
{
	vec4 vpos = gl_Vertex;
	
	float tsin = sin(cgtime + vpos.z/10.0);
	//vpos.y = vpos.y + tsin*10.0;
	
	gl_Position = (gl_ModelViewProjectionMatrix * vpos);
	Position = gl_Position.xyz;
	
	vertColor = gl_Color;
	vertNormal = gl_Normal;
	vertNormalXform = gl_NormalMatrix * gl_Normal;
	
	texture_coordinate = vec2(gl_MultiTexCoord0);
}