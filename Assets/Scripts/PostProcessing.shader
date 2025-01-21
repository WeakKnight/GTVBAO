Shader "Hidden/TinyPipeline/PostProcessing"
{
    SubShader
    {
        Pass
        {
            ZTest Always 
            ZWrite Off 
            Cull Off

            HLSLPROGRAM
            #pragma vertex vertex_entry
            #pragma fragment fragment_entry

            #include "UnityCG.cginc"
            
            struct vertex_input {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct vertex_output {
                float4 vertex : SV_POSITION;
                float2 texcoord : TEXCOORD0;
            };

            vertex_output vertex_entry(vertex_input v)
            {
                vertex_output o;
                o.texcoord.xy = v.texcoord.xy;
                o.vertex = v.vertex;

                #if UNITY_UV_STARTS_AT_TOP
                if (_ProjectionParams.x > 0)
                    o.texcoord.y = 1 - o.texcoord.y;
                #endif

                #if UNITY_REVERSED_Z
                o.vertex.z = 0;
                #else
                o.vertex.z = 1;
                #endif
                return o;
            }
            
            Texture2D<half4> _input_texture;
            Texture2D<half4> _ao_texture;
            
            half3 linear_to_sRGB(in half3 color)
            {
                float3 x = color * 12.92f;
                float3 y = 1.055f * pow(saturate(color), 1.0f / 2.4f) - 0.055f;

                float3 clr = color;
                clr.r = color.r < 0.0031308f ? x.r : y.r;
                clr.g = color.g < 0.0031308f ? x.g : y.g;
                clr.b = color.b < 0.0031308f ? x.b : y.b;

                return clr;
            }
            
            half3 tonemapping(half3 x)
            {
                float a = 2.51f;
                float b = 0.03f;
                float c = 2.43f;
                float d = 0.59f;
                float e = 0.14f;
                return saturate((x*(a*x+b))/(x*(c*x+d)+e));
            }
            
            half4 fragment_entry(vertex_output input) : SV_Target0
            {
                // return _input_texture.SampleLevel(sampler_input_texture, input.texcoord, 0);
                // return _input_texture.SampleLevel(sampler_input_texture, input.texcoord, input_texture_mip_level);
                half3 linColor = _input_texture.Load(uint3(input.vertex.xy, 0)).xyz;
                half3 ao = _ao_texture.Load(uint3(input.vertex.xy, 0)).xyz;
                return half4(ao, 1.0);
                return half4(tonemapping(linColor), 1.0);
            }
            
            ENDHLSL
        }
    }
}
