uniform sampler2D texture;

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
	vec4 texcolor = texture2D(texture, texture_coordinate);
	vec4 color = texcolor * vertColor;
	
	float bright = (color.r + color.g + color.b) / 3.0;
	bright = 1.0 - bright;
	
	vec4 overbright = vec4(bright,bright,bright,0.0);
	overbright = overbright * (1.0 - overbright);
	vec4 dim = vec4(0.4,0.4,0.7,1.0) - overbright * 1.5;
	vec4 highlights = texcolor * vertColor * dim;
	highlights = highlights * (1.0-highlights);
	highlights.a = 0.0;
	
	gl_FragColor = vertColor;
	//gl_FragColor = vec4(vertNormalXform.x,vertNormalXform.y,vertNormalXform.z,1.0);
}