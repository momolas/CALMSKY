//
//  GreatCircleSeparationEngine.swift
//  AstronomyKit
//
//  Pure Swift angular separation and position angle on the celestial sphere.
//  Replaces CAAAngularSeparation from AAplus.
//

import Foundation

public enum GreatCircleSeparationEngine: Sendable {

    @inlinable
    public static func separation(alpha1: Double, delta1: Double, alpha2: Double, delta2: Double) -> Double {
        let d1 = SphericalTrigonometry.degreesToRadians(delta1)
        let d2 = SphericalTrigonometry.degreesToRadians(delta2)
        let a1 = SphericalTrigonometry.hoursToRadians(alpha1)
        let a2 = SphericalTrigonometry.hoursToRadians(alpha2)

        let x = (cos(d1) * sin(d2)) - (sin(d1) * cos(d2) * cos(a2 - a1))
        let y = cos(d2) * sin(a2 - a1)
        let z = (sin(d1) * sin(d2)) + (cos(d1) * cos(d2) * cos(a2 - a1))

        var value = SphericalTrigonometry.radiansToDegrees(atan2(sqrt((x * x) + (y * y)), z))
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
        var value = SphericalTrigonometry.radiansToDegrees(atan2(sin(deltaAlpha), (cos(d2) * tan(d1)) - (sin(d2) * cos(deltaAlpha))))
        if value < 0 {
            value += 180.0
        }
        return value
    }

    @inlinable
    public static func distanceFromGreatArc(alpha1: Double, delta1: Double, alpha2: Double, delta2: Double, alpha3: Double, delta3: Double) -> Double {
        let d1 = SphericalTrigonometry.degreesToRadians(delta1)
        let d2 = SphericalTrigonometry.degreesToRadians(delta2)
        let d3 = SphericalTrigonometry.degreesToRadians(delta3)
        let a1 = SphericalTrigonometry.hoursToRadians(alpha1)
        let a2 = SphericalTrigonometry.hoursToRadians(alpha2)
        let a3 = SphericalTrigonometry.hoursToRadians(alpha3)

        let x1 = cos(d1) * cos(a1)
        let x2 = cos(d2) * cos(a2)
        let y1 = cos(d1) * sin(a1)
        let y2 = cos(d2) * sin(a2)
        let z1 = sin(d1)
        let z2 = sin(d2)

        let a = (y1 * z2) - (z1 * y2)
        let b = (z1 * x2) - (x1 * z2)
        let c = (x1 * y2) - (y1 * x2)

        let m = tan(a3)
        let n = tan(d3) / cos(a3)

        var value = SphericalTrigonometry.radiansToDegrees(asin((a + (b * m) + (c * n)) / (sqrt((a * a) + (b * b) + (c * c)) * sqrt(1.0 + (m * m) + (n * n)))))
        if value < 0 {
            value = abs(value)
        }
        return value
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
