#ifndef CUSTOM_LIGHTING_INCLUDE
#define CUSTOM_LIGHTING_INCLUDE

float3 IncommingLight(Surface s, Light l)
{
	return saturate(dot(s.normal, l.direction)) * l.color;
}

float3 GetLighting(Surface s, BRDF brdf, Light l)
{
	return IncommingLight(s, l) * DirectBRDF(s, brdf, l);
}

float3 GetLighting(Surface s, BRDF brdf)
{
	//return s.normal.y;
	//return s.normal.y * s.color;

	float3 color = float3(0.0, 0.0, 0.0);
	for (int i = 0; i < MAX_DIRECTION_LIGHT_COUNT; ++i)
	{
		Light l = GetDirectionLight(i);
		color += GetLighting(s, brdf, l);
	}
	return color;
}

#endif