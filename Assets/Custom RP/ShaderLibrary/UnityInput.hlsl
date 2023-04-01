#ifndef CUSTOM_UNITY_INPUT_INCLUDE
#define CUSTOM_UNITY_INPUT_INCLUDE

// All UnityPerDraw data gets instanced when needed.
CBUFFER_START(UnityPerDraw)

	// Common
	float4x4 unity_ObjectToWorld;
	float4x4 unity_WorldToObject;
	float4 unity_LODFade;
	real4 unity_WorldTransformParams;
	float3 _WorldSpaceCameraPos;	// 该变量的位置是我自己放的 我感觉可以放进这里，因为每次DrawCall都重新计算？

	// Bake Light Map
	float4 unity_LightmapST;
	float4 unity_DynamicLightmapST;

	// Bake Light Probe
	float4 unity_SHAr;
	float4 unity_SHAg;
	float4 unity_SHAb;
	float4 unity_SHBr;
	float4 unity_SHBg;
	float4 unity_SHBb;
	float4 unity_SHC;

	// Bake Light Probe Proxy Volume
	float4 unity_ProbeVolumeParams;
	float4x4 unity_ProbeVolumeWorldToObject;
	float4 unity_ProbeVolumeSizeInv;
	float4 unity_ProbeVolumeMin;

CBUFFER_END


float4x4 unity_prev_ObjectToWorld;
float4x4 unity_prev_WorldToObject;
float4x4 unity_ViewToWorld;


float4x4 unity_MatrixVP;
float4x4 unity_MatrixV;
float4x4 glstate_matrix_projection;

#endif