Shader "Hidden/TinyPipeline/GTVBAO"
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
            
            struct vertex_input {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct vertex_output {
                float4 vertex : SV_POSITION;
                float2 texcoord : TEXCOORD0;
            };

            #include "UnityCG.cginc"
            
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
            
            Texture2D<float> _depth_texture;
            SamplerState _inline_linear_clamp_sampler;
            float4 _camera_pixel_size;
            float4x4 _view_projection_matrix;
            float4x4 _projection_matrix;
            float4x4 _world_to_camera_matrix;
            float4x4 _camera_to_world_matrix;
            float4x4 _camera_to_screen_matrix;

            float2 world_position_to_screen_uv(float3 posW)
            {
                float4 projected = mul(_view_projection_matrix, float4(posW, 1.0f));
                float2 uv = (projected.xy / projected.w) * 0.5f + 0.5f;
                return uv;
            }

            float2 world_position_to_screen_uv(float3 posW, out float k)
            {
                float4 projected = mul(_view_projection_matrix, float4(posW, 1.0f));
                k = 1.0f / projected.w;
                float2 uv = (projected.xy * k) * 0.5f + 0.5f;
                return uv;
            }

            float get_linearized_depth(float2 texcoord)
            {
                float depth = _depth_texture.SampleLevel(_inline_linear_clamp_sampler, 1.0f - texcoord, 0).x;
                return LinearEyeDepth(depth);
            }
            
            float fragment_entry(vertex_output input) : SV_Target0
            {
                float linear_depth = get_linearized_depth(input.texcoord);
                return linear_depth;
            }
            
            ENDHLSL
        }
    }
}
