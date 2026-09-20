//
//  PrecessionNutationEngine.swift
//  AstronomyKit
//
//  Pure Swift general precession and IAU 1980 / 2000B nutation engine.
//  Replaces AAPrecession and AANutation from AAplus.
//

import Foundation

// MARK: - Nutation Engine (IAU 1980 Wahr Model / Meeus Ch. 22)

private struct NutationCoefficient: Sendable {
    let D: Int
    let M: Int
    let Mprime: Int
    let F: Int
    let omega: Int
    let sincoeff1: Double
    let sincoeff2: Double
    let coscoeff1: Double
    let coscoeff2: Double
}

private let gNutationCoeffs: [NutationCoefficient] = [
    NutationCoefficient(D: 0, M: 0, Mprime: 0, F: 0, omega: 1, sincoeff1: -171996, sincoeff2: -174.2, coscoeff1: 92025, coscoeff2: 8.9),
    NutationCoefficient(D: -2, M: 0, Mprime: 0, F: 2, omega: 2, sincoeff1: -13187, sincoeff2: -1.6, coscoeff1: 5736, coscoeff2: -3.1),
    NutationCoefficient(D: 0, M: 0, Mprime: 0, F: 2, omega: 2, sincoeff1: -2274, sincoeff2: -0.2, coscoeff1: 977, coscoeff2: -0.5),
    NutationCoefficient(D: 0, M: 0, Mprime: 0, F: 0, omega: 2, sincoeff1: 2062, sincoeff2: 0.2, coscoeff1: -895, coscoeff2: 0.5),
    NutationCoefficient(D: 0, M: 1, Mprime: 0, F: 0, omega: 0, sincoeff1: 1426, sincoeff2: -3.4, coscoeff1: 54, coscoeff2: -0.1),
    NutationCoefficient(D: 0, M: 0, Mprime: 1, F: 0, omega: 0, sincoeff1: 712, sincoeff2: 0.1, coscoeff1: -7, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 1, Mprime: 0, F: 2, omega: 2, sincoeff1: -517, sincoeff2: 1.2, coscoeff1: 224, coscoeff2: -0.6),
    NutationCoefficient(D: 0, M: 0, Mprime: 0, F: 2, omega: 1, sincoeff1: -386, sincoeff2: -0.4, coscoeff1: 200, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: 1, F: 2, omega: 2, sincoeff1: -301, sincoeff2: 0, coscoeff1: 129, coscoeff2: -0.1),
    NutationCoefficient(D: -2, M: -1, Mprime: 0, F: 2, omega: 2, sincoeff1: 217, sincoeff2: -0.5, coscoeff1: -95, coscoeff2: 0.3),
    NutationCoefficient(D: -2, M: 0, Mprime: 1, F: 0, omega: 0, sincoeff1: -158, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 0, Mprime: 0, F: 2, omega: 1, sincoeff1: 129, sincoeff2: 0.1, coscoeff1: -70, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: -1, F: 2, omega: 2, sincoeff1: 123, sincoeff2: 0, coscoeff1: -53, coscoeff2: 0),
    NutationCoefficient(D: 2, M: 0, Mprime: 0, F: 0, omega: 0, sincoeff1: 63, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: 1, F: 0, omega: 1, sincoeff1: 63, sincoeff2: 0.1, coscoeff1: -33, coscoeff2: 0),
    NutationCoefficient(D: 2, M: 0, Mprime: -1, F: 2, omega: 2, sincoeff1: -59, sincoeff2: 0, coscoeff1: 26, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: -1, F: 0, omega: 1, sincoeff1: -58, sincoeff2: -0.1, coscoeff1: 32, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: 1, F: 2, omega: 1, sincoeff1: -51, sincoeff2: 0, coscoeff1: 27, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 0, Mprime: 2, F: 0, omega: 0, sincoeff1: 48, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: -2, F: 2, omega: 1, sincoeff1: 46, sincoeff2: 0, coscoeff1: -24, coscoeff2: 0),
    NutationCoefficient(D: 2, M: 0, Mprime: 0, F: 2, omega: 2, sincoeff1: -38, sincoeff2: 0, coscoeff1: 16, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: 2, F: 2, omega: 2, sincoeff1: -31, sincoeff2: 0, coscoeff1: 13, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: 2, F: 0, omega: 0, sincoeff1: 29, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 0, Mprime: 1, F: 2, omega: 2, sincoeff1: 29, sincoeff2: 0, coscoeff1: -12, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: 0, F: 2, omega: 0, sincoeff1: 26, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 0, Mprime: 0, F: 2, omega: 0, sincoeff1: -22, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: -1, F: 2, omega: 1, sincoeff1: 21, sincoeff2: 0, coscoeff1: -10, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 2, Mprime: 0, F: 0, omega: 0, sincoeff1: 17, sincoeff2: -0.1, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 2, M: 0, Mprime: -1, F: 0, omega: 1, sincoeff1: 16, sincoeff2: 0, coscoeff1: -8, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 2, Mprime: 0, F: 2, omega: 2, sincoeff1: -16, sincoeff2: 0.1, coscoeff1: 7, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 1, Mprime: 0, F: 0, omega: 1, sincoeff1: -15, sincoeff2: 0, coscoeff1: 9, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 0, Mprime: 1, F: 0, omega: 1, sincoeff1: -13, sincoeff2: 0, coscoeff1: 7, coscoeff2: 0),
    NutationCoefficient(D: 0, M: -1, Mprime: 0, F: 0, omega: 1, sincoeff1: -12, sincoeff2: 0, coscoeff1: 6, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: 2, F: -2, omega: 0, sincoeff1: 11, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 2, M: 0, Mprime: -1, F: 2, omega: 1, sincoeff1: -10, sincoeff2: 0, coscoeff1: 5, coscoeff2: 0),
    NutationCoefficient(D: 2, M: 0, Mprime: 1, F: 2, omega: 2, sincoeff1: -8, sincoeff2: 0, coscoeff1: 3, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 1, Mprime: 0, F: 2, omega: 2, sincoeff1: 7, sincoeff2: 0, coscoeff1: -3, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 1, Mprime: 1, F: 0, omega: 0, sincoeff1: -7, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 0, M: -1, Mprime: 0, F: 2, omega: 2, sincoeff1: -7, sincoeff2: 0, coscoeff1: 3, coscoeff2: 0),
    NutationCoefficient(D: 2, M: 0, Mprime: 0, F: 2, omega: 1, sincoeff1: -7, sincoeff2: 0, coscoeff1: 3, coscoeff2: 0),
    NutationCoefficient(D: 2, M: 0, Mprime: 1, F: 0, omega: 0, sincoeff1: 6, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 0, Mprime: 2, F: 2, omega: 2, sincoeff1: 6, sincoeff2: 0, coscoeff1: -3, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 0, Mprime: 1, F: 2, omega: 1, sincoeff1: 6, sincoeff2: 0, coscoeff1: -3, coscoeff2: 0),
    NutationCoefficient(D: 2, M: 0, Mprime: -2, F: 0, omega: 1, sincoeff1: -6, sincoeff2: 0, coscoeff1: 3, coscoeff2: 0),
    NutationCoefficient(D: 2, M: 0, Mprime: 0, F: 0, omega: 1, sincoeff1: -6, sincoeff2: 0, coscoeff1: 3, coscoeff2: 0),
    NutationCoefficient(D: 0, M: -1, Mprime: 1, F: 0, omega: 0, sincoeff1: 5, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: -2, M: -1, Mprime: 0, F: 2, omega: 1, sincoeff1: -5, sincoeff2: 0, coscoeff1: 3, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 0, Mprime: 0, F: 0, omega: 1, sincoeff1: -5, sincoeff2: 0, coscoeff1: 3, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: 2, F: 2, omega: 1, sincoeff1: -5, sincoeff2: 0, coscoeff1: 3, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 0, Mprime: 2, F: 0, omega: 1, sincoeff1: 4, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 1, Mprime: 0, F: 2, omega: 1, sincoeff1: 4, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: 1, F: -2, omega: 0, sincoeff1: 4, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: -1, M: 0, Mprime: 1, F: 0, omega: 0, sincoeff1: -4, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 1, Mprime: 0, F: 0, omega: 0, sincoeff1: -4, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 1, M: 0, Mprime: 0, F: 0, omega: 0, sincoeff1: -4, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: 1, F: 2, omega: 0, sincoeff1: 3, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: -2, F: 2, omega: 2, sincoeff1: -3, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: -1, M: -1, Mprime: 1, F: 0, omega: 0, sincoeff1: -3, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 1, Mprime: 1, F: 0, omega: 0, sincoeff1: -3, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 0, M: -1, Mprime: 1, F: 2, omega: 2, sincoeff1: -3, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 2, M: -1, Mprime: -1, F: 2, omega: 2, sincoeff1: -3, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: 3, F: 2, omega: 2, sincoeff1: -3, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 2, M: -1, Mprime: 0, F: 2, omega: 2, sincoeff1: -3, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0)
]

