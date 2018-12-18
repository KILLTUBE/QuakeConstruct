uniform vec3 viewPos;
uniform vec3 viewNormal;

varying vec2 texture_coordinate; 
varying vec3 Position;
varying vec4 vertColor;
varying vec3 vpos;
varying vec3 normal;


void main()
{
	gl_Position = (gl_ModelViewProjectionMatrix * gl_Vertex);
	Position = gl_Position.xyz;
	
	vpos = gl_Vertex.xyz;
	normal = gl_NormalMatrix * gl_Normal;
	
	vertColor = gl_Color;
	
	texture_coordinate = vec2(gl_MultiTexCoord0);
}