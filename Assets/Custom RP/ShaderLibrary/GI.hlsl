#ifndef CUSTOM_GI_INCLUDE
#define CUSTOM_GI_INCLUDE

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"

TEXTURE2D(unity_Lightmap); // Bake Light Map
SAMPLER(samplerunity_Lightmap);

TEXTURE2D(unity_ShadowMask); // Bake Shadow Map
SAMPLER(samplerunity_ShadowMask);

TEXTURE3D_FLOAT(unity_ProbeVolumeSH); // Bake Light Probe Proxy Volume
SAMPLER(samplerunity_ProbeVolumeSH);

TEXTURECUBE(unity_SpecCube0); // GI.Specular
SAMPLER(samplerunity_SpecCube0);

#if defined (LIGHTMAP_ON)
	#define GI_ATTRIBUTE_DATA float2 lightMapUV : TEXCOORD1; // The light map UV are provided via the second texture coordinates channel
	#define GI_VARYINGS_DATA float2 lightMapUV : VAR_LIGHT_MAP_UV;
	#define TRANSFER_GI_DATA(input, output)  output.lightMapUV = input.lightMapUV * unity_LightmapST.xy + unity_LightmapST.zw;
	#define GI_FRAGMENT_DATA(input) input.lightMapUV
#else
	#define GI_ATTRIBUTE_DATA
	#define GI_VARYINGS_DATA
	#define TRANSFER_GI_DATA(input, output) 
	#define GI_FRAGMENT_DATA(input) 0.0
#endif

struct GI
{
	float3 diffuse;
	float3 specular;
	ShadowMask shadow_mask;
};

float3 SampleLightMap(float2 lightmap_uv)
{
#if defined(LIGHTMAP_ON)
	return SampleSingleLightmap(TEXTURE2D_ARGS(unity_Lightmap, samplerunity_Lightmap),
		lightmap_uv, float4(1.0, 1.0, 0.0, 0.0), 
	#if defined(UNITY_LIGHTMAP_FULL_HDR)
		false,
	#else 
		true,
	#endif
		float4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0, 0.0));
#else
	return 0;
#endif
}

float4 SampleBakedShadowMap(float2 lightmap_uv, Surface surface_ws)
{
#if defined(LIGHTMAP_ON)
	return SAMPLE_TEXTURE2D(unity_ShadowMask, samplerunity_ShadowMask, lightmap_uv);
#else
	if (unity_ProbeVolumeParams.x)
	{
		// 采样和SampleLightProbe一样
		// 如果直接返回unity_ProbesOcclusion的话LPPVs是没有插值效果的
		return SampleProbeOcclusion(TEXTURE3D_ARGS(unity_ProbeVolumeSH, samplerunity_ProbeVolumeSH),
			surface_ws.position,
			unity_ProbeVolumeWorldToObject,
			unity_ProbeVolumeParams.y, unity_ProbeVolumeParams.z,
			unity_ProbeVolumeMin.xyz, unity_ProbeVolumeSizeInv.xyz
		);
	}
	else
	{
		return unity_ProbesOcclusion;
	}
#endif
}

float3 SampleLightProbe(Surface surface_ws)
{
#if defined(LIGHTMAP_ON)
	return 0;
#else
	if (unity_ProbeVolumeParams.x)
	{
		return SampleProbeVolumeSH4(
			TEXTURE3D_ARGS(unity_ProbeVolumeSH, samplerunity_ProbeVolumeSH),
			surface_ws.position, surface_ws.normal,
			unity_ProbeVolumeWorldToObject,
			unity_ProbeVolumeParams.y, unity_ProbeVolumeParams.z,
			unity_ProbeVolumeMin.xyz, unity_ProbeVolumeSizeInv.xyz
		);
	}
	else
	{
		float4 coefficients[7];
		coefficients[0] = unity_SHAr;
		coefficients[1] = unity_SHAg;
		coefficients[2] = unity_SHAb;
		coefficients[3] = unity_SHBr;
		coefficients[4] = unity_SHBg;
		coefficients[5] = unity_SHBb;
		coefficients[6] = unity_SHC;
		return max(0.0, SampleSH9(coefficients, surface_ws.normal));
	}
#endif
}

float3 SampleEnvironment(Surface surface_ws, BRDF brdf)
{
	float3 uvw = reflect(-surface_ws.view_direction, surface_ws.normal);
	float mip_level = PerceptualRoughnessToMipmapLevel(brdf.perceptualRoughness);
	float4 environment = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, uvw, mip_level);
	return environment.rgb;
}

GI GetGI(float2 lightmap_uv, Surface surface_ws, BRDF brdf)
{
	GI gi;
	gi.shadow_mask.always_active = false;
	gi.shadow_mask.distance = false;
	gi.shadow_mask.shadows = 1.0;
	gi.diffuse = SampleLightMap(lightmap_uv) + SampleLightProbe(surface_ws);
	gi.specular = SampleEnvironment(surface_ws, brdf);

#if defined(_SHADOW_MASK_DISTANCE)
	gi.shadow_mask.distance = true;
	gi.shadow_mask.shadows = SampleBakedShadowMap(lightmap_uv, surface_ws);
#elif defined(_SHADOW_MASK_ALWAYS)
	gi.shadow_mask.always_active = true;
	gi.shadow_mask.shadows = SampleBakedShadowMap(lightmap_uv, surface_ws);
#endif

	return gi;
}

#endif