//
//  PlanetaryEngines.swift
//  AstronomyKit
//
//  Pure Swift implementations of planetary ephemeris theories (VSOP87 and Meeus).
//

import Foundation

public typealias CAAPlanet = KPCAAPlanet
public typealias CAAPlanetStrict = KPCAAPlanetStrict

// MARK: - CAAEarth

public enum CAAEarth: Sendable {

    @inlinable
    public static func eccentricity(_ jd: Double) -> Double {
        let t = (jd - 2451545.0) / 36525.0
        let t2 = t * t
        return 1.0 - (0.002516 * t) - (0.0000074 * t2)
    }

    @inlinable
    public static func Eccentricity(_ jd: Double) -> Double {
        eccentricity(jd)
    }

    @inlinable
    public static func sunMeanAnomaly(_ jd: Double) -> Double {
        let t = (jd - 2451545.0) / 36525.0
        let t2 = t * t
        let t3 = t2 * t
        return CAACoordinateTransformation.mapTo0To360Range(357.5291092 + (35999.0502909 * t) - (0.0001536 * t2) + (t3 / 24490000.0))
    }

    @inlinable
    public static func SunMeanAnomaly(_ jd: Double) -> Double {
        sunMeanAnomaly(jd)
    }

    public static func eclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            let rad = CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Earth.g_VSOP87D_L0_EARTH,
                VSOP87Tables_Earth.g_VSOP87D_L1_EARTH,
                VSOP87Tables_Earth.g_VSOP87D_L2_EARTH,
                VSOP87Tables_Earth.g_VSOP87D_L3_EARTH,
                VSOP87Tables_Earth.g_VSOP87D_L4_EARTH,
                VSOP87Tables_Earth.g_VSOP87D_L5_EARTH
            ], isAngle: true)
            return CAACoordinateTransformation.mapTo0To360Range(CAACoordinateTransformation.radiansToDegrees(rad))
        } else {
            let val = CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Earth.g_L0EarthCoefficients,
                VSOP87Tables_Earth.g_L1EarthCoefficients,
                VSOP87Tables_Earth.g_L2EarthCoefficients,
                VSOP87Tables_Earth.g_L3EarthCoefficients,
                VSOP87Tables_Earth.g_L4EarthCoefficients,
                VSOP87Tables_Earth.g_L5EarthCoefficients
            ])
            return CAACoordinateTransformation.mapTo0To360Range(CAACoordinateTransformation.radiansToDegrees(val))
        }
    }

    @inlinable
    public static func EclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        eclipticLongitude(jd, bHighPrecision)
    }

    public static func eclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            let rad = CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Earth.g_VSOP87D_B0_EARTH,
                VSOP87Tables_Earth.g_VSOP87D_B1_EARTH,
                VSOP87Tables_Earth.g_VSOP87D_B2_EARTH,
                VSOP87Tables_Earth.g_VSOP87D_B3_EARTH,
                VSOP87Tables_Earth.g_VSOP87D_B4_EARTH
            ], isAngle: true)
            var deg = CAACoordinateTransformation.radiansToDegrees(rad)
            if deg > 180.0 { deg -= 360.0 }
            return CAACoordinateTransformation.mapToMinus90To90Range(deg)
        } else {
            let val = CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Earth.g_B0EarthCoefficients,
                VSOP87Tables_Earth.g_B1EarthCoefficients
            ])
            return CAACoordinateTransformation.mapToMinus90To90Range(CAACoordinateTransformation.radiansToDegrees(val))
        }
    }

    @inlinable
    public static func EclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        eclipticLatitude(jd, bHighPrecision)
    }

    public static func radiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            return CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Earth.g_VSOP87D_R0_EARTH,
                VSOP87Tables_Earth.g_VSOP87D_R1_EARTH,
                VSOP87Tables_Earth.g_VSOP87D_R2_EARTH,
                VSOP87Tables_Earth.g_VSOP87D_R3_EARTH,
                VSOP87Tables_Earth.g_VSOP87D_R4_EARTH,
                VSOP87Tables_Earth.g_VSOP87D_R5_EARTH
            ], isAngle: false)
        } else {
            return CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Earth.g_R0EarthCoefficients,
                VSOP87Tables_Earth.g_R1EarthCoefficients,
                VSOP87Tables_Earth.g_R2EarthCoefficients,
                VSOP87Tables_Earth.g_R3EarthCoefficients,
                VSOP87Tables_Earth.g_R4EarthCoefficients
            ])
        }
    }

    @inlinable
    public static func RadiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        radiusVector(jd, bHighPrecision)
    }

    public static func eclipticLongitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            let rad = CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Earth.g_VSOP87B_L0_EARTH,
                VSOP87Tables_Earth.g_VSOP87B_L1_EARTH,
                VSOP87Tables_Earth.g_VSOP87B_L2_EARTH,
                VSOP87Tables_Earth.g_VSOP87B_L3_EARTH,
                VSOP87Tables_Earth.g_VSOP87B_L4_EARTH,
                VSOP87Tables_Earth.g_VSOP87B_L5_EARTH
            ], isAngle: true)
            return CAACoordinateTransformation.mapTo0To360Range(CAACoordinateTransformation.radiansToDegrees(rad))
        } else {
            let val = CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Earth.g_L0EarthCoefficients,
                VSOP87Tables_Earth.g_L1EarthCoefficientsJ2000,
                VSOP87Tables_Earth.g_L2EarthCoefficientsJ2000,
                VSOP87Tables_Earth.g_L3EarthCoefficientsJ2000,
                VSOP87Tables_Earth.g_L4EarthCoefficientsJ2000
            ])
            return CAACoordinateTransformation.mapTo0To360Range(CAACoordinateTransformation.radiansToDegrees(val))
        }
    }

    @inlinable
    public static func EclipticLongitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        eclipticLongitudeJ2000(jd, bHighPrecision)
    }

    public static func eclipticLatitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            let rad = CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Earth.g_VSOP87B_B0_EARTH,
                VSOP87Tables_Earth.g_VSOP87B_B1_EARTH,
                VSOP87Tables_Earth.g_VSOP87B_B2_EARTH,
                VSOP87Tables_Earth.g_VSOP87B_B3_EARTH,
                VSOP87Tables_Earth.g_VSOP87B_B4_EARTH,
                VSOP87Tables_Earth.g_VSOP87B_B5_EARTH
            ], isAngle: true)
            var deg = CAACoordinateTransformation.radiansToDegrees(rad)
            if deg > 180.0 { deg -= 360.0 }
            return CAACoordinateTransformation.mapToMinus90To90Range(deg)
        } else {
            let val = CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Earth.g_B0EarthCoefficients,
                VSOP87Tables_Earth.g_B1EarthCoefficientsJ2000,
                VSOP87Tables_Earth.g_B2EarthCoefficientsJ2000,
                VSOP87Tables_Earth.g_B3EarthCoefficientsJ2000,
                VSOP87Tables_Earth.g_B4EarthCoefficientsJ2000
            ])
            return CAACoordinateTransformation.mapToMinus90To90Range(CAACoordinateTransformation.radiansToDegrees(val))
        }
    }

    @inlinable
    public static func EclipticLatitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        eclipticLatitudeJ2000(jd, bHighPrecision)
    }
}

