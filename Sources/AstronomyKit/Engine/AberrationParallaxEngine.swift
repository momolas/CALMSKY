//
//  AberrationParallaxEngine.swift
//  AstronomyKit
//
//  Pure Swift Earth geodesy (WGS84/IAU 1976), diurnal parallax, parallactic angle, and annual aberration.
//  Replaces CAAGlobe, CAAParallactic, CAAParallax, and CAAAberration from AAplus.
//

import Foundation

// MARK: - Geodesy & Earth Globe

public enum GlobeEngine: Sendable {
    public static func rhoSinThetaPrime(latitude: Double, height: Double) -> Double {
        let phi = SphericalTrigonometry.degreesToRadians(latitude)
        let u = atan(0.99664719 * tan(phi))
        return (0.99664719 * sin(u)) + ((height / 6378140.0) * sin(phi))
    }

    public static func rhoCosThetaPrime(latitude: Double, height: Double) -> Double {
        let phi = SphericalTrigonometry.degreesToRadians(latitude)
        let u = atan(0.99664719 * tan(phi))
        return cos(u) + ((height / 6378140.0) * cos(phi))
    }

    public static func radiusOfParallelOfLatitude(latitude: Double) -> Double {
        let phi = SphericalTrigonometry.degreesToRadians(latitude)
        let sinGeo = sin(phi)
        return (6378.14 * cos(phi)) / sqrt(1.0 - (0.0066943847614084 * sinGeo * sinGeo))
    }

    public static func radiusOfCurvature(latitude: Double) -> Double {
        let phi = SphericalTrigonometry.degreesToRadians(latitude)
        let sinGeo = sin(phi)
        return (6378.14 * (1.0 - 0.0066943847614084)) / pow(1.0 - (0.0066943847614084 * sinGeo * sinGeo), 1.5)
    }

    public static func distanceBetweenPoints(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let phi1 = SphericalTrigonometry.degreesToRadians(lat1)
        let phi2 = SphericalTrigonometry.degreesToRadians(lat2)
        let l1 = SphericalTrigonometry.degreesToRadians(lon1)
        let l2 = SphericalTrigonometry.degreesToRadians(lon2)

        let f = (phi1 + phi2) / 2.0
        let g = (phi1 - phi2) / 2.0
        let lambda = (l1 - l2) / 2.0

        let sinG = sin(g)
        let cosG = cos(g)
        let cosF = cos(f)
        let sinF = sin(f)
        let sinLambda = sin(lambda)
        let cosLambda = cos(lambda)

        let s = (sinG * sinG * cosLambda * cosLambda) + (cosF * cosF * sinLambda * sinLambda)
        let c = (cosG * cosG * cosLambda * cosLambda) + (sinF * sinF * sinLambda * sinLambda)
        let w = atan(sqrt(s / c))
        let r = sqrt(s * c) / w
        let d = 2.0 * w * 6378.14
        let hPrime = (3.0 * r - 1.0) / (2.0 * c)
        let hPrime2 = (3.0 * r + 1.0) / (2.0 * s)
        let flattening = 0.0033528131778969144060323814696721

        return d * (1.0 + (flattening * hPrime * sinF * sinF * cosG * cosG) - (flattening * hPrime2 * cosF * cosF * sinG * sinG))
    }
}

public enum CAAGlobe: Sendable {
    @inlinable public static func rhoSinThetaPrime(latitude: Double, height: Double) -> Double {
        GlobeEngine.rhoSinThetaPrime(latitude: latitude, height: height)
    }
    @inlinable public static func rhoSinThetaPrime(_ GeographicalLatitude: Double, _ Height: Double) -> Double {
        GlobeEngine.rhoSinThetaPrime(latitude: GeographicalLatitude, height: Height)
    }
    @inlinable public static func RhoSinThetaPrime(_ GeographicalLatitude: Double, _ Height: Double) -> Double {
        GlobeEngine.rhoSinThetaPrime(latitude: GeographicalLatitude, height: Height)
    }

