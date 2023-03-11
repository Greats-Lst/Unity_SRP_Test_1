Shader "Custom RP/Lit" {

	Properties
	{
		_BaseMap("Texture", 2D) = "white" {}
		_BaseColor("Color", Color) = (0.5, 0.5, 0.5, 1.0)
		_Cutoff("Alpha CutOff", Range(0.0, 1.0)) = 0.5
		[Toggle(_CLIPPING)] _Clipping("Alpha Clipping", float) = 0
		[Toggle(_APPLYALPHATODIFFUSE)] _ApplyAlphaToDiffuse("Apply Alpha To Diffuse", float) = 0

		// BRDF
		_Metalic("Metalic", Range(0, 1)) = 1
		_Smoothness("Smoothness", Range(0, 1)) = 0.5
		
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", float) = 0
		[Enum(On, 1, Off, 0)] _ZWrite("Z Write", float) = 1
	}

	SubShader
	{
		Pass 
		{
			Tags
			{
				"LightMode" = "CustomLit"
			}
			// Here source refers to what gets drawn now and destination to what was drawn earlier and where the result will end up
			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]
			HLSLPROGRAM
			#pragma multi_compile_instancing
			#pragma shader_feature _CLIPPING
			#pragma shader_feature _APPLYALPHATODIFFUSE
			#pragma vertex LitPassVertex
			#pragma fragment LitPassFragment
			#include "LitPass.hlsl" // NOTE：这里少这个空格在Unity里不能编译通过！
			ENDHLSL
		}
	}

	CustomEditor "CustomShaderGUI"
}