// MARK: - CAAMercury

public enum CAAMercury: Sendable {

    public static func eclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            let rad = CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Mercury.g_VSOP87D_L0_MERCURY, VSOP87Tables_Mercury.g_VSOP87D_L1_MERCURY, VSOP87Tables_Mercury.g_VSOP87D_L2_MERCURY, VSOP87Tables_Mercury.g_VSOP87D_L3_MERCURY, VSOP87Tables_Mercury.g_VSOP87D_L4_MERCURY, VSOP87Tables_Mercury.g_VSOP87D_L5_MERCURY
            ], isAngle: true)
            return CAACoordinateTransformation.mapTo0To360Range(CAACoordinateTransformation.radiansToDegrees(rad))
        } else {
            let val = CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Mercury.g_L0MercuryCoefficients, VSOP87Tables_Mercury.g_L1MercuryCoefficients, VSOP87Tables_Mercury.g_L2MercuryCoefficients, VSOP87Tables_Mercury.g_L3MercuryCoefficients, VSOP87Tables_Mercury.g_L4MercuryCoefficients, VSOP87Tables_Mercury.g_L5MercuryCoefficients
            ])
            return CAACoordinateTransformation.mapTo0To360Range(CAACoordinateTransformation.radiansToDegrees(val))
        }
    }

    @inlinable
    public static func EclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        eclipticLongitude(jd, bHighPrecision)
    }

    public static func eclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            let rad = CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Mercury.g_VSOP87D_B0_MERCURY, VSOP87Tables_Mercury.g_VSOP87D_B1_MERCURY, VSOP87Tables_Mercury.g_VSOP87D_B2_MERCURY, VSOP87Tables_Mercury.g_VSOP87D_B3_MERCURY, VSOP87Tables_Mercury.g_VSOP87D_B4_MERCURY, VSOP87Tables_Mercury.g_VSOP87D_B5_MERCURY
            ], isAngle: true)
            var deg = CAACoordinateTransformation.radiansToDegrees(rad)
            if deg > 180.0 { deg -= 360.0 }
            return CAACoordinateTransformation.mapToMinus90To90Range(deg)
        } else {
            let val = CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Mercury.g_B0MercuryCoefficients, VSOP87Tables_Mercury.g_B1MercuryCoefficients, VSOP87Tables_Mercury.g_B2MercuryCoefficients, VSOP87Tables_Mercury.g_B3MercuryCoefficients
            ])
            return CAACoordinateTransformation.mapToMinus90To90Range(CAACoordinateTransformation.radiansToDegrees(val))
        }
    }

    @inlinable
    public static func EclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        eclipticLatitude(jd, bHighPrecision)
    }

    public static func radiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            return CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Mercury.g_VSOP87D_R0_MERCURY, VSOP87Tables_Mercury.g_VSOP87D_R1_MERCURY, VSOP87Tables_Mercury.g_VSOP87D_R2_MERCURY, VSOP87Tables_Mercury.g_VSOP87D_R3_MERCURY, VSOP87Tables_Mercury.g_VSOP87D_R4_MERCURY, VSOP87Tables_Mercury.g_VSOP87D_R5_MERCURY
            ], isAngle: false)
        } else {
            return CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Mercury.g_R0MercuryCoefficients, VSOP87Tables_Mercury.g_R1MercuryCoefficients, VSOP87Tables_Mercury.g_R2MercuryCoefficients, VSOP87Tables_Mercury.g_R3MercuryCoefficients
            ])
        }
    }

    @inlinable
    public static func RadiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        radiusVector(jd, bHighPrecision)
    }
}

