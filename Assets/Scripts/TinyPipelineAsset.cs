using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "Rendering/TinyPipelineAsset")]
public class TinyPipelineAsset : RenderPipelineAsset<TinyPipeline>
{
    protected override RenderPipeline CreatePipeline()
    {
        return new TinyPipeline();
    }
}
