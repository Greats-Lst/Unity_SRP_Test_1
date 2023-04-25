#ifndef CUSTOM_BRDF_INCLUDE
#define CUSTOM_BRDF_INCLUDE

#define MIN_REFLECTIVITY 0.04

struct BRDF
{
	float3 diffuse;
	float3 specular;
	float roughness;
	float perceptualRoughness;
	float fresnel;
};

float OneMinusReflectivity(float metailc)
{
	float range = 1.0 - MIN_REFLECTIVITY;
	return range * (1 - metailc);
}

BRDF GetBRDF(Surface s, bool apply_alpha_to_diffuse = false)
{
	BRDF brdf;

	float oneMinusReflectivity = OneMinusReflectivity(s.metalic);
	brdf.diffuse = s.color * oneMinusReflectivity;
	if (apply_alpha_to_diffuse)
	{
		brdf.diffuse *= s.alpha;
	}

	brdf.specular = lerp(MIN_REFLECTIVITY, s.color, s.metalic);

	brdf.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(s.smoothness); // 1 - s.smoothness
	brdf.roughness = PerceptualRoughnessToRoughness(brdf.perceptualRoughness); // perceptualRoughness * perceptualRoughness
	brdf.fresnel = saturate(s.smoothness + 1.0 - oneMinusReflectivity);
	return brdf;
}

float SpecularStrength(Surface s, BRDF brdf, Light l)
{
	// variant of the Minimalist CookTorrance BRDF
	// formula : 
	// 
	//						Sqr(r)
	//	   ___________________________________________
	//      Sqr(d) * max( 0.1, (Sqr(dot(L, H))) ) * n
	// 
	// d = Sqr(dot(N, H)) * (Sqr(r) - 1£© + 1.0001
	// n = 4 * r + 2
	// H = L + V

	float3 h = SafeNormalize(l.direction + s.view_direction);
	float nh2 = Square(saturate(dot(s.normal, h)));
	float lh2 = Square(saturate(dot(l.direction, h)));
	float r2 = Square(brdf.roughness);
	float d2 = Square(nh2 * (r2 - 1.0) + 1.00001);
	float normalization = brdf.roughness * 4.0 + 2.0;
	return r2 / (d2 * max(0.1, lh2) * normalization);
}

float3 DirectBRDF(Surface s, BRDF brdf, Light l)
{
	return SpecularStrength(s, brdf, l) * brdf.specular + brdf.diffuse;
}

float3 IndirectBRDF(Surface s, BRDF brdf, float3 diffuse, float3 specular)
{
	float fresnel_strength = Pow4(1.0 - saturate(dot(s.normal, s.view_direction)));
	fresnel_strength *= s.fresnel_strength;
	float3 reflection = specular * lerp(brdf.specular, brdf.fresnel, fresnel_strength);
	reflection /= brdf.roughness * brdf.roughness + 1; //roughness scatters reflection, so it should reduce the specular reflection that we end up seeing.
	return diffuse * brdf.diffuse + reflection;
}

#endif