using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class Shadows
{
    private const string m_buffer_name = "Shadows";
    private const int m_max_directional_light_shadow_count = 1;

    struct ShadowedDirectionalLight
    {
        public int VisibleLightIndex;
    }

    private CommandBuffer m_cmd_buffer = new CommandBuffer() { name = m_buffer_name };

    private ScriptableRenderContext m_context;
    private CullingResults m_culling_res;
    private ShadowSettings m_shadow_settings;

    private ShadowedDirectionalLight[] m_shadowed_dir_lights = new ShadowedDirectionalLight[m_max_directional_light_shadow_count];
    private int m_shadowed_dir_lights_count = 0;

    public void Setup(ScriptableRenderContext context, CullingResults cull_res, ShadowSettings shadow_settings)
    {
        m_context = context;
        m_culling_res = cull_res;
        m_shadow_settings = shadow_settings;

        m_cmd_buffer.BeginSample(m_buffer_name);
        //SetupLights();
        m_shadowed_dir_lights_count = 0;
        m_cmd_buffer.EndSample(m_buffer_name);
        ExecuteCmdBuffer();
    }

    public void ReserveDirectionalShadows(Light light, int light_idx)
    {
        if (m_shadowed_dir_lights_count < m_max_directional_light_shadow_count &&
            light.shadows != LightShadows.None &&
            light.shadowStrength > 0f &&
            m_culling_res.GetShadowCasterBounds(light_idx, out Bounds out_bounds))
        {
            m_shadowed_dir_lights[m_shadowed_dir_lights_count++] = new ShadowedDirectionalLight()
            {
                VisibleLightIndex = light_idx
            };
        }
    }

    private void ExecuteCmdBuffer()
    {
        m_context.ExecuteCommandBuffer(m_cmd_buffer);
        m_cmd_buffer.Clear();
    }
}