// MARK: - CAAVenus

public enum CAAVenus: Sendable {

    public static func eclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            let rad = CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Venus.g_VSOP87D_L0_VENUS, VSOP87Tables_Venus.g_VSOP87D_L1_VENUS, VSOP87Tables_Venus.g_VSOP87D_L2_VENUS, VSOP87Tables_Venus.g_VSOP87D_L3_VENUS, VSOP87Tables_Venus.g_VSOP87D_L4_VENUS, VSOP87Tables_Venus.g_VSOP87D_L5_VENUS
            ], isAngle: true)
            return CAACoordinateTransformation.mapTo0To360Range(CAACoordinateTransformation.radiansToDegrees(rad))
        } else {
            let val = CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Venus.g_L0VenusCoefficients, VSOP87Tables_Venus.g_L1VenusCoefficients, VSOP87Tables_Venus.g_L2VenusCoefficients, VSOP87Tables_Venus.g_L3VenusCoefficients, VSOP87Tables_Venus.g_L4VenusCoefficients, VSOP87Tables_Venus.g_L5VenusCoefficients
            ])
            return CAACoordinateTransformation.mapTo0To360Range(CAACoordinateTransformation.radiansToDegrees(val))
        }
    }

    @inlinable
    public static func EclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        eclipticLongitude(jd, bHighPrecision)
    }

    public static func eclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            let rad = CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Venus.g_VSOP87D_B0_VENUS, VSOP87Tables_Venus.g_VSOP87D_B1_VENUS, VSOP87Tables_Venus.g_VSOP87D_B2_VENUS, VSOP87Tables_Venus.g_VSOP87D_B3_VENUS, VSOP87Tables_Venus.g_VSOP87D_B4_VENUS, VSOP87Tables_Venus.g_VSOP87D_B5_VENUS
            ], isAngle: true)
            var deg = CAACoordinateTransformation.radiansToDegrees(rad)
            if deg > 180.0 { deg -= 360.0 }
            return CAACoordinateTransformation.mapToMinus90To90Range(deg)
        } else {
            let val = CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Venus.g_B0VenusCoefficients, VSOP87Tables_Venus.g_B1VenusCoefficients, VSOP87Tables_Venus.g_B2VenusCoefficients, VSOP87Tables_Venus.g_B3VenusCoefficients, VSOP87Tables_Venus.g_B4VenusCoefficients
            ])
            return CAACoordinateTransformation.mapToMinus90To90Range(CAACoordinateTransformation.radiansToDegrees(val))
        }
    }

    @inlinable
    public static func EclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        eclipticLatitude(jd, bHighPrecision)
    }

    public static func radiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            return CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Venus.g_VSOP87D_R0_VENUS, VSOP87Tables_Venus.g_VSOP87D_R1_VENUS, VSOP87Tables_Venus.g_VSOP87D_R2_VENUS, VSOP87Tables_Venus.g_VSOP87D_R3_VENUS, VSOP87Tables_Venus.g_VSOP87D_R4_VENUS, VSOP87Tables_Venus.g_VSOP87D_R5_VENUS
            ], isAngle: false)
        } else {
            return CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Venus.g_R0VenusCoefficients, VSOP87Tables_Venus.g_R1VenusCoefficients, VSOP87Tables_Venus.g_R2VenusCoefficients, VSOP87Tables_Venus.g_R3VenusCoefficients, VSOP87Tables_Venus.g_R4VenusCoefficients
            ])
        }
    }

    @inlinable
    public static func RadiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        radiusVector(jd, bHighPrecision)
    }
}

// MARK: - CAAMars

public enum CAAMars: Sendable {

