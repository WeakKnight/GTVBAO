#ifndef RANDOM_SEQUENCE_HLSL
#define RANDOM_SEQUENCE_HLSL

#define RANDOM_SAMPLER_TYPE_RANDOM 0
#define RANDOM_SAMPLER_TYPE_OWENSOBOL 1
#define RANDOM_SAMPLER_TYPE RANDOM_SAMPLER_TYPE_OWENSOBOL

struct random_sampler_state
{
    uint seed;
    uint index;

    static random_sampler_state create()
    {
    	random_sampler_state result;
        result.seed = 0u;
        result.index = 0u;
    	return result;
    }
};

// 32 bit Jenkins hash
uint JenkinsHash(uint a)
{
    // http://burtleburtle.net/bob/hash/integer.html
    a = (a + 0x7ed55d16) + (a << 12);
    a = (a ^ 0xc761c23c) ^ (a >> 19);
    a = (a + 0x165667b1) + (a << 5);
    a = (a + 0xd3a2646c) ^ (a << 9);
    a = (a + 0xfd7046c5) + (a << 3);
    a = (a ^ 0xb55a4f09) ^ (a >> 16);
    return a;
}

// High quality integer hash - this mixes bits almost perfectly
uint StrongIntegerHash(uint x)
{
	// From https://github.com/skeeto/hash-prospector
	// bias = 0.16540778981744320
	x ^= x >> 16;
	x *= 0xa812d533;
	x ^= x >> 15;
	x *= 0xb278e4ad;
	x ^= x >> 17;
	return x;
}

// This is a much weaker hash, but is faster and can be used to drive other hashes
uint WeakIntegerHash(uint x)
{
	// Generated using https://github.com/skeeto/hash-prospector
	// Estimated Bias ~583
	x *= 0x92955555u;
	x ^= x >> 15;
	return x;
}

uint Murmur3(inout random_sampler_state r)
{
#define ROT32(x, y) ((x << y) | (x >> (32 - y)))

    // https://en.wikipedia.org/wiki/MurmurHash
    uint c1 = 0xcc9e2d51;
    uint c2 = 0x1b873593;
    uint r1 = 15;
    uint r2 = 13;
    uint m = 5;
    uint n = 0xe6546b64;

    uint hash = r.seed;
    uint k = r.index++;
    k *= c1;
    k = ROT32(k, r1);
    k *= c2;

    hash ^= k;
    hash = ROT32(hash, r2) * m + n;

    hash ^= 4;
    hash ^= (hash >> 16);
    hash *= 0x85ebca6b;
    hash ^= (hash >> 13);
    hash *= 0xc2b2ae35;
    hash ^= (hash >> 16);

#undef ROT32

    return hash;
}

uint FastOwenScrambling(uint Index, uint Seed) 
{
	// Laine and Karras / Stratified Sampling for Stochastic Transparency / EGSR 2011

	// The operations below will mix bits toward the left, so temporarily reverse the order
	// NOTE: This operation has been performed outside this call
	// Index = reversebits(Index);
	
	// This follows the basic construction from the paper above. The error-diffusion sampler which
	// tiles a single point set across the screen, makes it much easier to visually "see" the impact of the scrambling.
	// When the scrambling is not good enough, the structure of the space-filling curve is left behind.
	// Care must be taken to ensure that the scrambling is still unbiased on average though. I found some cases
	// that seemed to produce lower visual error but were actually biased due to not touching certain bits,
	// leading to correlations across dimensions.

	// After much experimentation with the hash prospector, I discovered the following two constants which appear to
	// give results as good (or better) than the original 4 xor-mul constants from the Laine/Karras paper.
	// It isn't entirely clear to me why some constants work better than others. Some hashes with slightly less
    // bias produced visibly more error or worse looking power spectra.
	// Estimates below from hash prospector for all hashes of the form: add,xmul=c0,xmul=c1 (with c0 and c1 being
	// the constants below).
	// Ran with score_quality=16 for about ~10000 random hashes
	// Average bias: ~727.02
	//   Best  bias: ~723.05
	//   Worst bias: ~735.19
	Index += Seed; // randomize the index by our seed (pushes bits toward the left)
	Index ^= Index * 0x9c117646u;
	Index ^= Index * 0xe0705d72u;

	// Undo the reverse so that we get left-to-right scrambling
	// thereby emulating owen-scrambling
	return reversebits(Index);
}

