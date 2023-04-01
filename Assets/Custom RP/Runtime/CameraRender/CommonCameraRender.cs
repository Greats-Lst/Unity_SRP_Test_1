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
    private Lighting m_light = new Lighting();

    // Camera Buffer
    private CommandBuffer m_buffer = new CommandBuffer() { name = CommandBufferName };

    // Cull
    private CullingResults m_cull_res;

    // Drawing Geometry
    private static ShaderTagId m_unlit_shader_tag_id = new ShaderTagId("SRPDefaultUnlit"); // Tag.LightMode=SRPDefaultUnlit是固定的
    private static ShaderTagId m_lit_shader_tag_id = new ShaderTagId("CustomLit");

    public void Render(ScriptableRenderContext context, 
        Camera camera,
        bool enable_dynamic_batch, 
        bool enable_instancing,
        ShadowSettings shadow_settings)
    {
        m_context = context;
        m_camera = camera;

        PrepareBuffer();
        PrepareForSceneWindow();
        if (Cull(shadow_settings.MaxDistance) == false)
        {
            return;
        }

        m_buffer.BeginSample(SampleName);
        ExecuteBuffer();
        m_light.Setup(context, m_cull_res, shadow_settings);
        m_buffer.EndSample(SampleName);

        Setup();
        DrawVisibleGeometry(enable_dynamic_batch, enable_instancing);
        DrawUnsupportedShaders();
        DrawGizmos();
        m_light.ClearUp();
        Submit();
    }

    private bool Cull(float max_shadow_distance)
    {
        if (m_camera.TryGetCullingParameters(out ScriptableCullingParameters parameters))
        {
            parameters.shadowDistance = Mathf.Min(max_shadow_distance, m_camera.farClipPlane);
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
            // PerObjectData.Lightmaps : render lightmapped objects with a shader variant that has the LIGHTMAP_ON keyword.
            perObjectData = PerObjectData.Lightmaps | PerObjectData.LightProbe, 
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
        // Issue1 Resolve: 每一次设置CommandBuffer等于说要进行一次操作，比如第一次要进行Clear背景色，设置完就得立马开始进行（顺便附带了BeginSample）
        // 等所有东西全部渲染完之后又设置了一次CommandBuffer（这里是EndSample操作），设置再立马开始进行
        ExecuteBuffer();
        m_context.Submit();
    }

    private void ExecuteBuffer()
    {
        m_context.ExecuteCommandBuffer(m_buffer);
        m_buffer.Clear();
    }
}
