uniform sampler2D texture;
uniform float cgtime;
uniform vec3 viewPos;
uniform vec3 viewNormal;

varying vec2 texture_coordinate;
varying vec3 Position;
varying vec4 vertColor;

void main()
{
	vec2 tc = texture_coordinate;
	vec2 fc = gl_FragCoord.xy;
	
	vec4 texcolor = texture2D(texture, tc);
	vec4 texcolor2 = texture2D(texture, tc * 4.0);

	vec4 color = texcolor;
	
	color.rgb = texcolor2.rgb;

	color.r = color.r * vertColor.r;
	color.g = color.g * vertColor.g;
	color.b = color.b * vertColor.b;
	
	if(color.a > (1.0 - vertColor.a)) {
		float d = (1.0 - vertColor.a) - color.a;
		float sx = sin(tc.x*30.0 + tc.y*40.0 + cgtime * 2.0) * -13.0;
		sx += 13.0;
		
		d = (d * (20.0 + sx)) + 1.0;

		color.a = 0.0;
		color.r = 1.0 + (color.r - 1.0) * d;
		color.g = 1.0 + (color.g - 1.0) * d;
		color.b = 1.0 + (color.b - 1.0) * d;
	} else {

	}
	
	gl_FragColor = color;
}