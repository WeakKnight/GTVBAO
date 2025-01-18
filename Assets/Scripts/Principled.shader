Shader "TinyPipeline/Principled"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode", Float) = 2
        _BaseColorTex("Base Color Texture", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1.0, 1.0, 1.0, 1.0)
    }
    
    HLSLINCLUDE
    #pragma use_dxc
    #pragma enable_d3d11_debug_symbols
    #include "UnityCG.cginc"
    sampler2D _BaseColorTex;
    half4 _BaseColorTex_ST;
    float4 _BaseColor;
    ENDHLSL

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags
            {
                "LightMode" = "GBuffer"
            }
            
            Cull [_Cull]
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct VertexData
            {
                float4 position : POSITION;
                float2 uv0 : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv0 : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            

            v2f vert (VertexData v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.position);
                o.uv0 = TRANSFORM_TEX(v.uv0, _BaseColorTex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 col = _BaseColor * tex2D(_BaseColorTex, i.uv0);
                return col;
            }
            
            ENDHLSL
        }
    }
}
