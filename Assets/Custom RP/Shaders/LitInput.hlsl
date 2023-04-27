#ifndef CUSTOM_LIT_INPUT_INCLUDE
#define CUSTOM_LIT_INPUT_INCLUDE

#define INPUT_PROP(name) UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, name)

TEXTURE2D(_BaseMap);
TEXTURE2D(_EmissionMap);
TEXTURE2D(_MaskMap);
TEXTURE2D(_NormalMap);
SAMPLER(sampler_BaseMap);

TEXTURE2D(_DetailMap);
TEXTURE2D(_DetailNormalMap);
SAMPLER(sampler_DetailMap);

// for support to per-instance material Data
UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
	UNITY_DEFINE_INSTANCED_PROP(float4, _DetailMap_ST)
	UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionColor)
	UNITY_DEFINE_INSTANCED_PROP(float, _NormalScale)
	UNITY_DEFINE_INSTANCED_PROP(float, _DetailNormalScale)
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

float4 GetDetail(InputConfig c)
{
	if (c.useDetail)
	{
		float4 map = SAMPLE_TEXTURE2D(_DetailMap, sampler_DetailMap, c.baseUV);
		return map * 2.0 - 1.0;
	}
	return 0.0;
}

float4 GetMask(InputConfig c)
{
	if (c.useMask)
	{
		return SAMPLE_TEXTURE2D(_MaskMap, sampler_BaseMap, c.baseUV);
	}
	else
	{
		return 1;
	}
}

float2 TransformBaseUV(float2 baseUV)
{
	float4 base_map_st = INPUT_PROP(_BaseMap_ST);
	return baseUV * base_map_st.xy + base_map_st.zw;
}

float4 GetBase(InputConfig c)
{
	float4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, c.baseUV);
	float4 color = INPUT_PROP(_BaseColor);

	if (c.useDetail)
	{
		float detail = GetDetail(c).r * INPUT_PROP(_DetailAlbedo);
		{
			// Linear Space
			//map.rgb = lerp(map.rgb, detail < 0.0 ? 0.0 : 1.0, abs(detail));
		}
		{
			// Gamma Space
			float4 mask = GetMask(c);
			map.rgb = lerp(sqrt(map.rgb), detail < 0.0 ? 0.0 : 1.0, abs(detail) * mask.b);
			map.rgb *= map.rgb;
		}
	}
	

	return map * color;
}

float3 GetEmission(InputConfig c)
{
	float4 map = SAMPLE_TEXTURE2D(_EmissionMap, sampler_BaseMap, c.baseUV);
	float4 color = INPUT_PROP(_EmissionColor);
	return map.rgb * color.rgb;
}

float GetCutoff(InputConfig c)
{
	return INPUT_PROP(_Cutoff);
}

float GetMetalic(InputConfig c)
{
	float metalic = INPUT_PROP(_Metalic);
	metalic *= GetMask(c).r;
	return metalic;
}

float GetSmoothnes(InputConfig c)
{
	float smoothness = INPUT_PROP(_Smoothness);
	smoothness *= GetMask(c).a;

	if (c.useDetail)
	{
		float4 mask = GetMask(c);
		float detail = GetDetail(c).b * INPUT_PROP(_DetailSmoothness);
		smoothness = lerp(smoothness, detail < 0.0 ? 0.0 : 1.0, abs(detail) * mask.b);
	}

	return smoothness;
}

float GetFresnel(InputConfig c)
{
	return INPUT_PROP(_Fresnel);
}

float GetOcclusion(InputConfig c)
{
	// 只会影响间接光，不会影响直射光
	float occlusion_strenth = INPUT_PROP(_Occlusion);
	float occlusion = GetMask(c).g;
	occlusion = lerp(occlusion, 1.0, occlusion_strenth);
	return occlusion;
}

float3 GetNormalTS(InputConfig c)
{
	float4 normal_map = SAMPLE_TEXTURE2D(_NormalMap, sampler_BaseMap, c.baseUV);
	float normal_scale = INPUT_PROP(_NormalScale);
	float3 unpack_normal = UnpackNormal(normal_map, normal_scale).rgb;

	if (c.useDetail)
	{
		float4 detail_normal_map = SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailMap, c.detailUV);
		float detail_normal_scale = INPUT_PROP(_DetailNormalScale) * GetMask(c).b;
		float3 unpack_detail_normal = UnpackNormal(detail_normal_map, detail_normal_scale).rgb;
		unpack_normal = BlendNormalRNM(unpack_normal, unpack_detail_normal);
	}

	return unpack_normal;
}

#endif