//
//  GrassVertex 2.swift
//  Grass
//
//  Created by Manjit Bedi on 2025-10-14.
//


#ifndef GrassVertex_h
#define GrassVertex_h

#include <simd/simd.h>

struct GrassVertex {
    simd_float3 position;
    simd_float3 normal;
    simd_float2 uv;
};

struct GrassParams {
    simd_float2 planeSize;
    uint32_t grassCount;
    float time;
    float grassHeight;
    float grassWidth;
    float windStrength;
    float density;
};

#endif /* GrassVertex_h */