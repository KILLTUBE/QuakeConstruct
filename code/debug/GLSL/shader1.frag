uniform sampler2D texture0;
uniform float cgtime;
uniform vec3 viewPos;
uniform vec3 viewNormal;

varying vec2 texture_coordinate;
varying vec3 vertPos;
varying vec4 vertColor;
varying vec3 vertNormal;
varying vec3 vertNormalXform;

void main()
{
	float offx = texture_coordinate.x*180.0;
	float offy = texture_coordinate.y*180.0;
	
	float dp = dot(vec3(1.0,0.0,0.0), vertNormalXform);
	offx = dp * 20.0;
	
	dp = dot(vec3(0.0,1.0,0.0), vertNormalXform);
	offy = dp * 20.0;
	
	vec2 tc = vec2(0,0);
	tc.x = texture_coordinate.x + sin(cgtime + offx)/100.0;
	tc.y = texture_coordinate.y + sin(cgtime + offy)/100.0;
	tc.x += offx/1200.0;
	tc.y += offy/1200.0;
	
	vec4 tex = texture2D(texture0,tc);

	float mdist = vertPos.z; //100.0 - length(vertPos - viewPos);
	float dist = mdist / 10.0;
	dist -= 2.0;
	dist = clamp(dist,0.0,1.0);
	
	
	float dist2 = mdist / 400.0;
	dist2 -= 0.3;
	dist2 = clamp(dist2,0.0,1.0);
	dist2 = 1.0 - dist2;
	
	float r = 1.0 - dist;
	
	gl_FragColor = tex * vertColor;
	//gl_FragColor.a = 1.0;
	//gl_FragColor.r *= dist;
	//gl_FragColor.g *= dist;
	//gl_FragColor.b *= dist;
	gl_FragColor.a = dist*dist2;
	
	mdist /= 5.0;

}