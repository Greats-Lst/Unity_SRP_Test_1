using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CreateMeshInstancing : MonoBehaviour
{
    private static int m_color_id = Shader.PropertyToID("_BaseColor");

    [SerializeField]
    private Mesh m_mesh;

    [SerializeField]
    private Material m_mat;

    private Matrix4x4[] m_trs = new Matrix4x4[1023];
    private Vector4[] m_colors = new Vector4[1023];

    private MaterialPropertyBlock m_block;

    private void Awake()
    {
        for (int i = 0; i < m_trs.Length; ++i)
        {
            m_trs[i] = Matrix4x4.TRS(Random.insideUnitSphere * 10, Quaternion.identity, Vector3.one);
            m_colors[i] = new Vector4(Random.value, Random.value, Random.value, 1.0f);
        }
    }

    private void Update()
    {
        if (m_block == null)
        {
            m_block = new MaterialPropertyBlock();
            m_block.SetVectorArray(m_color_id, m_colors);
        }

        Graphics.DrawMeshInstanced(m_mesh, 0, m_mat, m_trs, 1023, m_block);
    }
}
