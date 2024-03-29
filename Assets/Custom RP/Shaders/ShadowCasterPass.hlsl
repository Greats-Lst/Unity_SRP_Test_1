#ifndef CUSTOM_SHADOW_CASTER_PASS_INCLUDE
#define CUSTOM_SHADOW_CASTER_PASS_INCLUDE

struct Attributes {
	float3 positionOS : POSITION;
	float2 baseUV : TEXCOORD0;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
	float4 positionCS : SV_POSITION;
	float2 baseUV : VAR_BASE_UV;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings ShadowCasterPassVertex(Attributes input) //: SV_POSITION
{
	Varyings output;
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
	float3 positionWS = TransformObjectToWorld(input.positionOS);
	output.positionCS = TransformWorldToHClip(positionWS);

	#if UNITY_REVERSED_Z
		output.positionCS.z = min(output.positionCS.z, output.positionCS.w * UNITY_NEAR_CLIP_VALUE);
	#else
		output.positionCS.z = max(output.positionCS.z, output.positionCS.w * UNITY_NEAR_CLIP_VALUE);
	#endif

	output.baseUV = TransformBaseUV(input.baseUV);
	return output;
}

void ShadowCasterPassFragment(Varyings input) //: SV_TARGET
{
	UNITY_SETUP_INSTANCE_ID(input);
	ClipLOD(input.positionCS.xy, unity_LODFade.x);
	InputConfig c = GetInputConfig(input.baseUV);
	float4 res_color = GetBase(c);

	#if defined(_SHADOWS_CLIP)
		clip(res_color.a - GetCutoff(c));
	#elif defined(_SHADOWS_DITHER)
		float dither = InterleavedGradientNoise(input.positionCS.xy, 0);
		clip(res_color.a - dither);
	#endif
}

#endif