    @inlinable public static func rhoCosThetaPrime(latitude: Double, height: Double) -> Double {
        GlobeEngine.rhoCosThetaPrime(latitude: latitude, height: height)
    }
    @inlinable public static func rhoCosThetaPrime(_ GeographicalLatitude: Double, _ Height: Double) -> Double {
        GlobeEngine.rhoCosThetaPrime(latitude: GeographicalLatitude, height: Height)
    }
    @inlinable public static func RhoCosThetaPrime(_ GeographicalLatitude: Double, _ Height: Double) -> Double {
        GlobeEngine.rhoCosThetaPrime(latitude: GeographicalLatitude, height: Height)
    }
    @inlinable public static func RadiusOfParallelOfLatitude(_ GeographicalLatitude: Double) -> Double {
        GlobeEngine.radiusOfParallelOfLatitude(latitude: GeographicalLatitude)
    }
    @inlinable public static func RadiusOfCurvature(_ GeographicalLatitude: Double) -> Double {
        GlobeEngine.radiusOfCurvature(latitude: GeographicalLatitude)
    }
    @inlinable public static func DistanceBetweenPoints(_ GeographicalLatitude1: Double, _ GeographicalLongitude1: Double, _ GeographicalLatitude2: Double, _ GeographicalLongitude2: Double) -> Double {
        GlobeEngine.distanceBetweenPoints(lat1: GeographicalLatitude1, lon1: GeographicalLongitude1, lat2: GeographicalLatitude2, lon2: GeographicalLongitude2)
    }
}

// MARK: - Parallactic Angle

public enum CAAParallactic: Sendable {
    public static func ParallacticAngle(_ HourAngle: Double, _ Latitude: Double, _ delta: Double) -> Double {
        let h = SphericalTrigonometry.hoursToRadians(HourAngle)
        let lat = SphericalTrigonometry.degreesToRadians(Latitude)
        let d = SphericalTrigonometry.degreesToRadians(delta)

        return SphericalTrigonometry.radiansToDegrees(atan2(sin(h), (tan(lat) * cos(d)) - (sin(d) * cos(h))))
    }

    public static func EclipticLongitudeOnHorizon(_ LocalSiderealTime: Double, _ ObliquityOfEcliptic: Double, _ Latitude: Double) -> Double {
        let theta = SphericalTrigonometry.hoursToRadians(LocalSiderealTime)
        let lat = SphericalTrigonometry.degreesToRadians(Latitude)
        let eps = SphericalTrigonometry.degreesToRadians(ObliquityOfEcliptic)

        let value = SphericalTrigonometry.radiansToDegrees(atan2(-cos(theta), (sin(eps) * tan(lat)) + (cos(eps) * sin(theta))))
        return SphericalTrigonometry.mapTo0To360Range(value)
    }

    public static func AngleBetweenEclipticAndHorizon(_ LocalSiderealTime: Double, _ ObliquityOfEcliptic: Double, _ Latitude: Double) -> Double {
        let theta = SphericalTrigonometry.hoursToRadians(LocalSiderealTime)
        let lat = SphericalTrigonometry.degreesToRadians(Latitude)
        let eps = SphericalTrigonometry.degreesToRadians(ObliquityOfEcliptic)

        let value = SphericalTrigonometry.radiansToDegrees(acos((cos(eps) * sin(lat)) - (sin(eps) * cos(lat) * sin(theta))))
        return SphericalTrigonometry.mapTo0To360Range(value)
    }

    public static func AngleBetweenNorthCelestialPoleAndNorthPoleOfEcliptic(_ Lambda: Double, _ Beta: Double, _ ObliquityOfEcliptic: Double) -> Double {
        let lam = SphericalTrigonometry.degreesToRadians(Lambda)
        let bet = SphericalTrigonometry.degreesToRadians(Beta)
        let eps = SphericalTrigonometry.degreesToRadians(ObliquityOfEcliptic)

        let value = SphericalTrigonometry.radiansToDegrees(atan2(cos(lam) * tan(eps), (sin(bet) * sin(lam) * tan(eps)) - cos(bet)))
        return SphericalTrigonometry.mapTo0To360Range(value)
    }
}

// MARK: - Diurnal Parallax

public enum CAAParallax: Sendable {
    public static let c1 = 4.2635232628103847e-05

    public static func DistanceToParallax(_ Distance: Double) -> Double {
        let pi = asin(c1 / Distance)
        return SphericalTrigonometry.radiansToDegrees(pi)
    }

    public static func ParallaxToDistance(_ Parallax: Double) -> Double {
        return c1 / sin(SphericalTrigonometry.degreesToRadians(Parallax))
    }

