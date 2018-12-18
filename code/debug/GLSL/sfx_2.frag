uniform sampler2D colorMap;

varying vec2 texture_coordinate;
varying vec3 Position;
varying vec4 vertColor;
uniform float cgtime;


float rand(vec2 co) {
        return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec4 bloom(vec2 t, float a) {
	vec4 plain0 = texture2D(colorMap, t + vec2(0,1)*a);
	plain0 += texture2D(colorMap, t + vec2(0,-1)*a);
	plain0 += texture2D(colorMap, t + vec2(1,0)*a);
	plain0 += texture2D(colorMap, t + vec2(-1,0)*a);
	
	plain0 += texture2D(colorMap, t + vec2(-1,-1)*a);
	plain0 += texture2D(colorMap, t + vec2(1,1)*a);
	plain0 += texture2D(colorMap, t + vec2(-1,1)*a);
	plain0 += texture2D(colorMap, t + vec2(1,-1)*a);
	
	plain0 = plain0 * plain0;
	
	return plain0 / 8.0;
}

void main(void)
{
	float WATER_TYPE_WATER = 0.0;
	float WATER_TYPE_QUAD = .5;
	float WATER_TYPE_WATERANDQUAD = 1;
	
	float type = vertColor.b;

	float amount = vertColor.a;
	float amount2 = amount;
	if(type > .4 && type < .6) {
		amount = 0.0;
	}
	
	vec2 c = vec2(0.5 + (vertColor.r - 0.5),0.5 + (vertColor.g - 0.5));
	vec2 tc = texture_coordinate;
	vec2 tc2 = texture_coordinate;
	tc.y = tc.y + 1;
	tc2.y = tc2.y + 1;
	
	vec2 d = (c - tc);
	float dist = sqrt(d.x*d.x + d.y*d.y);
	
	float x = tc.x * 43.0 + sin(cgtime + tc.x + dist * 10.0) * 2.0;
	float y = tc.y * 45.0 + cos(cgtime + tc.y + dist*10.0) * 2.0;
	float r = cos(rand(tc) / 2.0);
	r = r * 10.0;
	float dists = dist * 2.0;
	
	float mx = (cos(r + y + cgtime*5.0)/220.0);
	float my = (sin(r + x + cgtime*5.0)/220.0);
	
	tc.x = tc.x + mx * (1-dists/2.0) * amount;
	tc.y = tc.y + my * (1-dists/2.0) * amount;
	
	//tc = tc + ((d/2.0) * dist*2.5) * amount / 2.0;
	//tc = tc - (d/1.8) * amount / 2.0;
	
	if(type > .4) {
		tc = tc + ((c-tc)* (sin(cgtime + dists*3.0) / 8.0) * (1-dists)) * amount2;
	}
	
	if(tc.x < 0.01) tc.x = 0.01;
	if(tc.x > 0.99) tc.x = 0.99;
	if(tc.y < 0.01) tc.y = 0.01;
	if(tc.y > 0.99) tc.y = 0.99;
	
	vec4 color = texture2D(colorMap, tc);
	if(type > .4) {
		int i;
		color = color / (1.0 + 0.4 * amount2);
		for(i=0; i<12; i++) {
			float ix = float(i);
			tc = tc + ((d/2.0) * dist*2.5) * amount2 / 12.0;
			vec4 m = texture2D(colorMap, tc);
			float brt = (m.r + m.g + m.b);
			//if(brt < 0.8 + (sin(brt*85.0 + cgtime * 10.0) + 1.0) / 5.0) {
				//m = m * -1.0;
			//}
			
			m = m * (0.5 + ((sin(brt*15.0 + cgtime * 10.0) + 1.0) * dists)) * (dists + 0.3);
			
			m.r = m.r / (1.0 + (sin(0.0 + cgtime*5.0 - ix/2.0) + 1.0) * 14.0);
			m.g = m.g / (1.0 + (cos(0.0 + cgtime*5.0 - ix/2.0) + 1.0) * 14.0);
			color = color + m * amount2 / 10.0;
		}
	}
	
	tc2 += vec2(sin(cgtime + y/2.0)/200.0,sin(cgtime - x/2.0)/200.0)*(dists) * 2.0;
	
	if(tc2.x < 0.01) tc2.x = 0.01;
	if(tc2.x > 0.99) tc2.x = 0.99;
	if(tc2.y < 0.01) tc2.y = 0.01;
	if(tc2.y > 0.99) tc2.y = 0.99;
	
	vec4 plain0 = bloom(tc2,.0065);
	vec4 plain1 = bloom(tc2,.023);
	plain0 += bloom(tc2,.01) / 2.0;
	plain0 += bloom(tc2,.02) / 4.0;
	plain0 /= 12.0;
	
	//plain0 += (plain1*plain1*plain1*plain1) / 128.0;
	
	gl_FragColor = color + plain0 * amount2;
}