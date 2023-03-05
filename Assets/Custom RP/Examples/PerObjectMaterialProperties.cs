using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[DisallowMultipleComponent]
public class PerObjectMaterialProperties : MonoBehaviour
{
    public Color BaseColor = Color.white;

    private static MaterialPropertyBlock m_mat_block;
    private static int m_base_color_id = Shader.PropertyToID("_BaseColor");
    void Start()
    {
        if (m_mat_block == null)
        {
            m_mat_block = new MaterialPropertyBlock();
        }
    }

    public void SetRandomColor()
    {
        Start();

        var renderer = GetComponent<Renderer>();
        if (renderer == null)
        {
            return;
        }

        BaseColor.r = Random.Range(0f, 1f);
        BaseColor.g = Random.Range(0f, 1f);
        BaseColor.b = Random.Range(0f, 1f);
        m_mat_block.SetColor(m_base_color_id, BaseColor);
        renderer.SetPropertyBlock(m_mat_block);
    }
}
