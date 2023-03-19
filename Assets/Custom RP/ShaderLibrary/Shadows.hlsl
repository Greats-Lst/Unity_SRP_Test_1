#ifndef CUSTOM_SHADOWS_INCLUDE
#define CUSTOM_SHADOWS_INCLUDE

#define MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT 4
#define MAX_CASCADE_COUNT 4

TEXTURE2D_SHADOW(_DirectionalShadowAtlas);
#define SHADOW_SAMPLER sampler_linear_clamp_compare
SAMPLER_CMP(SHADOW_SAMPLER);

CBUFFER_START(_CustomShadows)
	int _CascadeCount;
	float4 _ShadowDistanceFade;
	float4 _CascadeData[MAX_CASCADE_COUNT];
	float4 _CascadeCullingSpheres[MAX_CASCADE_COUNT];
	float4x4 _DirectionalShadowMatrices[MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT * MAX_CASCADE_COUNT];
CBUFFER_END

struct DirectionalShadowData
{
	float strength;
	int tile_idx;
};

struct ShadowData
{
	int cascade_idx;
	float strength;
};

float FadedShadowStrength(float distance, float scale, float fade)
{
	return saturate((1 - distance * scale) * fade);
}

ShadowData GetShadowData(Surface surface_ws)
{
	ShadowData res;
	res.strength = FadedShadowStrength(surface_ws.depth, _ShadowDistanceFade.x, _ShadowDistanceFade.y);
	int i;
	for (i = 0; i < _CascadeCount; i++) {
		float4 sphere = _CascadeCullingSpheres[i];
		float dis_sqr = DistanceSquared(sphere.xyz, surface_ws.position);
		if (dis_sqr < sphere.w)
		{
			if (i == _CascadeCount - 1)
			{
				res.strength *= FadedShadowStrength(dis_sqr, _CascadeData[i].x, _ShadowDistanceFade.z);
			}
			break;
		}
	}
	if (i == _CascadeCount)
	{
		res.strength = 0.0;
	}
	res.cascade_idx = i;
	return res;
}

float SampleDirectionalShadowAtlas(float3 position_sts) // sts == shadow tile space
{
	return SAMPLE_TEXTURE2D_SHADOW(_DirectionalShadowAtlas, SHADOW_SAMPLER, position_sts);
}

float GetDirectionalShadowAttenuation(DirectionalShadowData direction_data, ShadowData shadow_data, Surface surface_ws) // world space
{
	if (direction_data.strength <= 0.0f)
	{
		return 1.0f;
	}

	float3 world_pos = surface_ws.position + surface_ws.normal * _CascadeData[shadow_data.cascade_idx].y;
	float3 position_sts = mul(_DirectionalShadowMatrices[direction_data.tile_idx], float4(world_pos, 1.0)).xyz;
	float shadow = SampleDirectionalShadowAtlas(position_sts);
	return lerp(1.0f, shadow, direction_data.strength);
}
#endif