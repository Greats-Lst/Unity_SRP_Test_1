#ifndef CUSTOM_LIGHT_INCLUDE
#define CUSTOM_LIGHT_INCLUDE

#define MAX_DIRECTION_LIGHT_COUNT 4

CBUFFER_START(_CustomLight)
	int _DirectionLightMaxCount;
	float4 _DirectionalLightColors[MAX_DIRECTION_LIGHT_COUNT];
	float4 _DirectionalLightDirections[MAX_DIRECTION_LIGHT_COUNT];
	float4 _DirectionalLightShadowData[MAX_DIRECTION_LIGHT_COUNT];
CBUFFER_END

struct Light
{
	float3 color;
	float3 direction;
	float attenuation;
};

DirectionalShadowData GetDirectionalShadowData(int idx)
{
	DirectionalShadowData data;
	data.strength = _DirectionalLightShadowData[idx].x;
	data.tile_idx = _DirectionalLightShadowData[idx].y;
	return data;
}

Light GetDirectionLight(int idx, Surface surface_ws)
{
	Light light;
	light.color = _DirectionalLightColors[idx];
	light.direction = _DirectionalLightDirections[idx];
	DirectionalShadowData shadow_data = GetDirectionalShadowData(idx);
	light.attenuation = GetDirectionalShadowAttenuation(shadow_data, surface_ws);
	return light;
}

#endif