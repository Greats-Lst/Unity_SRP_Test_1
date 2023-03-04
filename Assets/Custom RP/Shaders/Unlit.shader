Shader "Custom RP/Unlit" {

	Properties
	{
		_BaseColor("Color", Color) = (1.0, 0.0, 0.0, 1.0)
	}

	SubShader
	{
		Pass 
		{
			HLSLPROGRAM
			#pragma multi_compile_instancing
			#pragma vertex UnlitPassVertex
			#pragma fragment UnlitPassFragment
			#include "UnlitPass.hlsl" // NOTE：这里少这个空格在Unity里不能编译通过！
			ENDHLSL
		}
	}
}