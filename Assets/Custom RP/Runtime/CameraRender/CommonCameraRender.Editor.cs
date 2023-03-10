using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Profiling;

partial class CommonCameraRender
{
    partial void DrawUnsupportedShaders();

    partial void DrawGizmos();

    partial void PrepareForSceneWindow();

    partial void PrepareBuffer();

#if UNITY_EDITOR
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

    partial void DrawUnsupportedShaders()
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

    partial void DrawGizmos()
    {
        if (UnityEditor.Handles.ShouldRenderGizmos())
        {
            m_context.DrawGizmos(m_camera, GizmoSubset.PreImageEffects);
            m_context.DrawGizmos(m_camera, GizmoSubset.PostImageEffects);
        }
    }

    partial void PrepareForSceneWindow()
    {
        if (m_camera.cameraType == CameraType.SceneView)
        {
            ScriptableRenderContext.EmitWorldGeometryForSceneView(m_camera);
        }
    }

    string SampleName { get; set; }
    partial void PrepareBuffer()
    {
        Profiler.BeginSample("Editor Only");
        m_buffer.name = SampleName = m_camera.name;
        Profiler.EndSample();
    }
#else
    const string SampleName = CommandBufferName;
#endif
}
