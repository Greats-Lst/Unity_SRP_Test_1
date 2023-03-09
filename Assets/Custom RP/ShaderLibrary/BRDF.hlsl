#ifndef CUSTOM_BRDF_INCLUDE
#define CUSTOM_BRDF_INCLUDE

#define MIN_REFLECTIVITY 0.04

struct BRDF
{
	float3 diffuse;
	float3 specular;
	float roughness;
};

float OneMinusReflectivity(float metailc)
{
	float range = 1.0 - MIN_REFLECTIVITY;
	return range * (1 - metailc);
}

BRDF GetBRDF(Surface s)
{
	BRDF brdf;

	float oneMinusReflectivity = OneMinusReflectivity(s.metalic);
	brdf.diffuse = s.color * oneMinusReflectivity;

	brdf.specular = lerp(MIN_REFLECTIVITY, s.color, s.metalic);

	float perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(s.smoothness); // 1 - s.smoothness
	brdf.roughness = PerceptualRoughnessToRoughness(perceptualRoughness); // perceptualRoughness * perceptualRoughness
	return brdf;
}

#endif