uint EvolveSobolSeed(inout uint Seed)
{
	// constant from: https://www.pcg-random.org/posts/does-it-beat-the-minimal-standard.html
	const uint MCG_C = 2739110765;
	// a slightly weaker hash is ok since this drives FastOwenScrambling which is itself a hash
	// Note that the Seed evolution is just an integer addition and the hash should optimize away
	// when a particular dimension is not used
	return WeakIntegerHash(Seed += MCG_C);
}

// 32-bit Sobol matrices for dimension 1,2,3 from:
// S. Joe and F. Y. Kuo, Constructing Sobol sequences with better two-dimensional projections, SIAM J. Sci. Comput. 30, 2635-2654 (2008)
//    https://web.maths.unsw.edu.au/~fkuo/sobol/
// NOTE: we don't bother storing dimension 0 since it is just a bit reversal
// NOTE2: we don't bother storing dimension 1 either since it has a very simple pattern
// NOTE3: the matrix elements are reversed to save one reverse in the owen scrambling
static const uint2 SobolMatrices[] = {
	uint2(0x00000001, 0x00000001),
	uint2(0x00000003, 0x00000003),
	uint2(0x00000006, 0x00000004),
	uint2(0x00000009, 0x0000000a),
	uint2(0x00000017, 0x0000001f),
	uint2(0x0000003a, 0x0000002e),
	uint2(0x00000071, 0x00000045),
	uint2(0x000000a3, 0x000000c9),
	uint2(0x00000116, 0x0000011b),
	uint2(0x00000339, 0x000002a4),
	uint2(0x00000677, 0x0000079a),
	uint2(0x000009aa, 0x00000b67),
	uint2(0x00001601, 0x0000101e),
	uint2(0x00003903, 0x0000302d),
	uint2(0x00007706, 0x00004041),
	uint2(0x0000aa09, 0x0000a0c3),
	uint2(0x00010117, 0x0001f104),
	uint2(0x0003033a, 0x0002e28a),
	uint2(0x00060671, 0x000457df),
	uint2(0x000909a3, 0x000c9bae),
	uint2(0x00171616, 0x0011a105),
	uint2(0x003a3939, 0x002a7289),
	uint2(0x00717777, 0x0079e7db),
	uint2(0x00a3aaaa, 0x00b6dba4),
	uint2(0x01170001, 0x0100011a),
	uint2(0x033a0003, 0x030002a7),
	uint2(0x06710006, 0x0400079e),
	uint2(0x09a30009, 0x0a000b6d),
	uint2(0x16160017, 0x1f001001),
	uint2(0x3939003a, 0x2e003003),
	uint2(0x77770071, 0x45004004),
	uint2(0xaaaa00a3, 0xc900a00a)
};

float4 SobolSampler(uint SampleIndex, inout uint Seed)
{
	// first scramble the index to decorelate from other 4-tuples
	uint SobolIndex = FastOwenScrambling(SampleIndex, EvolveSobolSeed(Seed));
	// now get Sobol' point from this index
	uint4 Result = uint4(SobolIndex, SobolIndex, 0, 0);
	// y component can be computed without iteration
	// "An Implementation Algorithm of 2D Sobol Sequence Fast, Elegant, and Compact"
	// Abdalla Ahmed, EGSR 2024
	// See listing (19) in the paper
	// The code is different here because we want the output to be bit-reversed, but
	// the methodology is the same
	Result.y ^=  Result.y               >> 16;
	Result.y ^= (Result.y & 0xFF00FF00) >>  8;
	Result.y ^= (Result.y & 0xF0F0F0F0) >>  4;
	Result.y ^= (Result.y & 0xCCCCCCCC) >>  2;
	Result.y ^= (Result.y & 0xAAAAAAAA) >>  1;
    
	[unroll] 
    for (uint b = 0; b < 32; b++)
	{
		uint IndexBit = (SobolIndex >> b) & 1;		// bitfield extract
		Result.zw ^= IndexBit * SobolMatrices[b];
	}
	// finally scramble the points to avoid structured artifacts
	Result.x = FastOwenScrambling(Result.x, EvolveSobolSeed(Seed));
	Result.y = FastOwenScrambling(Result.y, EvolveSobolSeed(Seed));
	Result.z = FastOwenScrambling(Result.z, EvolveSobolSeed(Seed));
	Result.w = FastOwenScrambling(Result.w, EvolveSobolSeed(Seed));

	// output as float in [0,1) taking care not to skew the distribution
	// due to the non-uniform spacing of floats in this range
	return (Result >> 8) * 5.96046447754e-08; // * 2^-24
}

