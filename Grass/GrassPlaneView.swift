import SwiftUI
import RealityKit
import Metal

struct GrassPlaneView: View {
    @State var entity: ModelEntity?
    @State var mesh: LowLevelMesh?
    @State var timer: Timer?
    @State var startTime = CACurrentMediaTime()
    @State var isActive = true
    @Environment(\.scenePhase) var scenePhase

    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let computePipelineState: MTLComputePipelineState?
    let vertexCountBuffer: MTLBuffer

    let planeSize: SIMD2<Float> = SIMD2<Float>(1, 1)  // Smaller plane
    let grassCount: UInt32 = 100  // More blades
    let grassHeight: Float = 0.5
    let grassWidth: Float = 0.05
    let windStrength: Float = 0.5
    let density: Float = 100.0  // Higher density

    init() {
        let device = MTLCreateSystemDefaultDevice()!
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        self.vertexCountBuffer = device.makeBuffer(length: MemoryLayout<UInt32>.stride, options: .storageModeShared)!

        let library = device.makeDefaultLibrary()!

        print("Available Metal functions:")
        for name in library.functionNames {
            print("  - \(name)")
        }

        if let function = library.makeFunction(name: "generateGrass") {
            self.computePipelineState = try? device.makeComputePipelineState(function: function)
            if self.computePipelineState != nil {
                print("✅ Successfully created compute pipeline")
            } else {
                print("❌ Failed to create compute pipeline")
            }
        } else {
            print("❌ Could not find 'generateGrass' function in Metal library")
            self.computePipelineState = nil
        }
    }

    var body: some View {
        RealityView { content in
            let vertexCapacity = Int(grassCount * 10)
            let indexCapacity = Int(grassCount * 24)

            let lowLevelMesh = try! GrassVertex.initializeMesh(
                vertexCapacity: vertexCapacity,
                indexCapacity: indexCapacity
            )

            let meshResource = try! await MeshResource(from: lowLevelMesh)

            var material = PhysicallyBasedMaterial()
            material.baseColor = .init(tint: .init(red: 0.2, green: 0.6, blue: 0.1, alpha: 1))
            material.roughness = 0.9
            material.metallic = 0.0

            let entity = ModelEntity(mesh: meshResource, materials: [material])
            entity.position = SIMD3<Float>(0, 0, 0)
            content.add(entity)

            let groundPlane = createGroundPlane(size: planeSize)
            content.add(groundPlane)

            self.mesh = lowLevelMesh
            self.entity = entity

            addLighting(to: content)
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                isActive = true
                startTimer()
            case .inactive, .background:
                isActive = false
                stopTimer()
            @unknown default:
                break
            }
        }
    }

    func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            updateMesh()
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func updateMesh() {
        guard isActive,
              let mesh = mesh,
              let entity = entity,
              let computePipelineState = computePipelineState,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder()
        else { return }

        let currentTime = Float(CACurrentMediaTime() - startTime)

        var params = GrassParams(
            planeSize: planeSize,
            grassCount: grassCount,
            time: currentTime,
            grassHeight: grassHeight,
            grassWidth: grassWidth,
            windStrength: windStrength,
            density: density
        )

        vertexCountBuffer.contents().bindMemory(to: UInt32.self, capacity: 1).pointee = 0

        let vertexBuffer = mesh.replace(bufferIndex: 0, using: commandBuffer)
        let indexBuffer = mesh.replaceIndices(using: commandBuffer)

        computeEncoder.setComputePipelineState(computePipelineState)
        computeEncoder.setBuffer(vertexBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(indexBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(vertexCountBuffer, offset: 0, index: 2)
        computeEncoder.setBytes(&params, length: MemoryLayout<GrassParams>.stride, index: 3)

        let threadsPerThreadgroup = MTLSize(width: 256, height: 1, depth: 1)
        let threadgroups = MTLSize(
            width: (Int(grassCount) + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width,
            height: 1,
            depth: 1
        )

        computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
        computeEncoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        let indexCount = Int(vertexCountBuffer.contents().bindMemory(to: UInt32.self, capacity: 1).pointee)

        mesh.parts.replaceAll([
            LowLevelMesh.Part(
                indexCount: indexCount,
                topology: .triangle,
                bounds: BoundingBox(
                    min: SIMD3<Float>(-planeSize.x/2, 0, -planeSize.y/2),
                    max: SIMD3<Float>(planeSize.x/2, grassHeight, planeSize.y/2)
                )
            )
        ])

        // CRITICAL: Recreate MeshResource to force RealityKit to update the visual
        Task { @MainActor in
            if let newMeshResource = try? await MeshResource(from: mesh) {
                entity.model?.mesh = newMeshResource
            }
        }
    }

    func addLighting(to content: RealityViewContent) {
        let lightEntity = Entity()

        var directionalLight = DirectionalLightComponent()
        directionalLight.intensity = 2000
        directionalLight.color = .white

        lightEntity.components[DirectionalLightComponent.self] = directionalLight
        lightEntity.orientation = simd_quatf(angle: -.pi/4, axis: [1, 0, 0])

        content.add(lightEntity)
    }

    func createGroundPlane(size: SIMD2<Float>) -> ModelEntity {
        let groundMesh = MeshResource.generatePlane(width: size.x, depth: size.y)

        var groundMaterial = PhysicallyBasedMaterial()
        groundMaterial.baseColor = .init(tint: .init(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0))
        groundMaterial.roughness = 0.95
        groundMaterial.metallic = 0.0

        let groundEntity = ModelEntity(mesh: groundMesh, materials: [groundMaterial])
        groundEntity.position = SIMD3<Float>(0, -0.001, 0)

        return groundEntity
    }
}

#Preview {
    GrassPlaneView()
}
