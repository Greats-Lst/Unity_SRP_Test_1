using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class MyScriptRenderPipieline : RenderPipeline
{
    private CommonCameraRender m_camera_render = new CommonCameraRender();

    public MyScriptRenderPipieline()
    {
        GraphicsSettings.useScriptableRenderPipelineBatching = true;
    }

    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        foreach (var cam in cameras)
        {
            m_camera_render.Render(context, cam);
        }
    }
}