    public static func eclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            let rad = CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Mars.g_VSOP87D_L0_MARS, VSOP87Tables_Mars.g_VSOP87D_L1_MARS, VSOP87Tables_Mars.g_VSOP87D_L2_MARS, VSOP87Tables_Mars.g_VSOP87D_L3_MARS, VSOP87Tables_Mars.g_VSOP87D_L4_MARS, VSOP87Tables_Mars.g_VSOP87D_L5_MARS
            ], isAngle: true)
            return CAACoordinateTransformation.mapTo0To360Range(CAACoordinateTransformation.radiansToDegrees(rad))
        } else {
            let val = CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Mars.g_L0MarsCoefficients, VSOP87Tables_Mars.g_L1MarsCoefficients, VSOP87Tables_Mars.g_L2MarsCoefficients, VSOP87Tables_Mars.g_L3MarsCoefficients, VSOP87Tables_Mars.g_L4MarsCoefficients, VSOP87Tables_Mars.g_L5MarsCoefficients
            ])
            return CAACoordinateTransformation.mapTo0To360Range(CAACoordinateTransformation.radiansToDegrees(val))
        }
    }

    @inlinable
    public static func EclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        eclipticLongitude(jd, bHighPrecision)
    }

    public static func eclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            let rad = CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Mars.g_VSOP87D_B0_MARS, VSOP87Tables_Mars.g_VSOP87D_B1_MARS, VSOP87Tables_Mars.g_VSOP87D_B2_MARS, VSOP87Tables_Mars.g_VSOP87D_B3_MARS, VSOP87Tables_Mars.g_VSOP87D_B4_MARS, VSOP87Tables_Mars.g_VSOP87D_B5_MARS
            ], isAngle: true)
            var deg = CAACoordinateTransformation.radiansToDegrees(rad)
            if deg > 180.0 { deg -= 360.0 }
            return CAACoordinateTransformation.mapToMinus90To90Range(deg)
        } else {
            let val = CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Mars.g_B0MarsCoefficients, VSOP87Tables_Mars.g_B1MarsCoefficients, VSOP87Tables_Mars.g_B2MarsCoefficients, VSOP87Tables_Mars.g_B3MarsCoefficients, VSOP87Tables_Mars.g_B4MarsCoefficients
            ])
            return CAACoordinateTransformation.mapToMinus90To90Range(CAACoordinateTransformation.radiansToDegrees(val))
        }
    }

    @inlinable
    public static func EclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        eclipticLatitude(jd, bHighPrecision)
    }

    public static func radiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            return CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Mars.g_VSOP87D_R0_MARS, VSOP87Tables_Mars.g_VSOP87D_R1_MARS, VSOP87Tables_Mars.g_VSOP87D_R2_MARS, VSOP87Tables_Mars.g_VSOP87D_R3_MARS, VSOP87Tables_Mars.g_VSOP87D_R4_MARS, VSOP87Tables_Mars.g_VSOP87D_R5_MARS
            ], isAngle: false)
        } else {
            return CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Mars.g_R0MarsCoefficients, VSOP87Tables_Mars.g_R1MarsCoefficients, VSOP87Tables_Mars.g_R2MarsCoefficients, VSOP87Tables_Mars.g_R3MarsCoefficients, VSOP87Tables_Mars.g_R4MarsCoefficients
            ])
        }
    }

    @inlinable
    public static func RadiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        radiusVector(jd, bHighPrecision)
    }
}

// MARK: - CAAJupiter

public enum CAAJupiter: Sendable {