public enum CAANutation: Sendable {
    public static func NutationInLongitude(_ JD: Double) -> Double {
        let t = (JD - 2451545.0) / 36525.0
        let t2 = t * t
        let t3 = t2 * t

        let d = SphericalTrigonometry.mapTo0To360Range(297.85036 + 445267.111480 * t - 0.0019142 * t2 + t3 / 189474.0)
        let m = SphericalTrigonometry.mapTo0To360Range(357.52772 + 35999.050340 * t - 0.0001603 * t2 - t3 / 300000.0)
        let mPrime = SphericalTrigonometry.mapTo0To360Range(134.96298 + 477198.867398 * t + 0.0086972 * t2 + t3 / 56250.0)
        let f = SphericalTrigonometry.mapTo0To360Range(93.27191 + 483202.017538 * t - 0.0036825 * t2 + t3 / 327270.0)
        let omega = SphericalTrigonometry.mapTo0To360Range(125.04452 - 1934.136261 * t + 0.0020708 * t2 + t3 / 450000.0)

        var value = 0.0
        for coeff in gNutationCoeffs {
            let argument = Double(coeff.D) * d + Double(coeff.M) * m + Double(coeff.Mprime) * mPrime + Double(coeff.F) * f + Double(coeff.omega) * omega
            let argRad = SphericalTrigonometry.degreesToRadians(argument)
            value += (coeff.sincoeff1 + coeff.sincoeff2 * t) * sin(argRad) * 0.0001
        }
        return value
    }

