#ifndef CUSTOM_LIGHTING_INCLUDE
#define CUSTOM_LIGHTING_INCLUDE

float3 IncommingLight(Surface s, Light l)
{
	return saturate(dot(s.normal, l.direction) * l.attenuation) * l.color;;
}

float3 GetLighting(Surface s, BRDF brdf, Light l)
{
	return IncommingLight(s, l) * DirectBRDF(s, brdf, l);
}

float3 GetLighting(Surface surface_ws, BRDF brdf, GI gi)
{
	float3 color = gi.diffuse * brdf.diffuse;
	ShadowData shadow_data = GetShadowData(surface_ws);
	shadow_data.shadow_mask = gi.shadow_mask;
	return gi.shadow_mask.shadows.rgb;
	for (int i = 0; i < MAX_DIRECTION_LIGHT_COUNT; ++i)
	{
		Light l = GetDirectionLight(i, surface_ws, shadow_data);
		color += GetLighting(surface_ws, brdf, l);
	}
	return color;
}

#endif