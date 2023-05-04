#ifndef CUSTOM_LIGHT_INCLUDE
#define CUSTOM_LIGHT_INCLUDE

#define MAX_DIRECTION_LIGHT_COUNT 4
#define MAX_OTHER_LIGHT_COUNT 64

CBUFFER_START(_CustomLight)
	int _DirectionLightMaxCount;
	float4 _DirectionalLightColors[MAX_DIRECTION_LIGHT_COUNT];
	float4 _DirectionalLightDirections[MAX_DIRECTION_LIGHT_COUNT];
	float4 _DirectionalLightShadowData[MAX_DIRECTION_LIGHT_COUNT];

	int _OtherLightMaxCount;
	float4 _OtherLightColors[MAX_OTHER_LIGHT_COUNT];
	float4 _OtherLightPosition[MAX_OTHER_LIGHT_COUNT];
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
	// 因为增加了烘培阴影所以把阴影本身的强度放到Shadow.hlsl里进行烘培阴影和实时阴影插值之后再改变强度
	data.strength = _DirectionalLightShadowData[idx].x; //* shadow_data.strength;
	data.tile_idx = _DirectionalLightShadowData[idx].y + shadow_data.cascade_idx;
	data.normal_bias = _DirectionalLightShadowData[idx].z;
	data.mask_channel = _DirectionalLightShadowData[idx].w;
	return data;
}

Light GetDirectionLight(int idx, Surface surface_ws, ShadowData shadow_data)
{
	Light light;
	light.color = _DirectionalLightColors[idx].rgb;
	light.direction = _DirectionalLightDirections[idx].xyz;
	DirectionalShadowData dir_shadow_data = GetDirectionalShadowData(idx, shadow_data);
	light.attenuation = GetDirectionalShadowAttenuation(dir_shadow_data, shadow_data, surface_ws);
	return light;
}

Light GetOtherLight(int idx, Surface surface_ws, ShadowData shadow_data)
{
	Light light;
	light.color = _OtherLightColors[idx].rgb;
	float3 ray = _OtherLightPosition[idx].xyz - surface_ws.position;
	light.direction = normalize(ray);
	float sqr_distance = max(dot(ray, ray), 0.00001);
	//_OtherLightPosition[idx].w 存了1 / (light.range * light.range)
	float range_attrenuation = Square(max(0, 1.0 - Square(sqr_distance * _OtherLightPosition[idx].w)));
	light.attenuation = range_attrenuation;
	return light;
}

int GetOtherLightCount()
{
	return _OtherLightMaxCount;
}
#endif