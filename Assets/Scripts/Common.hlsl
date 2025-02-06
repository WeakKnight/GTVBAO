#ifndef COMMON_HLSL
#define COMMON_HLSL

static const float M_PI = 3.14159265;
static const float M_2PI = 6.28318531;  // 2pi
static const float M_4PI = 12.56637061;  // 4pi
static const float M_PI_2 = 1.57079632679489661923; // pi/2
static const float M_PI_4 = 0.785398163397448309616; // pi/4
static const float M_1_PI = 0.318309886183790671538; // 1/pi
static const float FLT_MIN = 1.175494351e-38F;        // min normalized positive value
static const float FLT_MAX = 3.402823466e+38F;        // max value
static const float kMinCosTheta = 1e-6f;
static const float kBigAccumWeight = 10000.0f;

float square(float x) { return x * x; }
float2 square(float2 x) { return x * x; }
float3 square(float3 x) { return x * x; }
float4 square(float4 x) { return x * x; }

float2 sample_disk(float2 random)
{
    float angle = 2 * M_PI * random.x;
    return float2(cos(angle), sin(angle)) * sqrt(random.y);
}

float3 sample_sphere(float2 random, out float solidAnglePdf)
{
    // See (6-8) in https://mathworld.wolfram.com/SpherePointPicking.html

    random.y = random.y * 2.0 - 1.0;

    float2 tangential = sample_disk(float2(random.x, 1.0 - square(random.y)));
    float elevation = random.y;

    solidAnglePdf = 0.25f / M_PI;

    return float3(tangential.xy, elevation);
}

float3 sample_sphere(float2 random)
{
    float pdf;
    return sample_sphere(random, pdf);
}

float4 quaternion_create(float3 from, float3 to)
{
    float3 xyz = cross(from, to);
    float s  =   dot(from, to);

    float u = rsqrt(max(0.0, s * 0.5 + 0.5));// rcp(cosine half-angle formula)
                    
    s    = 1.0 / u;
    xyz *= u * 0.5;

    return float4(xyz, s);
}

float4 quaternion_create(float3 to)
{
    //vec3 from = vec3(0.0, 0.0, 1.0);

    float3 xyz = float3(-to.y, to.x, 0.0);// cross(from, to);
    float s  =                   to.z;//   dot(from, to);

    float u = rsqrt(max(0.0, s * 0.5 + 0.5));// rcp(cosine half-angle formula)
    
    s    = 1.0 / u;
    xyz *= u * 0.5;

    return float4(xyz, s);        
}

float3 transform_xyz_by_unit_quaternion(float3 v, float4 q)
{
    float3 k = cross(q.xyz, v);
                
    return v + 2.0 * float3(dot(float3(q.wy, -q.z), k.xzy),
                          dot(float3(q.wz, -q.x), k.yxz),
                          dot(float3(q.wx, -q.y), k.zyx));
}
            
float3 transform_xyz_by_unit_quaternion_xy0s(float3 v, float4 q)
{
    float k = v.y * q.x - v.x * q.y;
    float g = 2.0 * (v.z * q.w + k);
                
    float3 r;
    r.xy = v.xy + q.yx * float2(g, -g);
    r.z  = v.z + 2.0 * (q.w * k - v.z * dot(q.xy, q.xy));
                
    return r;
}

float3 transform_xy0_by_unit_quaternion_xy0s(float2 v, float4 q)
{
    float o = q.x * v.y;
    float c = q.y * v.x;
                
    float3 b = float3( o - c,
                  -o + c,
                   o - c);
                
    return float3(v, 0.0) + 2.0 * (b * q.yxw);
}

float acos_poly(float x)
{
    // higher quality version of GTAOFastAcos (for the cost of one additional mad)
    // minimizes max abs(ACos_Approx(cos(x)) - x)
    return 1.5707963267948966 + (-0.20491203466059038 + 0.04832927023878897 * x) * x;
}

float acos_approx(float x)
{
    float u = acos_poly(abs(x)) * sqrt(1.0 - abs(x));
			
    return x >= 0.0 ? u : M_PI - u;
}

float acos_01_approx(float x)// x: [0,1]
{
    return acos_poly(x) * sqrt(1.0 - x);
}

float acos_approx_safe(float x)
{
    return acos_approx(clamp(x, -1.0, 1.0));
}

float2 acos_approx_safe(float2 v)
{
    return float2(acos_approx(clamp(v.x, -1.0, 1.0)), acos_approx(clamp(v.y, -1.0, 1.0)));
}

// convex/concave(based on b) step
float curvature_bias_step(float x, float b)
{
    return x + (x - x * x) * b;
}

// z curve shape step
float sin_step(float x)
{
    return 0.5 - 0.5 * cos(x * M_PI);
}

// inverse function of sin step
float inv_sin_step(float x)
{
    return acos(1.0 - 2.0 * x) * M_1_PI;
}

float inv_sin_step(float x, float s)
{
    if(s < 0.00001)
    {
        return x;
    }
    
    float u = asin(sin(s * M_PI_2) * (1.0 - 2.0 * x));
    return 0.5 - u * (M_1_PI / s);
}

float sample_slice(float x, float sinNV)
{
    float s = curvature_bias_step(sinNV, 0.15);
    
    x =    sin_step(x);
    float y = inv_sin_step(x, s);
    y = inv_sin_step(y);
    
    return y;
}

float2 complex_multiply(float2 c0, float2 c1)
{
	return float2(c0.x * c1.x - c0.y * c1.y, 
		        c0.y * c1.x + c0.x * c1.y);
}

// vvsN: view vec space normal | rnd01: [0, 1]
float2 sample_slice_direction(float3 vvsN, float rnd01)
{
    float ang0 = rnd01 * M_PI;
    
    float2 dir0 = float2(cos(ang0), sin(ang0));

    float l = length(vvsN.xy);

    if(l == 0.0) return dir0;
    
    // flip dir0 into hemi-circle of rsN.xy
    dir0 *= dot(dir0, vvsN.xy) < 0.0 ? -1.0 : 1.0;
    
    float2 n = vvsN.xy / l;    
    
    // align n with x-axis
    dir0 = complex_multiply(dir0, n * float2(1.0, -1.0));

    // sample slice angle
    float ang;
    {
        float x = atan(-dir0.y / dir0.x) * M_1_PI + 0.5;
        float sinNV = l;

        ang = sample_slice(x, sinNV) * M_PI - M_PI_2;
    }
    
    // ray space slice direction
    float2 dir = float2(cos(ang), sin(ang));
    
    // align x-axis with n
    dir = complex_multiply(dir, n);
    
    return dir;
}

float slice_rel_cdf_cos(float x, float angN, float cosN, bool isPhiLargerThanAngN)
{
    if(x <= 0.0 || x >= 1.0) return x;
    
    float phi = x * M_PI - M_PI_2;

    bool c = isPhiLargerThanAngN;
    
    float n0 = c ?  3.0 : 1.0;
    float n1 = c ? -1.0 : 1.0;
    float n2 = c ?  4.0 : 0.0;
    
    float t0 = n0 * cosN + n1 * cos(angN - 2.0 * phi) + (n2 * angN + (n1 * 2.0) * phi + M_PI) * sin(angN);
    float t1 = 4.0 * (cosN + angN * sin(angN));

    return t0 / t1;
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

#endif