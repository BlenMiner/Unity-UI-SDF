Shader "Unlit/RectangleRenderer"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255

        _ColorMask ("Color Mask", Float) = 15

        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
    }
    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP

            struct appdata
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex           : SV_POSITION;
                fixed4 color            : COLOR;
                float2 texcoord         : TEXCOORD0;
                float4 worldPosition    : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            fixed4 _Color;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;
            float4 _MainTex_ST;

            fixed4 _Roundness;
            float _Padding;
            float _OutlineSize;
            float _GraphicBlur;
            fixed4 _OutlineColor;

            float _ShadowSize;
            float _ShadowBlur;
            float _ShadowPow;
            fixed4 _ShadowColor;

            float2 _Size;

            v2f vert (appdata v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = v.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

                OUT.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);

                OUT.color = v.color * _Color;
                return OUT;
            }

            float sdRoundedBox(float2 p, float2 b, float4 r )
            {
                r.xy = (p.x>0.0)?r.xy : r.zw;
                r.x  = (p.y>0.0)?r.x  : r.y;
                float2 q = abs(p)-b+r.x;
                return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r.x;
            }

            fixed4 frag (v2f IN) : SV_Target
            {
                float2 uv = IN.texcoord;

                float2 normalizedPadding = float2(_Padding / _Size.x, _Padding / _Size.y);

                // Transform UV based on padding so image stays inside its container
                uv = uv * (1 + normalizedPadding * 2) - normalizedPadding;

                // For simplicity, convert UV to pixel coordinates
                float2 position = (uv - 0.5) * _Size;
                float2 halfSize = _Size * 0.5;

                half4 _GraphicColor = (tex2D(_MainTex, uv) + _TextureSampleAdd) * IN.color;

                // Signed distance field calculation
                float dist = sdRoundedBox(position, halfSize, _Roundness);
                float delta = fwidth(dist);

                // Calculate the different masks based on the SDF
                float graphicAlpha = 1 - smoothstep(-delta, 0, dist);
                float outlineAlpha = (1 - smoothstep(_OutlineSize - delta, _OutlineSize, dist));
                float shadowAlpha = (1 - smoothstep(_ShadowSize - _ShadowBlur - delta, _ShadowSize, dist));

                // Start with the background most layer, aka shadows
                shadowAlpha *= pow(shadowAlpha, _ShadowPow) * _ShadowColor.a;
                outlineAlpha *= _OutlineColor.a;
                graphicAlpha *= _GraphicColor.a;

                half4 effects = lerp(
                    lerp(
                        half4(_ShadowColor.rgb, shadowAlpha), 
                        half4(_OutlineColor.rgb, outlineAlpha),
                        outlineAlpha
                    ), 
                    half4(_GraphicColor.rgb, graphicAlpha),
                    graphicAlpha
                );
                
                // Unity stuff
                #ifdef UNITY_UI_CLIP_RECT
                effects.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                #endif

                #ifdef UNITY_UI_ALPHACLIP
                clip (effects.a - 0.001);
                #endif
                
                return effects;
            }
            ENDCG
        }
    }
}