    public static func NutationInObliquity(_ JD: Double) -> Double {
        let t = (JD - 2451545.0) / 36525.0
        let t2 = t * t
        let t3 = t2 * t

        let d = SphericalTrigonometry.mapTo0To360Range(297.85036 + 445267.111480 * t - 0.0019142 * t2 + t3 / 189474.0)
        let m = SphericalTrigonometry.mapTo0To360Range(357.52772 + 35999.050340 * t - 0.0001603 * t2 - t3 / 300000.0)
        let mPrime = SphericalTrigonometry.mapTo0To360Range(134.96298 + 477198.867398 * t + 0.0086972 * t2 + t3 / 56250.0)
        let f = SphericalTrigonometry.mapTo0To360Range(93.27191 + 483202.017538 * t - 0.0036825 * t2 + t3 / 327270.0)
        let omega = SphericalTrigonometry.mapTo0To360Range(125.04452 - 1934.136261 * t + 0.0020708 * t2 + t3 / 450000.0)

        var value = 0.0
        for coeff in gNutationCoeffs {
            let argument = Double(coeff.D) * d + Double(coeff.M) * m + Double(coeff.Mprime) * mPrime + Double(coeff.F) * f + Double(coeff.omega) * omega
            let argRad = SphericalTrigonometry.degreesToRadians(argument)
            value += (coeff.coscoeff1 + coeff.coscoeff2 * t) * cos(argRad) * 0.0001
        }
        return value
    }

