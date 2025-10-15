import Foundation
import RealityKit
import Metal

// Define GrassVertex in Swift (must match GrassVertex.h layout exactly)
struct GrassVertex {
    var position: SIMD3<Float>
    var normal: SIMD3<Float>
    var uv: SIMD2<Float>
}

extension GrassVertex {
    static var vertexAttributes: [LowLevelMesh.Attribute] = [
        .init(semantic: .position, format: .float3, offset: MemoryLayout<Self>.offset(of: \.position)!),
        .init(semantic: .normal, format: .float3, offset: MemoryLayout<Self>.offset(of: \.normal)!),
        .init(semantic: .uv0, format: .float2, offset: MemoryLayout<Self>.offset(of: \.uv)!)
    ]

    static var vertexLayouts: [LowLevelMesh.Layout] = [
        .init(bufferIndex: 0, bufferStride: MemoryLayout<Self>.stride)
    ]

    static var descriptor: LowLevelMesh.Descriptor {
        var desc = LowLevelMesh.Descriptor()
        desc.vertexAttributes = GrassVertex.vertexAttributes
        desc.vertexLayouts = GrassVertex.vertexLayouts
        desc.indexType = .uint32
        return desc
    }

    @MainActor static func initializeMesh(vertexCapacity: Int,
                                          indexCapacity: Int) throws -> LowLevelMesh {
        var desc = GrassVertex.descriptor
        desc.vertexCapacity = vertexCapacity
        desc.indexCapacity = indexCapacity
        return try LowLevelMesh(descriptor: desc)
    }
}

// Define GrassParams in Swift (must match GrassVertex.h layout exactly)
struct GrassParams {
    var planeSize: SIMD2<Float>
    var grassCount: UInt32
    var time: Float
    var grassHeight: Float
    var grassWidth: Float
    var windStrength: Float
    var density: Float
}
