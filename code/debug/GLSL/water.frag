uniform sampler2D texture0;
uniform float cgtime;
uniform vec3 viewPos;
uniform vec3 viewNormal;

varying vec2 texture_coordinate;
varying vec3 Position;
varying vec4 vertColor;

void main()
{
	float mx = 0.25;
	float my = 0.25;

	mx += sin(cgtime)*0.1;
	my += cos(cgtime)*0.1;
	
	float dx = mx + sin(cos(texture_coordinate.y))*10.0;
	float dy = my + cos(sin(texture_coordinate.x))*10.0;
	
	vec4 tex = texture2D(texture0,texture_coordinate * vec2(mx+dx,my+dy));
	
	tex = texture2D(texture0,texture_coordinate + vec2(mx*tex.r,my*tex.g));
	
	gl_FragColor.g = tex.g;
}