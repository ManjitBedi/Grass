import Foundation

/// Configuration for grass shader parameters
struct GrassShaderConfiguration {

    // MARK: - Density Settings

    /// Number of grass blades to generate
    var grassCount: UInt32

    // MARK: - Appearance Settings

    /// Height of grass blades in meters
    var grassHeight: Float

    /// Width of grass blades in meters
    var grassWidth: Float

    /// Base color (RGB)
    var baseColor: (r: Float, g: Float, b: Float)

    // MARK: - Animation Settings

    /// Wind animation strength (0 = no wind, 1 = strong wind)
    var windStrength: Float

    // MARK: - Plane Settings

    /// Size of the plane in meters (width, depth)
    var planeSize: SIMD2<Float>

    // MARK: - Default Presets

    static let sparse = GrassShaderConfiguration(
        grassCount: 10000,
        grassHeight: 0.1,
        grassWidth: 0.015,
        baseColor: (0.3, 0.5, 0.1),
        windStrength: 0.15,
        planeSize: SIMD2<Float>(10, 10)
    )

    static let normal = GrassShaderConfiguration(
        grassCount: 50000,
        grassHeight: 0.15,
        grassWidth: 0.02,
        baseColor: (0.2, 0.6, 0.1),
        windStrength: 0.1,
        planeSize: SIMD2<Float>(10, 10)
    )

    static let dense = GrassShaderConfiguration(
        grassCount: 100000,
        grassHeight: 0.18,
        grassWidth: 0.018,
        baseColor: (0.15, 0.65, 0.1),
        windStrength: 0.08,
        planeSize: SIMD2<Float>(10, 10)
    )

    static let lush = GrassShaderConfiguration(
        grassCount: 80000,
        grassHeight: 0.2,
        grassWidth: 0.025,
        baseColor: (0.1, 0.7, 0.15),
        windStrength: 0.12,
        planeSize: SIMD2<Float>(10, 10)
    )

    // MARK: - Color Presets

    static let healthyColor: (Float, Float, Float) = (0.2, 0.6, 0.1)
    static let dryColor: (Float, Float, Float) = (0.4, 0.35, 0.2)
    static let darkColor: (Float, Float, Float) = (0.1, 0.3, 0.05)
    static let autumnColor: (Float, Float, Float) = (0.5, 0.4, 0.1)

    // MARK: - Helpers

    /// Returns a copy with modified color
    func withColor(_ color: (Float, Float, Float)) -> GrassShaderConfiguration {
        var config = self
        config.baseColor = color
        return config
    }

    /// Returns a copy with modified grass count
    func withGrassCount(_ count: UInt32) -> GrassShaderConfiguration {
        var config = self
        config.grassCount = count
        return config
    }

    /// Returns a copy with modified wind strength
    func withWindStrength(_ strength: Float) -> GrassShaderConfiguration {
        var config = self
        config.windStrength = strength
        return config
    }

    /// Validates the configuration and returns any warnings
    func validate() -> [String] {
        var warnings: [String] = []

        if grassCount > 150000 {
            warnings.append("Grass count is very high (\(grassCount)) - may impact performance")
        }

        if grassHeight > 0.5 {
            warnings.append("Grass height is unusually tall (\(grassHeight)m)")
        }

        if windStrength > 0.5 {
            warnings.append("Wind strength is very high (\(windStrength)) - grass may look unrealistic")
        }

        return warnings
    }
}
