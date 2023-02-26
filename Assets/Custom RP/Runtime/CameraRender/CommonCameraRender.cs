using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class CommonCameraRender
{
    private ScriptableRenderContext m_context;

    private Camera m_camera;

    private CommandBuffer m_cmd_buffer;
    private string m_cmd_name = "Camera Render";

    public void Render(ScriptableRenderContext context, Camera camera)
    {
        m_context = context;
        m_camera = camera;

        m_cmd_buffer = new CommandBuffer()
        {
            name = m_cmd_name,
        };

        Setup();
        DrawVisibleGeometry();
        Submit();
    }

    private void Setup()
    {
        // Inject Profiler & Frame Debugger - 1
        m_cmd_buffer.BeginSample(m_cmd_name);

        m_context.ExecuteCommandBuffer(m_cmd_buffer);
        m_context.SetupCameraProperties(m_camera);
    }

    private void DrawVisibleGeometry()
    {
        m_context.DrawSkybox(m_camera);
    }

    private void Submit()
    {
        // Inject Profiler & Frame Debugger - 2
        m_cmd_buffer.EndSample("111");

        m_context.Submit();
    }
}
