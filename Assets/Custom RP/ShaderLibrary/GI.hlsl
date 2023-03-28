#ifndef CUSTOM_GI_INCLUDE
#define CUSTOM_GI_INCLUDE

#if defined (LIGHTMAP_ON)
	#define GI_ATTRIBUTE_DATA float2 lightMapUV : TEXCOORD1; // The light map UV are provided via the second texture coordinates channel
	#define GI_VARYINGS_DATA float2 lightMapUV : VAR_LIGHT_MAP_UV;
	#define TRANSFER_GI_DATA(input, output)  output.lightMapUV = input.lightMapUV;
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

GI GetGI(float2 lightmap_uv)
{
	GI gi;
	gi.diffuse = float3(lightmap_uv, 0.0);
	return gi;
}

#endif