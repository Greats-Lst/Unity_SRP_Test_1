Shader "Custom RP/Unlit" {

	Properties 
	{

	}

	SubShader
	{
		Pass 
		{
			HLSLPROGRAM
			#pragma vertex UnlitPassVertex
			#pragma fragment UnlitPassFragment
			#include "UnlitPass.hlsl" // NOTE：这里少这个空格在Unity里不能编译通过！
			ENDHLSL
		}
	}
}