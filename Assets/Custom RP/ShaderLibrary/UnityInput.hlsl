#ifndef CUSTOM_UNITY_INPUT_INCLUDE
#define CUSTOM_UNITY_INPUT_INCLUDE

// All UnityPerDraw data gets instanced when needed.
CBUFFER_START(UnityPerDraw)
	float4x4 unity_ObjectToWorld;
	float4x4 unity_WorldToObject;
	float4 unity_LODFade;
	real4 unity_WorldTransformParams;
	float3 _WorldSpaceCameraPos;	// �ñ�����λ�������Լ��ŵ� �Ҹо����ԷŽ������Ϊÿ��DrawCall�����¼��㣿

	float4 unity_LightmapST;
	float4 unity_DynamicLightmapST;

	float4 unity_SHAr;
	float4 unity_SHAg;
	float4 unity_SHAb;
	float4 unity_SHBr;
	float4 unity_SHBg;
	float4 unity_SHBb;
	float4 unity_SHC;
CBUFFER_END


float4x4 unity_prev_ObjectToWorld;
float4x4 unity_prev_WorldToObject;
float4x4 unity_ViewToWorld;


float4x4 unity_MatrixVP;
float4x4 unity_MatrixV;
float4x4 glstate_matrix_projection;

#endif