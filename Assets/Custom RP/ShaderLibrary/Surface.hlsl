#ifndef CUSTOM_SURFACE_INCLUDE
#define CUSTOM_SURFACE_INCLUDE

struct Surface
{
	float3 color;

	// 这里是没有管normal到底是哪个空间坐标的，
	// 那么在实际使用的时候就需要自己知道在哪个坐标系中进行
	float3 normal;

	float alpha;

	float metalic;

	float smoothness;
};

#endif