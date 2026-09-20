import Foundation
import simd

/// A 3D spatial vector with double-precision arithmetic operations,
/// standard in modern vector astrometry (NOVAS, SOFA, ICRS).
/// Accelerated with Apple SIMD hardware instructions.
public struct Vector3D: Sendable, Hashable, Equatable, CustomStringConvertible {
    public var rawValue: simd_double3

    public var x: Double {
        get { rawValue.x }
        set { rawValue.x = newValue }
    }
    public var y: Double {
        get { rawValue.y }
        set { rawValue.y = newValue }
    }
    public var z: Double {
        get { rawValue.z }
        set { rawValue.z = newValue }
    }

    public init(x: Double, y: Double, z: Double) {
        self.rawValue = simd_double3(x, y, z)
    }

    public init(_ rawValue: simd_double3) {
        self.rawValue = rawValue
    }

    /// Zero vector (0, 0, 0)
    public static let zero = Vector3D(simd_double3(0, 0, 0))

    /// Euclidean length (magnitude) of the vector
    public var length: Double {
        simd_length(rawValue)
    }

    /// Unit vector pointing in the same direction. Returns `.zero` if length is 0.
    public var normalized: Vector3D {
        let len = simd_length(rawValue)
        guard len > 0 else { return .zero }
        return Vector3D(rawValue / len)
    }

    public var description: String {
        "(\(x), \(y), \(z))"
    }

    // MARK: - Vector Arithmetic (Hardware SIMD)

    public static func + (lhs: Vector3D, rhs: Vector3D) -> Vector3D {
        Vector3D(lhs.rawValue + rhs.rawValue)
    }

    public static func - (lhs: Vector3D, rhs: Vector3D) -> Vector3D {
        Vector3D(lhs.rawValue - rhs.rawValue)
    }

    public static prefix func - (vector: Vector3D) -> Vector3D {
        Vector3D(-vector.rawValue)
    }

    public static func * (vector: Vector3D, scalar: Double) -> Vector3D {
        Vector3D(vector.rawValue * scalar)
    }

    public static func * (scalar: Double, vector: Vector3D) -> Vector3D {
        Vector3D(vector.rawValue * scalar)
    }

    public static func / (vector: Vector3D, scalar: Double) -> Vector3D {
        Vector3D(vector.rawValue / scalar)
    }

    /// Dot (scalar) product
    public func dot(_ other: Vector3D) -> Double {
        simd_dot(rawValue, other.rawValue)
    }

    /// Cross (vector) product
    public func cross(_ other: Vector3D) -> Vector3D {
        Vector3D(simd_cross(rawValue, other.rawValue))
    }

    /// Distance to another vector position
    public func distance(to other: Vector3D) -> Double {
        simd_distance(rawValue, other.rawValue)
    }

    /// Angle in radians between two non-zero vectors
    public func angle(to other: Vector3D) -> Double {
        let denom = simd_length(rawValue) * simd_length(other.rawValue)
        guard denom > 0 else { return 0 }
        let cosTheta = max(-1.0, min(1.0, simd_dot(rawValue, other.rawValue) / denom))
        return acos(cosTheta)
    }

    /// Convert spherical coordinates (Right Ascension, Declination in degrees, Distance) to Cartesian Vector3D
    public static func fromSpherical(ra: Double, dec: Double, distance: Double = 1.0) -> Vector3D {
        let raRad = ra * .pi / 180.0
        let decRad = dec * .pi / 180.0
        let cosDec = cos(decRad)
        return Vector3D(
            x: distance * cosDec * cos(raRad),
            y: distance * cosDec * sin(raRad),
            z: distance * sin(decRad)
        )
    }

    /// Convert Cartesian coordinates back to spherical (ra: degrees [0, 360), dec: degrees [-90, 90], distance)
    public var toSpherical: (ra: Double, dec: Double, distance: Double) {
        let dist = length
        guard dist > 0 else { return (0, 0, 0) }
        var ra = atan2(y, x) * 180.0 / .pi
        if ra < 0 { ra += 360.0 }
        let dec = asin(max(-1.0, min(1.0, z / dist))) * 180.0 / .pi
        return (ra, dec, dist)
    }
}

/// A 6-dimensional phase space state vector (position and velocity).
public struct StateVector: Sendable, Hashable, Equatable {
    public var position: Vector3D
    public var velocity: Vector3D

    public init(position: Vector3D, velocity: Vector3D) {
        self.position = position
        self.velocity = velocity
    }
}

/// Astrometric vector reductions conforming to NOVAS (Naval Observatory Vector Astrometry Software) formulas.
public enum AstrometryReductions: Sendable {
    /// Speed of light in astronomical units per day (AU / day)
    public static let speedOfLightAUPerDay: Double = 173.1446326846693

    /// Speed of light in meters per second
    public static let speedOfLightMPerS: Double = 299_792_458.0

    /// Heliocentric Gravitational constant GM_sun in AU^3 / day^2
    public static let heliocentricGravitationalConstant: Double = 0.0002959122082855911

    /// Relativistic gravitational light deflection near the Sun (Einstein deflection, NOVAS method).
    /// - Parameters:
    ///   - bodyPos: Heliocentric position vector of the target body or star direction (AU).
    ///   - earthPos: Heliocentric position vector of Earth (AU).
    /// - Returns: Deflected heliocentric direction vector.
    public static func gravitationalDeflection(bodyPos: Vector3D, earthPos: Vector3D) -> Vector3D {
        let p = bodyPos.normalized
        let e = earthPos
        let eLen = e.length
        guard eLen > 0 else { return p }

        let q = p.cross(e).cross(p)
        let qLen = q.length
        guard qLen > 1e-12 else { return p } // Exactly inline with the Sun

        let d = e.dot(p)
        let r = eLen
        // Relativistic factor 2 * mu / (c^2 * r * (1 + cosD))
        // For the Sun in astronomical units: 2 * GM_sun / c^2 = 9.87063e-9 AU
        let twoGmOverC2 = 9.8706338e-9 // 2 * GM_sun / c^2 in AU
        let factor = twoGmOverC2 / (r * (1.0 + d / r))

        let deltaP = q.normalized * factor
        return (p + deltaP).normalized
    }

    /// Stellar or planetary aberration correction using observer's heliocentric velocity vector (AU/day).
    /// - Parameters:
    ///   - direction: Unit direction vector of the incoming light.
    ///   - observerVelocity: Velocity vector of the observer (AU/day).
    /// - Returns: Apparent direction vector altered by aberration.
    public static func aberration(direction: Vector3D, observerVelocity: Vector3D) -> Vector3D {
        let u = direction.normalized
        let v = observerVelocity / speedOfLightAUPerDay
        let vLen = v.length
        guard vLen > 0 else { return u }

        let beta = (1.0 - vLen * vLen).squareRoot()
        let vDotU = v.dot(u)
        let denom = 1.0 + vDotU

        // Special relativity aberration formula
        let apparent = (u * beta + v + (v * (vDotU / (1.0 + beta)))) / denom
        return apparent.normalized
    }
}
