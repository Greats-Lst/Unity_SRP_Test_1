Shader "Custom RP/Lit" {

	Properties
	{
		_BaseMap("Texture", 2D) = "white" {}
		_BaseColor("Color", Color) = (0.5, 0.5, 0.5, 1.0)
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
			Tags
			{
				"LightMode" = "CustomLit"
			}
			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]
			HLSLPROGRAM
			#pragma multi_compile_instancing
			#pragma shader_feature _CLIPPING
			#pragma vertex LitPassVertex
			#pragma fragment LitPassFragment
			#include "LitPass.hlsl" // NOTE������������ո���Unity�ﲻ�ܱ���ͨ����
			ENDHLSL
		}
	}
}