    public static func MeanObliquityOfEcliptic(_ JD: Double) -> Double {
        let u = (JD - 2451545.0) / 3652500.0
        let u2 = u * u
        let u3 = u2 * u
        let u4 = u3 * u
        let u5 = u4 * u
        let u6 = u5 * u
        let u7 = u6 * u
        let u8 = u7 * u
        let u9 = u8 * u
        let u10 = u9 * u

        return SphericalTrigonometry.dmsToDegrees(23, 26, 21.448)
            - (SphericalTrigonometry.dmsToDegrees(0, 0, 4680.93) * u)
            - (SphericalTrigonometry.dmsToDegrees(0, 0, 1.55) * u2)
            + (SphericalTrigonometry.dmsToDegrees(0, 0, 1999.25) * u3)
            - (SphericalTrigonometry.dmsToDegrees(0, 0, 51.38) * u4)
            - (SphericalTrigonometry.dmsToDegrees(0, 0, 249.67) * u5)
            - (SphericalTrigonometry.dmsToDegrees(0, 0, 39.05) * u6)
            + (SphericalTrigonometry.dmsToDegrees(0, 0, 7.12) * u7)
            + (SphericalTrigonometry.dmsToDegrees(0, 0, 27.87) * u8)
            + (SphericalTrigonometry.dmsToDegrees(0, 0, 5.79) * u9)
            + (SphericalTrigonometry.dmsToDegrees(0, 0, 2.45) * u10)
    }

    public static func TrueObliquityOfEcliptic(_ JD: Double) -> Double {
        MeanObliquityOfEcliptic(JD) + SphericalTrigonometry.dmsToDegrees(0, 0, NutationInObliquity(JD))
    }

    @inlinable public static func nutationInLongitude(jd: Double) -> Double { NutationInLongitude(jd) }
    @inlinable public static func nutationInLongitude(_ JD: Double) -> Double { NutationInLongitude(JD) }
    @inlinable public static func nutationInObliquity(jd: Double) -> Double { NutationInObliquity(jd) }
    @inlinable public static func nutationInObliquity(_ JD: Double) -> Double { NutationInObliquity(JD) }
    @inlinable public static func meanObliquityOfEcliptic(jd: Double) -> Double { MeanObliquityOfEcliptic(jd) }
    @inlinable public static func meanObliquityOfEcliptic(_ JD: Double) -> Double { MeanObliquityOfEcliptic(JD) }
    @inlinable public static func trueObliquityOfEcliptic(jd: Double) -> Double { TrueObliquityOfEcliptic(jd) }
    @inlinable public static func trueObliquityOfEcliptic(_ JD: Double) -> Double { TrueObliquityOfEcliptic(JD) }

    public static func NutationInRightAscension(_ Alpha: Double, _ Delta: Double, _ Obliquity: Double, _ NutationInLongitude: Double, _ NutationInObliquity: Double) -> Double {
        let a = SphericalTrigonometry.hoursToRadians(Alpha)
        let d = SphericalTrigonometry.degreesToRadians(Delta)
        let eps = SphericalTrigonometry.degreesToRadians(Obliquity)

        return ((cos(eps) + (sin(eps) * sin(a) * tan(d))) * NutationInLongitude) - (cos(a) * tan(d) * NutationInObliquity)
    }

