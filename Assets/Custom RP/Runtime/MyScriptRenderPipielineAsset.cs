using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "Rendering/LST_RenderPipeline")]
public class MyScriptRenderPipielineAsset : RenderPipelineAsset
{
    [SerializeField]
    private bool m_enable_dynamic_batch;

    [SerializeField]
    private bool m_enable_instancing;

    [SerializeField]
    private bool m_enable_srp_batch;

    protected override RenderPipeline CreatePipeline()
    {
        return new MyScriptRenderPipieline(m_enable_dynamic_batch, m_enable_instancing, m_enable_srp_batch);
    }
}
