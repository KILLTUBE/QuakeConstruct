uniform sampler2D colorMap;

varying vec2 texture_coordinate;
varying vec3 Position;
varying vec4 vertColor;
uniform float cgtime;

float rand(vec2 co) {
        return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float noise(vec2 co) {
        return rand(floor(co * 128.0));
}


void main(void)
{
	vec2 tc = texture_coordinate;
	//vec2 tc = Position.xy;
	float off = rand(texture_coordinate*200);
	tc.x = Position.x;
	tc.y = Position.y;
	
	float x = tc.x*20 + off*50;
	float y = tc.y*20 - cgtime*20;
	float px = floor(x);
	float py = floor(y);
	float nx = ceil(x);
	float ny = ceil(y);
	
	float dx = 1.0 - (nx - x);
	float dy = 1.0 - (ny - y);

	
	float n1 = rand(vec2(px,py));
	float n2 = rand(vec2(nx,py));
	float n3 = rand(vec2(nx,ny));
	float n4 = rand(vec2(px,ny));
	
	float nx1 = n1 + (n2 - n1) * dx;
	float nx2 = n3 + (n4 - n3) * (1.0 - dx);
	float n = nx1 + (nx2 - nx1) * dy;
	
	vec4 color = texture2D(colorMap, texture_coordinate) * vertColor;
	vec4 c1 = color * vec4(n*n*6);
	vec4 c2 = color;
	
	gl_FragColor = c1 + (c2 - c1) * vertColor.a; //vec4(1.0,n+vertColor.a,n+vertColor.a,1);
}