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
                float3 normal : NORMAL;
                float4 posL : LOCALPOS;
            };
            

            v2f vert (VertexData v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.position);
                o.uv0 = TRANSFORM_TEX(v.uv0, _BaseColorTex);
                o.normal = v.normal;
                o.posL = v.position;
                return o;
            }

            struct GBufferOutput
            {
                float4 baseColor : SV_Target0;
                float4 posW : SV_Target1;
                float4 normalW : SV_Target2;
            };
            
            GBufferOutput frag (v2f i)
            {
                float3 worldNormal = UnityObjectToWorldNormal(i.normal);
                
                GBufferOutput output;
                output.baseColor = _BaseColor * tex2D(_BaseColorTex, i.uv0);
                output.posW = float4(mul(unity_ObjectToWorld, i.posL).xyz, 1.0f);
                output.normalW = float4(worldNormal.xyz, 1.0f);
                return output;
            }
            
            ENDHLSL
        }
    }
}
