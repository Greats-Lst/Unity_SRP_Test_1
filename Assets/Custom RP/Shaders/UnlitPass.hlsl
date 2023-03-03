#ifndef CUSTOM_UNLIT_PASS_INCLUDE
#define CUSTOM_UNLIT_PASS_INCLUDE

#include "../ShaderLibrary/Common.hlsl"

float4 _BaseColor;

float4 UnlitPassVertex(float3 positionOS : POSITION) : SV_POSITION
{
	//todo: 这里的矩阵竟然是有用的，但是我没有在Common.hlsl里设置这个值啊?
	float3 worldPos = TransformObjectToWorld(positionOS);
	return TransformWorldToHClip(worldPos);
}

float4 UnlitPassFragment() : SV_TARGET
{
	return _BaseColor;
}

#endif