    public static func Equatorial2Topocentric(_ Alpha: Double, _ Delta: Double, _ Distance: Double, _ Longitude: Double, _ Latitude: Double, _ Height: Double, _ JD: Double) -> CAA2DCoordinate {
        let rhoSin = GlobeEngine.rhoSinThetaPrime(latitude: Latitude, height: Height)
        let rhoCos = GlobeEngine.rhoCosThetaPrime(latitude: Latitude, height: Height)
        let theta = SiderealTimeEngine.apparentGreenwichSiderealTime(jd: JD)

        let d = SphericalTrigonometry.degreesToRadians(Delta)
        let cosDelta = cos(d)
        let pi = asin(c1 / Distance)
        let sinPi = sin(pi)

        let h = SphericalTrigonometry.hoursToRadians(theta - (Longitude / 15.0) - Alpha)
        let cosH = cos(h)
        let sinH = sin(h)

        let deltaAlpha = atan2(-rhoCos * sinPi * sinH, cosDelta - (rhoCos * sinPi * cosH))
        let topAlpha = SphericalTrigonometry.mapTo0To24Range(Alpha + SphericalTrigonometry.radiansToHours(deltaAlpha))
        let topDelta = SphericalTrigonometry.radiansToDegrees(atan2((sin(d) - (rhoSin * sinPi)) * cos(deltaAlpha), cosDelta - (rhoCos * sinPi * cosH)))

        return CAA2DCoordinate(topAlpha, topDelta)
    }
}

// MARK: - Annual Aberration (Ron & Vondrák 1986 / IAU Model)

private struct AberrationCoefficient: Sendable {
    let L2: Int; let L3: Int; let L4: Int; let L5: Int; let L6: Int; let L7: Int; let L8: Int
    let Ldash: Int; let D: Int; let Mdash: Int; let F: Int
    let xsin: Double; let xsint: Double; let xcos: Double; let xcost: Double
    let ysin: Double; let ysint: Double; let ycos: Double; let ycost: Double
    let zsin: Double; let zsint: Double; let zcos: Double; let zcost: Double
}

