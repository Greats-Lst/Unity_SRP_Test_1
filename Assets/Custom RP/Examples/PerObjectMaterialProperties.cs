using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[DisallowMultipleComponent]
public class PerObjectMaterialProperties : MonoBehaviour
{
    public Color BaseColor = Color.white;
    public float CutOff = 0.5f;
    public float Matalic = 0f;
    public float Smoothness = 0.5f;

    [SerializeField, ColorUsage(false, true)]
    Color EmissionColor = Color.black;

    private static MaterialPropertyBlock m_mat_block;
    private static int m_base_color_id = Shader.PropertyToID("_BaseColor");
    private static int m_cut_off_id = Shader.PropertyToID("_Cutoff");
    private static int m_metalic_id = Shader.PropertyToID("_Metalic");
    private static int m_smoothness_id = Shader.PropertyToID("_Smoothness");
    private static int m_emission_color_id = Shader.PropertyToID("_EmissionColor");
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
        m_mat_block.SetFloat(m_metalic_id, Matalic);
        m_mat_block.SetFloat(m_smoothness_id, Smoothness);
        m_mat_block.SetColor(m_emission_color_id, EmissionColor);
        renderer.SetPropertyBlock(m_mat_block);
    }

}
