using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class Shadows
{
    private const string m_buffer_name = "Shadows";
    private const int m_max_directional_light_shadow_count = 4;
    private const int m_max_cascade = 4;
    private static int m_dir_shadow_atlas_id = Shader.PropertyToID("_DirectionalShadowAtlas");
    private static int m_dir_shadow_matrices_id = Shader.PropertyToID("_DirectionalShadowMatrices");
    private static int m_cascade_count_id = Shader.PropertyToID("_CascadeCount");
    private static int m_cascade_culling_spheres_id = Shader.PropertyToID("_CascadeCullingSpheres");
    private static int m_cascade_data_id = Shader.PropertyToID("_CascadeData");
    private static int m_shadow_atlas_size_id = Shader.PropertyToID("_ShadowAtlasSize");
    private static int m_shadow_distance_fade_id = Shader.PropertyToID("_ShadowDistanceFade");

    private static string[] m_directional_filter_keywords =
    {
        "_DIRECTIONAL_PCF3",
        "_DIRECTIONAL_PCF5",
        "_DIRECTIONAL_PCF7",
    };

    private static string[] m_cascade_blend_mode_keywords =
    {
        "_CASCADE_BLEND_SOFT",
        "_CASCADE_BLEND_DITHER"
    };

    private static string[] m_shadow_mask_keywords =
    {
        "_SHADOW_MASK_DISTANCE",
    };

    private static Matrix4x4[] m_dir_shadow_matrices = new Matrix4x4[m_max_directional_light_shadow_count * m_max_cascade];
    private static Vector4[] m_cascade_culling_spheres = new Vector4[m_max_cascade];
    private static Vector4[] m_cascade_data = new Vector4[m_max_cascade];

    struct ShadowedDirectionalLight
    {
        public int VisibleLightIndex;
        public float SlopeScaleBias;
        public float ShadowNearPlane;
    }

    private CommandBuffer m_cmd_buffer = new CommandBuffer() { name = m_buffer_name };

    private ScriptableRenderContext m_context;
    private CullingResults m_culling_res;
    private ShadowSettings m_shadow_settings;

    private ShadowedDirectionalLight[] m_shadowed_dir_lights = new ShadowedDirectionalLight[m_max_directional_light_shadow_count];
    private int m_shadowed_dir_lights_count = 0;
    private bool m_use_shadow_mask = false;

    public void Setup(ScriptableRenderContext context, CullingResults cull_res, ShadowSettings shadow_settings)
    {
        m_context = context;
        m_culling_res = cull_res;
        m_shadow_settings = shadow_settings;
        m_use_shadow_mask = false;

        m_cmd_buffer.BeginSample(m_buffer_name);
        //SetupLights();
        m_shadowed_dir_lights_count = 0;
        m_cmd_buffer.EndSample(m_buffer_name);
        ExecuteBuffer();
    }

    public void ClearUp()
    {
        m_cmd_buffer.ReleaseTemporaryRT(m_dir_shadow_atlas_id);
        ExecuteBuffer();
    }

    public void Render()
    {
        if (m_shadowed_dir_lights_count > 0)
        {
            RenderDirectionalShadows();
        }
        else
        {
            m_cmd_buffer.GetTemporaryRT(m_dir_shadow_atlas_id, 1, 1,
                16, FilterMode.Bilinear, RenderTextureFormat.Shadowmap);
        }

        //We have to do this even if we end up not rendering any realtime shadows, because the shadow mask isn't realtime.
        m_cmd_buffer.BeginSample(m_buffer_name);
        SetKeyword(m_shadow_mask_keywords, m_use_shadow_mask ? 0 : -1);
        m_cmd_buffer.EndSample(m_buffer_name);
        ExecuteBuffer();
    }

    private void RenderDirectionalShadows()
    {
        int atlas_size = (int)m_shadow_settings.DirectionalShadow.AtlasSize;
        m_cmd_buffer.GetTemporaryRT(m_dir_shadow_atlas_id, atlas_size, atlas_size, 
            16, FilterMode.Bilinear, RenderTextureFormat.Shadowmap);
        // We don't care about its initial state as we'll immediately clear it,
        // so we'll use <RenderBufferLoadAction.DontCare>.
        // And the purpose of the texture is to contain the shadow data,
        // so we'll need to use <RenderBufferStoreAction.Store> as the third argument.
        m_cmd_buffer.SetRenderTarget(m_dir_shadow_atlas_id, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
        m_cmd_buffer.ClearRenderTarget(true, false, Color.clear);

        m_cmd_buffer.BeginSample(m_buffer_name);
        ExecuteBuffer();

        int tiles = m_shadowed_dir_lights_count * m_shadow_settings.DirectionalShadow.CascadeCount; // 首先得出会有几张阴影图
        int split = tiles <= 1 ? 1 : tiles <= 4 ? 2 : 4; // 根据阴影图的张数得出每张图的分辨率为多少 
        int tile_size = atlas_size / split;

        for (int i = 0; i < m_shadowed_dir_lights_count; ++i)
        {
            RenderDirectionalShadows(i, split, tile_size);
        }

        m_cmd_buffer.SetGlobalInt(m_cascade_count_id, m_shadow_settings.DirectionalShadow.CascadeCount);
        float f = 1f - m_shadow_settings.DirectionalShadow.CascadeFade;
        m_cmd_buffer.SetGlobalVector(m_shadow_distance_fade_id, new Vector4(
            1.0f / m_shadow_settings.MaxDistance,
            1.0f / m_shadow_settings.DistanceFade,
            1.0f / (1.0f - f * f)));
        m_cmd_buffer.SetGlobalVectorArray(m_cascade_culling_spheres_id, m_cascade_culling_spheres);
        m_cmd_buffer.SetGlobalVectorArray(m_cascade_data_id, m_cascade_data);
        m_cmd_buffer.SetGlobalMatrixArray(m_dir_shadow_matrices_id, m_dir_shadow_matrices);

        SetKeyword(m_directional_filter_keywords, (int)m_shadow_settings.DirectionalShadow.PCFFilterMode - 1);
        SetKeyword(m_cascade_blend_mode_keywords, (int)m_shadow_settings.DirectionalShadow.CascadeBlendMode - 1);

        m_cmd_buffer.SetGlobalVector(m_shadow_atlas_size_id, new Vector4(atlas_size, 1.0f / atlas_size));

        m_cmd_buffer.EndSample(m_buffer_name);
        ExecuteBuffer();
    }

    private void RenderDirectionalShadows(int index, int split, int tile_size)
    {
        ShadowedDirectionalLight light = m_shadowed_dir_lights[index];
        ShadowDrawingSettings set = new ShadowDrawingSettings(m_culling_res, light.VisibleLightIndex);
        int cascade_count = m_shadow_settings.DirectionalShadow.CascadeCount;
        int tile_offset = index * cascade_count; // 这盏灯在阴影级联图集合数组中的起始下标（想象成二维数组的一维表示）
        Vector3 ratios = m_shadow_settings.DirectionalShadow.CascadeRatio;

        // 因为之前是一个物体可能在多个级联球内部，Unity是为了让用户更好的进行Blend
        // It makes sense to try and cull some shadow casters from larger cascades if it can be guaranteed that their results will always be covered by a smaller cascade.
        float culling_factor = Mathf.Max(0f, 0.8f - m_shadow_settings.DirectionalShadow.CascadeFade);

        for (int i = 0; i < cascade_count; ++i)
        {
            m_culling_res.ComputeDirectionalShadowMatricesAndCullingPrimitives(
                light.VisibleLightIndex,
                //0, 1, Vector3.zero,
                i, cascade_count, ratios,
                tile_size, light.ShadowNearPlane,
                out Matrix4x4 view_matrix,
                out Matrix4x4 proj_matrix,
                out ShadowSplitData shadow_split_data);

            shadow_split_data.shadowCascadeBlendCullingFactor = culling_factor;
            set.splitData = shadow_split_data;
            if (index == 0)
            {
                SetCascadeData(i, shadow_split_data.cullingSphere, tile_size);
            }
            int tile_idx = tile_offset + i;
            m_dir_shadow_matrices[tile_idx] = Convert2AtlasMatrix(proj_matrix * view_matrix,
                SetTileViewport(tile_idx, split, tile_size), split);
            m_cmd_buffer.SetViewProjectionMatrices(view_matrix, proj_matrix);
            m_cmd_buffer.SetGlobalDepthBias(0f, light.SlopeScaleBias);
            ExecuteBuffer();
            // DrawShadows only renders objects with materials that have a "ShadowCaster" pass
            m_context.DrawShadows(ref set);
            m_cmd_buffer.SetGlobalDepthBias(0f, 0f);
        }
    }

    private void SetKeyword(string[] keywords, int enable_idx)
    {
        for (int i = 0; i < keywords.Length; ++i)
        {
            if (i == enable_idx)
            {
                m_cmd_buffer.EnableShaderKeyword(keywords[i]);
            }
            else
            {
                m_cmd_buffer.DisableShaderKeyword(keywords[i]);
            }
        }   
    }

    private void SetCascadeData(int index, Vector4 culling_sphere, int tile_size)
    {
        float texel_size = 2.0f * culling_sphere.w / tile_size; // 每级级联阴影的单张ShadowMap里单个像素对应多少世界坐标距离
        float filter_size = texel_size * ((float)m_shadow_settings.DirectionalShadow.PCFFilterMode + 1);
        culling_sphere.w -= filter_size;
        culling_sphere.w *= culling_sphere.w;
        m_cascade_culling_spheres[index] = culling_sphere;
        m_cascade_data[index] = new Vector4(1.0f / culling_sphere.w,
            filter_size * 1.4142f);
    }

    private Vector2 SetTileViewport(int index, int split, int tile_size)
    {
        // 可以理解为 index是 二维数组的一维表示 的下标，而split决定了需要把这个一维数组分割成split列的二维数组，tile_size则是每个小方块的resolution
        Vector2 offset = new Vector2(index % split, index / split);
        m_cmd_buffer.SetViewport(new Rect(offset.x * tile_size, offset.y * tile_size, 
            tile_size, tile_size));
        return offset;
    }

    public Vector3 ReserveDirectionalShadows(Light light, int light_idx)
    {
        if (m_shadowed_dir_lights_count < m_max_directional_light_shadow_count &&
            light.shadows != LightShadows.None &&
            light.shadowStrength > 0f)
        {
            LightBakingOutput light_bake = light.bakingOutput;
            if (light_bake.lightmapBakeType == LightmapBakeType.Mixed &&
                light_bake.mixedLightingMode == MixedLightingMode.Shadowmask)
            {
                m_use_shadow_mask = true;
            }

            if (m_culling_res.GetShadowCasterBounds(light_idx, out Bounds out_bounds) == false)
            {
                return new Vector3(-light.shadowStrength, 0, 0);
            }

            m_shadowed_dir_lights[m_shadowed_dir_lights_count] = new ShadowedDirectionalLight() { 
                VisibleLightIndex = light_idx,
                SlopeScaleBias = light.shadowBias,
                ShadowNearPlane = light.shadowNearPlane,
            };

            return new Vector3(light.shadowStrength, 
                m_shadow_settings.DirectionalShadow.CascadeCount * m_shadowed_dir_lights_count++,
                light.shadowNormalBias);
        }

        return Vector3.zero;
    }

    private void ExecuteBuffer()
    {
        m_context.ExecuteCommandBuffer(m_cmd_buffer);
        m_cmd_buffer.Clear();
    }

    /// <summary>
    /// 世界空间转ShadowMap空间
    /// </summary>
    /// <param name="m"></param>
    /// <param name="offset"></param>
    /// <param name="split"></param>
    /// <returns></returns>
    private Matrix4x4 Convert2AtlasMatrix(Matrix4x4 m, Vector2 offset, int split)
    {
        if (SystemInfo.usesReversedZBuffer)
        {
            // 一开始还想不通为什么设置列向量取反，还以为和左乘右乘矩阵有关系
            // 其实这里就是左乘（Mat * Point），左乘的最终结果里的z分量是由Mat的第三行和顶点的xyzw组合相加的
            // 所以取反第三行就能有取反最终结果里z分量的效果
            m.m20 = -m.m20;
            m.m21 = -m.m21;
            m.m22 = -m.m22;
            m.m23 = -m.m23;
        }

        // [-1, 1] => [0, 1] 
        // Matrix:
        // | 0.5    0       0       0.5 |
        // | 0      0.5     0       0.5 |
        // | 0      0       0.5     0.5 |
        // | 0      0       0       1   |
        //m.m00 = 0.5f * (m.m00 + m.m30);
        //m.m01 = 0.5f * (m.m01 + m.m31);
        //m.m02 = 0.5f * (m.m02 + m.m32);
        //m.m03 = 0.5f * (m.m03 + m.m33);
        //m.m10 = 0.5f * (m.m10 + m.m30);
        //m.m11 = 0.5f * (m.m11 + m.m31);
        //m.m12 = 0.5f * (m.m12 + m.m32);
        //m.m13 = 0.5f * (m.m13 + m.m33);
        //m.m20 = 0.5f * (m.m20 + m.m30);
        //m.m21 = 0.5f * (m.m21 + m.m31);
        //m.m22 = 0.5f * (m.m22 + m.m32);
        //m.m23 = 0.5f * (m.m23 + m.m33);

        // 因为ShadowMap被Split了，所以要从[0,1] -> 对应的分区
        // Matrix: (scale = 0.5, tmpOffset = 0.5) 但是本函数的参数中的offset传进来的是0或者1，具体可查看SetTileViewport
        // (tmpOffset = offset / 2)
        // | scale  0       0   tmpOffset.x |
        // | 0      scale   0   tmpOffset.y |
        // | 0      0       1   0           |
        // | 0      0       0   1           |
        //float scale = 1f / split;
        //m.m00 = (m.m00 + offset.x * m.m30) * scale;
        //m.m01 = (m.m01 + offset.x * m.m31) * scale;
        //m.m02 = (m.m02 + offset.x * m.m32) * scale;
        //m.m03 = (m.m03 + offset.x * m.m33) * scale;
        //m.m10 = (m.m10 + offset.y * m.m30) * scale;
        //m.m11 = (m.m11 + offset.y * m.m31) * scale;
        //m.m12 = (m.m12 + offset.y * m.m32) * scale;
        //m.m13 = (m.m13 + offset.y * m.m33) * scale;

        // 合并所有矩阵之后
        float scale = 1f / split;
        m.m00 = (0.5f * (m.m00 + m.m30) + offset.x * m.m30) * scale;
        m.m01 = (0.5f * (m.m01 + m.m31) + offset.x * m.m31) * scale;
        m.m02 = (0.5f * (m.m02 + m.m32) + offset.x * m.m32) * scale;
        m.m03 = (0.5f * (m.m03 + m.m33) + offset.x * m.m33) * scale;
        m.m10 = (0.5f * (m.m10 + m.m30) + offset.y * m.m30) * scale;
        m.m11 = (0.5f * (m.m11 + m.m31) + offset.y * m.m31) * scale;
        m.m12 = (0.5f * (m.m12 + m.m32) + offset.y * m.m32) * scale;
        m.m13 = (0.5f * (m.m13 + m.m33) + offset.y * m.m33) * scale;
        m.m20 = 0.5f * (m.m20 + m.m30);
        m.m21 = 0.5f * (m.m21 + m.m31);
        m.m22 = 0.5f * (m.m22 + m.m32);
        m.m23 = 0.5f * (m.m23 + m.m33);
        return m;
    }
}
