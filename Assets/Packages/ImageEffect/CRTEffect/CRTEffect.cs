using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class CRTEffect : ImageEffectBase
{
    #region Field

    [Header("Ghost")]
    public    float ghostDelayTimeSec = 1f;
    protected float ghostDelayTimeSecCounter = 0;

    [Header("Glare")]
    public bool useWebCamAsGlare = true;
    public Texture2D glareTex = null;

    protected WebCamTexture webCamTex;
    protected RenderTexture ghostTex;

    #endregion Field

    #region Method

    protected override void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (this.useWebCamAsGlare)
        {
            if (this.webCamTex == null)
            {
                InitializeWebCam();
            }

            base.material.SetTexture("_GlareTex", this.webCamTex);
        }
        else
        {
            if (this.glareTex != null)
            {
                base.material.SetTexture("_GlareTex", this.glareTex);
            }
        }

        if (this.ghostTex != null)
        {
            base.material.SetTexture("_GhostTex", this.ghostTex);
        }

        base.OnRenderImage(source, destination);

        RenderTexture.ReleaseTemporary(this.ghostTex);

        this.ghostTex = RenderTexture.GetTemporary(source.descriptor);
        Graphics.Blit(source, this.ghostTex);
    }

    protected void InitializeWebCam()
    {
        WebCamDevice[] devices = WebCamTexture.devices;
        this.webCamTex = new WebCamTexture(devices[0].name, Screen.width / 2, Screen.height / 2, 60);
        this.webCamTex.Play();
    }

    #endregion Method
}