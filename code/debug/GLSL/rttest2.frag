#define KERNEL_SIZE 9

varying vec2 texture_coordinate;
varying vec3 Position;
varying vec4 vertColor;

// Gaussian kernel
// 1 2 1
// 2 4 2
// 1 2 1	
float kernel[KERNEL_SIZE];

uniform sampler2D colorMap;
//uniform float width;
//uniform float height;

float step_w = 1.0/2;
float step_h = 1.0/2;

vec2 offset[KERNEL_SIZE];

void main(void)
{
   int i = 0;
   vec4 sum = vec4(0.0);
   
   offset[0] = vec2(-step_w, -step_h);
   offset[1] = vec2(0.0, -step_h);
   offset[2] = vec2(step_w, -step_h);
   
   offset[3] = vec2(-step_w, 0.0);
   offset[4] = vec2(0.0, 0.0);
   offset[5] = vec2(step_w, 0.0);
   
   offset[6] = vec2(-step_w, step_h);
   offset[7] = vec2(0.0, step_h);
   offset[8] = vec2(step_w, step_h);
   
   float pw = 0.3;
   kernel[0] = 0.0; 	kernel[1] = 1.0/pw;	kernel[2] = 0.0;
   kernel[3] = 1.0/pw;	kernel[4] = -4.0/pw;	kernel[5] = 1.0/pw;
   kernel[6] = 0.0;  kernel[7] = 1.0/pw;	kernel[8] = 0.0;
   
   
   /*if(texture_coordinate.s<0.495)
   {*/
	   for( i=0; i<KERNEL_SIZE; i++ )
	   {
			vec4 tmp = texture2D(colorMap, texture_coordinate.st + offset[i]);
			sum += tmp * kernel[i];
	   }
   /*}
   else if( texture_coordinate.s>0.505 )
   {
		sum = texture2D(colorMap, texture_coordinate.xy);
   }
   else
   {
		sum = vec4(1.0, 0.0, 0.0, 1.0);
	}*/

	//color +
   vec4 color = texture2D(colorMap, texture_coordinate) * vertColor;
   gl_FragColor =  -1*sum * vertColor;
   //gl_FragColor.a = texture2D(colorMap, texture_coordinate).a * vertColor.a;
}