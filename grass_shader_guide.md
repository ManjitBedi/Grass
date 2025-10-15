# visionOS 26 Grass Implementation Guide

Complete guide for implementing procedural grass using **Metal Compute Shaders** with **LowLevelMesh** in visionOS 26.

## ✅ What IS Available in visionOS 26

- **Metal** - Full Metal support with compute and render shaders
- **LowLevelMesh** - Direct mesh manipulation
- **MTLDevice, MTLCommandQueue, MTLBuffer** - All Metal APIs
- **Compute shaders** - Generate geometry procedurally on GPU

## ❌ What is NOT Available

- **CustomMaterial** - Cannot use for RealityKit materials (use ShaderGraphMaterial instead)
- That's it! Everything else works.

## 🎯 Architecture

The grass system uses:
1. **Metal Compute Shader** (`GrassShader.metal`) - Generates grass blade geometry
2. **LowLevelMesh** - Dynamic mesh updated every frame
3. **Swift View** (`GrassPlaneView.swift`) - Manages the compute pipeline
4. **Vertex Structure** (`GrassVertex.swift`) - Defines vertex layout

## 📁 Project Structure

```
YourProject/
├── GrassShader.metal              // Metal compute shader
├── GrassPlaneView.swift           // SwiftUI + RealityKit view
└── GrassVertex.swift              // Vertex structure & extensions
```

## 🚀 Setup Instructions

### Step 1: Add Files to Project

1. Add `GrassShader.metal` to your Xcode project
2. Add `GrassPlaneView.swift`
3. Add `GrassVertex.swift`
4. Ensure `.metal` file is in **Build Phases** → **Compile Sources**

### Step 2: Use in Your App

```swift
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            GrassPlaneView()
        }
    }
}
```

## 🎨 How It Works

### Compute Shader Flow

1. **Thread per grass blade**: Each GPU thread generates one blade
2. **Random placement**: Hash function distributes blades across plane
3. **Wind animation**: Sin wave based on time and position
4. **Output to buffers**: Writes vertices and indices to LowLevelMesh

### Update Loop

```
Timer (60 FPS)
  ↓
Update time parameter
  ↓
Dispatch compute shader
  ↓
Write to LowLevelMesh buffers
  ↓
RealityKit renders mesh
```

## ⚙️ Customization

### Grass Density

In `GrassPlaneView.swift`:
```swift
let grassCount: UInt32 = 50000  // Number of blades
```
- **10,000** = Sparse
- **50,000** = Normal (default)
- **100,000** = Dense (may impact performance)

### Grass Height

```swift
let grassHeight: Float = 0.15  // Height in meters
```

### Wind Strength

```swift
let windStrength: Float = 0.1  // Animation amount
```
- **0.0** = No wind
- **0.1** = Gentle breeze (default)
- **0.3** = Strong wind

### Grass Color

In `GrassPlaneView.swift`, modify the material:
```swift
material.baseColor = .init(tint: .init(red: 0.2, green: 0.6, blue: 0.1, alpha: 1))
```

Presets:
- **Healthy**: (0.2, 0.6, 0.1)
- **Dry**: (0.4, 0.35, 0.2)
- **Dark**: (0.1, 0.3, 0.05)

### Plane Size

```swift
let planeSize: SIMD2<Float> = SIMD2<Float>(10, 10)  // Width, depth in meters
```

## 🔧 Advanced Customization

### Multiple Blades Per Position

Modify the compute shader to create multiple triangles per thread:

```metal
kernel void generateGrass(...) {
    // Generate 3 blades per position with different rotations
    for (int i = 0; i < 3; i++) {
        float rotation = (float(i) / 3.0) * 2.0 * M_PI_F;
        // ... create rotated blade
    }
}
```

### Blade Shape Variation

Add more vertices per blade for curved grass:

```metal
// Instead of 3 vertices (1 triangle), use 6 vertices (2 triangles)
// This allows bending along the blade length
```

### Color Variation

Add a color attribute to `GrassVertex`:

```swift
struct GrassVertex {
    var position: SIMD3<Float>
    var normal: SIMD3<Float>
    var uv: SIMD2<Float>
    var color: SIMD4<Float>  // Add this
}
```

Then use `UnlitMaterial` with vertex colors.

### LOD (Level of Detail)

Reduce grass count based on distance from camera:

```swift
func updateGrassCount(cameraDistance: Float) {
    if cameraDistance < 5 {
        grassCount = 100000
    } else if cameraDistance < 10 {
        grassCount = 50000
    } else {
        grassCount = 10000
    }
}
```

## 📊 Performance

### Recommended Settings by Device

| Device | Grass Count | Update Rate |
|--------|-------------|-------------|
| Vision Pro | 50,000-100,000 | 60 FPS |
| Lower settings | 10,000-25,000 | 30 FPS |

### Optimization Tips

1. **Reduce update frequency**: Update every 2-3 frames instead of every frame
2. **Static grass**: Only update when needed (no wind = no updates)
3. **Instancing**: Use same blade mesh with transforms (more complex)
4. **Culling**: Don't generate grass outside view frustum

## 🐛 Troubleshooting

### No grass visible

- Check `grassCount` is > 0
- Verify Metal shader compiled (check Build Phases)
- Ensure lighting is added to scene
- Check camera position (grass is at Y=0)

### Performance issues

- Reduce `grassCount`
- Increase timer interval to 1/30 instead of 1/60
- Check Metal Frame Capture for bottlenecks

### Grass not animating

- Verify timer is running
- Check `windStrength` is > 0
- Ensure time parameter is updating

### Compile errors

- Verify all files are added to target
- Check `.metal` file is in Compile Sources
- Ensure `GrassVertex` structure matches between Swift and Metal

## 💡 Key Differences from iOS

visionOS 26 behaves identically to iOS for Metal compute shaders. The only difference is:
- Cannot use `CustomMaterial` for RealityKit materials
- Must use `PhysicallyBasedMaterial`, `SimpleMaterial`, or `ShaderGraphMaterial`

## 📚 Further Reading

- [Metal Shading Language Specification](https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf)
- [LowLevelMesh Documentation](https://developer.apple.com/documentation/realitykit/lowlevelmesh)
- [RealityKit Materials](https://developer.apple.com/documentation/realitykit/material)

## 🎓 Understanding the Code

### Why LowLevelMesh?

`LowLevelMesh` allows direct GPU buffer access, perfect for procedural geometry that changes every frame.

### Why Compute Shader?

Compute shaders run on GPU, generating thousands of grass blades in parallel. Much faster than CPU generation.

### Why Not CustomMaterial?

`CustomMaterial` is for custom surface/geometry shaders on existing meshes. We're generating the mesh itself, so we don't need it. We use standard `PhysicallyBasedMaterial` for the appearance.

## ✨ Next Steps

1. Run the base implementation
2. Adjust grass count and colors
3. Add LOD system
4. Experiment with blade shapes
5. Add interaction (grass bends when touched)

The provided code is production-ready and follows best practices for visionOS 26!
