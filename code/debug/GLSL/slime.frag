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

	mx += sin(cgtime + cos(texture_coordinate.y*1.0)*1.0)/8.0;
	my += cos(cgtime + sin(texture_coordinate.x*1.0)*1.0)/8.0;
	
	float dx = mx;
	float dy = my;
	
	vec4 tex = texture2D(texture0,texture_coordinate);
	vec4 distort = texture2D(texture0,(texture_coordinate / 10.0) + vec2(dx,dy));
	
	dx += cgtime/6.0;
	dy -= cgtime/6.0;
	
	vec4 distort2 = texture2D(texture0,(texture_coordinate / 2.0) + vec2(dx,dy));
	
	float omx = sin(cgtime/8.0 + (distort.r + distort2.g)/5.0)/2.0;
	float omy = cos(cgtime/8.0 + (distort.g + distort2.r)/5.0)/2.0;
	
	vec4 tex2 = texture2D(texture0,(texture_coordinate / 2.0) + vec2(mx+omx,my+omy));
	
	gl_FragColor = mix(tex2 * vertColor,tex,0.1);
	
	gl_FragColor.r = mix(gl_FragColor.r,1.0,1.0 - tex.a);
	gl_FragColor.g = mix(gl_FragColor.g,1.0,1.0 - tex.a);
	gl_FragColor.b = mix(gl_FragColor.b,1.0,1.0 - tex.a);
	//gl_FragColor.a = mix(gl_FragColor.a,1.0,1.0 - tex.a);
	
	gl_FragColor.rgb -= mx/5.0;
	gl_FragColor.rgb -= my/5.0;
	gl_FragColor.a = tex.a;
	
	
	//gl_FragColor.r += 1.0 - tex.a*1.2;
	//gl_FragColor.g += 1.0 - tex.a*1.2;
	//gl_FragColor.b += 1.0 - tex.a*1.2;
}