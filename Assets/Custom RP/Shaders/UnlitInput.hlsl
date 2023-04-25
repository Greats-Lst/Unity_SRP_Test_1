#ifndef CUSTOM_UNLIT_INPUT_INCLUDE
#define CUSTOM_UNLIT_INPUT_INCLUDE

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);

// for support to per-instance material Data
UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
	UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

float2 TransformBaseUV(float2 baseUV)
{
	float4 base_map_st = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST);
	return baseUV * base_map_st.xy + base_map_st.zw;
}

float4 GetBase(float2 baseUV)
{
	float4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, baseUV);
	float4 color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
	return map * color;
}

float GetCutoff(float2 baseUV)
{
	return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff);
}

float GetMetalic(float2 baseUV)
{
	return 0;
}

float GetSmoothnes(float2 baseUV)
{
	return 0;
}

float3 GetEmission(float2 baseUV)
{
	return GetBase(baseUV).rgb;
}

float GetFresnel(float2 baseUV)
{
	return 0.0;
}

#endif