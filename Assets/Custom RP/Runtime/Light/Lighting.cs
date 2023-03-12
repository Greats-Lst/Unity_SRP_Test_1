using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class Lighting
{
    private const string m_buffer_name = "Lighting";
    private const int m_max_directional_light_count = 4;

    // 以下Property会在Light.hlsl里定义
    private static int m_dir_light_count = Shader.PropertyToID("_DirectionLightMaxCount");
    private static int m_directional_light_color_tags = Shader.PropertyToID("_DirectionalLightColors");
    private static int m_directional_light_dir_tags = Shader.PropertyToID("_DirectionalLightDirections");

    private static Vector4[] m_direction_light_colors = new Vector4[m_max_directional_light_count];
    private static Vector4[] m_direction_light_dirs = new Vector4[m_max_directional_light_count];

    private CommandBuffer m_cmd_buffer = new CommandBuffer() { name = m_buffer_name };

    private CullingResults m_culling_res;
    private Shadows m_shadow = new Shadows();

    public void Setup(ScriptableRenderContext context, CullingResults cull_res, ShadowSettings shadow_settings)
    {
        m_culling_res = cull_res;

        m_cmd_buffer.BeginSample(m_buffer_name);
        m_shadow.Setup(context, cull_res, shadow_settings);
        SetupLights();
        m_cmd_buffer.EndSample(m_buffer_name);

        context.ExecuteCommandBuffer(m_cmd_buffer);
        m_cmd_buffer.Clear();
    }

    private void SetupLights()
    {
        int dir_light_count = 0;
        for (int i = 0; i < m_culling_res.visibleLights.Length; ++i)
        {
            var light = m_culling_res.visibleLights[i];
            if (light.lightType == LightType.Directional)
            {
                // 这里也很有意思，原文说light这个struct本身太大了，所以以引用方式传递
                SetupDirectionLights(dir_light_count++, ref light);
            }
            if (dir_light_count >= m_max_directional_light_count)
            {
                break;
            }
        }
        for (int i = 0; i < m_max_directional_light_count - dir_light_count; ++i)
        {
            m_direction_light_colors[m_max_directional_light_count - 1 - i] = Color.black;
        }

        m_cmd_buffer.SetGlobalInt(m_dir_light_count, dir_light_count);
        m_cmd_buffer.SetGlobalVectorArray(m_directional_light_color_tags, m_direction_light_colors);
        m_cmd_buffer.SetGlobalVectorArray(m_directional_light_dir_tags, m_direction_light_dirs);
    }

    private void SetupDirectionLights(int index, ref VisibleLight visible_light)
    {
        if (index < 0 || index > m_max_directional_light_count)
        {
            return;
        }

        m_shadow.ReserveDirectionalShadows(visible_light.light, index);
        m_direction_light_colors[index] = visible_light.finalColor.linear;
        // 这里很有意思，localToWorldMaxtrix以[x y z w]来表示的话，那么其实这个矩阵就是该对象的3个基向量在世界坐标系中的表示
        // 怎么理解呢，比如该对象没有旋转没有位移没有缩放，那么其z基向量在世界坐标系中的表示是（0，0，1），其z基向量在模型坐标系中的表示是（0，0，1）
        // 但是如果该对象绕着世界坐标的y轴顺时针旋转90°的话，那么其z基向量在世界坐标系中的表示是（1，0，0）（其实就是旋转到世界坐标系的x轴方向），其z基向量在模型坐标系中的表示还是（0，0，1）
        m_direction_light_dirs[index] = -visible_light.localToWorldMatrix.GetColumn(2);
    }
}
