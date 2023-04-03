#ifndef CUSTOM_META_PASS_INCLUDE
#define CUSTOM_META_PASS_INCLUDE

#include "../ShaderLibrary/Surface.hlsl"
#include "../ShaderLibrary/Shadows.hlsl"
#include "../ShaderLibrary/Light.hlsl"
#include "../ShaderLibrary/BRDF.hlsl"

struct Attributes {
	float3 positionOS : POSITION;
	float2 baseUV : TEXCOORD0;
};

struct Varyings
{
	float4 positionCS : SV_POSITION;
	float2 baseUV : VAR_BASE_UV;
};

Varyings MetaMetaPassVertex(Attributes input)
{
	Varyings output;
	output.positionCS = 0.0;
	output.baseUV = TransformBaseUV(input.baseUV);
	return output;
}

float4 LitPassFragment(Varyings input) : SV_TARGET
{
	float4 base = GetBase(input.baseUV);
	Surface s;
	ZERO_INITIALIZE(Surface, s);
	s.color = base.rgb;
	s.metalic = GetMetalic(input.baseUV);
	s.smoothness = GetSmoothnes(input.baseUV);
	BRDF brdf = GetBRDF(s);
	float4 meta = 0;
	return meta;

}

#endif