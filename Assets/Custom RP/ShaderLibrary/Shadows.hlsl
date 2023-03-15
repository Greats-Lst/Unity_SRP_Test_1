#ifndef CUSTOM_SHADOWS_INCLUDE
#define CUSTOM_SHADOWS_INCLUDE

#define MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT 4

TEXTURE2D_SHADOW(_DirectionalShadowAtlas);
#define SHADOW_SAMPLER sampler_linear_clamp_compare
SAMPLER_CMP(SHADOW_SAMPLER);

CBUFFER_START(_CustomShadows)
	float4x4 _DirectionalShadowMatrices[MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT];
CBUFFER_END

struct DirectionalShadowData
{
	float strength;
	int tile_idx;
};

float SampleDirectionalShadowAtlas(float3 position_sts) // sts == shadow tile space
{
	return SAMPLE_TEXTURE2D_SHADOW(_DirectionalShadowAtlas, SHADOW_SAMPLER, position_sts);
}

float GetDirectionalShadowAttenuation(DirectionalShadowData data, Surface surface_ws) // world space
{
	if (data.strength <= 0.0f)
	{
		return 1.0f;
	}

	float3 position_sts = mul(_DirectionalShadowMatrices[data.tile_idx], float4(surface_ws.position, 1.0)).xyz;
	float shadow = SampleDirectionalShadowAtlas(position_sts);
	return lerp(1.0f, shadow, data.strength);
}

#endif