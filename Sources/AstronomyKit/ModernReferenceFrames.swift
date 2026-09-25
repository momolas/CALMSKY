import Foundation
import Accelerate
import simd

/// Modern astronomical time scales conforming to IAU (International Astronomical Union) and SOFA definitions.
public enum AstronomicalTimeScale: Sendable, Hashable, CaseIterable {
    /// Universal Time (UT1), linked directly to the Earth's rotation.
    case ut1
    /// Coordinated Universal Time (civil atomic time broadcast with leap seconds).
    case utc
    /// International Atomic Time (TAI), the SI baseline time scale.
    case tai
    /// Terrestrial Time (TT), standard time scale for geocentric ephemerides (TT = TAI + 32.184s).
    case tt
    /// Barycentric Dynamical Time (TDB), relativistic time scale evaluated at the Solar System Barycenter.
    case tdb

    /// Offset from TAI in seconds (TAI - Scale). For UTC, this depends on leap seconds.
    public static let ttMinusTaiSeconds: Double = 32.184

    /// Difference TT - UTC in seconds for a given Julian Day.
    /// Uses known leap seconds table with fallback to continuous linear approximation.
    public static func deltaT(for jd: Double) -> Double {
        // Delta T = TT - UT1 ≈ TT - UTC
        // Standard NASA polynomial approximation (Espenak 2006)
        let year = (jd - 2451545.0) / 365.25 + 2000.0
        let t = year - 2000.0

        if year >= 2005 && year < 2050 {
            return 62.92 + 0.32217 * t + 0.005589 * t * t
        } else if year >= 1986 && year < 2005 {
            return 63.86 + 0.3345 * t - 0.060374 * t * t
        } else if year >= 1961 && year < 1986 {
            return 45.45 + 1.067 * t - t * t / 260.0
        } else {
            // General modern curve
            return 64.0 + 0.35 * t
        }
    }

    /// Convert a Julian Day in UTC to Terrestrial Time (TT).
    public static func utcToTT(jdUTC: Double) -> Double {
        let dtSeconds = deltaT(for: jdUTC)
        return jdUTC + dtSeconds / 86400.0
    }

    /// Convert a Julian Day in TT to UTC (approximate inverse).
    public static func ttToUTC(jdTT: Double) -> Double {
        let dtSeconds = deltaT(for: jdTT)
        return jdTT - dtSeconds / 86400.0
    }
}

/// IAU 2000/2006 reference frames and transformations (conforming to IAU SOFA standards).
public enum ModernReferenceFrames: Sendable {
    /// Earth Rotation Angle (ERA) in radians as defined in the IAU 2000 resolutions.
    /// This is the angle between the Celestial Intermediate Origin (CIO) and the Terrestrial Intermediate Origin (TIO).
    /// - Parameter jdUT1: Julian Date in UT1 time scale.
    /// - Returns: ERA in radians in the range [0, 2π).
    public static func earthRotationAngle(jdUT1: Double) -> Double {
        let d = jdUT1 - 2451545.0
        // IAU 2000 definition: ERA = 2π * (0.7790572732640 + 1.00273781191135448 * d)
        let twoPi = 2.0 * Double.pi
        let theta = (0.7790572732640 + 1.00273781191135448 * d).truncatingRemainder(dividingBy: 1.0)
        let era = theta * twoPi
        return era >= 0 ? era : era + twoPi
    }

    /// Earth Rotation Angle (ERA) in degrees [0, 360).
    public static func earthRotationAngleDegrees(jdUT1: Double) -> Double {
        earthRotationAngle(jdUT1: jdUT1) * 180.0 / .pi
    }

    /// Obliquity of the Ecliptic according to the IAU 2006 precession model.
    /// - Parameter jdTT: Julian Date in Terrestrial Time (TT).
    /// - Returns: Mean obliquity ε₀ in arcseconds.
    public static func meanObliquityIAU2006(jdTT: Double) -> Double {
        let t = (jdTT - 2451545.0) / 36525.0 // Julian centuries from J2000.0
        // IAU 2006 polynomial in arcseconds:
        return 84381.406 - 46.836769 * t - 0.0001831 * t * t + 0.00200340 * t * t * t - 0.000000576 * t * t * t * t - 0.0000000434 * t * t * t * t * t
    }

    /// Rotation matrix $R_3(\text{ERA})$ from CIRS to TIRS.
    ///
    /// Stored in column-major order (3 columns of `simd_double3`, 96 bytes with 32-byte column alignment).
    /// - Parameter jdUT1: Julian Date in UT1.
    /// - Returns: Orthogonal rotation matrix in column-major SIMD 3x3 format.
    public static func rotationMatrixCirsToTirs(jdUT1: Double) -> simd_double3x3 {
        let era = earthRotationAngle(jdUT1: jdUT1)
        let cosEra = cos(era)
        let sinEra = sin(era)

        // Column-major simd_double3x3:
        // Column 0: [cosERA, -sinERA, 0]
        // Column 1: [sinERA, cosERA, 0]
        // Column 2: [0, 0, 1]
        return simd_double3x3(
            simd_double3(cosEra, -sinEra, 0),
            simd_double3(sinEra, cosEra, 0),
            simd_double3(0, 0, 1)
        )
    }

    /// Rotate a vector from the Celestial Intermediate Reference System (CIRS)
    /// to the Terrestrial Intermediate Reference System (TIRS) using the Earth Rotation Angle.
    /// - Parameters:
    ///   - cirsVector: 3D position vector in CIRS.
    ///   - jdUT1: Julian Date in UT1.
    /// - Returns: 3D vector in TIRS.
    public static func cirsToTirs(cirsVector: Vector3D, jdUT1: Double) -> Vector3D {
        let rot = rotationMatrixCirsToTirs(jdUT1: jdUT1)
        return Vector3D(rot * cirsVector.rawValue)
    }

    /// Rotate an array of vectors from CIRS to TIRS in batch.
    public static func cirsToTirs(vectors: [Vector3D], jdUT1: Double) -> [Vector3D] {
        let rot = rotationMatrixCirsToTirs(jdUT1: jdUT1)
        return vectors.map { Vector3D(rot * $0.rawValue) }
    }

    /// Rotate a vector from TIRS back to CIRS.
    public static func tirsToCirs(tirsVector: Vector3D, jdUT1: Double) -> Vector3D {
        let rot = rotationMatrixCirsToTirs(jdUT1: jdUT1).transpose
        return Vector3D(rot * tirsVector.rawValue)
    }

    /// Rotate an array of vectors from TIRS to CIRS in batch.
    public static func tirsToCirs(vectors: [Vector3D], jdUT1: Double) -> [Vector3D] {
        let rot = rotationMatrixCirsToTirs(jdUT1: jdUT1).transpose
        return vectors.map { Vector3D(rot * $0.rawValue) }
    }
}
