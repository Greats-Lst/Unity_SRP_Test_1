using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class CommonCameraRender
{
    private const string CommandBufferName = "Render Camera";

    private ScriptableRenderContext m_context;
    private Camera m_camera;
    private CommandBuffer m_buffer = new CommandBuffer() { name = CommandBufferName };

    public void Render(ScriptableRenderContext context, Camera camera)
    {
        m_context = context;
        m_camera = camera;

        Setup();
        DrawVisibleGeometry();
        Submit();
    }

    private void Setup()
    {
        // Inject Profiler & Frame Debugger - 1
        m_buffer.BeginSample(CommandBufferName);

        //ExecuteBuffer();
        m_context.SetupCameraProperties(m_camera);
    }

    private void DrawVisibleGeometry()
    {
        m_context.DrawSkybox(m_camera);
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
