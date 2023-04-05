using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class CreateMeshInstancing : MonoBehaviour
{
    private static int m_color_id = Shader.PropertyToID("_BaseColor");
    private static int m_metalic_id = Shader.PropertyToID("_Metalic");
    private static int m_smoothness_id = Shader.PropertyToID("_Smoothness");

    [SerializeField]
    private Mesh m_mesh;

    [SerializeField]
    private Material m_mat;

    /// <summary>
    /// DrawInstanced的时候使用LPPV还是每帧生成LightProbe数据
    /// </summary>
    [SerializeField]
    private LightProbeProxyVolume m_lppv = null;

    [SerializeField]
    private int m_mesh_count = 1024;

    private Matrix4x4[] m_trs;
    private Vector4[] m_colors;
    private float[] m_matelics;
    private float[] m_smoothness;

    private MaterialPropertyBlock m_block;

    private void Awake()
    {
        m_trs = new Matrix4x4[m_mesh_count];
        m_colors = new Vector4[m_mesh_count];
        m_matelics = new float[m_mesh_count];
        m_smoothness = new float[m_mesh_count];

        for (int i = 0; i < m_trs.Length; ++i)
        {
            m_trs[i] = Matrix4x4.TRS(Random.insideUnitSphere * 10,
                Quaternion.Euler(Random.Range(0, 360), Random.Range(0, 360), Random.Range(0, 360)),
                new Vector3(Random.Range(0.5f, 1.5f), Random.Range(0.5f, 1.5f), Random.Range(0.5f, 1.5f)));

            m_colors[i] = new Vector4(Random.value, Random.value, Random.value, Random.Range(0.5f, 1.0f));
            m_matelics[i] = Random.value < 0.25 ? 1f : 0f;
            m_smoothness[i] = Random.Range(0.05f, 0.95f);
        }
    }

    private void Update()
    {
        if (m_block == null)
        {
            m_block = new MaterialPropertyBlock();
            m_block.SetVectorArray(m_color_id, m_colors);
            m_block.SetFloatArray(m_metalic_id, m_matelics);
            m_block.SetFloatArray(m_smoothness_id, m_smoothness);

            if (m_lppv == null)
            {
                var positions = new Vector3[m_mesh_count];
                for (int i = 0; i < m_mesh_count; ++i)
                {
                    positions[i] = m_trs[i].GetColumn(3);
                }
                var light_probes = new SphericalHarmonicsL2[m_mesh_count];
                LightProbes.CalculateInterpolatedLightAndOcclusionProbes(positions, light_probes, null);
                m_block.CopySHCoefficientArraysFrom(light_probes);
            }
        }

        var light_probe_usage = m_lppv == null ? LightProbeUsage.CustomProvided : LightProbeUsage.UseProxyVolume;
        Graphics.DrawMeshInstanced(m_mesh, 0, m_mat, m_trs, m_mesh_count, m_block,
            ShadowCastingMode.On, true, 0, null, light_probe_usage);
    }
}
