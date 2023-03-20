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

DirectionalShadowData GetDirectionalShadowData(int idx, ShadowData shadow_data)
{
	DirectionalShadowData data;
	data.strength = _DirectionalLightShadowData[idx].x * shadow_data.strength;
	data.tile_idx = _DirectionalLightShadowData[idx].y + shadow_data.cascade_idx;
	data.normal_bias = _DirectionalLightShadowData[idx].z;
	return data;
}

Light GetDirectionLight(int idx, Surface surface_ws, ShadowData shadow_data)
{
	Light light;
	light.color = _DirectionalLightColors[idx].xyz;
	light.direction = _DirectionalLightDirections[idx].xyz;
	DirectionalShadowData dir_shadow_data = GetDirectionalShadowData(idx, shadow_data);
	light.attenuation = GetDirectionalShadowAttenuation(dir_shadow_data, shadow_data, surface_ws);
	return light;
}

#endif