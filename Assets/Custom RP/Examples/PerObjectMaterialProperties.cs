using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[DisallowMultipleComponent]
public class PerObjectMaterialProperties : MonoBehaviour
{
    public Color BaseColor = Color.white;
    public float CutOff = 0.5f;

    private static MaterialPropertyBlock m_mat_block;
    private static int m_base_color_id = Shader.PropertyToID("_BaseColor");
    private static int m_cut_off_id = Shader.PropertyToID("_Cutoff");
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
        m_mat_block.SetFloat(m_cut_off_id, CutOff);
        renderer.SetPropertyBlock(m_mat_block);
    }
}