    public static func NutationInDeclination(_ Alpha: Double, _ Obliquity: Double, _ NutationInLongitude: Double, _ NutationInObliquity: Double) -> Double {
        let a = SphericalTrigonometry.hoursToRadians(Alpha)
        let eps = SphericalTrigonometry.degreesToRadians(Obliquity)

        return (sin(eps) * cos(a) * NutationInLongitude) + (sin(a) * NutationInObliquity)
    }
}

// MARK: - Precession Engine (Meeus Ch. 21)

public enum CAAPrecession: Sendable {
    public static func PrecessEquatorial(_ Alpha: Double, _ Delta: Double, _ JD0: Double, _ JD: Double) -> CAA2DCoordinate {
        let t0 = (JD0 - 2451545.0) / 36525.0
        let t0Squared = t0 * t0
        let t = (JD - JD0) / 36525.0
        let tSquared = t * t
        let tCubed = tSquared * t

        let a = SphericalTrigonometry.hoursToRadians(Alpha)
        let d = SphericalTrigonometry.degreesToRadians(Delta)
        let cosDelta = cos(d)
        let sinDelta = sin(d)

        let sigma = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.dmsToDegrees(0, 0, ((2306.2181 + (1.39656 * t0) - (0.000139 * t0Squared)) * t) + ((0.30188 - (0.000344 * t0)) * tSquared) + (0.017998 * tCubed)))
        let zeta = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.dmsToDegrees(0, 0, ((2306.2181 + (1.39656 * t0) - (0.000139 * t0Squared)) * t) + ((1.09468 + (0.000066 * t0)) * tSquared) + (0.018203 * tCubed)))
        let phi = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.dmsToDegrees(0, 0, ((2004.3109 - (0.8533 * t0) - (0.000217 * t0Squared)) * t) - ((0.42665 + (0.000217 * t0)) * tSquared) - (0.041833 * tCubed)))

        let cosPhi = cos(phi)
        let sinPhi = sin(phi)
        let cosAlphaPlusSigma = cos(a + sigma)
        let capA = cosDelta * sin(a + sigma)
        let capB = (cosPhi * cosDelta * cosAlphaPlusSigma) - (sinPhi * sinDelta)
        let capC = (sinPhi * cosDelta * cosAlphaPlusSigma) + (cosPhi * sinDelta)

        let x = SphericalTrigonometry.mapTo0To24Range(SphericalTrigonometry.radiansToHours(atan2(capA, capB) + zeta))
        let y = SphericalTrigonometry.radiansToDegrees(asin(capC))
        return CAA2DCoordinate(x, y)
    }

    public static func PrecessEquatorialFK4(_ Alpha: Double, _ Delta: Double, _ JD0: Double, _ JD: Double) -> CAA2DCoordinate {
        let t0 = (JD0 - 2415020.3135) / 36524.2199
        let t = (JD - JD0) / 36524.2199
        let tSquared = t * t
        let tCubed = tSquared * t

        let a = SphericalTrigonometry.hoursToRadians(Alpha)
        let d = SphericalTrigonometry.degreesToRadians(Delta)
        let cosDelta = cos(d)
        let sinDelta = sin(d)

        let sigma = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.dmsToDegrees(0, 0, ((2304.250 + (1.396 * t0)) * t) + (0.302 * tSquared) + (0.018 * tCubed)))
        let zeta = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.dmsToDegrees(0, 0, ((2304.250 + (1.396 * t0)) * t) + (1.093 * tSquared) + (0.018 * tCubed)))
        let phi = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.dmsToDegrees(0, 0, ((2004.682 - (0.853 * t0)) * t) - (0.426 * tSquared) - (0.042 * tCubed)))

        let cosPhi = cos(phi)
        let sinPhi = sin(phi)
        let cosAlphaPlusSigma = cos(a + sigma)
        let capA = cosDelta * sin(a + sigma)
        let capB = (cosPhi * cosDelta * cosAlphaPlusSigma) - (sinPhi * sinDelta)
        let capC = (sinPhi * cosDelta * cosAlphaPlusSigma) + (cosPhi * sinDelta)

        let x = SphericalTrigonometry.mapTo0To24Range(SphericalTrigonometry.radiansToHours(atan2(capA, capB) + zeta))
        let y = SphericalTrigonometry.radiansToDegrees(asin(capC))
        return CAA2DCoordinate(x, y)
    }

    public static func PrecessEcliptic(_ Lambda: Double, _ Beta: Double, _ JD0: Double, _ JD: Double) -> CAA2DCoordinate {
        let T = (JD0 - 2451545.0) / 36525.0
        let TSquared = T * T
        let t = (JD - JD0) / 36525.0
        let tSquared = t * t
        let tCubed = tSquared * t

        let lam = SphericalTrigonometry.degreesToRadians(Lambda)
        let bet = SphericalTrigonometry.degreesToRadians(Beta)
        let cosBeta = cos(bet)
        let sinBeta = sin(bet)

        let eta = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.dmsToDegrees(0, 0, ((47.0029 - (0.06603 * T) + (0.000598 * TSquared)) * t) + ((-0.03302 + (0.000598 * T)) * tSquared) + (0.00006 * tCubed)))
        let cosEta = cos(eta)
        let sinEta = sin(eta)

        let pi = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.dmsToDegrees(0, 0, (174.876384 * 3600.0) + (3289.4789 * T) + (0.60622 * TSquared) - ((869.8089 + (0.50491 * T)) * t) + (0.03536 * tSquared)))
        let sinPiMinusLambda = sin(pi - lam)

        let p = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.dmsToDegrees(0, 0, ((5029.0966 + (2.22226 * T) - (0.000042 * TSquared)) * t) + ((1.11113 - (0.000042 * T)) * tSquared) - (0.000006 * tCubed)))
        let capA = (cosEta * cosBeta * sinPiMinusLambda) - (sinEta * sinBeta)
        let capB = cosBeta * cos(pi - lam)
        let capC = (cosEta * sinBeta) + (sinEta * cosBeta * sinPiMinusLambda)

        let x = SphericalTrigonometry.mapTo0To360Range(SphericalTrigonometry.radiansToDegrees(p + pi - atan2(capA, capB)))
        let y = SphericalTrigonometry.radiansToDegrees(asin(capC))
        return CAA2DCoordinate(x, y)
    }

    public static func EquatorialPMToEcliptic(_ Alpha: Double, _ Delta: Double, _ Beta: Double, _ PMAlpha: Double, _ PMDelta: Double, _ Epsilon: Double) -> CAA2DCoordinate {
        let eps = SphericalTrigonometry.degreesToRadians(Epsilon)
        let sinEps = sin(eps)
        let cosEps = cos(eps)

        let a = SphericalTrigonometry.hoursToRadians(Alpha)
        let cosAlpha = cos(a)
        let sinAlpha = sin(a)

        let d = SphericalTrigonometry.degreesToRadians(Delta)
        let cosDelta = cos(d)
        let sinDelta = sin(d)

        let b = SphericalTrigonometry.degreesToRadians(Beta)
        let cosBeta = cos(b)

        let x = ((PMDelta * sinEps * cosAlpha) + (PMAlpha * cosDelta * ((cosEps * cosDelta) + (sinEps * sinDelta * sinAlpha)))) / (cosBeta * cosBeta)
        let y = (PMDelta * ((cosEps * cosDelta) + (sinEps * sinDelta * sinAlpha)) - (PMAlpha * sinEps * cosAlpha * cosDelta)) / cosBeta
        return CAA2DCoordinate(x, y)
    }

    public static func AdjustPositionUsingUniformProperMotion(_ t: Double, _ Alpha: Double, _ Delta: Double, _ PMAlpha: Double, _ PMDelta: Double) -> CAA2DCoordinate {
        let x = SphericalTrigonometry.mapTo0To24Range(Alpha + ((PMAlpha * t) / 3600.0))
        let y = SphericalTrigonometry.mapToMinus90To90Range(Delta + ((PMDelta * t) / 3600.0))
        return CAA2DCoordinate(x, y)
    }

    public static func AdjustPositionUsingMotionInSpace(_ r: Double, _ DeltaR: Double, _ t: Double, _ Alpha: Double, _ Delta: Double, _ PMAlpha: Double, _ PMDelta: Double) -> CAA2DCoordinate {
        let dr = DeltaR / 977792.0
        let pmA = PMAlpha / 13751.0
        let pmD = PMDelta / 206265.0

        let a = SphericalTrigonometry.hoursToRadians(Alpha)
        let cosAlpha = cos(a)
        let sinAlpha = sin(a)
        let d = SphericalTrigonometry.degreesToRadians(Delta)
        let cosDelta = cos(d)
        let rCosDelta = r * cosDelta

        var x = rCosDelta * cosAlpha
        var y = rCosDelta * sinAlpha
        var z = r * sin(d)

        let deltaX = ((x / r) * dr) - (z * pmD * cosAlpha) - (y * pmA)
        let deltaY = ((y / r) * dr) - (z * pmD * sinAlpha) + (x * pmA)
        let deltaZ = ((z / r) * dr) + (r * pmD * cosDelta)

        x += t * deltaX
        y += t * deltaY
        z += t * deltaZ

        let newAlpha = SphericalTrigonometry.mapTo0To24Range(SphericalTrigonometry.radiansToHours(atan2(y, x)))
        let newDelta = SphericalTrigonometry.radiansToDegrees(atan2(z, sqrt((x * x) + (y * y))))
        return CAA2DCoordinate(newAlpha, newDelta)
    }
}

