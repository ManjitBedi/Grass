import Metal

/// Optional helper class for managing grass parameters and presets
class GrassPlaneManager {

    /// Grass configuration presets
    enum GrassPreset {
        case sparse
        case normal
        case dense
        case lush

        var config: GrassConfig {
            switch self {
            case .sparse:
                return GrassConfig(
                    grassCount: 10000,
                    grassHeight: 0.1,
                    grassWidth: 0.015,
                    windStrength: 0.15,
                    baseColor: (0.3, 0.5, 0.1)
                )
            case .normal:
                return GrassConfig(
                    grassCount: 50000,
                    grassHeight: 0.15,
                    grassWidth: 0.02,
                    windStrength: 0.1,
                    baseColor: (0.2, 0.6, 0.1)
                )
            case .dense:
                return GrassConfig(
                    grassCount: 100000,
                    grassHeight: 0.18,
                    grassWidth: 0.018,
                    windStrength: 0.08,
                    baseColor: (0.15, 0.65, 0.1)
                )
            case .lush:
                return GrassConfig(
                    grassCount: 80000,
                    grassHeight: 0.2,
                    grassWidth: 0.025,
                    windStrength: 0.12,
                    baseColor: (0.1, 0.7, 0.15)
                )
            }
        }
    }

    /// Color presets for different grass types
    enum GrassColor {
        case healthy
        case dry
        case dark
        case autumn

        var rgb: (Float, Float, Float) {
            switch self {
            case .healthy:
                return (0.2, 0.6, 0.1)
            case .dry:
                return (0.4, 0.35, 0.2)
            case .dark:
                return (0.1, 0.3, 0.05)
            case .autumn:
                return (0.5, 0.4, 0.1)
            }
        }
    }

    /// Complete grass configuration
    struct GrassConfig {
        var grassCount: UInt32
        var grassHeight: Float
        var grassWidth: Float
        var windStrength: Float
        var baseColor: (Float, Float, Float)
        var planeSize: SIMD2<Float> = SIMD2<Float>(10, 10)

        mutating func applyColor(_ color: GrassColor) {
            baseColor = color.rgb
        }
    }

    /// Validates Metal device capabilities
    static func validateMetalSupport() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw GrassError.metalNotAvailable
        }

        guard let library = device.makeDefaultLibrary() else {
            throw GrassError.shaderLibraryNotFound
        }

        guard library.makeFunction(name: "generateGrass") != nil else {
            throw GrassError.shaderFunctionNotFound
        }
    }

    /// Calculates optimal grass count based on performance target
    static func recommendedGrassCount(targetFPS: Int = 60) -> UInt32 {
        // Simple heuristic - in practice, profile on device
        switch targetFPS {
        case 30:
            return 25000
        case 60:
            return 50000
        case 90:
            return 75000
        default:
            return 50000
        }
    }
}

/// Errors that can occur when creating grass
enum GrassError: Error {
    case metalNotAvailable
    case shaderLibraryNotFound
    case shaderFunctionNotFound

    var localizedDescription: String {
        switch self {
        case .metalNotAvailable:
            return "Metal is not available on this device"
        case .shaderLibraryNotFound:
            return "Could not load Metal shader library. Ensure GrassShader.metal is in your project."
        case .shaderFunctionNotFound:
            return "Could not find 'generateGrass' function. Ensure GrassShader.metal is compiled."
        }
    }
}
