Shader "Custom RP/Unlit" {

	Properties
	{
		_BaseMap("Texture", 2D) = "white" {}
		_BaseColor("Color", Color) = (1.0, 0.0, 0.0, 1.0)
		_Cutoff("Alpha CutOff", Range(0.0, 1.0)) = 0.5
		[Toggle(_CLIPPING)] _Clipping ("Alpha Clipping", float) = 0
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", float) = 0
		[Enum(On, 1, Off, 0)] _ZWrite("Z Write", float) = 1
	}

	SubShader
	{
		Pass 
		{
			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]
			HLSLPROGRAM
			#pragma multi_compile_instancing
			#pragma shader_feature _CLIPPING
			#pragma vertex UnlitPassVertex
			#pragma fragment UnlitPassFragment
			#include "UnlitPass.hlsl" // NOTE：这里少这个空格在Unity里不能编译通过！
			ENDHLSL
		}
	}

	CustomEditor "CustomShaderGUI"
}