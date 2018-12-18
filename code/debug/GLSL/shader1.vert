uniform float cgtime;
uniform vec3 viewPos;
uniform vec3 viewNormal;
uniform vec2 fov;

varying vec2 texture_coordinate; 
varying vec3 vertPos;
varying vec4 vertColor;
varying vec3 vertNormal;
varying vec3 vertNormalXform;


void main()
{
	vec4 vpos = gl_Vertex;
	vec3 nm = gl_NormalMatrix * gl_Normal;
	
	float dist = length(vpos.xyz - viewPos) / 100.0;
	
	float tsin = sin(cgtime + vpos.x/10.0);
	
	gl_Position = (gl_ModelViewProjectionMatrix * vpos);
	vertPos = (gl_ModelViewMatrix * vpos).xyz;
	//vertPos = (gl_ModelViewProjectionMatrix * vpos).xyz;
	
	vertColor = gl_Color;
	vertNormal = gl_Normal;
	vertNormalXform = gl_NormalMatrix * gl_Normal;
	
	float nfov = fov.x/2.0;
	nfov = ((3.58 - (nfov/25.2))*5.0) - (3.58 + 1.79 + 1.79);
	
	float z = nfov / vertPos.z;
	float x = vertPos.x * z;
	float y = vertPos.y * z;
	
	x *= -0.275;
	y *= -0.368;
	
	x += 0.5;
	y += 0.5;

	//vertPos = vpos.xyz;
	vertPos = (gl_ModelViewProjectionMatrix * vpos).xyz;
	
	texture_coordinate = vec2(x,y); //gl_MultiTexCoord0
}