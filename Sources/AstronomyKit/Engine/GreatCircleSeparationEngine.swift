//
//  GreatCircleSeparationEngine.swift
//  AstronomyKit
//
//  Pure Swift angular separation and position angle on the celestial sphere.
//  Replaces CAAAngularSeparation from AAplus.
//

import Foundation
import simd

public enum GreatCircleSeparationEngine: Sendable {

    @inlinable
    public static func separation(alpha1: Double, delta1: Double, alpha2: Double, delta2: Double) -> Double {
        let d1 = SphericalTrigonometry.degreesToRadians(delta1)
        let d2 = SphericalTrigonometry.degreesToRadians(delta2)
        let a1 = SphericalTrigonometry.hoursToRadians(alpha1)
        let a2 = SphericalTrigonometry.hoursToRadians(alpha2)

        let sinD1 = sin(d1)
        let cosD1 = cos(d1)
        let sinD2 = sin(d2)
        let cosD2 = cos(d2)
        let deltaA = a2 - a1
        let sinDeltaA = sin(deltaA)
        let cosDeltaA = cos(deltaA)

        let cosD2CosDeltaA = cosD2 * cosDeltaA
        let x = (cosD1 * sinD2) - (sinD1 * cosD2CosDeltaA)
        let y = cosD2 * sinDeltaA
        let z = (sinD1 * sinD2) + (cosD1 * cosD2CosDeltaA)

        let normXY = sqrt((x * x) + (y * y))
        var value = SphericalTrigonometry.radiansToDegrees(atan2(normXY, z))
        if value < 0 {
            value += 180.0
        }
        return value
    }

    @inlinable
    public static func positionAngle(alpha1: Double, delta1: Double, alpha2: Double, delta2: Double) -> Double {
        let d1 = SphericalTrigonometry.degreesToRadians(delta1)
        let d2 = SphericalTrigonometry.degreesToRadians(delta2)
        let a1 = SphericalTrigonometry.hoursToRadians(alpha1)
        let a2 = SphericalTrigonometry.hoursToRadians(alpha2)

        let deltaAlpha = a1 - a2
        let sinDeltaAlpha = sin(deltaAlpha)
        let cosDeltaAlpha = cos(deltaAlpha)
        let y = sinDeltaAlpha
        let x = (cos(d2) * tan(d1)) - (sin(d2) * cosDeltaAlpha)

        var value = SphericalTrigonometry.radiansToDegrees(atan2(y, x))
        if value < 0 {
            value += 180.0
        }
        return value
    }

    @inlinable
    public static func distanceFromGreatArc(
        alpha1: Double, delta1: Double,
        alpha2: Double, delta2: Double,
        alpha3: Double, delta3: Double
    ) -> Double {
        let d1 = SphericalTrigonometry.degreesToRadians(delta1)
        let d2 = SphericalTrigonometry.degreesToRadians(delta2)
        let d3 = SphericalTrigonometry.degreesToRadians(delta3)
        let a1 = SphericalTrigonometry.hoursToRadians(alpha1)
        let a2 = SphericalTrigonometry.hoursToRadians(alpha2)
        let a3 = SphericalTrigonometry.hoursToRadians(alpha3)

        let cosD1 = cos(d1)
        let cosD2 = cos(d2)
        let cosD3 = cos(d3)

        let v1 = simd_double3(cosD1 * cos(a1), cosD1 * sin(a1), sin(d1))
        let v2 = simd_double3(cosD2 * cos(a2), cosD2 * sin(a2), sin(d2))
        let v3 = simd_double3(cosD3 * cos(a3), cosD3 * sin(a3), sin(d3))

        let cross = simd_cross(v1, v2)
        let crossLen = simd_length(cross)
        guard crossLen > 0 else { return 0.0 }

        let sinDist = simd_dot(cross, v3) / crossLen
        let clampedSin = max(-1.0, min(1.0, sinDist))
        return abs(SphericalTrigonometry.radiansToDegrees(asin(clampedSin)))
    }
}

// MARK: - Backward-Compatibility Adapter for CAAAngularSeparation

public enum CAAAngularSeparation: Sendable {
    @inlinable public static func Separation(_ Alpha1: Double, _ Delta1: Double, _ Alpha2: Double, _ Delta2: Double) -> Double {
        GreatCircleSeparationEngine.separation(alpha1: Alpha1, delta1: Delta1, alpha2: Alpha2, delta2: Delta2)
    }
    @inlinable public static func PositionAngle(_ Alpha1: Double, _ Delta1: Double, _ Alpha2: Double, _ Delta2: Double) -> Double {
        GreatCircleSeparationEngine.positionAngle(alpha1: Alpha1, delta1: Delta1, alpha2: Alpha2, delta2: Delta2)
    }
    @inlinable public static func DistanceFromGreatArc(_ Alpha1: Double, _ Delta1: Double, _ Alpha2: Double, _ Delta2: Double, _ Alpha3: Double, _ Delta3: Double) -> Double {
        GreatCircleSeparationEngine.distanceFromGreatArc(alpha1: Alpha1, delta1: Delta1, alpha2: Alpha2, delta2: Delta2, alpha3: Alpha3, delta3: Delta3)
    }
}
