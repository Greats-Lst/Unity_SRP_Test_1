#ifndef CUSTOM_UNLIT_PASS_INCLUDE
#define CUSTOM_UNLIT_PASS_INCLUDE

#include "../ShaderLibrary/Common.hlsl"

float4 _BaseColor;

float4 UnlitPassVertex(float3 positionOS : POSITION) : SV_POSITION
{
	//todo: ����ľ���Ȼ�����õģ�������û����Common.hlsl���������ֵ��?
	float3 worldPos = TransformObjectToWorld(positionOS);
	return TransformWorldToHClip(worldPos);
}

float4 UnlitPassFragment() : SV_TARGET
{
	return _BaseColor;
}

#endif