private let gAberrationCoeffs: [AberrationCoefficient] = [
    AberrationCoefficient(L2: 0, L3: 1, L4: 0, L5: 0, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: -1719914, xsint: -2, xcos: -25, xcost: 0, ysin: 25, ysint: -13, ycos: 1578089, ycost: 156, zsin: 10, zsint: 32, zcos: 684185, zcost: -358),
    AberrationCoefficient(L2: 0, L3: 2, L4: 0, L5: 0, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: 6434, xsint: 141, xcos: 28007, xcost: -107, ysin: 25697, ysint: -95, ycos: -5904, ycost: -130, zsin: 11141, zsint: -48, zcos: -2559, zcost: -55),
    AberrationCoefficient(L2: 0, L3: 0, L4: 0, L5: 1, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: 715, xsint: 0, xcos: 0, xcost: 0, ysin: 6, ysint: 0, ycos: -657, ycost: 0, zsin: -15, zsint: 0, zcos: -282, zcost: 0),
    AberrationCoefficient(L2: 0, L3: 0, L4: 0, L5: 0, L6: 0, L7: 0, L8: 0, Ldash: 1, D: 0, Mdash: 0, F: 0, xsin: 715, xsint: 0, xcos: 0, xcost: 0, ysin: 0, ysint: 0, ycos: -656, ycost: 0, zsin: 0, zsint: 0, zcos: -285, zcost: 0),
    AberrationCoefficient(L2: 0, L3: 3, L4: 0, L5: 0, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: 486, xsint: -5, xcos: -236, xcost: -4, ysin: -216, ysint: -4, ycos: -446, ycost: 5, zsin: -94, zsint: 0, zcos: -193, zcost: 0),
    AberrationCoefficient(L2: 0, L3: 0, L4: 0, L5: 0, L6: 1, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: 159, xsint: 0, xcos: 0, xcost: 0, ysin: 2, ysint: 0, ycos: -147, ycost: 0, zsin: -6, zsint: 0, zcos: -61, zcost: 0),
    AberrationCoefficient(L2: 0, L3: 0, L4: 0, L5: 0, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 1, xsin: 0, xsint: 0, xcos: 0, xcost: 0, ysin: 0, ysint: 0, ycos: 26, ycost: 0, zsin: 0, zsint: 0, zcos: -59, zcost: 0),
    AberrationCoefficient(L2: 0, L3: 0, L4: 0, L5: 0, L6: 0, L7: 0, L8: 0, Ldash: 1, D: 0, Mdash: 1, F: 0, xsin: 39, xsint: 0, xcos: 0, xcost: 0, ysin: 0, ysint: 0, ycos: -36, ycost: 0, zsin: 0, zsint: 0, zcos: -16, zcost: 0),
    AberrationCoefficient(L2: 0, L3: 0, L4: 0, L5: 2, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: 33, xsint: 0, xcos: -10, xcost: 0, ysin: -9, ysint: 0, ycos: -30, ycost: 0, zsin: -5, zsint: 0, zcos: -13, zcost: 0),
    AberrationCoefficient(L2: 0, L3: 2, L4: 0, L5: -1, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: 31, xsint: 0, xcos: 1, xcost: 0, ysin: 1, ysint: 0, ycos: -28, ycost: 0, zsin: 0, zsint: 0, zcos: -12, zcost: 0),
    AberrationCoefficient(L2: 0, L3: 3, L4: -8, L5: 3, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: 8, xsint: 0, xcos: -28, xcost: 0, ysin: 25, ysint: 0, ycos: 8, ycost: 0, zsin: 11, zsint: 0, zcos: 3, zcost: 0),
    AberrationCoefficient(L2: 0, L3: 5, L4: -8, L5: 3, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: 8, xsint: 0, xcos: -28, xcost: 0, ysin: -25, ysint: 0, ycos: -8, ycost: 0, zsin: -11, zsint: 0, zcos: -3, zcost: 0),
    AberrationCoefficient(L2: 2, L3: -1, L4: 0, L5: 0, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: 21, xsint: 0, xcos: 0, xcost: 0, ysin: 0, ysint: 0, ycos: -19, ycost: 0, zsin: 0, zsint: 0, zcos: -8, zcost: 0),
    AberrationCoefficient(L2: 1, L3: 0, L4: 0, L5: 0, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: -19, xsint: 0, xcos: 0, xcost: 0, ysin: 0, ysint: 0, ycos: 17, ycost: 0, zsin: 0, zsint: 0, zcos: 8, zcost: 0),
    AberrationCoefficient(L2: 0, L3: 0, L4: 0, L5: 0, L6: 0, L7: 1, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: 17, xsint: 0, xcos: 0, xcost: 0, ysin: 0, ysint: 0, ycos: -16, ycost: 0, zsin: 0, zsint: 0, zcos: -7, zcost: 0),
    AberrationCoefficient(L2: 0, L3: 1, L4: 0, L5: -2, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: 16, xsint: 0, xcos: 0, xcost: 0, ysin: 0, ysint: 0, ycos: 15, ycost: 0, zsin: 1, zsint: 0, zcos: 7, zcost: 0),
    AberrationCoefficient(L2: 0, L3: 0, L4: 0, L5: 0, L6: 0, L7: 0, L8: 1, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: 16, xsint: 0, xcos: 0, xcost: 0, ysin: 1, ysint: 0, ycos: -15, ycost: 0, zsin: -3, zsint: 0, zcos: -6, zcost: 0),
    AberrationCoefficient(L2: 0, L3: 1, L4: 0, L5: 1, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: 11, xsint: 0, xcos: -1, xcost: 0, ysin: -1, ysint: 0, ycos: -10, ycost: 0, zsin: -1, zsint: 0, zcos: -5, zcost: 0),
    AberrationCoefficient(L2: 2, L3: -2, L4: 0, L5: 0, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: 0, xsint: 0, xcos: -11, xcost: 0, ysin: -10, ysint: 0, ycos: 0, ycost: 0, zsin: -4, zsint: 0, zcos: 0, zcost: 0),
    AberrationCoefficient(L2: 0, L3: 1, L4: 0, L5: -1, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: -11, xsint: 0, xcos: -2, xcost: 0, ysin: -2, ysint: 0, ycos: 9, ycost: 0, zsin: -1, zsint: 0, zcos: 4, zcost: 0),
    AberrationCoefficient(L2: 0, L3: 4, L4: 0, L5: 0, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: -7, xsint: 0, xcos: -8, xcost: 0, ysin: -8, ysint: 0, ycos: 6, ycost: 0, zsin: -3, zsint: 0, zcos: 3, zcost: 0),
    AberrationCoefficient(L2: 0, L3: 3, L4: 0, L5: -2, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: -10, xsint: 0, xcos: 0, xcost: 0, ysin: 0, ysint: 0, ycos: 9, ycost: 0, zsin: 0, zsint: 0, zcos: 4, zcost: 0),
    AberrationCoefficient(L2: 1, L3: -2, L4: 0, L5: 0, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: -9, xsint: 0, xcos: 0, xcost: 0, ysin: 0, ysint: 0, ycos: -9, ycost: 0, zsin: 0, zsint: 0, zcos: -4, zcost: 0),
    AberrationCoefficient(L2: 2, L3: -3, L4: 0, L5: 0, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: -9, xsint: 0, xcos: 0, xcost: 0, ysin: 0, ysint: 0, ycos: -8, ycost: 0, zsin: 0, zsint: 0, zcos: -4, zcost: 0),
    AberrationCoefficient(L2: 0, L3: 0, L4: 0, L5: 0, L6: 2, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: 0, xsint: 0, xcos: -9, xcost: 0, ysin: -8, ysint: 0, ycos: 0, ycost: 0, zsin: -3, zsint: 0, zcos: 0, zcost: 0),
    AberrationCoefficient(L2: 2, L3: -4, L4: 0, L5: 0, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: 0, xsint: 0, xcos: -9, xcost: 0, ysin: 8, ysint: 0, ycos: 0, ycost: 0, zsin: 3, zsint: 0, zcos: 0, zcost: 0),
    AberrationCoefficient(L2: 0, L3: 3, L4: -2, L5: 0, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: 8, xsint: 0, xcos: 0, xcost: 0, ysin: 0, ysint: 0, ycos: -8, ycost: 0, zsin: 0, zsint: 0, zcos: -3, zcost: 0),
    AberrationCoefficient(L2: 0, L3: 0, L4: 0, L5: 0, L6: 0, L7: 0, L8: 0, Ldash: 1, D: 2, Mdash: -1, F: 0, xsin: 8, xsint: 0, xcos: 0, xcost: 0, ysin: 0, ysint: 0, ycos: -7, ycost: 0, zsin: 0, zsint: 0, zcos: -3, zcost: 0),
    AberrationCoefficient(L2: 8, L3: -12, L4: 0, L5: 0, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: -4, xsint: 0, xcos: -7, xcost: 0, ysin: -6, ysint: 0, ycos: 4, ycost: 0, zsin: -3, zsint: 0, zcos: 2, zcost: 0),
    AberrationCoefficient(L2: 8, L3: -14, L4: 0, L5: 0, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: -4, xsint: 0, xcos: -7, xcost: 0, ysin: 6, ysint: 0, ycos: -4, ycost: 0, zsin: 3, zsint: 0, zcos: -2, zcost: 0),
    AberrationCoefficient(L2: 0, L3: 0, L4: 2, L5: 0, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: -6, xsint: 0, xcos: -5, xcost: 0, ysin: -4, ysint: 0, ycos: 5, ycost: 0, zsin: -2, zsint: 0, zcos: 2, zcost: 0),
    AberrationCoefficient(L2: 3, L3: -4, L4: 0, L5: 0, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: -1, xsint: 0, xcos: -1, xcost: 0, ysin: -2, ysint: 0, ycos: -7, ycost: 0, zsin: 1, zsint: 0, zcos: -4, zcost: 0),
    AberrationCoefficient(L2: 0, L3: 2, L4: 0, L5: -2, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: 4, xsint: 0, xcos: -6, xcost: 0, ysin: -5, ysint: 0, ycos: -4, ycost: 0, zsin: -2, zsint: 0, zcos: -2, zcost: 0),
    AberrationCoefficient(L2: 3, L3: -3, L4: 0, L5: 0, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: 0, xsint: 0, xcos: -7, xcost: 0, ysin: -6, ysint: 0, ycos: 0, ycost: 0, zsin: -3, zsint: 0, zcos: 0, zcost: 0),
    AberrationCoefficient(L2: 0, L3: 2, L4: -2, L5: 0, L6: 0, L7: 0, L8: 0, Ldash: 0, D: 0, Mdash: 0, F: 0, xsin: 5, xsint: 0, xcos: -5, xcost: 0, ysin: -4, ysint: 0, ycos: -5, ycost: 0, zsin: -2, zsint: 0, zcos: -2, zcost: 0),
    AberrationCoefficient(L2: 0, L3: 0, L4: 0, L5: 0, L6: 0, L7: 0, L8: 0, Ldash: 1, D: -2, Mdash: 0, F: 0, xsin: 5, xsint: 0, xcos: 0, xcost: 0, ysin: 0, ysint: 0, ycos: -5, ycost: 0, zsin: 0, zsint: 0, zcos: -2, zcost: 0),
]

