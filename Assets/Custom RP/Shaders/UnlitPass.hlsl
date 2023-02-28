#ifndef CUSTOM_UNLIT_PASS_INCLUDE
#define CUSTOM_UNLIT_PASS_INCLUDE

float4 UnlitPassVertex(float3 position_os : POSITION) : SV_POSITION
{
	return float4(position_os, 1.0f);
}

float4 UnlitPassFragment() : SV_TARGET
{
	return 1.0f;
}

#endif