#ifndef CUSTOM_SURFACE_INCLUDE
#define CUSTOM_SURFACE_INCLUDE

struct Surface
{
	float3 color;

	float3 position;

	float depth;

	float3 view_direction;

	// 这里是没有管normal到底是哪个空间坐标的，
	// 那么在实际使用的时候就需要自己知道在哪个坐标系中进行
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