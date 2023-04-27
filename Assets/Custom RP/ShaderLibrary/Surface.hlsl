#ifndef CUSTOM_SURFACE_INCLUDE
#define CUSTOM_SURFACE_INCLUDE

struct Surface
{
	float3 color;

	float3 position;

	float depth;

	float3 view_direction;

	// ������û�й�normal�������ĸ��ռ�����ģ�
	// ��ô��ʵ��ʹ�õ�ʱ�����Ҫ�Լ�֪�����ĸ�����ϵ�н���
	float3 normal;

	float3 interporlated_normal;

	float alpha;

	float metalic;

	float occlusion;

	float smoothness;

	float fresnel_strength;

	float dither;
};

#endif