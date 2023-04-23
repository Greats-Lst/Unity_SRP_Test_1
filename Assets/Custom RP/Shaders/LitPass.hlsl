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
	GI_ATTRIBUTE_DATA
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
	float4 positionCS : SV_POSITION;
	float2 baseUV : VAR_BASE_UV;
	float3 normalWS : VAR_NORMAL;
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
	output.normalWS = TransformObjectToWorldNormal(input.normalOS);
	return output;
}


float4 LitPassFragment(Varyings input) : SV_TARGET
{
	UNITY_SETUP_INSTANCE_ID(input);
	ClipLOD(input.positionCS.xy, unity_LODFade.x);
	float3 normal = normalize(input.normalWS);
	float4 res_color_1 = GetBase(input.baseUV);

#if defined(_CLIPPING)
	clip(res_color_1.a - GetCutoff(input.baseUV));
#endif

	Surface s;
	s.color = res_color_1.rgb;
	s.position = input.positionWS;
	s.depth = -TransformWorldToView(input.positionWS).z;
	s.normal = normal;
	s.alpha = res_color_1.a;
	s.metalic = GetMetalic(input.baseUV);
	s.smoothness = GetSmoothnes(input.baseUV);
	s.view_direction = normalize(_WorldSpaceCameraPos - input.positionWS);
	s.dither = InterleavedGradientNoise(input.positionCS.xy, 0); // ‘Î…˘…˙≥…
#if defined(_APPLYALPHATODIFFUSE)
	BRDF brdf = GetBRDF(s, true);
#else
	BRDF brdf = GetBRDF(s);
#endif
	GI gi = GetGI(GI_FRAGMENT_DATA(input), s);
	float3 res_color_2 = GetLighting(s, brdf, gi);
	res_color_2 += GetEmission(input.baseUV);
	return float4(res_color_2, s.alpha);
}

#endif