#ifndef CUSTOM_LIGHT_INCLUDE
#define CUSTOM_LIGHT_INCLUDE

#define MAX_DIRECTION_LIGHT_COUNT 4

CBUFFER_START(_CustomLight)
	int _DirectionLightMaxCount;
	float4 _DirectionalLightColors[MAX_DIRECTION_LIGHT_COUNT];
	float4 _DirectionalLightDirections[MAX_DIRECTION_LIGHT_COUNT];
CBUFFER_END

struct Light
{
	float3 color;
	float3 direction;
};

Light GetDirectionLight(int idx)
{
	Light light;
	light.color = _DirectionalLightColors[idx];
	light.direction = _DirectionalLightDirections[idx];
	return light;
}

#endif