    public static func eclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            let rad = CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Jupiter.g_VSOP87D_L0_JUPITER, VSOP87Tables_Jupiter.g_VSOP87D_L1_JUPITER, VSOP87Tables_Jupiter.g_VSOP87D_L2_JUPITER, VSOP87Tables_Jupiter.g_VSOP87D_L3_JUPITER, VSOP87Tables_Jupiter.g_VSOP87D_L4_JUPITER, VSOP87Tables_Jupiter.g_VSOP87D_L5_JUPITER
            ], isAngle: true)
            return CAACoordinateTransformation.mapTo0To360Range(CAACoordinateTransformation.radiansToDegrees(rad))
        } else {
            let val = CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Jupiter.g_L0JupiterCoefficients, VSOP87Tables_Jupiter.g_L1JupiterCoefficients, VSOP87Tables_Jupiter.g_L2JupiterCoefficients, VSOP87Tables_Jupiter.g_L3JupiterCoefficients, VSOP87Tables_Jupiter.g_L4JupiterCoefficients, VSOP87Tables_Jupiter.g_L5JupiterCoefficients
            ])
            return CAACoordinateTransformation.mapTo0To360Range(CAACoordinateTransformation.radiansToDegrees(val))
        }
    }

    @inlinable
    public static func EclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        eclipticLongitude(jd, bHighPrecision)
    }

    public static func eclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            let rad = CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Jupiter.g_VSOP87D_B0_JUPITER, VSOP87Tables_Jupiter.g_VSOP87D_B1_JUPITER, VSOP87Tables_Jupiter.g_VSOP87D_B2_JUPITER, VSOP87Tables_Jupiter.g_VSOP87D_B3_JUPITER, VSOP87Tables_Jupiter.g_VSOP87D_B4_JUPITER, VSOP87Tables_Jupiter.g_VSOP87D_B5_JUPITER
            ], isAngle: true)
            var deg = CAACoordinateTransformation.radiansToDegrees(rad)
            if deg > 180.0 { deg -= 360.0 }
            return CAACoordinateTransformation.mapToMinus90To90Range(deg)
        } else {
            let val = CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Jupiter.g_B0JupiterCoefficients, VSOP87Tables_Jupiter.g_B1JupiterCoefficients, VSOP87Tables_Jupiter.g_B2JupiterCoefficients, VSOP87Tables_Jupiter.g_B3JupiterCoefficients, VSOP87Tables_Jupiter.g_B4JupiterCoefficients, VSOP87Tables_Jupiter.g_B5JupiterCoefficients
            ])
            return CAACoordinateTransformation.mapToMinus90To90Range(CAACoordinateTransformation.radiansToDegrees(val))
        }
    }

    @inlinable
    public static func EclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        eclipticLatitude(jd, bHighPrecision)
    }

    public static func radiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            return CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Jupiter.g_VSOP87D_R0_JUPITER, VSOP87Tables_Jupiter.g_VSOP87D_R1_JUPITER, VSOP87Tables_Jupiter.g_VSOP87D_R2_JUPITER, VSOP87Tables_Jupiter.g_VSOP87D_R3_JUPITER, VSOP87Tables_Jupiter.g_VSOP87D_R4_JUPITER, VSOP87Tables_Jupiter.g_VSOP87D_R5_JUPITER
            ], isAngle: false)
        } else {
            return CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Jupiter.g_R0JupiterCoefficients, VSOP87Tables_Jupiter.g_R1JupiterCoefficients, VSOP87Tables_Jupiter.g_R2JupiterCoefficients, VSOP87Tables_Jupiter.g_R3JupiterCoefficients, VSOP87Tables_Jupiter.g_R4JupiterCoefficients, VSOP87Tables_Jupiter.g_R5JupiterCoefficients
            ])
        }
    }

    @inlinable
    public static func RadiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        radiusVector(jd, bHighPrecision)
    }
}

// MARK: - CAASaturn

public enum CAASaturn: Sendable {

    public static func eclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            let rad = CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Saturn.g_VSOP87D_L0_SATURN, VSOP87Tables_Saturn.g_VSOP87D_L1_SATURN, VSOP87Tables_Saturn.g_VSOP87D_L2_SATURN, VSOP87Tables_Saturn.g_VSOP87D_L3_SATURN, VSOP87Tables_Saturn.g_VSOP87D_L4_SATURN, VSOP87Tables_Saturn.g_VSOP87D_L5_SATURN
            ], isAngle: true)
            return CAACoordinateTransformation.mapTo0To360Range(CAACoordinateTransformation.radiansToDegrees(rad))
        } else {
            let val = CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Saturn.g_L0SaturnCoefficients, VSOP87Tables_Saturn.g_L1SaturnCoefficients, VSOP87Tables_Saturn.g_L2SaturnCoefficients, VSOP87Tables_Saturn.g_L3SaturnCoefficients, VSOP87Tables_Saturn.g_L4SaturnCoefficients, VSOP87Tables_Saturn.g_L5SaturnCoefficients
            ])
            return CAACoordinateTransformation.mapTo0To360Range(CAACoordinateTransformation.radiansToDegrees(val))
        }
    }

    @inlinable
    public static func EclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        eclipticLongitude(jd, bHighPrecision)
    }

    public static func eclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            let rad = CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Saturn.g_VSOP87D_B0_SATURN, VSOP87Tables_Saturn.g_VSOP87D_B1_SATURN, VSOP87Tables_Saturn.g_VSOP87D_B2_SATURN, VSOP87Tables_Saturn.g_VSOP87D_B3_SATURN, VSOP87Tables_Saturn.g_VSOP87D_B4_SATURN, VSOP87Tables_Saturn.g_VSOP87D_B5_SATURN
            ], isAngle: true)
            var deg = CAACoordinateTransformation.radiansToDegrees(rad)
            if deg > 180.0 { deg -= 360.0 }
            return CAACoordinateTransformation.mapToMinus90To90Range(deg)
        } else {
            let val = CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Saturn.g_B0SaturnCoefficients, VSOP87Tables_Saturn.g_B1SaturnCoefficients, VSOP87Tables_Saturn.g_B2SaturnCoefficients, VSOP87Tables_Saturn.g_B3SaturnCoefficients, VSOP87Tables_Saturn.g_B4SaturnCoefficients, VSOP87Tables_Saturn.g_B5SaturnCoefficients
            ])
            return CAACoordinateTransformation.mapToMinus90To90Range(CAACoordinateTransformation.radiansToDegrees(val))
        }
    }

    @inlinable
    public static func EclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        eclipticLatitude(jd, bHighPrecision)
    }

    public static func radiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            return CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Saturn.g_VSOP87D_R0_SATURN, VSOP87Tables_Saturn.g_VSOP87D_R1_SATURN, VSOP87Tables_Saturn.g_VSOP87D_R2_SATURN, VSOP87Tables_Saturn.g_VSOP87D_R3_SATURN, VSOP87Tables_Saturn.g_VSOP87D_R4_SATURN, VSOP87Tables_Saturn.g_VSOP87D_R5_SATURN
            ], isAngle: false)
        } else {
            return CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Saturn.g_R0SaturnCoefficients, VSOP87Tables_Saturn.g_R1SaturnCoefficients, VSOP87Tables_Saturn.g_R2SaturnCoefficients, VSOP87Tables_Saturn.g_R3SaturnCoefficients, VSOP87Tables_Saturn.g_R4SaturnCoefficients, VSOP87Tables_Saturn.g_R5SaturnCoefficients
            ])
        }
    }

    @inlinable
    public static func RadiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        radiusVector(jd, bHighPrecision)
    }
}

