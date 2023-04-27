#ifndef CUSTOM_UNLIT_INPUT_INCLUDE
#define CUSTOM_UNLIT_INPUT_INCLUDE

#define INPUT_PROP(name) UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, name)

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
	float4 base_map_st = INPUT_PROP(_BaseMap_ST);
	return baseUV * base_map_st.xy + base_map_st.zw;
}

float4 GetBase(InputConfig c)
{
	float4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, c.baseUV);
	float4 color = INPUT_PROP(_BaseColor);
	return map * color;
}

float GetCutoff(InputConfig c)
{
	return INPUT_PROP(_Cutoff);
}

float GetMetalic(InputConfig c)
{
	return 0;
}

float GetSmoothnes(InputConfig c)
{
	return 0;
}

float3 GetEmission(InputConfig c)
{
	return GetBase(c).rgb;
}

float GetFresnel(InputConfig c)
{
	return 0.0;
}

#endif