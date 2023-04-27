#ifndef CUSTOM_SHADOWS_INCLUDE
#define CUSTOM_SHADOWS_INCLUDE

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Shadow/ShadowSamplingTent.hlsl"

#if defined(_DIRECTIONAL_PCF3)
	#define DIRECTIONAL_FILTER_SAMPLES 4
	#define DIRECTIONAL_FILTER_SETUP SampleShadow_ComputeSamples_Tent_3x3
#elif defined(_DIRECTIONAL_PCF5)
	#define DIRECTIONAL_FILTER_SAMPLES 9
	#define DIRECTIONAL_FILTER_SETUP SampleShadow_ComputeSamples_Tent_5x5
#elif defined(_DIRECTIONAL_PCF7)
	#define DIRECTIONAL_FILTER_SAMPLES 16
	#define DIRECTIONAL_FILTER_SETUP SampleShadow_ComputeSamples_Tent_7x7
#endif

#define MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT 4
#define MAX_CASCADE_COUNT 4

TEXTURE2D_SHADOW(_DirectionalShadowAtlas);
#define SHADOW_SAMPLER sampler_linear_clamp_compare
SAMPLER_CMP(SHADOW_SAMPLER);

CBUFFER_START(_CustomShadows)
	int _CascadeCount;
	float4 _ShadowAtlasSize;
	float4 _ShadowDistanceFade;
	float4 _CascadeData[MAX_CASCADE_COUNT];
	float4 _CascadeCullingSpheres[MAX_CASCADE_COUNT];
	float4x4 _DirectionalShadowMatrices[MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT * MAX_CASCADE_COUNT];
CBUFFER_END

struct DirectionalShadowData
{
	float strength;
	int tile_idx;
	float normal_bias;
	int mask_channel;
};

struct ShadowMask
{
	bool always_active;
	bool distance;
	float4 shadows;
};

struct ShadowData
{
	int cascade_idx;
	float cascade_blend;
	float strength;
	ShadowMask shadow_mask;
};

float FadedShadowStrength(float distance, float scale, float fade)
{
	return saturate((1 - distance * scale) * fade);
}

ShadowData GetShadowData(Surface surface_ws)
{
	ShadowData res;
	res.shadow_mask.always_active = false;
	res.shadow_mask.distance = false;
	res.shadow_mask.shadows = 1.0;
	res.cascade_blend = 1.0f;
	res.strength = FadedShadowStrength(surface_ws.depth, _ShadowDistanceFade.x, _ShadowDistanceFade.y);
	int i;
	for (i = 0; i < _CascadeCount; i++) {
		float4 sphere = _CascadeCullingSpheres[i];
		float dis_sqr = DistanceSquared(sphere.xyz, surface_ws.position);
		if (dis_sqr < sphere.w)
		{
			float fade = FadedShadowStrength(dis_sqr, _CascadeData[i].x, _ShadowDistanceFade.z);
			if (i == _CascadeCount - 1)
			{
				res.strength *= fade;
			}
			else
			{
				res.cascade_blend = fade;
			}
			break;
		}
	}

	if (i == _CascadeCount)
	{
		res.strength = 0.0;
	}
#if defined(_CASCADE_BLEND_DITHER)
	else if (res.cascade_blend < surface_ws.dither)
	{
		i += 1;
	}
#endif

#if !defined(_CASCADE_BLEND_SOFT)
	res.cascade_blend = 1.0f;
#endif

	res.cascade_idx = i;
	return res;
}

float SampleDirectionalShadowAtlas(float3 position_sts) // sts == shadow tile space
{
	return SAMPLE_TEXTURE2D_SHADOW(_DirectionalShadowAtlas, SHADOW_SAMPLER, position_sts);
}

float FilterDirectionalShadow(float3 position_sts)
{
#if defined(DIRECTIONAL_FILTER_SETUP)
	float weights[DIRECTIONAL_FILTER_SAMPLES];
	float2 new_position_sample[DIRECTIONAL_FILTER_SAMPLES];
	float4 size = _ShadowAtlasSize.yyxx;
	float2 cur_pos = position_sts.xy;
	DIRECTIONAL_FILTER_SETUP(size, cur_pos, weights, new_position_sample);
	float shadow = 0;
	for (int i = 0; i < DIRECTIONAL_FILTER_SAMPLES; ++i)
	{
		shadow += weights[i] * SampleDirectionalShadowAtlas(float3(new_position_sample[i].xy, position_sts.z));
	}
	return shadow;
#else
	return SampleDirectionalShadowAtlas(position_sts);
#endif
}

float GetCascadedShadow(DirectionalShadowData direction_data, ShadowData shadow_data, Surface surface_ws)
{
	float3 world_pos = surface_ws.position + surface_ws.interporlated_normal * (direction_data.normal_bias * _CascadeData[shadow_data.cascade_idx].y);
	float3 position_sts = mul(_DirectionalShadowMatrices[direction_data.tile_idx], float4(world_pos, 1.0)).xyz;
	float shadow = FilterDirectionalShadow(position_sts);
	if (shadow_data.cascade_blend < 1.0f)
	{
		float3 next_world_pos = surface_ws.position + surface_ws.interporlated_normal * (direction_data.normal_bias * _CascadeData[shadow_data.cascade_idx + 1].y);
		float3 next_position_sts = mul(_DirectionalShadowMatrices[direction_data.tile_idx + 1], float4(next_world_pos, 1.0)).xyz;
		float next_shadow = FilterDirectionalShadow(next_position_sts);
		shadow = lerp(next_shadow, shadow, shadow_data.cascade_blend);
	}
	return shadow;
}

float GetBakedShadow(ShadowMask mask, int mask_channel)
{
	float shadow = 1.0f;
	if (mask.distance || mask.always_active)
	{
		if (mask_channel >= 0)
		{
			shadow = mask.shadows[mask_channel];
		}
	}
	return shadow;
}

float GetBakedShadow(ShadowMask mask, float strength, int mask_channel)
{
	float shadow = 1.0f;
	if (mask.distance || mask.always_active)
	{
		shadow = lerp(1.0f, GetBakedShadow(mask, mask_channel), strength);
	}
	return shadow;
}

float MixBakedAndRealTimeShadow(ShadowData global, float shadow, float strength, int mask_channel)
{
	float baked = GetBakedShadow(global.shadow_mask, mask_channel);
	if (global.shadow_mask.always_active)
	{
		shadow = lerp(1.0f, shadow, global.strength);
		shadow = min(baked, shadow);
		return lerp(1.0f, shadow, strength);
	}
	if (global.shadow_mask.distance)
	{
		shadow = lerp(baked, shadow, global.strength);
		return lerp(1.0f, shadow, strength);
	}
	return lerp(1.0f, shadow, strength * global.strength);
}

float GetDirectionalShadowAttenuation(DirectionalShadowData direction_data, ShadowData global, Surface surface_ws) // world space
{
	#if !defined(_RECEIVE_SHADOWS)
		return 1.0;
	#endif

	float shadow;
	if (direction_data.strength * global.strength <= 0.0f)
	{
		shadow = GetBakedShadow(global.shadow_mask, abs(direction_data.strength), direction_data.mask_channel);
	}
	else
	{
		shadow = GetCascadedShadow(direction_data, global, surface_ws);
		shadow = MixBakedAndRealTimeShadow(global, shadow, direction_data.strength, direction_data.mask_channel);
	}

	return shadow;
}
#endif