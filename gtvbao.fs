#version 310 es
#ifdef GL_EXT_shader_texture_lod
#extension GL_EXT_shader_texture_lod : enable
#endif

precision highp float;
precision highp int;
#define HLSLCC_ENABLE_UNIFORM_BUFFERS 1
#if HLSLCC_ENABLE_UNIFORM_BUFFERS
#define UNITY_UNIFORM
#else
#define UNITY_UNIFORM uniform
#endif
#define UNITY_SUPPORTS_UNIFORM_LOCATION 1
#if UNITY_SUPPORTS_UNIFORM_LOCATION
#define UNITY_LOCATION(x) layout(location = x)
#define UNITY_BINDING(x) layout(binding = x, std140)
#else
#define UNITY_LOCATION(x)
#define UNITY_BINDING(x) layout(std140)
#endif
uniform 	vec4 _camera_pixel_size_and_screen_size;
uniform 	vec4 hlslcc_mtx4x4_projection_matrix[4];
uniform 	vec4 hlslcc_mtx4x4_camera_to_world_matrix[4];
uniform 	int frame_index;
uniform 	int _encoded_depth_mip_level;
uniform 	float _ao_cascade_sample_radius;
UNITY_LOCATION(0) uniform mediump sampler2DArray g_stbn_vec4_texture_array;
UNITY_LOCATION(1) uniform mediump sampler2D _GBuffer_NormalMipChain;
UNITY_LOCATION(2) uniform mediump sampler2D _GBuffer_DepthMipChain;
layout(location = 0) in highp vec2 vs_TEXCOORD0;
layout(location = 0) out highp vec4 SV_Target0;
vec2 u_xlat0;
uvec4 u_xlatu0;
vec3 u_xlat1;
uvec4 u_xlatu1;
bvec2 u_xlatb1;
vec3 u_xlat2;
mediump vec3 u_xlat16_3;
mediump vec3 u_xlat16_4;
mediump vec3 u_xlat16_5;
vec2 u_xlat6;
vec4 u_xlat7;
vec2 u_xlat8;
float u_xlat9;
mediump float u_xlat16_10;
vec3 u_xlat11;
mediump float u_xlat16_11;
bvec2 u_xlatb11;
mediump vec2 u_xlat16_12;
vec3 u_xlat13;
vec3 u_xlat23;
mediump vec2 u_xlat16_23;
int u_xlati23;
uint u_xlatu23;
bool u_xlatb23;
mediump vec2 u_xlat16_24;
vec2 u_xlat28;
bool u_xlatb28;
float u_xlat29;
mediump vec2 u_xlat16_31;
mediump float u_xlat16_32;
mediump float u_xlat16_33;
uint u_xlatu34;
float u_xlat35;
int u_xlati35;
vec2 u_xlat36;
int u_xlati36;
vec2 u_xlat37;
mediump vec2 u_xlat16_37;
uint u_xlatu37;
bool u_xlatb37;
mediump vec2 u_xlat16_40;
float u_xlat42;
float u_xlat43;
float u_xlat44;
float u_xlat46;
mediump float u_xlat16_46;
mediump float u_xlat16_47;
float u_xlat48;
int u_xlati48;
bool u_xlatb48;
float u_xlat51;
mediump float u_xlat16_51;
uint u_xlatu51;
bool u_xlatb51;
void main()
{
vec4 hlslcc_FragCoord = vec4(gl_FragCoord.xyz, 1.0/gl_FragCoord.w);
    u_xlat0.xy = floor(hlslcc_FragCoord.xy);
    u_xlatu0.xy = uvec2(u_xlat0.xy);
    u_xlatu0.xy = u_xlatu0.xy & uvec2(127u, 127u);
    u_xlatu0.z = uint(frame_index) & 63u;
    u_xlatu0.w = 0u;
    u_xlat0.xy = texelFetch(g_stbn_vec4_texture_array, ivec3(u_xlatu0.xyz), int(u_xlatu0.w)).xy;
    u_xlat28.xy = vs_TEXCOORD0.xy * _camera_pixel_size_and_screen_size.zw + vec2(-0.5, -0.5);
    u_xlat28.xy = roundEven(u_xlat28.xy);
    u_xlatu1.xy =  uvec2(ivec2(u_xlat28.xy));
    u_xlatu1.zw = uvec2(ivec2(_encoded_depth_mip_level, _encoded_depth_mip_level)) + uvec2(4294967295u, 4294967295u);
    u_xlat2.z = texelFetch(_GBuffer_DepthMipChain, ivec2(u_xlatu1.xy), int(u_xlatu1.w)).x;
    u_xlat28.xy = texelFetch(_GBuffer_NormalMipChain, ivec2(u_xlatu1.xy), int(u_xlatu1.w)).xy;
    u_xlat16_3.xy = u_xlat28.xy * vec2(2.0, 2.0) + vec2(-1.0, -1.0);
    u_xlat16_4.xyz = -abs(u_xlat16_3.xyx) + vec3(1.0, 1.0, 1.0);
    u_xlat16_5.z = -abs(u_xlat16_3.y) + u_xlat16_4.x;
    u_xlatb28 = u_xlat16_5.z<0.0;
    u_xlatb1.xy = greaterThanEqual(u_xlat16_3.xyxx, vec4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlat16_31.x = (u_xlatb1.x) ? u_xlat16_4.y : (-u_xlat16_4.y);
    u_xlat16_31.y = (u_xlatb1.y) ? u_xlat16_4.z : (-u_xlat16_4.z);
    u_xlat16_5.xy = (bool(u_xlatb28)) ? u_xlat16_31.xy : u_xlat16_3.xy;
    u_xlat16_3.x = dot(u_xlat16_5.xyz, u_xlat16_5.xyz);
    u_xlat16_3.x = inversesqrt(u_xlat16_3.x);
    u_xlat16_3.xyz = u_xlat16_3.xxx * u_xlat16_5.xyz;
    u_xlat1.x = dot(hlslcc_mtx4x4_camera_to_world_matrix[0].xyz, u_xlat16_3.xyz);
    u_xlat1.y = dot(hlslcc_mtx4x4_camera_to_world_matrix[1].xyz, u_xlat16_3.xyz);
    u_xlat1.z = dot(hlslcc_mtx4x4_camera_to_world_matrix[2].xyz, u_xlat16_3.xyz);
    u_xlat28.x = dot(u_xlat1.xyz, u_xlat1.xyz);
    u_xlat28.x = inversesqrt(u_xlat28.x);
    u_xlat1.xyz = u_xlat28.xxx * u_xlat1.xyz;
    u_xlat28.xy = vs_TEXCOORD0.xy * vec2(2.0, 2.0) + vec2(-1.0, -1.0);
    u_xlat28.xy = u_xlat28.xy + (-hlslcc_mtx4x4_projection_matrix[2].xy);
    u_xlat6.x = hlslcc_mtx4x4_projection_matrix[0].x;
    u_xlat6.y = hlslcc_mtx4x4_projection_matrix[1].y;
    u_xlat28.xy = u_xlat28.xy / u_xlat6.xy;
    u_xlat2.xy = u_xlat2.zz * u_xlat28.xy;
    u_xlat7.xyz = u_xlat2.xyz * vec3(0.995999992, 0.995999992, -0.995999992);
    u_xlat28.x = dot((-u_xlat7.xyz), (-u_xlat7.xyz));
    u_xlat28.x = inversesqrt(u_xlat28.x);
    u_xlat7.xyw = u_xlat28.xxx * (-u_xlat7.xyz);
    u_xlat8.y = _camera_pixel_size_and_screen_size.w * _camera_pixel_size_and_screen_size.x;
    u_xlat28.x = _ao_cascade_sample_radius * 0.0299999993;
    u_xlat42 = dot(u_xlat28.xx, abs(u_xlat7.zz));
    u_xlat44 = u_xlat2.z * -0.0498000011;
    u_xlat44 = min(abs(u_xlat44), 1.0);
    u_xlat42 = u_xlat42 + 1.0;
    u_xlat42 = log2(u_xlat42);
    u_xlat42 = u_xlat42 * 0.415888339;
    u_xlat42 = u_xlat44 * 0.200000003 + u_xlat42;
    u_xlat16_3.x = u_xlat0.x + -0.5;
    u_xlat0.x = u_xlat16_3.x * 1.57079637;
    u_xlat9 = cos(u_xlat0.x);
    u_xlat0.x = sin(u_xlat0.x);
    u_xlat16_4.xy = u_xlat1.yz * u_xlat7.wx;
    u_xlat16_4.xy = u_xlat7.yw * u_xlat1.zx + (-u_xlat16_4.xy);
    u_xlat16_32 = dot(u_xlat1.xyz, u_xlat7.xyw);
    u_xlat29 = float(int(u_xlatu1.w));
    u_xlat43 = u_xlat42 + u_xlat42;
    u_xlat8.x = 1.0;
    u_xlat16_46 = 0.0;
    u_xlat44 = 0.0;
    u_xlat16_5.x = u_xlat0.x;
    u_xlat16_5.y = u_xlat9;
    u_xlatu34 = 0u;
    while(true){
        u_xlatb48 = u_xlatu34>=2u;
        if(u_xlatb48){break;}
        u_xlat36.xy = u_xlat28.xx * u_xlat16_5.xy;
        u_xlat36.xy = u_xlat8.xy * u_xlat36.xy;
        u_xlat16_33 = dot(u_xlat16_5.xy, u_xlat7.xy);
        u_xlat16_47 = dot(u_xlat16_5.xy, u_xlat1.xy);
        u_xlat16_10 = dot(u_xlat16_5.xy, u_xlat16_4.xy);
        u_xlat16_24.x = (-u_xlat16_33) * u_xlat16_33 + 1.0;
        u_xlat16_24.x = max(u_xlat16_24.x, 0.0);
        u_xlat16_24.x = inversesqrt(u_xlat16_24.x);
        u_xlat16_10 = u_xlat16_24.x * u_xlat16_10;
        u_xlat16_10 = (-u_xlat16_10) * u_xlat16_10 + 1.0;
        u_xlat16_10 = max(u_xlat16_10, 0.0);
        u_xlat16_10 = sqrt(u_xlat16_10);
        u_xlat48 = float(1.0) / float(u_xlat16_10);
        u_xlat48 = u_xlat16_32 * u_xlat48;
        u_xlat48 = clamp(u_xlat48, 0.0, 1.0);
        u_xlat35 = u_xlat48 * -0.156582996 + 1.57079637;
        u_xlat16_24.x = (-u_xlat48) + 1.0;
        u_xlat16_24.x = sqrt(u_xlat16_24.x);
        u_xlat16_24.x = u_xlat35 * u_xlat16_24.x;
        u_xlat16_33 = u_xlat16_32 * u_xlat16_33;
        u_xlatb48 = u_xlat16_47<u_xlat16_33;
        u_xlat16_33 = (u_xlatb48) ? (-u_xlat16_24.x) : u_xlat16_24.x;
        u_xlati48 = int(0xFFFFFFFFu);
        for(int u_xlati_loop_1 = 0 ; u_xlati_loop_1<3 ; u_xlati_loop_1++)
        {
            u_xlat16_47 = float(u_xlati_loop_1);
            u_xlat16_47 = u_xlat0.y + u_xlat16_47;
            u_xlat16_47 = u_xlat16_47 * 0.333333343;
            u_xlat23.xy = vec2(u_xlat16_47) * u_xlat36.xy + vs_TEXCOORD0.xy;
            u_xlat16_24.xy = (-u_xlat23.xy) * u_xlat23.xy + u_xlat23.xy;
            u_xlat16_24.xy = clamp(u_xlat16_24.xy, 0.0, 1.0);
            u_xlat16_47 = u_xlat16_24.y * u_xlat16_24.x;
            u_xlatb51 = u_xlat16_47==0.0;
            if(u_xlatb51){
                break;
            }
            u_xlat16_51 = textureLod(_GBuffer_DepthMipChain, u_xlat23.xy, u_xlat29).x;
            u_xlat23.xy = u_xlat23.xy * vec2(2.0, 2.0) + (-hlslcc_mtx4x4_projection_matrix[2].xy);
            u_xlat23.xy = u_xlat23.xy + vec2(-1.0, -1.0);
            u_xlat23.xy = u_xlat23.xy / u_xlat6.xy;
            u_xlat11.xy = vec2(u_xlat16_51) * u_xlat23.xy;
            u_xlat11.z = (-u_xlat16_51);
            u_xlat23.xyz = (-u_xlat2.xyz) * vec3(0.995999992, 0.995999992, -0.995999992) + u_xlat11.xyz;
            u_xlat11.y = dot(u_xlat23.xyz, u_xlat7.xyw);
            u_xlat23.x = dot(u_xlat23.xyz, u_xlat23.xyz);
            u_xlat11.x = (-u_xlat42) + u_xlat11.y;
            u_xlat37.x = (-u_xlat43) * u_xlat11.y + u_xlat23.x;
            u_xlat37.x = u_xlat42 * u_xlat42 + u_xlat37.x;
            u_xlat16_12.y = inversesqrt(u_xlat23.x);
            u_xlat16_12.x = inversesqrt(u_xlat37.x);
            u_xlat16_24.xy = u_xlat11.xy * u_xlat16_12.xy;
            u_xlat16_23.xy = abs(u_xlat16_24.xy) * vec2(-0.156582996, -0.156582996) + vec2(1.57079637, 1.57079637);
            u_xlat16_12.xy = -abs(u_xlat16_24.xy) + vec2(1.0, 1.0);
            u_xlat16_12.xy = sqrt(u_xlat16_12.xy);
            u_xlat16_40.xy = u_xlat16_23.xy * u_xlat16_12.xy;
            u_xlatb11.xy = greaterThanEqual(u_xlat16_24.xyxx, vec4(0.0, 0.0, 0.0, 0.0)).xy;
            u_xlat16_23.xy = (-u_xlat16_23.xy) * u_xlat16_12.xy + vec2(3.14159274, 3.14159274);
            u_xlat23.x = (u_xlatb11.x) ? u_xlat16_40.x : u_xlat16_23.x;
            u_xlat23.y = (u_xlatb11.y) ? u_xlat16_40.y : u_xlat16_23.y;
            u_xlat16_24.xy = vec2(u_xlat16_33) + (-u_xlat23.xy);
            u_xlat16_23.xy = u_xlat16_24.xy * vec2(0.318309873, 0.318309873) + vec2(0.5, 0.5);
            u_xlat16_23.xy = clamp(u_xlat16_23.xy, 0.0, 1.0);
            u_xlat16_24.xy = u_xlat16_23.xy * u_xlat16_23.xy;
            u_xlat16_12.xy = (-u_xlat16_23.xy) * vec2(2.0, 2.0) + vec2(3.0, 3.0);
            u_xlat16_47 = u_xlat16_24.x * u_xlat16_12.x;
            u_xlat16_24.x = u_xlat16_47 * 32.0;
            u_xlatu23 = uint(u_xlat16_24.x);
            u_xlat16_47 = u_xlat16_24.y * u_xlat16_12.y + (-u_xlat16_47);
            u_xlat16_47 = clamp(u_xlat16_47, 0.0, 1.0);
            u_xlat16_47 = u_xlat16_47 * 32.0;
            u_xlat16_47 = ceil(u_xlat16_47);
            u_xlatu37 = uint(u_xlat16_47);
            u_xlati48 = int(bitfieldInsert(u_xlati48, 0, int(u_xlatu23) & int(0x1F), int(u_xlatu37)));
        }
        u_xlati35 = u_xlati48;
        for(int u_xlati_loop_2 = 0 ; u_xlati_loop_2<3 ; u_xlati_loop_2++)
        {
            u_xlat16_47 = float(u_xlati_loop_2);
            u_xlat16_47 = u_xlat0.y + u_xlat16_47;
            u_xlat16_47 = u_xlat16_47 * 0.333333343;
            u_xlat37.xy = vec2(u_xlat16_47) * (-u_xlat36.xy) + vs_TEXCOORD0.xy;
            u_xlat16_24.xy = (-u_xlat37.xy) * u_xlat37.xy + u_xlat37.xy;
            u_xlat16_24.xy = clamp(u_xlat16_24.xy, 0.0, 1.0);
            u_xlat16_47 = u_xlat16_24.y * u_xlat16_24.x;
            u_xlatb11.x = u_xlat16_47==0.0;
            if(u_xlatb11.x){
                break;
            }
            u_xlat16_11 = textureLod(_GBuffer_DepthMipChain, u_xlat37.xy, u_xlat29).x;
            u_xlat37.xy = u_xlat37.xy * vec2(2.0, 2.0) + (-hlslcc_mtx4x4_projection_matrix[2].xy);
            u_xlat37.xy = u_xlat37.xy + vec2(-1.0, -1.0);
            u_xlat37.xy = u_xlat37.xy / u_xlat6.xy;
            u_xlat13.xy = vec2(u_xlat16_11) * u_xlat37.xy;
            u_xlat13.z = (-u_xlat16_11);
            u_xlat11.xyz = (-u_xlat2.xyz) * vec3(0.995999992, 0.995999992, -0.995999992) + u_xlat13.xyz;
            u_xlat13.x = dot(u_xlat11.xyz, u_xlat7.xyw);
            u_xlat37.x = dot(u_xlat11.xyz, u_xlat11.xyz);
            u_xlat13.y = (-u_xlat42) + u_xlat13.x;
            u_xlat51 = (-u_xlat43) * u_xlat13.x + u_xlat37.x;
            u_xlat51 = u_xlat42 * u_xlat42 + u_xlat51;
            u_xlat16_12.x = inversesqrt(u_xlat37.x);
            u_xlat16_12.y = inversesqrt(u_xlat51);
            u_xlat16_24.xy = u_xlat16_12.xy * u_xlat13.xy;
            u_xlat16_37.xy = abs(u_xlat16_24.xy) * vec2(-0.156582996, -0.156582996) + vec2(1.57079637, 1.57079637);
            u_xlat16_12.xy = -abs(u_xlat16_24.xy) + vec2(1.0, 1.0);
            u_xlat16_12.xy = sqrt(u_xlat16_12.xy);
            u_xlat16_40.xy = u_xlat16_37.xy * u_xlat16_12.xy;
            u_xlatb11.xy = greaterThanEqual(u_xlat16_24.xyxx, vec4(0.0, 0.0, 0.0, 0.0)).xy;
            u_xlat16_37.xy = (-u_xlat16_37.xy) * u_xlat16_12.xy + vec2(3.14159274, 3.14159274);
            u_xlat37.x = (u_xlatb11.x) ? u_xlat16_40.x : u_xlat16_37.x;
            u_xlat37.y = (u_xlatb11.y) ? u_xlat16_40.y : u_xlat16_37.y;
            u_xlat16_24.xy = vec2(u_xlat16_33) + u_xlat37.xy;
            u_xlat16_37.xy = u_xlat16_24.xy * vec2(0.318309873, 0.318309873) + vec2(0.5, 0.5);
            u_xlat16_37.xy = clamp(u_xlat16_37.xy, 0.0, 1.0);
            u_xlat16_24.xy = u_xlat16_37.xy * u_xlat16_37.xy;
            u_xlat16_12.xy = (-u_xlat16_37.xy) * vec2(2.0, 2.0) + vec2(3.0, 3.0);
            u_xlat16_47 = u_xlat16_24.x * u_xlat16_12.x;
            u_xlat16_24.x = u_xlat16_47 * 32.0;
            u_xlatu37 = uint(u_xlat16_24.x);
            u_xlat16_47 = u_xlat16_24.y * u_xlat16_12.y + (-u_xlat16_47);
            u_xlat16_47 = clamp(u_xlat16_47, 0.0, 1.0);
            u_xlat16_47 = u_xlat16_47 * 32.0;
            u_xlat16_47 = ceil(u_xlat16_47);
            u_xlatu51 = uint(u_xlat16_47);
            u_xlati35 = int(bitfieldInsert(u_xlati35, 0, int(u_xlatu37) & int(0x1F), int(u_xlatu51)));
        }
        u_xlati36 = bitCount(u_xlati35);
        u_xlat36.x = float(u_xlati36);
        u_xlat36.x = u_xlat36.x * 0.03125;
        u_xlat46 = u_xlat36.x * u_xlat16_10 + u_xlat16_46;
        u_xlat44 = u_xlat44 + u_xlat16_10;
        u_xlat11.x = dot(u_xlat16_5.xy, vec2(-4.37113883e-08, 1.0));
        u_xlat11.y = dot(u_xlat16_5.xy, vec2(-1.0, -4.37113883e-08));
        u_xlatu34 = u_xlatu34 + 1u;
        u_xlat16_46 = u_xlat46;
        u_xlat16_5.xy = u_xlat11.xy;
    }
    SV_Target0.x = u_xlat16_46 / u_xlat44;
    SV_Target0.yzw = vec3(1.0, 0.0, 0.0);
    return;
}