// MARK: - FK5 Reference Frame Conversion Engine (CAAFK5)

public enum CAAFK5: Sendable {
    @inlinable public static func correctionInLongitude(longitude: Double, latitude: Double, jd: Double) -> Double {
        CorrectionInLongitude(longitude, latitude, jd)
    }
    @inlinable public static func correctionInLongitude(_ Longitude: Double, _ Latitude: Double, _ JD: Double) -> Double {
        CorrectionInLongitude(Longitude, Latitude, JD)
    }

    @inlinable public static func correctionInLatitude(longitude: Double, jd: Double) -> Double {
        CorrectionInLatitude(longitude, jd)
    }
    @inlinable public static func correctionInLatitude(_ Longitude: Double, _ JD: Double) -> Double {
        CorrectionInLatitude(Longitude, JD)
    }

    @inlinable public static func convertVSOPToFK5J2000(_ value: CAA3DCoordinate) -> CAA3DCoordinate {
        ConvertVSOPToFK5J2000(value)
    }

    @inlinable public static func convertVSOPToFK5B1950(_ value: CAA3DCoordinate) -> CAA3DCoordinate {
        ConvertVSOPToFK5B1950(value)
    }

    @inlinable public static func convertVSOPToFK5AnyEquinox(value: CAA3DCoordinate, jdedate: Double) -> CAA3DCoordinate {
        ConvertVSOPToFK5AnyEquinox(value, jdedate)
    }
    @inlinable public static func convertVSOPToFK5AnyEquinox(_ value: CAA3DCoordinate, jdEquinox: Double) -> CAA3DCoordinate {
        ConvertVSOPToFK5AnyEquinox(value, jdEquinox)
    }
    @inlinable public static func convertVSOPToFK5AnyEquinox(_ value: CAA3DCoordinate, _ JDEquinox: Double) -> CAA3DCoordinate {
        ConvertVSOPToFK5AnyEquinox(value, JDEquinox)
    }

