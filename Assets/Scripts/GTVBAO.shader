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

            #include "RandomSequence.hlsl"

            static const uint ao_ray_direction_count = 32;

            float clip_ray_by_near_plane(float3 origin, float3 dir, float rayMaxDist, float zPlane)
            {
                return ((origin.z + dir.z * rayMaxDist) < zPlane) ? (zPlane - origin.z) / dir.z : rayMaxDist;
            }
            
            float reference_ao(random_sampler_state rng, float3 world_position, float3 world_normal)
            {
                // const float near_plane = 0.1;
                // const float max_ray_trace_distance = 2.0;
                // for(uint i = 0u; i < ao_ray_direction_count; ++i)
                // {
                //     float2 XY = sample_uniform_rng_2d(rng);
                //     float3 ray_direction = sample_sphere(XY);
                //     // why this is for cosine weighted hemisphere
                //     ray_direction = normalize(ray_direction + world_normal);
                //
                //     float3 camera_space_position = mul(_world_to_camera_matrix, float4(world_position, 1.0f)).xyz;
                //     float3 camera_space_ray_direction = normalize(mul(transpose((float3x3)_camera_to_world_matrix), ray_direction).xyz);
                //     
                //     float ray_length = clip_ray_by_near_plane(camera_space_position, camera_space_ray_direction, max_ray_trace_distance, near_plane);
                //     float3 camera_space_end_position = camera_space_ray_direction * ray_length + camera_space_position;
                //     
                //     // _camera_to_screen_matrix
                //     float4 rayStart = mul(_camera_to_screen_matrix, float4(camera_space_position, 1.0));
                //     float4 rayEnd   = mul(_camera_to_screen_matrix, float4(camera_space_end_position, 1.0));
                //     
                //     float rwStart = 1.0 / rayStart.w;
                //     float rwEnd   = 1.0 / rayEnd.w;
                //     
                //     float2 tcStart = rayStart.xy * rwStart * 0.5 + 0.5;
                //     float2 tcEnd   = rayEnd.xy   * rwEnd   * 0.5 + 0.5;
                //     
                //     float2  tcDelta0 = tcEnd - tcStart;
                //     float rwDelta0 = rwEnd - rwStart;
                //
                //     float2  uvDelta0       = tcDelta0 * iResolution.xy;
                //     float uvDelta0RcpLen = inversesqrt(dot(uvDelta0, uvDelta0));
                //
                //     // 1 px step size
                //     float2  tcDelta = tcDelta0 * uvDelta0RcpLen;
                //     float rwDelta = rwDelta0 * uvDelta0RcpLen;
                // }
                return 1.0;
            }
            /*
            float ReferenceAO(vec2 uv0, vec3 wpos, vec3 N, uint dirCount)
            {
                uvec2 uvu = uvec2(uv0);

                vec3 positionVS = VPos_from_WPos(wpos);

                uint frame = USE_TEMP_ACCU_COND ? uint(iFrame) : 0u;

                float occ = 0.0;
                
                for(uint i = 0u; i < dirCount; ++i)
                {
                    uint n = frame * dirCount + i;
                    
                    vec2 s = Hash11x2(uvec3(uvu, n), 0x3579A945u);

                    vec3 rayDir = Sample_Sphere(s); 
                    
                    if(USE_UNIFORM_HEMISHPHERE_WEIGHTING)
                    {
                        // uniform weighted hemisphere
                        rayDir -= N * min(dot(rayDir, N) * 2.0, 0.0);// flip if on wrong side
                    }
                    else
                    {
                        // cosine weighted hemisphere
                        rayDir = normalize(rayDir + N);
                    }
                    

                    // ray march in screen space
                    vec4 rayStart = PPos_from_WPos(wpos);
                    vec4 rayEnd   = PPos_from_WPos(wpos + rayDir * (nearZ * 0.5));
                    
                    float rwStart = 1.0 / rayStart.w;
                    float rwEnd   = 1.0 / rayEnd.w;
                    
                    vec2 tcStart = rayStart.xy * rwStart * 0.5 + 0.5;
                    vec2 tcEnd   = rayEnd.xy   * rwEnd   * 0.5 + 0.5;
                    
                    vec2  tcDelta0 = tcEnd - tcStart;
                    float rwDelta0 = rwEnd - rwStart;
                    
                    vec2  uvDelta0       = tcDelta0 * iResolution.xy;
                    float uvDelta0RcpLen = inversesqrt(dot(uvDelta0, uvDelta0));

                    // 1 px step size
                    vec2  tcDelta = tcDelta0 * uvDelta0RcpLen;
                    float rwDelta = rwDelta0 * uvDelta0RcpLen;
                    
                    float rnd01 = Hash01(uvec3(uvu, n), 0x2D56DA3Bu);

                    const float count = Raymarching_SampleCount;
                    
                    const float s = pow(Raymarching_Width, 1.0/count);
                    
                    float t = pow(s, rnd01);// init t: [1, s]

                    for (float i = 0.0; i < count; ++i)
                    {
                        vec2  tc = tcStart + tcDelta * t;
                        float rw = rwStart + rwDelta * t;

                        t *= s;

                        float depth = 1.0 / rw;

                        // handle oob
                        if(tc.x < 0.0 || tc.x >= 1.0 || tc.y < 0.0 || tc.y >= 1.0) break;
                        
                        float sampleDepth = textureLod(iChannel2, tc.xy, 0.0).w;

                        if(depth > sampleDepth && depth < sampleDepth + Thickness)
                        {
                            occ += 1.0;
                            
                            break;
                        }
                     }
                    
                }
                
                occ /= float(dirCount);
                
                return 1.0 - occ;
            }
             */
            
            float fragment_entry(vertex_output input) : SV_Target0
            {
                const uint frame_index = 0u;
                random_sampler_state rng = init_random_sampler(input.vertex, frame_index * ao_ray_direction_count);
                float linear_depth = get_linearized_depth(input.texcoord);
                return linear_depth;
            }
            
            ENDHLSL
        }
    }
}
