#ifndef CUSTOM_UNITY_INPUT_INCLUDE
#define CUSTOM_UNITY_INPUT_INCLUDE

// All UnityPerDraw data gets instanced when needed.
CBUFFER_START(UnityPerDraw)
	float4x4 unity_ObjectToWorld;
	float4x4 unity_WorldToObject;
	float4 unity_LODFade;
	real4 unity_WorldTransformParams;
	float3 _WorldSpaceCameraPos;	// 该变量的位置是我自己放的 我感觉可以放进这里，因为每次DrawCall都重新计算？

	float4 unity_LightmapST;
	float4 unity_DynamicLightmapST;
CBUFFER_END


float4x4 unity_prev_ObjectToWorld;
float4x4 unity_prev_WorldToObject;
float4x4 unity_ViewToWorld;


float4x4 unity_MatrixVP;
float4x4 unity_MatrixV;
float4x4 glstate_matrix_projection;

#endif