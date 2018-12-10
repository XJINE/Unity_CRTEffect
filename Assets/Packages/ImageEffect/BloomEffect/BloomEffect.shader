Shader "ImageEffect/BloomEffect"
{
    Properties
    {
        [HideInInspector]
        _MainTex("Texture", 2D) = "white" {}

        [KeywordEnum(ADDITIVE, SCREEN, DEBUG)]
        _BLOOM_TYPE("Bloom Type", Float) = 0

        _Parameter("(Threhold, Intensity, SamplingFrequency, None)", Vector) = (0.8, 1.0, 1.0, 0.0)
    }
    SubShader
    {
        CGINCLUDE

        #include "UnityCG.cginc"
        #include "Assets/Packages/ImageFilterLibrary/ImageFilterLibrary.cginc"

        sampler2D _MainTex;
        float4    _MainTex_ST;
        float4    _MainTex_TexelSize;
        float4    _Parameter;

        #define BRIGHTNESS_THRESHOLD _Parameter.x
        #define INTENSITY            _Parameter.y
        #define SAMPLING_FREQUENCY   _Parameter.z

        ENDCG

        // STEP:1
        // Get (resized) brightness image.

        Pass
        {
            CGPROGRAM

            #pragma vertex vert_img
            #pragma fragment frag

            fixed4 frag(v2f_img input) : SV_Target
            {
                float4 color = tex2D(_MainTex, input.uv);
                return max(color - BRIGHTNESS_THRESHOLD, 0) * INTENSITY;
            }

            ENDCG
        }

        // STEP:2, 3
        // Get blurred brightness image.

        CGINCLUDE

        struct v2f_img_gaussian
        {
            float4 pos    : SV_POSITION;
            half2  uv     : TEXCOORD0;
            half2  offset : TEXCOORD1;
            UNITY_VERTEX_INPUT_INSTANCE_ID
            UNITY_VERTEX_OUTPUT_STEREO
        };

        float4 frag_gaussian (v2f_img_gaussian input) : SV_Target
        {
            return GaussianFilter(_MainTex, _MainTex_ST, input.uv, input.offset);
        }

        ENDCG

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag_gaussian

            v2f_img_gaussian vert(appdata_img v)
            {
                v2f_img_gaussian o;

                UNITY_INITIALIZE_OUTPUT(v2f_img_gaussian, o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.pos    = UnityObjectToClipPos (v.vertex);
                o.uv     = v.texcoord;
                o.offset = _MainTex_TexelSize.xy * float2(1, 0) * SAMPLING_FREQUENCY;

                return o;
            }

            ENDCG
        }

        Pass
        {
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag_gaussian

            v2f_img_gaussian vert(appdata_img v)
            {
                v2f_img_gaussian o;
                UNITY_INITIALIZE_OUTPUT(v2f_img_gaussian, o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.pos    = UnityObjectToClipPos (v.vertex);
                o.uv     = v.texcoord;
                o.offset = _MainTex_TexelSize.xy * float2(0, 1) * SAMPLING_FREQUENCY;

                return o;
            }

            ENDCG
        }

        // STEP:4
        // Composite.

        Pass
        {
            CGPROGRAM

            #pragma vertex vert_img
            #pragma fragment frag
            #pragma multi_compile _BLOOM_TYPE_ADDITIVE _BLOOM_TYPE_SCREEN _BLOOM_TYPE_DEBUG
            #pragma multi_compile _ _BLOOM_COLOR

            sampler2D _BloomTex;
            float4    _BloomColor;
            float     _BLOOM_TYPE;

            fixed4 frag(v2f_img input) : SV_Target
            {
                float4 mainColor  = tex2D(_MainTex,  input.uv);
                float4 bloomColor = tex2D(_BloomTex, input.uv);

                #ifdef _BLOOM_COLOR

                bloomColor.rgb = (bloomColor.r + bloomColor.g + bloomColor.b) * 0.3333 * _BloomColor;

                #endif

                #ifdef _BLOOM_TYPE_SCREEN

                return mainColor + bloomColor - saturate(mainColor * bloomColor);

                #elif _BLOOM_TYPE_ADDITIVE

                return mainColor + bloomColor;

                #else

                return bloomColor;

                #endif
            }

            ENDCG
        }
    }
}