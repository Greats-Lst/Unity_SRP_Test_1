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
	// NOTE：重新设置Id还是蛮重要的一步，因为我在脚本中使用Graphics.DrawMeshInstanced来画的，
	// 如果我们猜测下GPU Instancing的实现原理的话，可以想象成设置好材质和流水线其他设置（因为能合批是因为材质相同），
	// 那么要画各种实例的话，必然需要先用一个数组去记录每个实例的材质数据（通过UnityPerMaterial数组？），
	// 而既然要用数组那肯定就需要知道当前这个实例在数组中的下标是什么，
	// 所以不管在vs还是ps里肯定第一要务就是把下标设置好（至少在UNITY_ACCESS_INSTANCED_PROP之前要设置好）
	// 否则GPU使用的应该还是下标为0的数据
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