random_sampler_state initRandomSamplerExt(uint positionSeed, uint timeSeed)
{
	random_sampler_state state;

#if RANDOM_SAMPLER_TYPE == RANDOM_SAMPLER_TYPE_RANDOM
    state.index = 1;
    state.seed = JenkinsHash(positionSeed) + timeSeed;
#elif RANDOM_SAMPLER_TYPE == RANDOM_SAMPLER_TYPE_OWENSOBOL
		// pre-compute bit reversal needed for FastOwenScrambling since this index doesn't change
	state.index = reversebits(timeSeed);
	// change seed to get a unique sequence per pixel
	state.seed  = StrongIntegerHash(positionSeed);
#else
#error unreachable
#endif
	return state;
}

// "Explodes" an integer, i.e. inserts a 0 between each bit.  Takes inputs up to 16 bit wide.
//      For example, 0b11111111 -> 0b1010101010101010
uint integerExplode(uint x)
{
	x = (x | (x << 8)) & 0x00FF00FF;
	x = (x | (x << 4)) & 0x0F0F0F0F;
	x = (x | (x << 2)) & 0x33333333;
	x = (x | (x << 1)) & 0x55555555;
	return x;
}

// Converts a 2D position to a linear index following a Z-curve pattern.
uint ZCurveToLinearIndex(uint2 xy)
{
	return integerExplode(xy[0]) | (integerExplode(xy[1]) << 1);
}

random_sampler_state init_random_sampler(uint2 pixelPos, uint frameIndex)
{
    random_sampler_state state;

	uint linearPixelIndex = ZCurveToLinearIndex(pixelPos);

#if RANDOM_SAMPLER_TYPE == RANDOM_SAMPLER_TYPE_RANDOM
    state.index = 1;
    state.seed = JenkinsHash(linearPixelIndex) + frameIndex;
#elif RANDOM_SAMPLER_TYPE == RANDOM_SAMPLER_TYPE_OWENSOBOL
    state = initRandomSamplerExt(pixelPos.x + pixelPos.y * 65535, frameIndex);
#else
#error unreachable
#endif
    return state;
}

float sample_uniform_rng(inout random_sampler_state r)
{
#if RANDOM_SAMPLER_TYPE == RANDOM_SAMPLER_TYPE_RANDOM
    uint v = Murmur3(r);
    const uint one = asuint(1.f);
    const uint mask = (1 << 23) - 1;
    return asfloat((mask & v) | one) - 1.f;
#elif RANDOM_SAMPLER_TYPE == RANDOM_SAMPLER_TYPE_OWENSOBOL
    return SobolSampler(r.index, r.seed).x;
#else
#error unreachable
#endif
}

float2 sample_uniform_rng_2d(inout random_sampler_state r)
{
#if RANDOM_SAMPLER_TYPE == RANDOM_SAMPLER_TYPE_RANDOM
    return float2(sampleUniformRng(r), sampleUniformRng(r));
#elif RANDOM_SAMPLER_TYPE == RANDOM_SAMPLER_TYPE_OWENSOBOL
	return SobolSampler(r.index, r.seed).xy;
#else
#error unreachable
#endif
}

float3 sample_uniform_rng_3d(inout random_sampler_state r)
{
#if RANDOM_SAMPLER_TYPE == RANDOM_SAMPLER_TYPE_RANDOM
    return float3(sampleUniformRng(r), sampleUniformRng(r), sampleUniformRng(r));
#elif RANDOM_SAMPLER_TYPE == RANDOM_SAMPLER_TYPE_OWENSOBOL
	return SobolSampler(r.index, r.seed).xyz;
#else
#error unreachable
#endif
}

float4 sample_uniform_rng_4d(inout random_sampler_state r)
{
#if RANDOM_SAMPLER_TYPE == RANDOM_SAMPLER_TYPE_RANDOM
    return float4(sampleUniformRng(r), sampleUniformRng(r), sampleUniformRng(r), sampleUniformRng(r));
#elif RANDOM_SAMPLER_TYPE == RANDOM_SAMPLER_TYPE_OWENSOBOL
	return SobolSampler(r.index, r.seed);
#else
#error unreachable
#endif
}

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

#endif