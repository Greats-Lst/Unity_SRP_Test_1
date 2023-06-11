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
	float3 color = IndirectBRDF(surface_ws, brdf, gi.diffuse, gi.specular);
	ShadowData shadow_data = GetShadowData(surface_ws);
	shadow_data.shadow_mask = gi.shadow_mask;

	for (int i = 0; i < GetDirectionalLightCount(); ++i)
	{
		Light l = GetDirectionLight(i, surface_ws, shadow_data);
		color += GetLighting(surface_ws, brdf, l);
	}

	for (int j = 0; j < GetOtherLightCount(); ++j)
	{
		Light l = GetOtherLight(j, surface_ws, shadow_data);
		color += GetLighting(surface_ws, brdf, l);
	}

	return color;
}

#endif