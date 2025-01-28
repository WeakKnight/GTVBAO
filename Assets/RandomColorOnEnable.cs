using UnityEngine;

[RequireComponent(typeof(Renderer))]
public class RandomColorOnEnable : MonoBehaviour
{
    private Renderer objectRenderer;
    private MaterialPropertyBlock propBlock;

    void Awake()
    {
        objectRenderer = GetComponent<Renderer>();
        propBlock = new MaterialPropertyBlock();
    }

    void OnEnable()
    {
        SetRandomCuteColor();
    }

    private void SetRandomCuteColor()
    {
        // Generate a random color with high brightness and saturation
        float hue = Random.Range(0f, 1f); // Full color spectrum
        float saturation = Random.Range(0.7f, 1f); // High saturation
        float brightness = Random.Range(0.7f, 1f); // High brightness

        Color randomColor = Color.HSVToRGB(hue, saturation, brightness);

        // Apply the color to the MaterialPropertyBlock
        propBlock.SetColor("_BaseColor", randomColor);
        objectRenderer.SetPropertyBlock(propBlock);
    }
}