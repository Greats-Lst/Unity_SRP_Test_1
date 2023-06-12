using Unity.Collections;
using UnityEngine;
using UnityEngine.Experimental.GlobalIllumination;
using LightType = UnityEngine.LightType;

public partial class MyScriptRenderPipieline
{
    partial void InitializeForEditor();

#if UNITY_EDITOR

    partial void InitializeForEditor()
    {
        Lightmapping.SetDelegate(lights_delegate);
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);

        Lightmapping.ResetDelegate();
    }

    static Lightmapping.RequestLightsDelegate lights_delegate =
        (Light[] lights, NativeArray<LightDataGI> output) => {
            var light_data = new LightDataGI();
            for (int i = 0; i < lights.Length; ++i)
            {
                Light light = lights[i];
                switch (light.type)
                {
                    case LightType.Directional:
                        var directional_light = new DirectionalLight();
                        LightmapperUtils.Extract(light, ref directional_light);
                        light_data.Init(ref directional_light);
                        break;
                    case LightType.Point:
                        var point_light = new PointLight();
                        LightmapperUtils.Extract(light, ref point_light);
                        light_data.Init(ref point_light);
                        break;
                    case LightType.Spot:
                        var spot_light = new SpotLight();
                        LightmapperUtils.Extract(light, ref spot_light);
                        light_data.Init(ref spot_light);
                        break;
                    case LightType.Area:
                        var rect_light = new RectangleLight();
                        LightmapperUtils.Extract(light, ref rect_light);
                        rect_light.mode = LightMode.Baked;
                        light_data.Init(ref rect_light);
                        break;
                    default:
                        light_data.InitNoBake(light.GetInstanceID());
                        break;
                }
                light_data.falloff = FalloffType.InverseSquared;
                output[i] = light_data;
            }
        };

#endif
}
