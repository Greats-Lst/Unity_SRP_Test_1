#ifndef CUSTOM_UNLIT_PASS_INCLUDE
#define CUSTOM_UNLIT_PASS_INCLUDE

//#include "../ShaderLibrary/Common.hlsl"

//CBUFFER_START(UnityPerMaterial)
//	float4 _BaseColor;
//CBUFFER_END

//TEXTURE2D(_BaseMap);
//SAMPLER(sampler_BaseMap);

// for support to per-instance material Data
//UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
//	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
//
//	//float4 _BaseColor;
//	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
//
//	UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
//UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

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

Varyings UnlitPassVertex(Attributes input) //: SV_POSITION
{
	Varyings output;
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
	float3 worldPos = TransformObjectToWorld(input.positionOS);
	output.positionCS = TransformWorldToHClip(worldPos);

	//float4 st = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST);
	//output.baseUV = input.baseUV * st.xy + st.zw;
	output.baseUV = TransformBaseUV(input.baseUV);
	return output;
}


float4 UnlitPassFragment(Varyings input) : SV_TARGET
{
	// NOTE����������Id��������Ҫ��һ������Ϊ���ڽű���ʹ��Graphics.DrawMeshInstanced�����ģ�
	// ������ǲ²���GPU Instancing��ʵ��ԭ��Ļ���������������úò��ʺ���ˮ���������ã���Ϊ�ܺ�������Ϊ������ͬ����
	// ��ôҪ������ʵ���Ļ�����Ȼ��Ҫ����һ������ȥ��¼ÿ��ʵ���Ĳ������ݣ�ͨ��UnityPerMaterial���飿����
	// ����ȻҪ�������ǿ϶�����Ҫ֪����ǰ���ʵ���������е��±���ʲô��
	// ���Բ�����vs����ps��϶���һҪ����ǰ��±����úã�������UNITY_ACCESS_INSTANCED_PROP֮ǰҪ���úã�
	// ����GPUʹ�õ�Ӧ�û����±�Ϊ0������
	UNITY_SETUP_INSTANCE_ID(input);

	//float4 base_map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.baseUV);
	//float4 base_color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
	//float4 res_color = base_map * base_color;
	float4 res_color = GetBase(input.baseUV);
#if defined(_CLIPPING)
	//float alpha_cut_off = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff);
	clip(res_color.a - GetCutoff(input.baseUV));
#endif
	return res_color;
}

#endif