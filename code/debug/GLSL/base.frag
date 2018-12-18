uniform sampler2D texture;
uniform vec3 viewPos;
uniform vec3 viewNormal;

varying vec2 texture_coordinate;
varying vec3 Position;
varying vec4 vertColor;

void main()
{
	vec4 texcolor = texture2D(texture, texture_coordinate);
	vec4 color = texcolor * vertColor;
	
	gl_FragColor = color;
}