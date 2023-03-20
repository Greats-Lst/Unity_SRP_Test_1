#ifndef CUSTOM_LIT_PASS_INCLUDE
#define CUSTOM_LIT_PASS_INCLUDE

#include "../ShaderLibrary/Common.hlsl"
#include "../ShaderLibrary/Surface.hlsl"
#include "../ShaderLibrary/Shadows.hlsl"
#include "../ShaderLibrary/Light.hlsl"
#include "../ShaderLibrary/BRDF.hlsl"
#include "../ShaderLibrary/Lighting.hlsl"

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);

// for support to per-instance material Data
UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
	UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
	UNITY_DEFINE_INSTANCED_PROP(float, _Metalic)
	UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)
UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

struct Attributes {
	float3 positionOS : POSITION;
	float2 baseUV : TEXCOORD0;
	float3 normalOS : NORMAL;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
	float4 positionCS : SV_POSITION;
	float2 baseUV : VAR_BASE_UV;
	float3 normalWS : VAR_NORMAL;
	float3 positionWS : VAR_POSITION;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings LitPassVertex(Attributes input) //: SV_POSITION
{
	Varyings output;
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
	output.positionWS = TransformObjectToWorld(input.positionOS);
	output.positionCS = TransformWorldToHClip(output.positionWS);

	float4 st = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST);
	output.baseUV = input.baseUV * st.xy + st.zw;
	output.normalWS = TransformObjectToWorldNormal(input.normalOS);
	return output;
}


float4 LitPassFragment(Varyings input) : SV_TARGET
{
	UNITY_SETUP_INSTANCE_ID(input);

	float3 normal = normalize(input.normalWS);
	float4 base_map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.baseUV);
	float4 base_color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
	float4 res_color_1 = base_map * base_color;

#if defined(_CLIPPING)
	float alpha_cut_off = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff);
	clip(res_color_1.a - alpha_cut_off);
#endif

	Surface s;
	s.color = res_color_1.rgb;
	s.position = input.positionWS;
	s.depth = -TransformWorldToView(input.positionWS).z;
	s.normal = normal;
	s.alpha = res_color_1.a;
	s.metalic = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Metalic);
	s.smoothness = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Smoothness);
	s.view_direction = normalize(_WorldSpaceCameraPos - input.positionWS);
	s.dither = InterleavedGradientNoise(input.positionCS.xy, 0); // ‘Î…˘…˙≥…
#if defined(_APPLYALPHATODIFFUSE)
	BRDF brdf = GetBRDF(s, true);
#else
	BRDF brdf = GetBRDF(s);
#endif
	float3 res_color_2 = GetLighting(s, brdf);

	return float4(res_color_2, s.alpha);
}

#endif