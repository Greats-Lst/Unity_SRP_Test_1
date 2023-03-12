using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class Shadows
{
    private const string m_buffer_name = "Shadows";
    private const int m_max_directional_light_shadow_count = 1;
    private static int m_dir_shadow_atlas_id = Shader.PropertyToID("_DirectionalShadowAtlas");

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
        ExecuteBuffer();
    }

    public void Render()
    {
        if (m_shadowed_dir_lights_count > 0)
        {
            RenderDirectionalLightShadows();
        }
        else
        {
            m_cmd_buffer.GetTemporaryRT(m_dir_shadow_atlas_id, 1, 1,
                16, FilterMode.Bilinear, RenderTextureFormat.Shadowmap);
        }
    }

    public void RenderDirectionalLightShadows()
    {
        int atlas_size = (int)m_shadow_settings.DirectionalShadow.AtlasSize;
        m_cmd_buffer.GetTemporaryRT(m_dir_shadow_atlas_id, atlas_size, atlas_size, 
            16, FilterMode.Bilinear, RenderTextureFormat.Shadowmap);
        // We don't care about its initial state as we'll immediately clear it,
        // so we'll use <RenderBufferLoadAction.DontCare>.
        // And the purpose of the texture is to contain the shadow data,
        // so we'll need to use <RenderBufferStoreAction.Store> as the third argument.
        m_cmd_buffer.SetRenderTarget(m_dir_shadow_atlas_id, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
        m_cmd_buffer.ClearRenderTarget(true, true, Color.clear); // m_cmd_buffer.ClearRenderTarget(true, false, Color.clear)
        ExecuteBuffer();
    }

    public void ClearUp()
    {
        m_cmd_buffer.ReleaseTemporaryRT(m_dir_shadow_atlas_id);
        ExecuteBuffer();
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

    private void ExecuteBuffer()
    {
        m_context.ExecuteCommandBuffer(m_cmd_buffer);
        m_cmd_buffer.Clear();
    }
}
