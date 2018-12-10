Shader "ImageEffect/Base"
{
    Properties
    {
        [HideInInspector]
        _MainTex("Texture", 2D) = "white" {}
        _GlareTex("GlareTex", 2D) = "black" {}
        _GhostTex("GhostTex", 2D) = "black" {}
        [KeywordEnum(APERTUREGRILL, SHADOWMASK)]
        _CRT_TYPE("CRT Type", Float) = 0
        _GhostStrength("Ghost Strength", Range(0, 0.5)) = 0.5
        _BarrelDistortionStrength("Barrel Distortion Strength (K1, K2, -, -)", Float) = (0.2, 0.01, 0, 0)
        _RGBSandStormNoise("RGB Sand Storm Noise", Range(0, 1)) = 0.01
        _CornerShoadowStrength("Corner Shadow Strength", Range(0, 5)) = 1
        _UnevenNoiseStrength("Uneven Noise Strength", Range(0, 1)) = 1
        _BacklightStrength("Backlight Strength", Range(0, 1)) = 0.2
        _ScanLine("Scan Line (min, max, speed, width)", Vector) = (0.5, 1, 30, 500)
        _Light("Light(x, y, z, str)", Float) = (0, 1, 1, 10)
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM

            #include "UnityCG.cginc"
            #include "CRTEffectLibrary.cginc"
            #pragma vertex vert_img
            #pragma fragment frag
            #pragma multi_compile _CRT_TYPE_APERTUREGRILL _CRT_TYPE_SHADOWMASK

            sampler2D _MainTex;
            float4    _MainTex_TexelSize;
            sampler2D _GlareTex;
            sampler2D _GhostTex;

            float  _GhostStrength;
            float4 _BarrelDistortionStrength;
            float  _BacklightStrength;
            float  _RGBSandStormNoise;
            float  _CornerShoadowStrength;
            float  _UnevenNoiseStrength;
            float4 _ScanLine;
            float4 _Light;

            float rand(float2 co)
            {
                return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
            }

            fixed4 frag(v2f_img input) : SV_Target
            {
                float2 distortedCoord = GetBarrelDistortedCoord(input.uv, _BarrelDistortionStrength.x, _BarrelDistortionStrength.y);

                #ifdef _CRT_TYPE_APERTUREGRILL

                float4 color = GetApertureGrillColor(_MainTex, distortedCoord, _MainTex_TexelSize.zw, _MainTex_TexelSize.xy);
                float4 ghostColor = GetApertureGrillColor(_GhostTex, distortedCoord, _MainTex_TexelSize.zw, _MainTex_TexelSize.xy);

                #else

                float4 color = GetShadowMaskColor(_MainTex, distortedCoord, _MainTex_TexelSize.zw, _MainTex_TexelSize.xy);
                float4 ghostColor = GetShadowMaskColor(_GhostTex, distortedCoord, _MainTex_TexelSize.zw, _MainTex_TexelSize.xy);

                #endif

                color = color * (1 - _GhostStrength) + ghostColor * _GhostStrength;

                color.rgb *= lerp(_ScanLine.x, _ScanLine.y, saturate(sin(_Time.y * _ScanLine.z + distortedCoord.y * _ScanLine.w)));
                color.rgb *= 1 - CRTRandom(input.uv, _Time.x) * _UnevenNoiseStrength;
                color.rgb += lerp(-1, 1, _BacklightStrength);

                bool rgbSandStormNoise = CRTRandom(distortedCoord.xy, _Time.y) < _RGBSandStormNoise;
                color.r = rgbSandStormNoise ? CRTRandom(distortedCoord + float2(_Time.y, 0), _Time.y) : color.r;
                color.g = rgbSandStormNoise ? CRTRandom(distortedCoord + float2(_Time.y, 1), _Time.y) : color.g;
                color.b = rgbSandStormNoise ? CRTRandom(distortedCoord + float2(_Time.y, 2), _Time.x * _Time.y) : color.b;

                color.rgb *= GetCornerShadowPower(distortedCoord, _CornerShoadowStrength);
                color.rgb += tex2D(_GlareTex, float2(1 - distortedCoord.x, distortedCoord.y)) * 0.05;// * glareStrength;
                color.rgb += GetGlassSpecular(input.uv, distortedCoord, _Light);

                bool outOfRange = distortedCoord.x < 0 || 1 < distortedCoord.x || distortedCoord.y < 0 || 1 < distortedCoord.y;
                color = outOfRange ? 0 : color;

                return color;
            }

            ENDCG
        }
    }
}