public enum CAAAberration: Sendable {
    public static func earthVelocity(jd: Double) -> CAA3DCoordinate {
        let t = (jd - 2451545.0) / 36525.0
        let l2 = 3.1761467 + (1021.3285546 * t)
        let l3 = 1.7534703 + (628.3075849 * t)
        let l4 = 6.2034809 + (334.0612431 * t)
        let l5 = 0.5995465 + (52.9690965 * t)
        let l6 = 0.8740168 + (21.3299095 * t)
        let l7 = 5.4812939 + (7.4781599 * t)
        let l8 = 5.3118863 + (3.8133036 * t)
        let ldash = 3.8103444 + (8399.6847337 * t)
        let d = 5.1984667 + (7771.3771486 * t)
        let mdash = 2.3555559 + (8328.6914289 * t)
        let f = 1.6279052 + (8433.4661601 * t)

        var vx = 0.0
        var vy = 0.0
        var vz = 0.0

        for coeff in gAberrationCoeffs {
            let argument = (Double(coeff.L2) * l2) + (Double(coeff.L3) * l3) + (Double(coeff.L4) * l4) + (Double(coeff.L5) * l5) +
                           (Double(coeff.L6) * l6) + (Double(coeff.L7) * l7) + (Double(coeff.L8) * l8) + (Double(coeff.Ldash) * ldash) +
                           (Double(coeff.D) * d) + (Double(coeff.Mdash) * mdash) + (Double(coeff.F) * f)

            let sinArg = sin(argument)
            let cosArg = cos(argument)

            vx += (coeff.xsin + (coeff.xsint * t)) * sinArg + (coeff.xcos + (coeff.xcost * t)) * cosArg
            vy += (coeff.ysin + (coeff.ysint * t)) * sinArg + (coeff.ycos + (coeff.ycost * t)) * cosArg
            vz += (coeff.zsin + (coeff.zsint * t)) * sinArg + (coeff.zcos + (coeff.zcost * t)) * cosArg
        }

        return CAA3DCoordinate(vx, vy, vz)
    }

