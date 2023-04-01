#ifndef CUSTOM_GI_INCLUDE
#define CUSTOM_GI_INCLUDE

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"

TEXTURE2D(unity_Lightmap); // unity的烘培光照应该就在这里了
SAMPLER(samplerunity_Lightmap);

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

GI GetGI(float2 lightmap_uv)
{
	GI gi;
	gi.diffuse = SampleLightMap(lightmap_uv);
	return gi;
}

#endif