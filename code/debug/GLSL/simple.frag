#define KERNEL_SIZE 9

uniform sampler2D colorMap;

varying vec2 texture_coordinate;
varying vec3 Position;
varying vec4 vertColor;

void main(void)
{
   vec4 color = texture2D(colorMap, texture_coordinate) * vertColor;
   //color = color + vec4(1.0,1.0,0.6,1.0);
   gl_FragColor =  color;
}