// MARK: - CAAUranus

public enum CAAUranus: Sendable {

    public static func eclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            let rad = CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Uranus.g_VSOP87D_L0_URANUS, VSOP87Tables_Uranus.g_VSOP87D_L1_URANUS, VSOP87Tables_Uranus.g_VSOP87D_L2_URANUS, VSOP87Tables_Uranus.g_VSOP87D_L3_URANUS, VSOP87Tables_Uranus.g_VSOP87D_L4_URANUS, VSOP87Tables_Uranus.g_VSOP87D_L5_URANUS
            ], isAngle: true)
            return CAACoordinateTransformation.mapTo0To360Range(CAACoordinateTransformation.radiansToDegrees(rad))
        } else {
            let val = CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Uranus.g_L0UranusCoefficients, VSOP87Tables_Uranus.g_L1UranusCoefficients, VSOP87Tables_Uranus.g_L2UranusCoefficients, VSOP87Tables_Uranus.g_L3UranusCoefficients, VSOP87Tables_Uranus.g_L4UranusCoefficients
            ])
            return CAACoordinateTransformation.mapTo0To360Range(CAACoordinateTransformation.radiansToDegrees(val))
        }
    }

    @inlinable
    public static func EclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        eclipticLongitude(jd, bHighPrecision)
    }

    public static func eclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            let rad = CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Uranus.g_VSOP87D_B0_URANUS, VSOP87Tables_Uranus.g_VSOP87D_B1_URANUS, VSOP87Tables_Uranus.g_VSOP87D_B2_URANUS, VSOP87Tables_Uranus.g_VSOP87D_B3_URANUS, VSOP87Tables_Uranus.g_VSOP87D_B4_URANUS
            ], isAngle: true)
            var deg = CAACoordinateTransformation.radiansToDegrees(rad)
            if deg > 180.0 { deg -= 360.0 }
            return CAACoordinateTransformation.mapToMinus90To90Range(deg)
        } else {
            let val = CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Uranus.g_B0UranusCoefficients, VSOP87Tables_Uranus.g_B1UranusCoefficients, VSOP87Tables_Uranus.g_B2UranusCoefficients, VSOP87Tables_Uranus.g_B3UranusCoefficients
            ])
            return CAACoordinateTransformation.mapToMinus90To90Range(CAACoordinateTransformation.radiansToDegrees(val))
        }
    }

    @inlinable
    public static func EclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        eclipticLatitude(jd, bHighPrecision)
    }

    public static func radiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            return CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Uranus.g_VSOP87D_R0_URANUS, VSOP87Tables_Uranus.g_VSOP87D_R1_URANUS, VSOP87Tables_Uranus.g_VSOP87D_R2_URANUS, VSOP87Tables_Uranus.g_VSOP87D_R3_URANUS, VSOP87Tables_Uranus.g_VSOP87D_R4_URANUS
            ], isAngle: false)
        } else {
            return CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Uranus.g_R0UranusCoefficients, VSOP87Tables_Uranus.g_R1UranusCoefficients, VSOP87Tables_Uranus.g_R2UranusCoefficients, VSOP87Tables_Uranus.g_R3UranusCoefficients, VSOP87Tables_Uranus.g_R4UranusCoefficients
            ])
        }
    }

    @inlinable
    public static func RadiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        radiusVector(jd, bHighPrecision)
    }
}

// MARK: - CAANeptune

public enum CAANeptune: Sendable {

