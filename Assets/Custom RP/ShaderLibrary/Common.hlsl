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

float Square(float v)
{
	return v * v;
}

float DistanceSquared(float3 lhs, float3 rhs)
{
	return dot(lhs - rhs, lhs - rhs);
}

#endif