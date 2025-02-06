using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "Rendering/TinyPipelineAsset")]
public class TinyPipelineAsset : RenderPipelineAsset
{
    protected override RenderPipeline CreatePipeline()
    {
        return new TinyPipeline(BlueNoiseTextures);
    }

    public Texture2D[] BlueNoiseTextures;
}