    public static func EquatorialAberration(_ Alpha: Double, _ Delta: Double, _ JD: Double, _ bHighPrecision: Bool = true) -> CAA2DCoordinate {
        let alphaRad = SphericalTrigonometry.degreesToRadians(Alpha * 15.0)
        let deltaRad = SphericalTrigonometry.degreesToRadians(Delta)

        let cosAlpha = cos(alphaRad)
        let sinAlpha = sin(alphaRad)
        let cosDelta = cos(deltaRad)
        let sinDelta = sin(deltaRad)

        let velocity = earthVelocity(jd: JD)
        let c = 17314463350.0

        let x = SphericalTrigonometry.radiansToHours(((velocity.Y * cosAlpha) - (velocity.X * sinAlpha)) / (c * cosDelta))
        let y = SphericalTrigonometry.radiansToDegrees(-(((((velocity.X * cosAlpha) + (velocity.Y * sinAlpha)) * sinDelta) - (velocity.Z * cosDelta)) / c))

        return CAA2DCoordinate(x, y)
    }

    public static func EclipticAberration(_ Lambda: Double, _ Beta: Double, _ JD: Double, _ bHighPrecision: Bool = true) -> CAA2DCoordinate {
        let t = (JD - 2451545.0) / 36525.0
        let tSquared = t * t
        let e = 0.016708634 - (0.000042037 * t) - (0.0000001267 * tSquared)
        let piDeg = 102.93735 + (1.71946 * t) + (0.00046 * tSquared)
        let k = 20.49552

        // Solar longitude approximation
        let l0 = SphericalTrigonometry.mapTo0To360Range(280.46646 + 36000.76983 * t + 0.0003032 * tSquared)
        let m = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(357.52911 + 35999.05029 * t - 0.0001537 * tSquared))
        let c = (1.914602 - 0.004817 * t - 0.000014 * tSquared) * sin(m) + (0.019993 - 0.000101 * t) * sin(2.0 * m) + 0.000289 * sin(3.0 * m)
        let sunLongitude = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(l0 + c))

        let piRad = SphericalTrigonometry.degreesToRadians(piDeg)
        let lambdaRad = SphericalTrigonometry.degreesToRadians(Lambda)
        let betaRad = SphericalTrigonometry.degreesToRadians(Beta)

        let x = (-k * cos(sunLongitude - lambdaRad) + e * k * cos(piRad - lambdaRad)) / cos(betaRad) / 3600.0
        let y = -k * sin(betaRad) * (sin(sunLongitude - lambdaRad) - e * sin(piRad - lambdaRad)) / 3600.0

        return CAA2DCoordinate(x, y)
    }
}