    public static func eclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            let rad = CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Neptune.g_VSOP87D_L0_NEPTUNE, VSOP87Tables_Neptune.g_VSOP87D_L1_NEPTUNE, VSOP87Tables_Neptune.g_VSOP87D_L2_NEPTUNE, VSOP87Tables_Neptune.g_VSOP87D_L3_NEPTUNE, VSOP87Tables_Neptune.g_VSOP87D_L4_NEPTUNE, VSOP87Tables_Neptune.g_VSOP87D_L5_NEPTUNE
            ], isAngle: true)
            return CAACoordinateTransformation.mapTo0To360Range(CAACoordinateTransformation.radiansToDegrees(rad))
        } else {
            let val = CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Neptune.g_L0NeptuneCoefficients, VSOP87Tables_Neptune.g_L1NeptuneCoefficients, VSOP87Tables_Neptune.g_L2NeptuneCoefficients, VSOP87Tables_Neptune.g_L3NeptuneCoefficients, VSOP87Tables_Neptune.g_L4NeptuneCoefficients
            ])
            return CAACoordinateTransformation.mapTo0To360Range(CAACoordinateTransformation.radiansToDegrees(val))
        }
    }

    @inlinable
    public static func EclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        eclipticLongitude(jd, bHighPrecision)
    }

    public static func eclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            let rad = CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Neptune.g_VSOP87D_B0_NEPTUNE, VSOP87Tables_Neptune.g_VSOP87D_B1_NEPTUNE, VSOP87Tables_Neptune.g_VSOP87D_B2_NEPTUNE, VSOP87Tables_Neptune.g_VSOP87D_B3_NEPTUNE, VSOP87Tables_Neptune.g_VSOP87D_B4_NEPTUNE, VSOP87Tables_Neptune.g_VSOP87D_B5_NEPTUNE
            ], isAngle: true)
            var deg = CAACoordinateTransformation.radiansToDegrees(rad)
            if deg > 180.0 { deg -= 360.0 }
            return CAACoordinateTransformation.mapToMinus90To90Range(deg)
        } else {
            let val = CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Neptune.g_B0NeptuneCoefficients, VSOP87Tables_Neptune.g_B1NeptuneCoefficients, VSOP87Tables_Neptune.g_B2NeptuneCoefficients, VSOP87Tables_Neptune.g_B3NeptuneCoefficients
            ])
            return CAACoordinateTransformation.mapToMinus90To90Range(CAACoordinateTransformation.radiansToDegrees(val))
        }
    }

    @inlinable
    public static func EclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        eclipticLatitude(jd, bHighPrecision)
    }

    public static func radiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        if bHighPrecision {
            return CAAVSOP87.calculate(jd: jd, tables: [
                VSOP87Tables_Neptune.g_VSOP87D_R0_NEPTUNE, VSOP87Tables_Neptune.g_VSOP87D_R1_NEPTUNE, VSOP87Tables_Neptune.g_VSOP87D_R2_NEPTUNE, VSOP87Tables_Neptune.g_VSOP87D_R3_NEPTUNE, VSOP87Tables_Neptune.g_VSOP87D_R4_NEPTUNE
            ], isAngle: false)
        } else {
            return CAAVSOP87.calculateTruncated(jd: jd, tables: [
                VSOP87Tables_Neptune.g_R0NeptuneCoefficients, VSOP87Tables_Neptune.g_R1NeptuneCoefficients, VSOP87Tables_Neptune.g_R2NeptuneCoefficients, VSOP87Tables_Neptune.g_R3NeptuneCoefficients
            ])
        }
    }

    @inlinable
    public static func RadiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        radiusVector(jd, bHighPrecision)
    }
}

// MARK: - CAAPluto

public enum CAAPluto: Sendable {

    private static let arguments: [(j: Double, s: Double, p: Double)] = [
        (0, 0, 1), (0, 0, 2), (0, 0, 3), (0, 0, 4), (0, 0, 5), (0, 0, 6),
        (0, 1, -1), (0, 1, 0), (0, 1, 1), (0, 1, 2), (0, 1, 3),
        (0, 2, -2), (0, 2, -1), (0, 2, 0),
        (1, -1, 0), (1, -1, 1),
        (1, 0, -3), (1, 0, -2), (1, 0, -1), (1, 0, 0), (1, 0, 1), (1, 0, 2), (1, 0, 3), (1, 0, 4),
        (1, 1, -3), (1, 1, -2), (1, 1, -1), (1, 1, 0), (1, 1, 1), (1, 1, 3),
        (2, 0, -6), (2, 0, -5), (2, 0, -4), (2, 0, -3), (2, 0, -2), (2, 0, -1), (2, 0, 0), (2, 0, 1), (2, 0, 2), (2, 0, 3),
        (3, 0, -2), (3, 0, -1), (3, 0, 0)
    ]

