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

	float alpha;

	float metalic;

	float smoothness;
};

#endif