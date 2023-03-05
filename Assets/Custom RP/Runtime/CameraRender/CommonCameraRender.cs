using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public partial class CommonCameraRender
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
    private static ShaderTagId m_unlit_shader_tag_id = new ShaderTagId("SRPDefaultUnlit"); // Tag.LightMode=SRPDefaultUnlit是固定的
    private static ShaderTagId m_lit_shader_tag_id = new ShaderTagId("CustomLit");

    public void Render(ScriptableRenderContext context, Camera camera,
        bool enable_dynamic_batch, bool enable_instancing)
    {
        m_context = context;
        m_camera = camera;

        PrepareBuffer();
        PrepareForSceneWindow();
        if (Cull() == false)
        {
            return;
        }

        Setup();
        DrawVisibleGeometry(enable_dynamic_batch, enable_instancing);
        DrawUnsupportedShaders();
        DrawGizmos();
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
        var flag = m_camera.clearFlags;
        bool clear_depth_status = flag <= CameraClearFlags.Depth;
        bool clear_color_status = flag == CameraClearFlags.Color;
        Color background_color = clear_color_status ? m_camera.backgroundColor.linear : Color.clear;
        m_buffer.ClearRenderTarget(clear_depth_status, clear_color_status, background_color);
        // Inject Profiler & Frame Debugger - 1
        m_buffer.BeginSample(SampleName);

        ExecuteBuffer();
    }

    private void DrawVisibleGeometry(bool enable_dynamic_batch, bool enable_instancing)
    {
        var sorting_setting = new SortingSettings(m_camera)
        {
            // front-to-back for opaque
            criteria = SortingCriteria.CommonOpaque
        };
        var drawing_settings = new DrawingSettings(m_unlit_shader_tag_id, sorting_setting)
        {
            enableDynamicBatching = enable_dynamic_batch,
            enableInstancing = enable_instancing,
        };
        drawing_settings.SetShaderPassName(1, m_lit_shader_tag_id); // 构造时已经设置了第一个Shader Pass（m_unlit_shader_tag_id）
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

    private void Submit()
    {
        // Inject Profiler & Frame Debugger - 2
        m_buffer.EndSample(SampleName);

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
