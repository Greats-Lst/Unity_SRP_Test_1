#ifndef CUSTOM_COMMON_INCLUDE
#define CUSTOM_COMMON_INCLUDE

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "UnityInput.hlsl"

#define UNITY_MATRIX_M unity_ObjectToWorld
#define UNITY_MATRIX_I_M unity_WorldToObject
#define UNITY_MATRIX_V unity_MatrixV
#define UNITY_MATRIX_VP unity_MatrixVP
#define UNITY_MATRIX_P glstate_matrix_projection
#define UNITY_PREV_MATRIX_M unity_prev_ObjectToWorld
#define UNITY_PREV_MATRIX_I_M unity_prev_WorldToObject
#define UNITY_MATRIX_I_V unity_ViewToWorld


//增加了Occlusion Probes之后break了GPUInstancing
//The occlusion data can get instanced automatically, but UnityInstancing only does this when SHADOWS_SHADOWMASK is defined
#if defined(_SHADOW_MASK_ALWAYS) || defined(_SHADOW_MASK_DISTANCE)
	#define SHADOWS_SHADOWMASK
#endif 



#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"

struct InputConfig
{
	float2 baseUV;
	float2 detailUV;
	bool useMask;
	bool useDetail;
};

InputConfig GetInputConfig(float2 baseUV, float2 detailUV = 0.0)
{
	InputConfig c;
	c.baseUV = baseUV;
	c.detailUV = detailUV;
	c.useMask = false;
	c.useDetail = false;
	return c;
}

float Square(float v)
{
	return v * v;
}

float DistanceSquared(float3 lhs, float3 rhs)
{
	return dot(lhs - rhs, lhs - rhs);
}

void ClipLOD(float2 positionCS, float fade) 
{
#if defined(LOD_FADE_CROSSFADE)
	float dither = InterleavedGradientNoise(positionCS.xy, 0);
	clip(fade + (fade < 0.0 ? dither : -dither));
#endif
}

float3 UnpackNormal(float4 sample_normal, float scale)
{
#if defined(UNITY_NO_DXT5nm)
	return UnpackNormalRGB(sample_normal, scale);
#else 
	return UnpackNormalmapRGorAG(sample_normal, scale);
#endif
}

float3 NormalTangentToWorld(float3 normal_ts, float3 normal_ws, float4 tangent_ws)
{
	float3x3 tangent_to_world = CreateTangentToWorld(normal_ws, tangent_ws.xyz, tangent_ws.w);
	return TransformTangentToWorld(normal_ts, tangent_to_world);
}

#endif