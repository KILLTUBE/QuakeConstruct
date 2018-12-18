uniform sampler2D texture_0;
uniform sampler2D texture_1;
uniform float cgtime;
uniform vec3 viewPos;
uniform vec3 viewNormal;

varying vec2 texture_coordinate;
varying vec3 Position;
varying vec4 vertColor;

void main()
{
	vec4 tex = texture2D(texture_0,texture_coordinate);
	vec4 tex2 = texture2D(texture_1,texture_coordinate);
	
	//gl_FragColor = ((tex + tex2 + tex3) / 3.0) * vertColor;
	gl_FragColor.r = tex.r;
	gl_FragColor.g = tex2.g;
	gl_FragColor.b = tex2.b;
	gl_FragColor.a = tex.a;
}