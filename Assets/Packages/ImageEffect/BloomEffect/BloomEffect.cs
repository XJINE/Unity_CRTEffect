using System.Collections.Generic;
using UnityEngine;

public class BloomEffect : ImageEffectBase
{
    public enum BloomType
    {
        _BLOOM_TYPE_ADDITIVE = 0,
        _BLOOM_TYPE_SCREEN   = 1,
        _BLOOM_TYPE_DEBUG    = 2
    }

    #region Field

    private static Dictionary<BloomType, string> BloomTypes = new Dictionary<BloomType, string>()
    {
        { BloomType._BLOOM_TYPE_ADDITIVE, BloomType._BLOOM_TYPE_ADDITIVE.ToString() },
        { BloomType._BLOOM_TYPE_SCREEN,   BloomType._BLOOM_TYPE_SCREEN.ToString() },
        { BloomType._BLOOM_TYPE_DEBUG,    BloomType._BLOOM_TYPE_DEBUG.ToString() }
    };

    public BloomEffect.BloomType bloomType = BloomEffect.BloomType._BLOOM_TYPE_ADDITIVE;

    public bool coloredBloom = false;

    [Tooltip("This is enabled when coloredBloom.")]
    public Color bloomColor = Color.white;

    private static string BloomColorKeyword = "_BLOOM_COLOR";

    [Range(0, 1)]
    public float threshold = 1;

    [Range(0, 10)]
    public float intensity = 1;

    [Range(1, 10)]
    public float size = 1;

    [Range(1, 10)]
    public int divisor = 3;

    [Range(1, 5)]
    public int iteration = 5;

    private int idBloomColor = 0;
    private int idParameter  = 0;
    private int idBloomTex   = 0;

    #endregion Field

    #region Method

    protected override void Start()
    {
        base.Start();

        this.idBloomColor = Shader.PropertyToID("_BloomColor");
        this.idParameter  = Shader.PropertyToID("_Parameter");
        this.idBloomTex   = Shader.PropertyToID("_BloomTex");
    }

    protected override void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        base.material.EnableKeyword(BloomEffect.BloomTypes[this.bloomType]);

        if (this.coloredBloom)
        {
            base.material.EnableKeyword(BloomEffect.BloomColorKeyword);
            base.material.SetColor(this.idBloomColor, this.bloomColor);
        }
        else
        {
            base.material.DisableKeyword(BloomEffect.BloomColorKeyword);
        }

        RenderTexture resizedTex1 = RenderTexture.GetTemporary(source.width  / this.divisor,
                                                               source.height / this.divisor,
                                                               source.depth,
                                                               source.format);
        RenderTexture resizedTex2 = RenderTexture.GetTemporary(resizedTex1.descriptor);

        // STEP:0
        // Get resized birghtness image.

        base.material.SetVector(this.idParameter, new Vector3(this.threshold, this.intensity, this.size));
        Graphics.Blit(source, resizedTex1, base.material, 0);

        // STEP:1,2
        // Get blurred brightness image.

        for (int i = 1; i <= this.iteration; i++)
        {
            Graphics.Blit(resizedTex1, resizedTex2, base.material, 1);
            Graphics.Blit(resizedTex2, resizedTex1, base.material, 2);
            base.material.SetVector(this.idParameter, new Vector3(this.threshold, this.intensity, this.size + i));
        }

        // STEP:3
        // Composite.

        base.material.SetTexture(this.idBloomTex, resizedTex1);
        Graphics.Blit(source, destination, base.material, 3);

        RenderTexture.ReleaseTemporary(resizedTex1);
        RenderTexture.ReleaseTemporary(resizedTex2);

        base.material.DisableKeyword(BloomEffect.BloomTypes[this.bloomType]);
    }

    #endregion Method
}