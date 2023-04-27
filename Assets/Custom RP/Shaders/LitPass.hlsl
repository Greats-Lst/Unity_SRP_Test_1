#ifndef CUSTOM_LIT_PASS_INCLUDE
#define CUSTOM_LIT_PASS_INCLUDE

//#include "../ShaderLibrary/Common.hlsl"
#include "../ShaderLibrary/Surface.hlsl"
#include "../ShaderLibrary/Shadows.hlsl"
#include "../ShaderLibrary/Light.hlsl"
#include "../ShaderLibrary/BRDF.hlsl"
#include "../ShaderLibrary/GI.hlsl"
#include "../ShaderLibrary/Lighting.hlsl"

//TEXTURE2D(_BaseMap);
//SAMPLER(sampler_BaseMap);
//
//// for support to per-instance material Data
//UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
//	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
//	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
//	UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
//	UNITY_DEFINE_INSTANCED_PROP(float, _Metalic)
//	UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)
//UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

struct Attributes {
	float3 positionOS : POSITION;
	float2 baseUV : TEXCOORD0;
	float3 normalOS : NORMAL;
	float4 tangentOS : TANGENT;
	GI_ATTRIBUTE_DATA
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
	float4 positionCS : SV_POSITION;
	float2 baseUV : VAR_BASE_UV;
	float2 detailUV : VAR_DETAIL_UV;
	float3 normalWS : VAR_NORMAL;
#if defined(_NORMAL_MAP)
	float4 tangentWS : VAR_TANGENT;
#endif
	float3 positionWS : VAR_POSITION;
	GI_VARYINGS_DATA
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings LitPassVertex(Attributes input) //: SV_POSITION
{
	Varyings output;
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
	TRANSFER_GI_DATA(input, output);
	output.positionWS = TransformObjectToWorld(input.positionOS);
	output.positionCS = TransformWorldToHClip(output.positionWS);

	//float4 st = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST);
	//output.baseUV = input.baseUV * st.xy + st.zw;
	output.baseUV = TransformBaseUV(input.baseUV);
#if defined(_DETAIL_MAP)
	output.detailUV = TransformDetailUV(input.baseUV);
#endif
	output.normalWS = TransformObjectToWorldNormal(input.normalOS);
#if defined(_NORMAL_MAP)
	output.tangentWS = float4(TransformObjectToWorldDir(input.tangentOS.xyz), input.tangentOS.w);
#endif
	return output;
}


float4 LitPassFragment(Varyings input) : SV_TARGET
{
	UNITY_SETUP_INSTANCE_ID(input);
	ClipLOD(input.positionCS.xy, unity_LODFade.x);
	InputConfig c = GetInputConfig(input.baseUV);
#if defined(_MASK_MAP)
	c.useMask = true;
#endif
#if defined(_DETAIL_MAP)
	c.detailUV = input.detailUV;
	c.useDetail = true;
#endif
	float4 res_color_1 = GetBase(c);

#if defined(_CLIPPING)
	clip(res_color_1.a - GetCutoff(c));
#endif

	Surface s;
	s.color = res_color_1.rgb;
	s.position = input.positionWS;
	s.depth = -TransformWorldToView(input.positionWS).z;
#if defined(_NORMAL_MAP)
	s.normal = NormalTangentToWorld(GetNormalTS(c), input.normalWS, input.tangentWS);
	s.interporlated_normal = input.normalWS;
#else
	s.normal = normalize(input.normalWS);
	s.interporlated_normal = s.normal;
#endif
	s.alpha = res_color_1.a;
	s.metalic = GetMetalic(c);
	s.smoothness = GetSmoothnes(c);
	s.occlusion = GetOcclusion(c);
	s.fresnel_strength = GetFresnel(c);
	s.view_direction = normalize(_WorldSpaceCameraPos - input.positionWS);
	s.dither = InterleavedGradientNoise(input.positionCS.xy, 0); // ‘Î…˘…˙≥…
#if defined(_APPLYALPHATODIFFUSE)
	BRDF brdf = GetBRDF(s, true);
#else
	BRDF brdf = GetBRDF(s);
#endif
	GI gi = GetGI(GI_FRAGMENT_DATA(input), s, brdf);
	float3 res_color_2 = GetLighting(s, brdf, gi);
	res_color_2 += GetEmission(c);
	return float4(res_color_2, s.alpha);
}

#endif