#ifndef CUSTOM_LIGHTING_INCLUDE
#define CUSTOM_LIGHTING_INCLUDE

float3 GetLighting(Surface s)
{
	//return s.normal.y;
	return s.normal.y * s.color;
}

#endif