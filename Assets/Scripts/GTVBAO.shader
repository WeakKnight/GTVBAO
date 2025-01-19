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
            float4 _camera_pixel_size_and_screen_size;
            float4x4 _view_projection_matrix;
            float4x4 _projection_matrix;
            float4x4 _world_to_camera_matrix;
            float4x4 _camera_to_world_matrix;
            float4x4 _camera_to_screen_matrix;

            float get_linearized_depth(float2 texcoord)
            {
                float depth = _depth_texture.SampleLevel(_inline_linear_clamp_sampler, 1.0f - texcoord, 0).x;
                return LinearEyeDepth(depth);
            }

            float3 compute_view_position(float linearZ, float2 uv, float4x4 mProj, bool leftHanded = true, bool perspective = true)
            {
                float scale = perspective ? linearZ : 1;
                scale *= leftHanded ? 1 : -1;

                float2 p11_22 = float2(mProj._11, mProj._22);
                float2 p13_31 = float2(mProj._13, mProj._23);
                return float3((uv * 2.0 - 1.0 - p13_31) / p11_22 * scale, linearZ);
            }

            float3 compute_view_position_perspectiveLH(float linearZ, float2 uv, float4x4 mProj)
            {
                return compute_view_position(linearZ, uv, mProj, true, true);
            }
            
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

            float3 screen_position_to_camera_position(float2 texcoord)
            {
                float linearZ = get_linearized_depth(texcoord);
                float3 posCS = -compute_view_position_perspectiveLH(linearZ, texcoord, _projection_matrix);
                return posCS;
            }
            
            #include "RandomSequence.hlsl"
            #include "Common.hlsl"
            
            static const uint ao_ray_direction_count = 4;
            static const float camera_near_z = 0.1;
            static const float ray_maching_sample_count = 16;
            static const float ray_marching_width = 128;
            static const float ray_marching_thickness = 0.5;
            
            float ssao(random_sampler_state rng, float3 camera_space_position, float3 camera_space_normal)
            {
                float3 V = -normalize(camera_space_position);
                
                float ao = 0.0;
                for (uint direction_index = 0; direction_index < ao_ray_direction_count; direction_index++)
                {
                    float4 random_number = sample_uniform_rng_4d(rng);

                    // slice direction sampling
                    float3 camera_space_sample_direction;
                    float2 screen_space_sample_direction;
                    {
                        float4 quaternion_to_V = quaternion_create(V);
                        float4 quaternion_from_V = quaternion_to_V * float4(float3(-1.0, -1.0, -1.0), 1.0);// conjugate
                        float3 camera_space_normal_from_V = transform_xyz_by_unit_quaternion_xy0s(camera_space_normal, quaternion_from_V);
                        screen_space_sample_direction = sample_slice_direction(camera_space_normal_from_V, random_number.x);
                        camera_space_sample_direction = transform_xy0_by_unit_quaternion_xy0s(screen_space_sample_direction, quaternion_from_V);
                        float3 ray_start = mul(_camera_to_screen_matrix, float4(camera_space_position, 1.0));
                        float3 ray_end = mul(_camera_to_screen_matrix, float4(camera_space_position + camera_space_sample_direction * camera_near_z * 0.5, 1.0));
                        float3 ray_direction = ray_end - ray_start;
                        ray_direction /= length(ray_direction.xy);
                        screen_space_sample_direction = ray_direction.xy;
                    }

                    // construct slice
                    float cos_N;
                    float ang_N;
                    {
                        float3 slice_N = cross(V, camera_space_sample_direction);
                        float3 proj_N = camera_space_normal - slice_N * dot(camera_space_normal, slice_N);
                        float proj_N_squared_length = dot(proj_N, proj_N);
                        if (proj_N_squared_length == 0.0)
                        {
                            return 1.0;
                        }
                        float proj_N_rcp_len = rsqrt(proj_N_squared_length);
                        cos_N = dot(proj_N, V) * proj_N_rcp_len;
                        float3 T = cross(slice_N, proj_N);
                        float sgn = dot(V, T) < 0.0 ? -1.0 : 1.0;
                        ang_N = sgn * acos_approx_safe(cos_N);
                    }

                    // find horizons
                    float4 ray_start = mul(_camera_to_screen_matrix, float4(camera_space_position, 1.0));
                    float ang_off = ang_N * M_1_PI + 0.5;
                    uint occusion_bits = 0u;
                    for(float d = -1.0; d <= 1.0; d += 2.0)
                    {
                        float2 ray_direction = screen_space_sample_direction * d;
                        const float step_length = pow(ray_marching_width, 1.0 / ray_maching_sample_count);
                        float t = pow(step_length, random_number.z);
                        random_number.z = 1.0 - random_number.z;
                        for (float i = 0; i < ray_maching_sample_count; i++)
                        {
                            float2 screen_space_sample_position = ray_start + ray_direction * t;
                            t += step_length;
                            if(screen_space_sample_position.x < 0.0 || screen_space_sample_position.x >= _camera_pixel_size_and_screen_size.z || screen_space_sample_position.y < 0.0 || screen_space_sample_position.y >= _camera_pixel_size_and_screen_size.w)
                            {
                                break;
                            }
                            float3 camera_space_sample_position = screen_position_to_camera_position(screen_space_sample_position);
                            float3 delta_front = camera_space_sample_position - camera_space_position;
                            float3 delta_back  = delta_front - V * ray_marching_thickness;

                            // project samples onto unit circle and compute angles relative to V
                            float2 horizon_cos = float2(dot(normalize(delta_front), V), 
                                   dot(normalize(delta_back), V));
                            float2 horizon_ang = acos_approx_safe(horizon_cos) * d;
                             // shift relative angles from V to N + map to [0,1]
                            float2 horizon_01 = clamp(horizon_ang * M_1_PI + ang_off, 0.0, 1.0);
                            // sampling direction flips min/max angles
                            horizon_01 = d >= 0.0 ? horizon_01.xy : horizon_01.yx;

                            // map to slice relative distribution
                            horizon_01.x = slice_rel_cdf_cos(horizon_01.x, ang_N, cos_N, d > 0.0);
                            horizon_01.y = slice_rel_cdf_cos(horizon_01.y, ang_N, cos_N, d > 0.0);

                            // jitter sample locations + clamp01
                            horizon_01 = clamp(horizon_01 + random_number.w * (1.0/32.0), 0.0, 1.0);
                           
                            uint occlusion_bitmask;// turn arc into bit mask
                            {
                                uint2 horInt = uint2(floor(horizon_01 * 32.0));

                                uint OxFFFFFFFFu = 0xFFFFFFFFu;// don't inline here! ANGLE bug: https://issues.angleproject.org/issues/353039526

                                uint mX = horInt.x < 32u ? OxFFFFFFFFu <<        horInt.x  : 0u;
                                uint mY = horInt.y != 0u ? OxFFFFFFFFu >> (32u - horInt.y) : 0u;

                                occlusion_bitmask = mX & mY;            
                            }

                            occusion_bits = occusion_bits | occlusion_bitmask;
                        }
                    }
                    float occ0 = float(countbits(occusion_bits)) * (1.0/32.0);
                    float slice_weight = 1.0;
                    ao += slice_weight - slice_weight * occ0;
                }
                ao /= float(ao_ray_direction_count);
                return ao;
            }

            float ssao_ext(random_sampler_state rng, float3 world_position, float3 world_normal)
            {
                float3 camera_space_position = mul(_world_to_camera_matrix, float4(world_position, 1.0f)).xyz;
                float3 camera_space_normal = normalize(mul(transpose((float3x3)_camera_to_world_matrix), world_normal).xyz);
                return ssao(rng, camera_space_position, camera_space_normal);
            }
            float fragment_entry(vertex_output input, bool is_front_face : SV_IsFrontFace) : SV_Target0
            {
                const uint frame_index = 0u;
                random_sampler_state rng = init_random_sampler(input.vertex, frame_index * ao_ray_direction_count);
                // float linear_depth = get_linearized_depth(input.texcoord);
                float3 camera_space_position = screen_position_to_camera_position(input.texcoord);
                float3 camera_space_normal = normalize(cross(ddy(camera_space_position.xyz), ddx(camera_space_position.xyz))) * (is_front_face ? 1.0 : -1.0);
                return ssao(rng, camera_space_position, camera_space_normal);
            }
            
            ENDHLSL
        }
    }
}
