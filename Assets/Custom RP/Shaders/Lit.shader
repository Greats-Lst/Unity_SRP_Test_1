Shader "Custom RP/Lit" {

	Properties
	{
		_BaseMap("Texture", 2D) = "white" {}
		_BaseColor("Color", Color) = (0.5, 0.5, 0.5, 1.0)
		[NoScaleOffset] _EmissionMap("Emission", 2D) = "white" {}
		[HDR] _EmissionColor("Emission Color", Color) = (0.0, 0.0, 0.0, 0.0)
		_Cutoff("Alpha CutOff", Range(0.0, 1.0)) = 0.5
		[Toggle(_CLIPPING)] _Clipping("Alpha Clipping", float) = 0
		[Toggle(_APPLYALPHATODIFFUSE)] _ApplyAlphaToDiffuse("Apply Alpha To Diffuse", float) = 0
		[KeywordEnum(On, Clip, Dither, Off)] _Shadows ("Shadows", Float) = 0
		[Toggle(_RECEIVE_SHADOWS)] _ReceiveShadows("Receive Shadows", Float) = 1

		// Baked Transparency
		[HideInInspector] _MainTex ("Texture For Light Map", 2D) = "white" {}
		[HideInInspector] _Color ("Color For Light Map", Color) = (0.5, 0.5, 0.5, 1.0)

		// BRDF
		_Metalic("Metalic", Range(0, 1)) = 1
		_Smoothness("Smoothness", Range(0, 1)) = 0.5
		_Fresnel("Fresnel", Range(0, 1)) = 1
		
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", float) = 0
		[Enum(On, 1, Off, 0)] _ZWrite("Z Write", float) = 1
	}

	SubShader
	{
		HLSLINCLUDE
			#include "../ShaderLibrary/Common.hlsl"
			#include "LitInput.hlsl"
		ENDHLSL

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
			#pragma target 3.5
			#pragma multi_compile _ _DIRECTIONAL_PCF3 _DIRECTIONAL_PCF5 _DIRECTIONAL_PCF7
			// NOTE: 这里少个回车竟然无法生效
			#pragma multi_compile _ _CASCADE_BLEND_SOFT _CASCADE_BLEND_DITHER
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ _SHADOW_MASK_ALWAYS _SHADOW_MASK_DISTANCE
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_instancing
			#pragma shader_feature _CLIPPING
			#pragma shader_feature _APPLYALPHATODIFFUSE
			#pragma shader_feature _RECEIVE_SHADOWS
			#pragma vertex LitPassVertex
			#pragma fragment LitPassFragment
			#include "LitPass.hlsl" // NOTE：这里少这个空格在Unity里不能编译通过！
			ENDHLSL
		}

		Pass
		{
			Tags
			{
				"LightMode" = "ShadowCaster"
			}

			ColorMask 0

			HLSLPROGRAM
			#pragma target 3.5
			//#pragma shader_feature _CLIPPING
			#pragma shader_feature _ _SHADOWS_CLIP _SHADOWS_DITHER
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_instancing
			#pragma vertex ShadowCasterPassVertex
			#pragma fragment ShadowCasterPassFragment
			#include "ShadowCasterPass.hlsl" // NOTE：这里少这个空格在Unity里不能编译通过！
			ENDHLSL
		}

		Pass
		{
			Tags
			{
				"LightMode" = "Meta"
			}

			Cull Off

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex MetaPassVertex
			#pragma fragment MetaPassFragment
			#include "MetaPass.hlsl"
			ENDHLSL
		}
	}

	CustomEditor "CustomShaderGUI"
}