#ifndef CUSTOM_META_PASS_INCLUDE
#define CUSTOM_META_PASS_INCLUDE

#include "../ShaderLibrary/Surface.hlsl"
#include "../ShaderLibrary/Shadows.hlsl"
#include "../ShaderLibrary/Light.hlsl"
#include "../ShaderLibrary/BRDF.hlsl"

bool4 unity_MetaFragmentControl;
float unity_OneOverOutputBoost;
float unity_MaxOutputValue;

struct Attributes {
	float3 positionOS : POSITION;
	float2 baseUV : TEXCOORD0;
	float2 lightmapUV : TEXCOORD1;
};

struct Varyings
{
	float4 positionCS : SV_POSITION;
	float2 baseUV : VAR_BASE_UV;
};

Varyings MetaPassVertex(Attributes input)
{
	Varyings output;
	input.positionOS.xy = input.lightmapUV * unity_LightmapST.xy + unity_LightmapST.zw; // ISSUE:没懂，有没有可能是随便设置的？
	input.positionOS.z = input.positionOS.z > 0.0 ? FLT_MIN : 0.0;
	output.positionCS = TransformWorldToHClip(input.positionOS);
	output.baseUV = TransformBaseUV(input.baseUV);
	return output;
}

float4 MetaPassFragment(Varyings input) : SV_TARGET
{
	float4 base = GetBase(input.baseUV);
	Surface s;
	ZERO_INITIALIZE(Surface, s);
	s.color = base.rgb;
	s.metalic = GetMetalic(input.baseUV);
	s.smoothness = GetSmoothnes(input.baseUV);
	BRDF brdf = GetBRDF(s);
	float4 meta = 0.0;
	// If the X flag is set then diffuse reflectivity is requested
	if (unity_MetaFragmentControl.x)
	{
		meta = float4(brdf.diffuse, 1.0);
		meta.rgb += brdf.specular * brdf.roughness * 0.5;
		meta.rgb = min(PositivePow(meta.rgb, unity_OneOverOutputBoost), unity_MaxOutputValue);
	}
	else if (unity_MetaFragmentControl.y)
	{
		meta = float4(GetEmission(input.baseUV), 1.0);
	}
	return meta;
}

#endif