    public static func CorrectionInLongitude(_ Longitude: Double, _ Latitude: Double, _ JD: Double) -> Double {
        let T = (JD - 2451545.0) / 36525.0
        var Ldash = Longitude - (1.397 * T) - (0.00031 * T * T)
        Ldash = SphericalTrigonometry.degreesToRadians(Ldash)
        let latRad = SphericalTrigonometry.degreesToRadians(Latitude)
        let value = -0.09033 + (0.03916 * (cos(Ldash) + sin(Ldash))) * tan(latRad)
        return SphericalTrigonometry.dmsToDegrees(0, 0, value)
    }

    public static func CorrectionInLatitude(_ Longitude: Double, _ JD: Double) -> Double {
        let T = (JD - 2451545.0) / 36525.0
        var Ldash = Longitude - (1.397 * T) - (0.00031 * T * T)
        Ldash = SphericalTrigonometry.degreesToRadians(Ldash)
        let value = 0.03916 * (cos(Ldash) - sin(Ldash))
        return SphericalTrigonometry.dmsToDegrees(0, 0, value)
    }

    public static func ConvertVSOPToFK5J2000(_ value: CAA3DCoordinate) -> CAA3DCoordinate {
        var result = CAA3DCoordinate()
        result.X = value.X + (0.000000440360 * value.Y) - (0.000000190919 * value.Z)
        result.Y = (-0.000000479966 * value.X) + (0.917482137087 * value.Y) - (0.397776982902 * value.Z)
        result.Z = (0.397776982902 * value.Y) + (0.917482137087 * value.Z)
        return result
    }