    private static let longitudeCoeffs: [(a: Double, b: Double)] = [
        (-19799805, 19850055), (897144, -4954829), (611149, 1211027), (-341243, -189585),
        (129287, -34992), (-38164, 30893), (20442, -9987), (-4063, -5071), (-6016, -3336),
        (-3956, 3039), (-667, 3572), (1276, 501), (1152, -917), (630, -1277), (2571, -459),
        (899, -1449), (-1016, 1043), (-2343, -1012), (7042, 788), (1199, -338), (418, -67),
        (120, -274), (-60, -159), (-82, -29), (-36, -29), (-40, 7), (-14, 22), (4, 13),
        (5, 2), (-1, 0), (2, 0), (-4, 5), (4, -7), (14, 24), (-49, -34), (163, -48),
        (9, -24), (-4, 1), (-3, 1), (1, 3), (-3, -1), (5, -3), (0, 0)
    ]

    private static let latitudeCoeffs: [(a: Double, b: Double)] = [
        (-5452852, -14974862), (3527812, 1672790), (-1050748, 327647), (178690, -292153),
        (18650, 100340), (-30697, -25823), (4878, 11248), (226, -64), (2030, -836),
        (69, -604), (-247, -567), (-57, 1), (-122, 175), (-49, -164), (-197, 199),
        (-25, 217), (589, -248), (-269, 711), (185, 193), (315, 807), (-130, -43),
        (5, 3), (2, 17), (2, 5), (2, 3), (7, 0), (4, -5), (1, -3), (0, -2), (0, 1),
        (1, 0), (0, -3), (-2, -1), (-3, 3), (2, 1), (2, -4), (0, 7), (1, 0), (0, -1),
        (0, 0), (-1, 0), (1, 0), (0, 0)
    ]

    private static let radiusCoeffs: [(a: Double, b: Double)] = [
        (6686546, 689329), (-1182759, -304240), (159310, -204104), (-19134, 40164),
        (-4415, -9624), (3240, 142), (-110, 693), (-2598, -141), (-517, 344),
        (399, 40), (105, -341), (-498, 111), (-176, -117), (103, -188), (-235, -23),
        (-140, 104), (-33, 44), (73, -107), (50, 48), (47, 4), (11, -3),
        (-19, 9), (0, 2), (9, 2), (-3, 4), (-3, -3), (4, -3), (0, 2), (2, 0),
        (-1, 0), (0, -1), (5, 6), (3, 1), (6, -2), (2, 2), (-2, -2), (14, 13),
        (-63, 13), (136, -236), (273, 1065), (251, 149), (-25, -9), (9, -2),
        (-8, 7), (2, -10), (19, 35), (10, 3)
    ]

    public static func eclipticLongitude(_ jd: Double) -> Double {
        let t = (jd - 2451545.0) / 36525.0
        let j = 34.35 + 3034.9057 * t
        let s = 50.08 + 1222.1138 * t
        let p = 238.96 + 144.9600 * t

        var l = 0.0
        for i in 0..<arguments.count {
            let alpha = CAACoordinateTransformation.degreesToRadians(arguments[i].j * j + arguments[i].s * s + arguments[i].p * p)
            l += longitudeCoeffs[i].a * sin(alpha) + longitudeCoeffs[i].b * cos(alpha)
        }
        l = l / 1_000_000.0
        l += 238.958116 + 144.96 * t
        return CAACoordinateTransformation.mapTo0To360Range(l)
    }

    @inlinable
    public static func EclipticLongitude(_ jd: Double) -> Double {
        eclipticLongitude(jd)
    }

    public static func eclipticLatitude(_ jd: Double) -> Double {
        let t = (jd - 2451545.0) / 36525.0
        let j = 34.35 + 3034.9057 * t
        let s = 50.08 + 1222.1138 * t
        let p = 238.96 + 144.9600 * t

        var b = 0.0
        for i in 0..<arguments.count {
            let alpha = CAACoordinateTransformation.degreesToRadians(arguments[i].j * j + arguments[i].s * s + arguments[i].p * p)
            b += latitudeCoeffs[i].a * sin(alpha) + latitudeCoeffs[i].b * cos(alpha)
        }
        b = b / 1_000_000.0 - 3.908239
        return CAACoordinateTransformation.mapToMinus90To90Range(b)
    }

    @inlinable
    public static func EclipticLatitude(_ jd: Double) -> Double {
        eclipticLatitude(jd)
    }

    public static func radiusVector(_ jd: Double) -> Double {
        let t = (jd - 2451545.0) / 36525.0
        let j = 34.35 + 3034.9057 * t
        let s = 50.08 + 1222.1138 * t
        let p = 238.96 + 144.9600 * t

        var r = 0.0
        for i in 0..<arguments.count {
            let alpha = CAACoordinateTransformation.degreesToRadians(arguments[i].j * j + arguments[i].s * s + arguments[i].p * p)
            r += radiusCoeffs[i].a * sin(alpha) + radiusCoeffs[i].b * cos(alpha)
        }
        r = r / 10_000_000.0 + 40.7241346
        return r
    }

    @inlinable
    public static func RadiusVector(_ jd: Double) -> Double {
        radiusVector(jd)
    }
}
