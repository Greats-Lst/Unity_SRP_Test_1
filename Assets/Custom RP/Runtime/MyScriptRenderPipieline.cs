using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class MyScriptRenderPipieline : RenderPipeline
{
    private CommonCameraRender m_camera_render = new CommonCameraRender();
    private bool m_enable_dynamic_batch;
    private bool m_enable_instancing;
    public MyScriptRenderPipieline(bool enable_dynamic_batch, bool enable_instancing, bool enable_srp_batch)
    {
        GraphicsSettings.useScriptableRenderPipelineBatching = enable_srp_batch;

        m_enable_dynamic_batch = enable_dynamic_batch;
        m_enable_instancing = enable_instancing;
    }

    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        foreach (var cam in cameras)
        {
            m_camera_render.Render(context, cam, m_enable_dynamic_batch, m_enable_instancing);
        }
    }
}
