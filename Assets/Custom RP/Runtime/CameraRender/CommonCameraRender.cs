using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class CommonCameraRender
{
    private const string CommandBufferName = "Render Camera";

    // Overall Render
    private ScriptableRenderContext m_context;
    private Camera m_camera;

    // Camera Buffer
    private CommandBuffer m_buffer = new CommandBuffer() { name = CommandBufferName };

    // Cull
    private CullingResults m_cull_res;

    // Drawing Geometry
    private static ShaderTagId m_unlit_shader_tag_id = new ShaderTagId("SRPDefaultUnlit"); // 这里的SRPDefaultUnlit是固定的
    private static ShaderTagId[] m_legacy_shader_tag_ids =
    {
        new ShaderTagId("Always"),
        new ShaderTagId("ForwardBase"),
        new ShaderTagId("PrepassBase"),
        new ShaderTagId("Vertex"),
        new ShaderTagId("VertexLMRGBM"),
        new ShaderTagId("VertexLM")
    };

    // Editor Rendering
    private static Material m_error_mat;

    public void Render(ScriptableRenderContext context, Camera camera)
    {
        m_context = context;
        m_camera = camera;

        if (Cull() == false)
        {
            return;
        }

        Setup();
        DrawVisibleGeometry();
        DrawUnsupportedShaders();
        Submit();
    }

    private bool Cull()
    {
        if (m_camera.TryGetCullingParameters(out ScriptableCullingParameters parameters))
        {
            m_cull_res = m_context.Cull(ref parameters);
            return true;
        }

        return false;
    }

    private void Setup()
    {
        m_context.SetupCameraProperties(m_camera);
        m_buffer.ClearRenderTarget(true, true, Color.clear);
        // Inject Profiler & Frame Debugger - 1
        m_buffer.BeginSample(CommandBufferName);

        ExecuteBuffer();
    }

    private void DrawVisibleGeometry()
    {
        var sorting_setting = new SortingSettings(m_camera)
        {
            // front-to-back for opaque
            criteria = SortingCriteria.CommonOpaque
        };
        var drawing_settings = new DrawingSettings(m_unlit_shader_tag_id, sorting_setting);
        var filtering_settings = new FilteringSettings(RenderQueueRange.opaque);

        // Opaque
        m_context.DrawRenderers(m_cull_res, ref drawing_settings, ref filtering_settings);

        // Sky Box
        m_context.DrawSkybox(m_camera);

        // Transparent
        sorting_setting.criteria = SortingCriteria.CommonTransparent;
        drawing_settings.sortingSettings = sorting_setting;
        filtering_settings.renderQueueRange = RenderQueueRange.transparent;
        m_context.DrawRenderers(m_cull_res, ref drawing_settings, ref filtering_settings);
    }

    private void DrawUnsupportedShaders()
    {
        if (m_error_mat == null)
        {
            m_error_mat = new Material(Shader.Find("Hidden/InternalErrorShader"));
        }

        var drawing_setting = new DrawingSettings(m_legacy_shader_tag_ids[0], new SortingSettings(m_camera));
        drawing_setting.overrideMaterial = m_error_mat;
        var filtering_setting = FilteringSettings.defaultValue;

        for (int i = 1; i < m_legacy_shader_tag_ids.Length; ++i)
        {
            drawing_setting.SetShaderPassName(i, m_legacy_shader_tag_ids[i]);
        }

        m_context.DrawRenderers(m_cull_res, ref drawing_setting, ref filtering_setting);
    }

    private void Submit()
    {
        // Inject Profiler & Frame Debugger - 2
        m_buffer.EndSample(CommandBufferName);

        // Issue1：不太懂为什么Setup做一次，这里还要再做一次才能在FrameDebugger里显示出来
        ExecuteBuffer();
        m_context.Submit();
    }

    private void ExecuteBuffer()
    {
        m_context.ExecuteCommandBuffer(m_buffer);
        m_buffer.Clear();
    }
}
