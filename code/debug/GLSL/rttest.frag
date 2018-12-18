uniform sampler2D tex0;
uniform float cgtime;
uniform vec3 viewPos;
uniform vec3 viewNormal;

varying vec2 texture_coordinate;
varying vec3 Position;
varying vec4 vertColor;

vec3 HSVtoRGB(vec3 color)
{
    float f,p,q,t, hueRound;
    int hueIndex;
    float hue, saturation, value;
    vec3 result;

    /* just for clarity */
    hue = color.r / 57.3;
    saturation = color.g;
    value = color.b;
    
    float v = value;

    hueRound = floor(hue * 6.0);
    hueIndex = int(hueRound) % 6;
    f = (hue * 6.0) - hueRound;
    p = value * (1.0 - saturation);
    q = value * (1.0 - f*saturation);
    t = value * (1.0 - (1.0 - f)*saturation);

    switch(hueIndex)
    {
        case 0:
            result = vec3(v,t,p);
        break;
        case 1:
            result = vec3(q,v,p);
        break;
        case 2:
            result = vec3(p,v,t);
        break;
        case 3:
            result = vec3(p,q,v);
        break;
        case 4:
            result = vec3(t,p,v);
        break;
        case 5:
            result = vec3(v,p,q);
        break;
    }
    return result;
}

void main(void)
{
	vec2 tc = texture_coordinate;
	vec2 tc2 = texture_coordinate;
	
	float q = 4;
	float x = floor(tc.x*q);
	float y = floor(tc.y*q);
	tc.x = x/q;
	tc.y = y/q;
	
	x = ceil(tc2.x*q);
	y = ceil(tc2.y*q);
	tc2.x = x/q;
	tc2.y = y/q;
	
	vec4 color2 = texture2D(tex0,vec2(tc.x,tc.y));
	vec4 color3 = texture2D(tex0,vec2(tc2.x,tc.y));
	vec4 color4 = texture2D(tex0,vec2(tc2.x,tc2.y));
	vec4 color5 = texture2D(tex0,vec2(tc.x,tc2.y));
	vec4 color = texture2D(tex0,texture_coordinate);
	
	float mx = (texture_coordinate.x - tc.x) * q;
	float my = (texture_coordinate.y - tc.y) * q;
	
	float mx2 = (texture_coordinate.x - tc2.x) * q;
	float my2 = (texture_coordinate.y - tc2.y) * q;
	
	vec4 vcolor1 = mix(color2,color3,mx);
	vec4 vcolor2 = mix(color5,color4,mx);
	
	vec4 fcolor = mix(vcolor1,vcolor2,my);
	fcolor = fcolor * vertColor;
	
	float rbrt = (color.r + color.g + color.b) / 16.0;
	float brt = rbrt * 360.0;
	//brt = 15.0;
	
	brt += rbrt * 360.0;
	brt += cgtime * 10.0;

	color *= vertColor;	
	vec4 ocolor = color;

	
	//color *= rbrt * 12.0;
	color.a = ocolor.a;
	//color = color - vec4(10.0);
	
	float comp = (ocolor.g + ocolor.b)/1.2;
	comp = min(max(ocolor.r - comp,0)*30.0,1.0);
	//color.r = max(0.0,color.r);
	color.rgb = color.rgb * mix(vec3(1.0),vec3(0.5,0.0,0.0),comp);
	
	
	vec3 rgb = HSVtoRGB(vec3(brt,1,1));
	gl_FragColor = vec4(rgb * (1.0 - rbrt),color.a);
	//gl_FragColor = color;
}