    public static func ConvertVSOPToFK5B1950(_ value: CAA3DCoordinate) -> CAA3DCoordinate {
        var result = CAA3DCoordinate()
        result.X = (0.999925702634 * value.X) + (0.012189716217 * value.Y) + (0.000011134016 * value.Z)
        result.Y = (-0.011179418036 * value.X) + (0.917413998946 * value.Y) - (0.397777041885 * value.Z)
        result.Z = (-0.004859003787 * value.X) + (0.397747363646 * value.Y) + (0.917482111428 * value.Z)
        return result
    }

    public static func ConvertVSOPToFK5AnyEquinox(_ value: CAA3DCoordinate, _ JDEquinox: Double) -> CAA3DCoordinate {
        let t = (JDEquinox - 2451545.0) / 36525.0
        let tsquared = t * t
        let tcubed = tsquared * t

        var sigma = (2306.2181 * t) + (0.30188 * tsquared) + (0.017988 * tcubed)
        sigma = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.dmsToDegrees(0, 0, sigma))

        var zeta = (2306.2181 * t) + (1.09468 * tsquared) + (0.018203 * tcubed)
        zeta = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.dmsToDegrees(0, 0, zeta))

        var phi = (2004.3109 * t) - (0.42665 * tsquared) - (0.041833 * tcubed)
        phi = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.dmsToDegrees(0, 0, phi))

        let cossigma = cos(sigma)
        let coszeta = cos(zeta)
        let cosphi = cos(phi)
        let sinsigma = sin(sigma)
        let sinzeta = sin(zeta)
        let sinphi = sin(phi)

        let xx = (cossigma * coszeta * cosphi) - (sinsigma * sinzeta)
        let xy = (sinsigma * coszeta) + (cossigma * sinzeta * cosphi)
        let xz = cossigma * sinphi
        let yx = (-cossigma * sinzeta) - (sinsigma * coszeta * cosphi)
        let yy = (cossigma * coszeta) - (sinsigma * sinzeta * cosphi)
        let yz = -sinsigma * sinphi
        let zx = -coszeta * sinphi
        let zy = -sinzeta * sinphi
        let zz = cosphi

        var result = CAA3DCoordinate()
        result.X = (xx * value.X) + (yx * value.Y) + (zx * value.Z)
        result.Y = (xy * value.X) + (yy * value.Y) + (zy * value.Z)
        result.Z = (xz * value.X) + (yz * value.Y) + (zz * value.Z)
        return result
    }
}

