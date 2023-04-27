#ifndef CUSTOM_LIT_INPUT_INCLUDE
#define CUSTOM_LIT_INPUT_INCLUDE

#define INPUT_PROP(name) UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, name)

TEXTURE2D(_BaseMap);
TEXTURE2D(_EmissionMap);
TEXTURE2D(_MaskMap);
TEXTURE2D(_NormalMap);
SAMPLER(sampler_BaseMap);

TEXTURE2D(_DetailMap);
SAMPLER(sampler_DetailMap);

// for support to per-instance material Data
UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
	UNITY_DEFINE_INSTANCED_PROP(float4, _DetailMap_ST)
	UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionColor)
	UNITY_DEFINE_INSTANCED_PROP(float, _NormalScale)
	UNITY_DEFINE_INSTANCED_PROP(float, _DetailAlbedo)
	UNITY_DEFINE_INSTANCED_PROP(float, _DetailSmoothness)
	UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
	UNITY_DEFINE_INSTANCED_PROP(float, _Metalic)
	UNITY_DEFINE_INSTANCED_PROP(float, _Occlusion)
	UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)
	UNITY_DEFINE_INSTANCED_PROP(float, _Fresnel)
UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

float2 TransformDetailUV(float2 baseUV)
{
	float4 detail_map_st = INPUT_PROP(_DetailMap_ST);
	return baseUV * detail_map_st.xy + detail_map_st.zw;
}

float4 GetDetail(float2 baseUV)
{
	float4 map = SAMPLE_TEXTURE2D(_DetailMap, sampler_DetailMap, baseUV);
	return map * 2.0 - 1.0;
}

float4 GetMask(float2 baseUV)
{
	return SAMPLE_TEXTURE2D(_MaskMap, sampler_BaseMap, baseUV);
}

float2 TransformBaseUV(float2 baseUV)
{
	float4 base_map_st = INPUT_PROP(_BaseMap_ST);
	return baseUV * base_map_st.xy + base_map_st.zw;
}

float4 GetBase(float2 baseUV, float2 detailUV = 0.0)
{
	float4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, baseUV);
	float4 color = INPUT_PROP(_BaseColor);
	float4 mask = GetMask(baseUV);

	float detail = GetDetail(detailUV).r * INPUT_PROP(_DetailAlbedo);
	{
		// Linear Space
		//map.rgb = lerp(map.rgb, detail < 0.0 ? 0.0 : 1.0, abs(detail));
	}
	{
		// Gamma Space
		map.rgb = lerp(sqrt(map.rgb), detail < 0.0 ? 0.0 : 1.0, abs(detail) * mask.b);
		map.rgb *= map.rgb;
	}
	

	return map * color;
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
	float metalic = INPUT_PROP(_Metalic);
	metalic *= GetMask(baseUV).r;
	return metalic;
}

float GetSmoothnes(float2 baseUV, float2 detailUV = 0.0)
{
	float smoothness = INPUT_PROP(_Smoothness);
	smoothness *= GetMask(baseUV).a;
	float4 mask = GetMask(baseUV);

	float detail = GetDetail(detailUV).b * INPUT_PROP(_DetailSmoothness);
	smoothness = lerp(smoothness, detail < 0.0 ? 0.0 : 1.0, abs(detail) * mask.b);

	return smoothness;
}

float GetFresnel(float2 baseUV)
{
	return INPUT_PROP(_Fresnel);
}

float GetOcclusion(float2 baseUV)
{
	// 只会影响间接光，不会影响直射光
	float occlusion_strenth = INPUT_PROP(_Occlusion);
	float occlusion = GetMask(baseUV).g;
	occlusion = lerp(occlusion, 1.0, occlusion_strenth);
	return occlusion;
}

float3 GetNormalTS(float2 baseUV)
{
	float4 normal_map = SAMPLE_TEXTURE2D(_NormalMap, sampler_BaseMap, baseUV);
	float normal_scale = INPUT_PROP(_NormalScale);
	float3 unpack_normal = UnpackNormal(normal_map, normal_scale).rgb;
	return unpack_normal;
}

#endif