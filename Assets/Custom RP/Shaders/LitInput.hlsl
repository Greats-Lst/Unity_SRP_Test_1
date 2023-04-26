#ifndef CUSTOM_LIT_INPUT_INCLUDE
#define CUSTOM_LIT_INPUT_INCLUDE

#define INPUT_PROP(name) UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, name)

TEXTURE2D(_BaseMap);
TEXTURE2D(_EmissionMap);
TEXTURE2D(_MaskMap);
SAMPLER(sampler_BaseMap);

// for support to per-instance material Data
UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
	UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionColor)
	UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
	UNITY_DEFINE_INSTANCED_PROP(float, _Metalic)
	UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)
	UNITY_DEFINE_INSTANCED_PROP(float, _Fresnel)
UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

float2 TransformBaseUV(float2 baseUV)
{
	float4 base_map_st = INPUT_PROP(_BaseMap_ST);
	return baseUV * base_map_st.xy + base_map_st.zw;
}

float4 GetBase(float2 baseUV)
{
	float4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, baseUV);
	float4 color = INPUT_PROP(_BaseColor);
	return map * color;
}

float4 GetMask(float2 baseUV)
{
	return SAMPLE_TEXTURE2D(_MaskMap, sampler_BaseMap, baseUV);
}

float3 GetEmission(float2 baseUV)
{
	float4 map = SAMPLE_TEXTURE2D(_EmissionMap, sampler_BaseMap, baseUV);
	float4 color = INPUT_PROP(_EmissionColor);
	return map.rgb * color.rgb;
}

float GetCutoff(float2 baseUV)
{
	return INPUT_PROP(_Cutoff);
}

float GetMetalic(float2 baseUV)
{
	return INPUT_PROP(_Metalic);
}

float GetSmoothnes(float2 baseUV)
{
	return INPUT_PROP(_Smoothness);
}

float GetFresnel(float2 baseUV)
{
	return INPUT_PROP(_Fresnel);
}

#endif