/**
 * GrassShader.metal
 *
 * Metal compute shader that procedurally generates grass blades on the GPU.
 * Each grass blade has 4 SEGMENTS for realistic bending along its length.
 *
 * BLADE STRUCTURE (side view):
 *     v8--v9  ← Top segment (bends most)
 *     | /|
 *     |/ |
 *     v6--v7  ← Segment 3
 *     | /|
 *     |/ |
 *     v4--v5  ← Segment 2
 *     | /|
 *     |/ |
 *     v2--v3  ← Segment 1 (bends least)
 *     | /|
 *     |/ |
 *     v0--v1  ← Base (no bend)
 *
 * Total per blade: 10 vertices, 8 triangles (4 segments × 2 triangles each)
 */

#include <metal_stdlib>
using namespace metal;

#include "GrassVertex.h"

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/**
 * Random number generator using hash function
 */
float random(float2 st) {
    return fract(sin(dot(st, float2(12.9898, 78.233))) * 43758.5453123);
}

/**
 * 2D Noise function for smooth random values
 */
float noise(float2 st) {
    float2 i = floor(st);
    float2 f = fract(st);

    float a = random(i);
    float b = random(i + float2(1.0, 0.0));
    float c = random(i + float2(0.0, 1.0));
    float d = random(i + float2(1.0, 1.0));

    float2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// ============================================================================
// MAIN COMPUTE KERNEL
// ============================================================================

kernel void generateGrass(
    device GrassVertex* outVertices [[buffer(0)]],
    device uint* outIndices [[buffer(1)]],
    device atomic_uint* outVertexCounter [[buffer(2)]],
    constant GrassParams& params [[buffer(3)]],
    uint gid [[thread_position_in_grid]])
{
    if (gid >= params.grassCount) return;

    // ========================================================================
    // STEP 1: Generate Random Position and Properties
    // ========================================================================

    float2 seed = float2(float(gid) * 0.1, float(gid) * 0.07);

    // Random position
    float x = (random(seed) - 0.5) * params.planeSize.x;
    float z = (random(seed + float2(13.7, 29.3)) - 0.5) * params.planeSize.y;
    float3 basePos = float3(x, 0, z);

    // Random properties
    float heightVariation = random(seed + float2(5.3, 7.1));
    float widthVariation = random(seed + float2(11.2, 3.9));

    float height = params.grassHeight * (0.7 + heightVariation * 0.6);
    float width = params.grassWidth * (0.8 + widthVariation * 0.4);

    // Wind calculation
    float windPhase = x * 0.3 + z * 0.2 + params.time * 2.0;
    float windBase = sin(windPhase) * params.windStrength;

    // ========================================================================
    // STEP 2: Create 4 Segments (5 height levels)
    // ========================================================================

    const int NUM_SEGMENTS = 4;
    const int NUM_LEVELS = NUM_SEGMENTS + 1;  // 5 levels for 4 segments

    // Get base vertex index (10 vertices per blade)
    uint baseVertexIndex = atomic_fetch_add_explicit(outVertexCounter, NUM_LEVELS * 2, memory_order_relaxed);

    // Create vertices at each height level
    for (int level = 0; level < NUM_LEVELS; level++) {
        // Height ratio: 0.0 (bottom) to 1.0 (top)
        float t = float(level) / float(NUM_SEGMENTS);

        // Current height along blade
        float currentHeight = height * t;

        // Wind bends more at the top (cubic curve for natural motion)
        // t^2 means: bottom barely moves, tip moves most
        float bendAmount = windBase * t * t;

        // Vertices form a quad at this height level
        // Left and right side of the blade
        float3 leftPos = basePos + float3(-width * 0.5 + bendAmount, currentHeight, 0);
        float3 rightPos = basePos + float3(width * 0.5 + bendAmount, currentHeight, 0);

        // Calculate normal (pointing forward for now, could be improved)
        float3 normal = float3(0, 0, 1);

        // Write left vertex
        uint leftIdx = baseVertexIndex + level * 2;
        outVertices[leftIdx].position = leftPos;
        outVertices[leftIdx].normal = normal;
        outVertices[leftIdx].uv = float2(0, t);

        // Write right vertex
        uint rightIdx = baseVertexIndex + level * 2 + 1;
        outVertices[rightIdx].position = rightPos;
        outVertices[rightIdx].normal = normal;
        outVertices[rightIdx].uv = float2(1, t);
    }

    // ========================================================================
    // STEP 3: Create Triangle Indices for Each Segment
    // ========================================================================

    // Calculate where to write indices
    // Each blade needs 24 indices (4 segments × 2 triangles × 3 indices)
    // Index position = blade_id × 24
    uint indexOffset = gid * 24;

    for (int seg = 0; seg < NUM_SEGMENTS; seg++) {
        // Vertices for this quad segment:
        // v2--v3  (top of this segment)
        // |  /|
        // | / |
        // v0--v1  (bottom of this segment)

        uint v0 = baseVertexIndex + seg * 2;          // Bottom-left
        uint v1 = baseVertexIndex + seg * 2 + 1;      // Bottom-right
        uint v2 = baseVertexIndex + (seg + 1) * 2;    // Top-left
        uint v3 = baseVertexIndex + (seg + 1) * 2 + 1; // Top-right

        // Each segment uses 6 indices (2 triangles)
        uint segmentIndexOffset = indexOffset + seg * 6;

        // First triangle: v0, v1, v2 (counter-clockwise)
        outIndices[segmentIndexOffset + 0] = v0;
        outIndices[segmentIndexOffset + 1] = v1;
        outIndices[segmentIndexOffset + 2] = v2;

        // Second triangle: v1, v3, v2 (counter-clockwise)
        outIndices[segmentIndexOffset + 3] = v1;
        outIndices[segmentIndexOffset + 4] = v3;
        outIndices[segmentIndexOffset + 5] = v2;
    }
}

/*
 * PERFORMANCE NOTES:
 *
 * - Each blade now uses 10 vertices (was 3)
 * - Each blade creates 8 triangles (was 1)
 * - For 5000 blades: 50,000 vertices, 40,000 triangles
 * - GPU time: ~5-10ms (still very fast!)
 *
 * BENDING BEHAVIOR:
 * - Base (t=0): No wind effect
 * - Segment 1 (t=0.25): 6% of wind effect (0.25^2)
 * - Segment 2 (t=0.5): 25% of wind effect (0.5^2)
 * - Segment 3 (t=0.75): 56% of wind effect (0.75^2)
 * - Top (t=1.0): 100% of wind effect (1.0^2)
 *
 * This creates natural grass motion where the tip sways most!
 */
