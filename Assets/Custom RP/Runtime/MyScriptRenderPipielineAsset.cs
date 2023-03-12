using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "Rendering/LST_RenderPipeline")]
public class MyScriptRenderPipielineAsset : RenderPipelineAsset
{
    [SerializeField]
    private bool EnableDynamicBatch;

    [SerializeField]
    private bool EnableGPUInstancing;

    [SerializeField]
    private bool EnableSRPBatch;

    [SerializeField]
    private ShadowSettings ShadowSettings = default;

    protected override RenderPipeline CreatePipeline()
    {
        return new MyScriptRenderPipieline(EnableDynamicBatch, EnableGPUInstancing, EnableSRPBatch, ShadowSettings);
    }
}
