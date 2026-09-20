//
//  MeeusSunMoonEngine.swift
//  AstronomyKit
//
//  Pure Swift implementations of Solar, Lunar, and Eclipse algorithms
//  from Jean Meeus' Astronomical Algorithms.
//

import Foundation

// MARK: - CAASun

public enum CAASun: Sendable {

    public static func geometricEclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        return CAACoordinateTransformation.mapTo0To360Range(CAAEarth.eclipticLongitude(jd, bHighPrecision) + 180.0)
    }

    @inlinable
    public static func GeometricEclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        geometricEclipticLongitude(jd, bHighPrecision)
    }

    public static func geometricEclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        return -CAAEarth.eclipticLatitude(jd, bHighPrecision)
    }

    @inlinable
    public static func GeometricEclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        geometricEclipticLatitude(jd, bHighPrecision)
    }

    public static func geometricEclipticLongitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        return CAACoordinateTransformation.mapTo0To360Range(CAAEarth.eclipticLongitudeJ2000(jd, bHighPrecision) + 180.0)
    }

    @inlinable
    public static func GeometricEclipticLongitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        geometricEclipticLongitudeJ2000(jd, bHighPrecision)
    }

    public static func geometricEclipticLatitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        return -CAAEarth.eclipticLatitudeJ2000(jd, bHighPrecision)
    }

    @inlinable
    public static func GeometricEclipticLatitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        geometricEclipticLatitudeJ2000(jd, bHighPrecision)
    }

    public static func geometricFK5EclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        var lon = geometricEclipticLongitude(jd, bHighPrecision)
        let lat = geometricEclipticLatitude(jd, bHighPrecision)
        lon += CAAFK5.correctionInLongitude(longitude: lon, latitude: lat, jd: jd)
        return CAACoordinateTransformation.mapTo0To360Range(lon)
    }

    @inlinable
    public static func GeometricFK5EclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        geometricFK5EclipticLongitude(jd, bHighPrecision)
    }

    public static func geometricFK5EclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        let lon = geometricEclipticLongitude(jd, bHighPrecision)
        var lat = geometricEclipticLatitude(jd, bHighPrecision)
        lat += CAAFK5.correctionInLatitude(longitude: lon, jd: jd)
        return CAACoordinateTransformation.mapToMinus90To90Range(lat)
    }

    @inlinable
    public static func GeometricFK5EclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        geometricFK5EclipticLatitude(jd, bHighPrecision)
    }

    public static func apparentEclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        var lon = geometricFK5EclipticLongitude(jd, bHighPrecision)
        lon += CAACoordinateTransformation.dmsToDegrees(degrees: 0, minutes: 0, seconds: CAANutation.nutationInLongitude(jd: jd))
        let r = CAAEarth.radiusVector(jd, bHighPrecision)
        if bHighPrecision {
            lon -= (0.005775518 * r * CAACoordinateTransformation.dmsToDegrees(degrees: 0, minutes: 0, seconds: variationGeometricEclipticLongitude(jd)))
        } else {
            lon -= CAACoordinateTransformation.dmsToDegrees(degrees: 0, minutes: 0, seconds: 20.4898 / r)
        }
        return CAACoordinateTransformation.mapTo0To360Range(lon)
    }

    @inlinable
    public static func ApparentEclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        apparentEclipticLongitude(jd, bHighPrecision)
    }

    public static func apparentEclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        return geometricFK5EclipticLatitude(jd, bHighPrecision)
    }

    @inlinable
    public static func ApparentEclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        apparentEclipticLatitude(jd, bHighPrecision)
    }

    public static func equatorialRectangularCoordinatesMeanEquinox(_ jd: Double, _ bHighPrecision: Bool = true) -> CAA3DCoordinate {
        let lon = CAACoordinateTransformation.degreesToRadians(geometricFK5EclipticLongitude(jd, bHighPrecision))
        let lat = CAACoordinateTransformation.degreesToRadians(geometricFK5EclipticLatitude(jd, bHighPrecision))
        let r = CAAEarth.radiusVector(jd, bHighPrecision)
        let epsilon = CAACoordinateTransformation.degreesToRadians(CAANutation.meanObliquityOfEcliptic(jd: jd))
        let cosEps = cos(epsilon)
        let sinEps = sin(epsilon)
        let cosLat = cos(lat)
        let sinLat = sin(lat)
        let cosLon = cos(lon)
        let sinLon = sin(lon)

        return CAA3DCoordinate(
            x: r * cosLat * cosLon,
            y: r * (cosLat * sinLon * cosEps - sinLat * sinEps),
            z: r * (cosLat * sinLon * sinEps + sinLat * cosEps)
        )
    }

    @inlinable
    public static func EquatorialRectangularCoordinatesMeanEquinox(_ jd: Double, _ bHighPrecision: Bool = true) -> CAA3DCoordinate {
        equatorialRectangularCoordinatesMeanEquinox(jd, bHighPrecision)
    }

    public static func eclipticRectangularCoordinatesJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> CAA3DCoordinate {
        let lon = CAACoordinateTransformation.degreesToRadians(geometricEclipticLongitudeJ2000(jd, bHighPrecision))
        let lat = CAACoordinateTransformation.degreesToRadians(geometricEclipticLatitudeJ2000(jd, bHighPrecision))
        let r = CAAEarth.radiusVector(jd, bHighPrecision)
        return CAA3DCoordinate(
            x: r * cos(lat) * cos(lon),
            y: r * cos(lat) * sin(lon),
            z: r * sin(lat)
        )
    }

    @inlinable
    public static func EclipticRectangularCoordinatesJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> CAA3DCoordinate {
        eclipticRectangularCoordinatesJ2000(jd, bHighPrecision)
    }

    public static func equatorialRectangularCoordinatesJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> CAA3DCoordinate {
        let val = eclipticRectangularCoordinatesJ2000(jd, bHighPrecision)
        return CAAFK5.convertVSOPToFK5J2000(val)
    }

    @inlinable
    public static func EquatorialRectangularCoordinatesJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> CAA3DCoordinate {
        equatorialRectangularCoordinatesJ2000(jd, bHighPrecision)
    }

    public static func equatorialRectangularCoordinatesB1950(_ jd: Double, _ bHighPrecision: Bool = true) -> CAA3DCoordinate {
        let val = eclipticRectangularCoordinatesJ2000(jd, bHighPrecision)
        return CAAFK5.convertVSOPToFK5B1950(val)
    }

    @inlinable
    public static func EquatorialRectangularCoordinatesB1950(_ jd: Double, _ bHighPrecision: Bool = true) -> CAA3DCoordinate {
        equatorialRectangularCoordinatesB1950(jd, bHighPrecision)
    }

    public static func equatorialRectangularCoordinatesAnyEquinox(_ jd: Double, _ jdEquinox: Double, _ bHighPrecision: Bool = true) -> CAA3DCoordinate {
        let val = equatorialRectangularCoordinatesJ2000(jd, bHighPrecision)
        return CAAFK5.convertVSOPToFK5AnyEquinox(value: val, jdedate: jdEquinox)
    }

    @inlinable
    public static func EquatorialRectangularCoordinatesAnyEquinox(_ jd: Double, _ jdEquinox: Double, _ bHighPrecision: Bool = true) -> CAA3DCoordinate {
        equatorialRectangularCoordinatesAnyEquinox(jd, jdEquinox, bHighPrecision)
    }

    public static func variationGeometricEclipticLongitude(_ jd: Double) -> Double {
        let d = jd - 2451545.0
        let tau = d / 365250.0
        let tau2 = tau * tau
        let tau3 = tau2 * tau

        let deltaLambda = 3548.193 +
            118.568 * sin(CAACoordinateTransformation.degreesToRadians(87.5287 + 359993.7286 * tau)) +
            2.476 * sin(CAACoordinateTransformation.degreesToRadians(85.0561 + 719987.4571 * tau)) +
            1.376 * sin(CAACoordinateTransformation.degreesToRadians(27.8502 + 4452671.1152 * tau)) +
            0.119 * sin(CAACoordinateTransformation.degreesToRadians(73.1375 + 450368.8564 * tau)) +
            0.114 * sin(CAACoordinateTransformation.degreesToRadians(337.2264 + 329644.6718 * tau)) +
            0.086 * sin(CAACoordinateTransformation.degreesToRadians(222.5400 + 659289.3436 * tau)) +
            0.078 * sin(CAACoordinateTransformation.degreesToRadians(162.8136 + 9224659.7915 * tau)) +
            0.054 * sin(CAACoordinateTransformation.degreesToRadians(82.5823 + 1079981.1857 * tau)) +
            0.052 * sin(CAACoordinateTransformation.degreesToRadians(171.5189 + 225184.4282 * tau)) +
            0.034 * sin(CAACoordinateTransformation.degreesToRadians(30.3214 + 4092677.3866 * tau)) +
            0.033 * sin(CAACoordinateTransformation.degreesToRadians(119.8105 + 337181.4711 * tau)) +
            0.023 * sin(CAACoordinateTransformation.degreesToRadians(247.5418 + 299295.6151 * tau)) +
            0.023 * sin(CAACoordinateTransformation.degreesToRadians(325.1526 + 315559.5560 * tau)) +
            0.021 * sin(CAACoordinateTransformation.degreesToRadians(155.1241 + 675553.2846 * tau)) +
            7.311 * tau * sin(CAACoordinateTransformation.degreesToRadians(333.4515 + 359993.7286 * tau)) +
            0.305 * tau * sin(CAACoordinateTransformation.degreesToRadians(330.9814 + 719987.4571 * tau)) +
            0.010 * tau * sin(CAACoordinateTransformation.degreesToRadians(328.5170 + 1079981.1857 * tau)) +
            0.309 * tau2 * sin(CAACoordinateTransformation.degreesToRadians(241.4518 + 359993.7286 * tau)) +
            0.021 * tau2 * sin(CAACoordinateTransformation.degreesToRadians(205.0482 + 719987.4571 * tau)) +
            0.004 * tau2 * sin(CAACoordinateTransformation.degreesToRadians(297.8610 + 4452671.1152 * tau)) +
            0.010 * tau3 * sin(CAACoordinateTransformation.degreesToRadians(154.7066 + 359993.7286 * tau))
        return deltaLambda
    }

    @inlinable
    public static func VariationGeometricEclipticLongitude(_ jd: Double) -> Double {
        variationGeometricEclipticLongitude(jd)
    }
}

// MARK: - CAAEquinoxesAndSolstices

public enum CAAEquinoxesAndSolstices: Sendable {

    public static func northwardEquinox(_ year: Int, _ bHighPrecision: Bool = true) -> Double {
        var jde = 0.0
        if year <= 1000 {
            let y = Double(year) / 1000.0
            jde = 1721139.29189 + 365242.13740 * y + 0.06134 * y * y + 0.00111 * y * y * y - 0.00071 * y * y * y * y
        } else {
            let y = Double(year - 2000) / 1000.0
            jde = 2451623.80984 + 365242.37404 * y + 0.05169 * y * y - 0.00411 * y * y * y - 0.00057 * y * y * y * y
        }
        var correction = 0.0
        repeat {
            let sunLong = CAASun.apparentEclipticLongitude(jde, bHighPrecision)
            correction = 58.0 * sin(CAACoordinateTransformation.degreesToRadians(-sunLong))
            jde += correction
        } while abs(correction) > 0.00001
        return jde
    }

    @inlinable
    public static func NorthwardEquinox(_ year: Int, _ bHighPrecision: Bool = true) -> Double {
        northwardEquinox(year, bHighPrecision)
    }

    public static func northernSolstice(_ year: Int, _ bHighPrecision: Bool = true) -> Double {
        var jde = 0.0
        if year <= 1000 {
            let y = Double(year) / 1000.0
            jde = 1721233.25401 + 365241.72562 * y - 0.05323 * y * y + 0.00907 * y * y * y + 0.00025 * y * y * y * y
        } else {
            let y = Double(year - 2000) / 1000.0
            jde = 2451716.56767 + 365241.62603 * y + 0.00325 * y * y + 0.00888 * y * y * y - 0.00030 * y * y * y * y
        }
        var correction = 0.0
        repeat {
            let sunLong = CAASun.apparentEclipticLongitude(jde, bHighPrecision)
            correction = 58.0 * sin(CAACoordinateTransformation.degreesToRadians(90.0 - sunLong))
            jde += correction
        } while abs(correction) > 0.00001
        return jde
    }

    @inlinable
    public static func NorthernSolstice(_ year: Int, _ bHighPrecision: Bool = true) -> Double {
        northernSolstice(year, bHighPrecision)
    }

    public static func southwardEquinox(_ year: Int, _ bHighPrecision: Bool = true) -> Double {
        var jde = 0.0
        if year <= 1000 {
            let y = Double(year) / 1000.0
            jde = 1721325.70455 + 365242.49558 * y - 0.11677 * y * y - 0.00297 * y * y * y + 0.00074 * y * y * y * y
        } else {
            let y = Double(year - 2000) / 1000.0
            jde = 2451810.21715 + 365242.01767 * y - 0.11575 * y * y + 0.00337 * y * y * y + 0.00078 * y * y * y * y
        }
        var correction = 0.0
        repeat {
            let sunLong = CAASun.apparentEclipticLongitude(jde, bHighPrecision)
            correction = 58.0 * sin(CAACoordinateTransformation.degreesToRadians(180.0 - sunLong))
            jde += correction
        } while abs(correction) > 0.00001
        return jde
    }

    @inlinable
    public static func SouthwardEquinox(_ year: Int, _ bHighPrecision: Bool = true) -> Double {
        southwardEquinox(year, bHighPrecision)
    }

    public static func southernSolstice(_ year: Int, _ bHighPrecision: Bool = true) -> Double {
        var jde = 0.0
        if year <= 1000 {
            let y = Double(year) / 1000.0
            jde = 1721414.39987 + 365242.88257 * y - 0.00769 * y * y - 0.00933 * y * y * y - 0.00006 * y * y * y * y
        } else {
            let y = Double(year - 2000) / 1000.0
            jde = 2451900.05952 + 365242.74049 * y - 0.06223 * y * y - 0.00823 * y * y * y + 0.00032 * y * y * y * y
        }
        var correction = 0.0
        repeat {
            let sunLong = CAASun.apparentEclipticLongitude(jde, bHighPrecision)
            correction = 58.0 * sin(CAACoordinateTransformation.degreesToRadians(270.0 - sunLong))
            jde += correction
        } while abs(correction) > 0.00001
        return jde
    }

    @inlinable
    public static func SouthernSolstice(_ year: Int, _ bHighPrecision: Bool = true) -> Double {
        southernSolstice(year, bHighPrecision)
    }

    public static func lengthOfSpring(_ year: Int, _ bNorthernHemisphere: Bool, _ bHighPrecision: Bool = true) -> Double {
        if bNorthernHemisphere {
            return northernSolstice(year, bHighPrecision) - northwardEquinox(year, bHighPrecision)
        } else {
            return southernSolstice(year, bHighPrecision) - southwardEquinox(year, bHighPrecision)
        }
    }

    @inlinable
    public static func LengthOfSpring(_ year: Int, _ bNorthernHemisphere: Bool, _ bHighPrecision: Bool = true) -> Double {
        lengthOfSpring(year, bNorthernHemisphere, bHighPrecision)
    }

    public static func lengthOfSummer(_ year: Int, _ bNorthernHemisphere: Bool, _ bHighPrecision: Bool = true) -> Double {
        if bNorthernHemisphere {
            return southwardEquinox(year, bHighPrecision) - northernSolstice(year, bHighPrecision)
        } else {
            return northwardEquinox(year + 1, bHighPrecision) - southernSolstice(year, bHighPrecision)
        }
    }

    @inlinable
    public static func LengthOfSummer(_ year: Int, _ bNorthernHemisphere: Bool, _ bHighPrecision: Bool = true) -> Double {
        lengthOfSummer(year, bNorthernHemisphere, bHighPrecision)
    }

    public static func lengthOfAutumn(_ year: Int, _ bNorthernHemisphere: Bool, _ bHighPrecision: Bool = true) -> Double {
        if bNorthernHemisphere {
            return southernSolstice(year, bHighPrecision) - southwardEquinox(year, bHighPrecision)
        } else {
            return northernSolstice(year, bHighPrecision) - northwardEquinox(year, bHighPrecision)
        }
    }

    @inlinable
    public static func LengthOfAutumn(_ year: Int, _ bNorthernHemisphere: Bool, _ bHighPrecision: Bool = true) -> Double {
        lengthOfAutumn(year, bNorthernHemisphere, bHighPrecision)
    }

    public static func lengthOfWinter(_ year: Int, _ bNorthernHemisphere: Bool, _ bHighPrecision: Bool = true) -> Double {
        if bNorthernHemisphere {
            return northwardEquinox(year + 1, bHighPrecision) - southernSolstice(year, bHighPrecision)
        } else {
            return southwardEquinox(year, bHighPrecision) - northernSolstice(year, bHighPrecision)
        }
    }

    @inlinable
    public static func LengthOfWinter(_ year: Int, _ bNorthernHemisphere: Bool, _ bHighPrecision: Bool = true) -> Double {
        lengthOfWinter(year, bNorthernHemisphere, bHighPrecision)
    }
}

// MARK: - CAAPhysicalSun

public enum CAAPhysicalSun: Sendable {

    public static func calculate(_ jd: Double, _ bHighPrecision: Bool = true) -> CAAPhysicalSunDetails {
        let theta = CAACoordinateTransformation.mapTo0To360Range((jd - 2398220.0) * 360.0 / 25.38)
        let I = 7.25
        let K = 73.6667 + (1.3958333 * (jd - 2396758.0) / 36525.0)

        let L = CAAEarth.eclipticLongitude(jd, bHighPrecision)
        let R = CAAEarth.radiusVector(jd, bHighPrecision)
        var sunLong = L + 180.0 - CAACoordinateTransformation.dmsToDegrees(degrees: 0, minutes: 0, seconds: 20.4898 / R)
        var epsilon = CAANutation.trueObliquityOfEcliptic(jd: jd)

        epsilon = CAACoordinateTransformation.degreesToRadians(epsilon)
        sunLong = CAACoordinateTransformation.degreesToRadians(sunLong)
        let kRad = CAACoordinateTransformation.degreesToRadians(K)
        let iRad = CAACoordinateTransformation.degreesToRadians(I)
        let thetaRad = CAACoordinateTransformation.degreesToRadians(theta)

        let x = atan(-cos(sunLong) * tan(epsilon))
        let y = atan(-cos(sunLong - kRad) * tan(iRad))

        var details = CAAPhysicalSunDetails()
        details.P = CAACoordinateTransformation.radiansToDegrees(x + y)
        details.B0 = CAACoordinateTransformation.radiansToDegrees(asin(sin(sunLong - kRad) * sin(iRad)))
        let sunLongMinusK = sunLong - kRad
        let eta = atan2(-sin(sunLongMinusK) * cos(iRad), -cos(sunLongMinusK))
        details.L0 = CAACoordinateTransformation.mapTo0To360Range(CAACoordinateTransformation.radiansToDegrees(eta - thetaRad))
        return details
    }

    @inlinable
    public static func Calculate(_ jd: Double, _ bHighPrecision: Bool = true) -> CAAPhysicalSunDetails {
        calculate(jd, bHighPrecision)
    }

    public static func timeOfStartOfRotation(_ c: Int) -> Double {
        let cD = Double(c)
        var jed = 2398140.2270 + 27.2752316 * cD
        let m = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(281.96 + 26.882476 * cD))
        let twoM = 2.0 * m
        jed += (0.1454 * sin(m) - 0.0085 * sin(twoM) - 0.0141 * cos(twoM))
        return jed
    }

    @inlinable
    public static func TimeOfStartOfRotation(_ c: Int) -> Double {
        timeOfStartOfRotation(c)
    }
}

// MARK: - CAAMoon

public enum CAAMoon: Sendable {

    private static let dmmf1: [(d: Int, m: Int, mdash: Int, f: Int)] = [
        (0, 0, 1, 0),
        (2, 0, -1, 0),
        (2, 0, 0, 0),
        (0, 0, 2, 0),
        (0, 1, 0, 0),
        (0, 0, 0, 2),
        (2, 0, -2, 0),
        (2, -1, -1, 0),
        (2, 0, 1, 0),
        (2, -1, 0, 0),
        (0, 1, -1, 0),
        (1, 0, 0, 0),
        (0, 1, 1, 0),
        (2, 0, 0, -2),
        (0, 0, 1, 2),
        (0, 0, 1, -2),
        (4, 0, -1, 0),
        (0, 0, 3, 0),
        (4, 0, -2, 0),
        (2, 1, -1, 0),
        (2, 1, 0, 0),
        (1, 0, -1, 0),
        (1, 1, 0, 0),
        (2, -1, 1, 0),
        (2, 0, 2, 0),
        (4, 0, 0, 0),
        (2, 0, -3, 0),
        (0, 1, -2, 0),
        (2, 0, -1, 2),
        (2, -1, -2, 0),
        (1, 0, 1, 0),
        (2, -2, 0, 0),
        (0, 1, 2, 0),
        (0, 2, 0, 0),
        (2, -2, -1, 0),
        (2, 0, 1, -2),
        (2, 0, 0, 2),
        (4, -1, -1, 0),
        (0, 0, 2, 2),
        (3, 0, -1, 0),
        (2, 1, 1, 0),
        (4, -1, -2, 0),
        (0, 2, -1, 0),
        (2, 2, -1, 0),
        (2, 1, -2, 0),
        (2, -1, 0, -2),
        (4, 0, 1, 0),
        (0, 0, 4, 0),
        (4, -1, 0, 0),
        (1, 0, -2, 0),
        (2, 1, 0, -2),
        (0, 0, 2, -2),
        (1, 1, 1, 0),
        (3, 0, -2, 0),
        (4, 0, -3, 0),
        (2, -1, 2, 0),
        (0, 2, 1, 0),
        (1, 1, -1, 0),
        (2, 0, 3, 0),
        (2, 0, -1, -2),
    ]

    private static let lCoeffs: [(a: Double, b: Double)] = [
        (6288774, -20905355),
        (1274027, -3699111),
        (658314, -2955968),
        (213618, -569925),
        (-185116, 48888),
        (-114332, -3149),
        (58793, 246158),
        (57066, -152138),
        (53322, -170733),
        (45758, -204586),
        (-40923, -129620),
        (-34720, 108743),
        (-30383, 104755),
        (15327, 10321),
        (-12528, 0),
        (10980, 79661),
        (10675, -34782),
        (10034, -23210),
        (8548, -21636),
        (-7888, 24208),
        (-6766, 30824),
        (-5163, -8379),
        (4987, -16675),
        (4036, -12831),
        (3994, -10445),
        (3861, -11650),
        (3665, 14403),
        (-2689, -7003),
        (-2602, 0),
        (2390, 10056),
        (-2348, 6322),
        (2236, -9884),
        (-2120, 5751),
        (-2069, 0),
        (2048, -4950),
        (-1773, 4130),
        (-1595, 0),
        (1215, -3958),
        (-1110, 0),
        (-892, 3258),
        (-810, 2616),
        (759, -1897),
        (-713, -2117),
        (-700, 2354),
        (691, 0),
        (596, 0),
        (549, -1423),
        (537, -1117),
        (520, -1571),
        (-487, -1739),
        (-399, 0),
        (-381, -4421),
        (351, 0),
        (-340, 0),
        (330, 0),
        (327, 0),
        (-323, 1165),
        (299, 0),
        (294, 0),
        (0, 8752),
    ]

    private static let dmmf3: [(d: Int, m: Int, mdash: Int, f: Int)] = [
        (0, 0, 0, 1),
        (0, 0, 1, 1),
        (0, 0, 1, -1),
        (2, 0, 0, -1),
        (2, 0, -1, 1),
        (2, 0, -1, -1),
        (2, 0, 0, 1),
        (0, 0, 2, 1),
        (2, 0, 1, -1),
        (0, 0, 2, -1),
        (2, -1, 0, -1),
        (2, 0, -2, -1),
        (2, 0, 1, 1),
        (2, 1, 0, -1),
        (2, -1, -1, 1),
        (2, -1, 0, 1),
        (2, -1, -1, -1),
        (0, 1, -1, -1),
        (4, 0, -1, -1),
        (0, 1, 0, 1),
        (0, 0, 0, 3),
        (0, 1, -1, 1),
        (1, 0, 0, 1),
        (0, 1, 1, 1),
        (0, 1, 1, -1),
        (0, 1, 0, -1),
        (1, 0, 0, -1),
        (0, 0, 3, 1),
        (4, 0, 0, -1),
        (4, 0, -1, 1),
        (0, 0, 1, -3),
        (4, 0, -2, 1),
        (2, 0, 0, -3),
        (2, 0, 2, -1),
        (2, -1, 1, -1),
        (2, 0, -2, 1),
        (0, 0, 3, -1),
        (2, 0, 2, 1),
        (2, 0, -3, -1),
        (2, 1, -1, 1),
        (2, 1, 0, 1),
        (4, 0, 0, 1),
        (2, -1, 1, 1),
        (2, -2, 0, -1),
        (0, 0, 1, 3),
        (2, 1, 1, -1),
        (1, 1, 0, -1),
        (1, 1, 0, 1),
        (0, 1, -2, -1),
        (2, 1, -1, -1),
        (1, 0, 1, 1),
        (2, -1, -2, -1),
        (0, 1, 2, 1),
        (4, 0, -2, -1),
        (4, -1, -1, -1),
        (1, 0, 1, -1),
        (4, 0, 1, -1),
        (1, 0, -1, -1),
        (4, -1, 0, -1),
        (2, -2, 0, 1),
    ]

    private static let bCoeffs: [Double] = [
        5128122,
        280602,
        277693,
        173237,
        55413,
        46271,
        32573,
        17198,
        9266,
        8822,
        8216,
        4324,
        4200,
        -3359,
        2463,
        2211,
        2065,
        -1870,
        1828,
        -1794,
        -1749,
        -1565,
        -1491,
        -1475,
        -1410,
        -1344,
        -1335,
        1107,
        1021,
        833,
        777,
        671,
        607,
        596,
        491,
        -451,
        439,
        422,
        421,
        -366,
        -351,
        331,
        315,
        302,
        -283,
        -229,
        223,
        223,
        -220,
        -220,
        -185,
        181,
        -177,
        176,
        166,
        -164,
        132,
        -119,
        115,
        107,
    ]

    public static func meanLongitude(_ jd: Double) -> Double {
        let t = (jd - 2451545.0) / 36525.0
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t
        return CAACoordinateTransformation.mapTo0To360Range(218.3164477 + 481267.88123421 * t - 0.0015786 * t2 + t3 / 538841.0 - t4 / 65194000.0)
    }

    @inlinable
    public static func MeanLongitude(_ jd: Double) -> Double {
        meanLongitude(jd)
    }

    public static func meanElongation(_ jd: Double) -> Double {
        let t = (jd - 2451545.0) / 36525.0
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t
        return CAACoordinateTransformation.mapTo0To360Range(297.8501921 + 445267.1114034 * t - 0.0018819 * t2 + t3 / 545868.0 - t4 / 113065000.0)
    }

    @inlinable
    public static func MeanElongation(_ jd: Double) -> Double {
        meanElongation(jd)
    }

    public static func meanAnomaly(_ jd: Double) -> Double {
        let t = (jd - 2451545.0) / 36525.0
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t
        return CAACoordinateTransformation.mapTo0To360Range(134.9633964 + 477198.8675055 * t + 0.0087414 * t2 + t3 / 69699.0 - t4 / 14712000.0)
    }

    @inlinable
    public static func MeanAnomaly(_ jd: Double) -> Double {
        meanAnomaly(jd)
    }

    public static func argumentOfLatitude(_ jd: Double) -> Double {
        let t = (jd - 2451545.0) / 36525.0
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t
        return CAACoordinateTransformation.mapTo0To360Range(93.2720950 + 483202.0175233 * t - 0.0036539 * t2 - t3 / 3526000.0 + t4 / 863310000.0)
    }

    @inlinable
    public static func ArgumentOfLatitude(_ jd: Double) -> Double {
        argumentOfLatitude(jd)
    }

    public static func meanLongitudeAscendingNode(_ jd: Double) -> Double {
        let t = (jd - 2451545.0) / 36525.0
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t
        return CAACoordinateTransformation.mapTo0To360Range(125.0445479 - 1934.1362891 * t + 0.0020754 * t2 + t3 / 467441.0 - t4 / 60616000.0)
    }

    @inlinable
    public static func MeanLongitudeAscendingNode(_ jd: Double) -> Double {
        meanLongitudeAscendingNode(jd)
    }

    public static func meanLongitudePerigee(_ jd: Double) -> Double {
        let t = (jd - 2451545.0) / 36525.0
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t
        return CAACoordinateTransformation.mapTo0To360Range(83.3532465 + 4069.0137287 * t - 0.0103200 * t2 - t3 / 80053.0 + t4 / 18999000.0)
    }

    @inlinable
    public static func MeanLongitudePerigee(_ jd: Double) -> Double {
        meanLongitudePerigee(jd)
    }

    public static func trueLongitudeAscendingNode(_ jd: Double) -> Double {
        var node = meanLongitudeAscendingNode(jd)
        let d = CAACoordinateTransformation.degreesToRadians(meanElongation(jd))
        let m = CAACoordinateTransformation.degreesToRadians(CAAEarth.sunMeanAnomaly(jd))
        let mdash = CAACoordinateTransformation.degreesToRadians(meanAnomaly(jd))
        let f = CAACoordinateTransformation.degreesToRadians(argumentOfLatitude(jd))

        node -= 1.4979 * sin(2.0 * (d - f))
        node -= 0.1500 * sin(m)
        node -= 0.1226 * sin(2.0 * d)
        node += 0.1176 * sin(2.0 * f)
        node -= 0.0801 * sin(2.0 * (mdash - f))
        return CAACoordinateTransformation.mapTo0To360Range(node)
    }

    @inlinable
    public static func TrueLongitudeAscendingNode(_ jd: Double) -> Double {
        trueLongitudeAscendingNode(jd)
    }

    public static func eclipticLongitude(_ jd: Double) -> Double {
        let ldashDeg = meanLongitude(jd)
        let ldash = CAACoordinateTransformation.degreesToRadians(ldashDeg)
        let d = CAACoordinateTransformation.degreesToRadians(meanElongation(jd))
        let m = CAACoordinateTransformation.degreesToRadians(CAAEarth.sunMeanAnomaly(jd))
        let mdash = CAACoordinateTransformation.degreesToRadians(meanAnomaly(jd))
        let f = CAACoordinateTransformation.degreesToRadians(argumentOfLatitude(jd))

        let e = CAAEarth.eccentricity(jd)
        let e2 = e * e
        let t = (jd - 2451545.0) / 36525.0

        let a1 = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(119.75 + 131.849 * t))
        let a2 = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(53.09 + 479264.290 * t))

        var sigmaL = 0.0
        for i in 0..<dmmf1.count {
            let term = dmmf1[i]
            var s = lCoeffs[i].a * sin(Double(term.d) * d + Double(term.m) * m + Double(term.mdash) * mdash + Double(term.f) * f)
            if term.m == 1 || term.m == -1 {
                s *= e
            } else if term.m == 2 || term.m == -2 {
                s *= e2
            }
            sigmaL += s
        }

        sigmaL += 3958.0 * sin(a1)
        sigmaL += 1962.0 * sin(ldash - f)
        sigmaL += 318.0 * sin(a2)

        let nutationInLong = CAANutation.nutationInLongitude(jd: jd)
        return CAACoordinateTransformation.mapTo0To360Range(ldashDeg + (sigmaL / 1_000_000.0) + (nutationInLong / 3600.0))
    }

    @inlinable
    public static func EclipticLongitude(_ jd: Double) -> Double {
        eclipticLongitude(jd)
    }

    public static func radiusVector(_ jd: Double) -> Double {
        let d = CAACoordinateTransformation.degreesToRadians(meanElongation(jd))
        let m = CAACoordinateTransformation.degreesToRadians(CAAEarth.sunMeanAnomaly(jd))
        let mdash = CAACoordinateTransformation.degreesToRadians(meanAnomaly(jd))
        let f = CAACoordinateTransformation.degreesToRadians(argumentOfLatitude(jd))
        let e = CAAEarth.eccentricity(jd)
        let e2 = e * e

        var sigmaR = 0.0
        for i in 0..<dmmf1.count {
            let term = dmmf1[i]
            var s = lCoeffs[i].b * cos(Double(term.d) * d + Double(term.m) * m + Double(term.mdash) * mdash + Double(term.f) * f)
            if term.m == 1 || term.m == -1 {
                s *= e
            } else if term.m == 2 || term.m == -2 {
                s *= e2
            }
            sigmaR += s
        }
        return 385000.56 + (sigmaR / 1000.0)
    }

    @inlinable
    public static func RadiusVector(_ jd: Double) -> Double {
        radiusVector(jd)
    }

    public static func eclipticLatitude(_ jd: Double) -> Double {
        let ldash = CAACoordinateTransformation.degreesToRadians(meanLongitude(jd))
        let d = CAACoordinateTransformation.degreesToRadians(meanElongation(jd))
        let m = CAACoordinateTransformation.degreesToRadians(CAAEarth.sunMeanAnomaly(jd))
        let mdash = CAACoordinateTransformation.degreesToRadians(meanAnomaly(jd))
        let f = CAACoordinateTransformation.degreesToRadians(argumentOfLatitude(jd))

        let e = CAAEarth.eccentricity(jd)
        let e2 = e * e
        let t = (jd - 2451545.0) / 36525.0

        let a1 = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(119.75 + 131.849 * t))
        let a3 = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(313.45 + 481266.484 * t))

        var sigmaB = 0.0
        for i in 0..<dmmf3.count {
            let term = dmmf3[i]
            var s = bCoeffs[i] * sin(Double(term.d) * d + Double(term.m) * m + Double(term.mdash) * mdash + Double(term.f) * f)
            if term.m == 1 || term.m == -1 {
                s *= e
            } else if term.m == 2 || term.m == -2 {
                s *= e2
            }
            sigmaB += s
        }

        sigmaB -= 2235.0 * sin(ldash)
        sigmaB += 382.0 * sin(a3)
        sigmaB += 175.0 * sin(a1 - f)
        sigmaB += 175.0 * sin(a1 + f)
        sigmaB += 127.0 * sin(ldash - mdash)
        sigmaB -= 115.0 * sin(ldash + mdash)

        return sigmaB / 1_000_000.0
    }

    @inlinable
    public static func EclipticLatitude(_ jd: Double) -> Double {
        eclipticLatitude(jd)
    }

    @inlinable
    public static func radiusVectorToHorizontalParallax(_ radiusVector: Double) -> Double {
        return CAACoordinateTransformation.radiansToDegrees(asin(6378.14 / radiusVector))
    }

    @inlinable
    public static func RadiusVectorToHorizontalParallax(_ radiusVector: Double) -> Double {
        radiusVectorToHorizontalParallax(radiusVector)
    }

    @inlinable
    public static func horizontalParallaxToRadiusVector(_ parallax: Double) -> Double {
        return 6378.14 / sin(CAACoordinateTransformation.degreesToRadians(parallax))
    }

    @inlinable
    public static func HorizontalParallaxToRadiusVector(_ parallax: Double) -> Double {
        horizontalParallaxToRadiusVector(parallax)
    }
}

// MARK: - CAAMoonPhases

public enum CAAMoonPhases: Sendable {

    @inlinable
    public static func k(_ year: Double) -> Double {
        return 12.3685 * (year - 2000.0)
    }

    @inlinable
    public static func K(_ year: Double) -> Double {
        k(year)
    }

    @inlinable
    public static func meanPhase(_ k: Double) -> Double {
        let t = k / 1236.85
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t
        return 2451550.09766 + 29.530588861 * k + 0.00015437 * t2 - 0.000000150 * t3 + 0.00000000073 * t4
    }

    @inlinable
    public static func MeanPhase(_ k: Double) -> Double {
        meanPhase(k)
    }

    public static func truePhase(_ k: Double) -> Double {
        let jd = meanPhase(k)
        let t = k / 1236.85
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t
        let e = 1.0 - 0.002516 * t - 0.0000074 * t2
        let e2 = e * e

        let m = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(2.5534 + 29.10535670 * k - 0.0000014 * t2 - 0.00000011 * t3))
        let mdash = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(201.5643 + 385.81693528 * k + 0.0107582 * t2 + 0.00001238 * t3 - 0.000000058 * t4))
        let f = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(160.7108 + 390.67050284 * k - 0.0016118 * t2 - 0.00000227 * t3 + 0.000000011 * t4))
        let omega = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(124.7746 - 1.56375588 * k + 0.0020672 * t2 + 0.00000215 * t3))

        let a1 = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(299.77 + 0.107408 * k - 0.009173 * t2))
        let a2 = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(251.88 + 0.016321 * k))
        let a3 = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(251.83 + 26.651886 * k))
        let a4 = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(349.42 + 36.412478 * k))
        let a5 = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(84.66 + 18.206239 * k))
        let a6 = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(141.74 + 53.303771 * k))
        let a7 = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(207.14 + 2.453732 * k))
        let a8 = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(154.84 + 7.306860 * k))
        let a9 = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(34.52 + 27.261239 * k))
        let a10 = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(207.19 + 0.121824 * k))
        let a11 = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(291.34 + 1.844379 * k))
        let a12 = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(161.72 + 24.198154 * k))
        let a13 = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(239.56 + 25.513099 * k))
        let a14 = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(331.55 + 3.592518 * k))

        var intPart = 0.0
        let frac = modf(k, &intPart)
        var phase = Int(round(frac * 4.0))
        if phase < 0 { phase += 4 }

        var deltaJD = 0.0
        if phase == 0 { // New Moon
            deltaJD = -0.40720 * sin(mdash) +
                0.17241 * e * sin(m) +
                0.01608 * sin(2.0 * mdash) +
                0.01039 * sin(2.0 * f) +
                0.00739 * e * sin(mdash - m) -
                0.00514 * e * sin(mdash + m) +
                0.00208 * e2 * sin(2.0 * m) -
                0.00111 * sin(mdash - 2.0 * f) -
                0.00057 * sin(mdash + 2.0 * f) +
                0.00056 * e * sin(2.0 * mdash + m) -
                0.00042 * sin(3.0 * mdash) +
                0.00042 * e * sin(m + 2.0 * f) +
                0.00038 * e * sin(m - 2.0 * f) -
                0.00024 * e * sin(2.0 * mdash - m) -
                0.00017 * sin(omega) -
                0.00007 * sin(mdash + 2.0 * m) +
                0.00004 * sin(2.0 * (mdash - f)) +
                0.00004 * sin(3.0 * m) +
                0.00003 * sin(mdash + m - 2.0 * f) +
                0.00003 * sin(2.0 * (mdash + f)) -
                0.00003 * sin(mdash + m + 2.0 * f) +
                0.00003 * sin(mdash - m + 2.0 * f) -
                0.00002 * sin(mdash - m - 2.0 * f) -
                0.00002 * sin(3.0 * mdash + m) +
                0.00002 * sin(4.0 * mdash)
        } else if phase == 2 { // Full Moon
            deltaJD = -0.40614 * sin(mdash) +
                0.17302 * e * sin(m) +
                0.01614 * sin(2.0 * mdash) +
                0.01043 * sin(2.0 * f) +
                0.00734 * e * sin(mdash - m) -
                0.00514 * e * sin(mdash + m) +
                0.00209 * e2 * sin(2.0 * m) -
                0.00111 * sin(mdash - 2.0 * f) -
                0.00057 * sin(mdash + 2.0 * f) +
                0.00056 * e * sin(2.0 * mdash + m) -
                0.00042 * sin(3.0 * mdash) +
                0.00042 * e * sin(m + 2.0 * f) +
                0.00038 * e * sin(m - 2.0 * f) -
                0.00024 * e * sin(2.0 * mdash - m) -
                0.00017 * sin(omega) -
                0.00007 * sin(mdash + 2.0 * m) +
                0.00004 * sin(2.0 * (mdash - f)) +
                0.00004 * sin(3.0 * m) +
                0.00003 * sin(mdash + m - 2.0 * f) +
                0.00003 * sin(2.0 * (mdash + f)) -
                0.00003 * sin(mdash + m + 2.0 * f) +
                0.00003 * sin(mdash - m + 2.0 * f) -
                0.00002 * sin(mdash - m - 2.0 * f) -
                0.00002 * sin(3.0 * mdash + m) +
                0.00002 * sin(4.0 * mdash)
        } else { // First / Last Quarter
            deltaJD = -0.62801 * sin(mdash) +
                0.17172 * e * sin(m) -
                0.01183 * e * sin(mdash + m) +
                0.00862 * sin(2.0 * mdash) +
                0.00804 * sin(2.0 * f) +
                0.00454 * e * sin(mdash - m) +
                0.00204 * e2 * sin(2.0 * m) -
                0.00180 * sin(mdash - 2.0 * f) -
                0.00070 * sin(mdash + 2.0 * f) -
                0.00040 * sin(3.0 * mdash) -
                0.00034 * e * sin(2.0 * mdash - m) +
                0.00032 * e * sin(m + 2.0 * f) +
                0.00032 * e * sin(m - 2.0 * f) -
                0.00028 * e2 * sin(mdash + 2.0 * m) +
                0.00027 * e * sin(2.0 * mdash + m) -
                0.00017 * sin(omega) -
                0.00005 * sin(mdash - m - 2.0 * f) +
                0.00004 * sin(2.0 * (mdash + f)) -
                0.00004 * sin(mdash + m + 2.0 * f) +
                0.00004 * sin(mdash - 2.0 * m) +
                0.00003 * sin(mdash + m - 2.0 * f) +
                0.00003 * sin(3.0 * m) +
                0.00002 * sin(2.0 * (mdash - f)) +
                0.00002 * sin(mdash - m + 2.0 * f) -
                0.00002 * sin(3.0 * mdash + m)
            if phase == 1 { // First Quarter
                deltaJD += 0.00306 - 0.00038 * e * cos(m) + 0.00026 * cos(mdash) - 0.00002 * cos(mdash - m) + 0.00002 * cos(mdash + m) + 0.00002 * cos(2.0 * f)
            } else { // Last Quarter
                deltaJD -= 0.00306 - 0.00038 * e * cos(m) + 0.00026 * cos(mdash) - 0.00002 * cos(mdash - m) + 0.00002 * cos(mdash + m) + 0.00002 * cos(2.0 * f)
            }
        }

        let additions = 0.000325 * sin(a1) +
            0.000165 * sin(a2) +
            0.000164 * sin(a3) +
            0.000126 * sin(a4) +
            0.000110 * sin(a5) +
            0.000062 * sin(a6) +
            0.000060 * sin(a7) +
            0.000056 * sin(a8) +
            0.000047 * sin(a9) +
            0.000042 * sin(a10) +
            0.000040 * sin(a11) +
            0.000037 * sin(a12) +
            0.000035 * sin(a13) +
            0.000023 * sin(a14)

        return jd + deltaJD + additions
    }

    @inlinable
    public static func TruePhase(_ k: Double) -> Double {
        truePhase(k)
    }
}

// MARK: - CAAMoonNodes

public enum CAAMoonNodes: Sendable {

    @inlinable
    public static func k(_ year: Double) -> Double {
        return 13.4223 * (year - 2000.05)
    }

    @inlinable
    public static func K(_ year: Double) -> Double {
        k(year)
    }

    public static func passageThroNode(_ k: Double) -> Double {
        let t = k / 1342.23
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t

        let d = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(183.6380 + 331.73735682 * k + 0.0014852 * t2 + 0.00000209 * t3 - 0.000000010 * t4))
        let m = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(17.4006 + 26.82037250 * k + 0.0001186 * t2 + 0.00000006 * t3))
        let mdash = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(38.3776 + 355.52747313 * k + 0.0123499 * t2 + 0.000014627 * t3 - 0.000000069 * t4))
        let omega = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(123.9767 - 1.44098956 * k + 0.0020608 * t2 + 0.00000214 * t3 - 0.000000016 * t4))
        let v = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(299.75 + 132.85 * t - 0.009173 * t2))
        let p = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(CAACoordinateTransformation.radiansToDegrees(omega) + 272.75 - 2.3 * t))
        let e = 1.0 - 0.002516 * t - 0.0000074 * t2

        let twoD = 2.0 * d
        let fourD = 4.0 * d
        let twoMdash = 2.0 * mdash

        let jd = 2451565.1619 + 27.212220817 * k + 0.0002762 * t2 + 0.000000021 * t3 - 0.000000000088 * t4 -
            0.4721 * sin(mdash) -
            0.1649 * sin(twoD) -
            0.0868 * sin(twoD - mdash) +
            0.0084 * sin(twoD + mdash) -
            e * 0.0083 * sin(twoD - m) -
            e * 0.0039 * sin(twoD - m - mdash) +
            0.0034 * sin(twoMdash) -
            0.0031 * sin(twoD - twoMdash) +
            e * 0.0030 * sin(twoD + m) +
            e * 0.0028 * sin(m - mdash) +
            e * 0.0026 * sin(m) +
            0.0025 * sin(fourD) +
            0.0024 * sin(d) +
            e * 0.0022 * sin(m + mdash) +
            0.0017 * sin(omega) +
            0.0014 * sin(fourD - mdash) +
            e * 0.0005 * sin(twoD + m - mdash) +
            e * 0.0004 * sin(twoD - m + mdash) -
            e * 0.0003 * sin(twoD - 2.0 * m) +
            e * 0.0003 * sin(fourD - m) +
            0.0003 * sin(v) +
            0.0003 * sin(p)
        return jd
    }

    @inlinable
    public static func PassageThroNode(_ k: Double) -> Double {
        passageThroNode(k)
    }
}

// MARK: - CAAMoonPerigeeApogee

public enum CAAMoonPerigeeApogee: Sendable {

    private static let paCoeffs1: [(d: Double, m: Double, f: Double, c: Double, t: Double)] = [
        (2, 0, 0, -1.6769, 0),
        (4, 0, 0, 0.4589, 0),
        (6, 0, 0, -0.1856, 0),
        (8, 0, 0, 0.0883, 0),
        (2, -1, 0, -0.0773, 0.00019),
        (0, 1, 0, 0.0502, -0.00013),
        (10, 0, 0, -0.0460, 0),
        (4, -1, 0, 0.0422, -0.00011),
        (6, -1, 0, -0.0256, 0),
        (12, 0, 0, 0.0253, 0),
        (1, 0, 0, 0.0237, 0),
        (8, -1, 0, 0.0162, 0),
        (14, 0, 0, -0.0145, 0),
        (0, 0, 2, 0.0129, 0),
        (3, 0, 0, -0.0112, 0),
        (10, -1, 0, -0.0104, 0),
        (16, 0, 0, 0.0086, 0),
        (12, -1, 0, 0.0069, 0),
        (5, 0, 0, 0.0066, 0),
        (2, 0, 2, -0.0053, 0),
        (18, 0, 0, -0.0052, 0),
        (14, -1, 0, -0.0046, 0),
        (7, 0, 0, -0.0041, 0),
        (2, 1, 0, 0.0040, 0),
        (20, 0, 0, 0.0032, 0),
        (1, 1, 0, -0.0032, 0),
        (16, -1, 0, 0.0031, 0),
        (4, 1, 0, -0.0029, 0),
        (9, 0, 0, 0.0027, 0),
        (4, 0, 2, 0.0027, 0),
        (2, -2, 0, -0.0027, 0),
        (4, -2, 0, 0.0024, 0),
        (6, -2, 0, -0.0021, 0),
        (22, 0, 0, -0.0021, 0),
        (18, -1, 0, -0.0021, 0),
        (6, 1, 0, 0.0019, 0),
        (11, 0, 0, -0.0018, 0),
        (8, 1, 0, -0.0014, 0),
        (4, 0, -2, -0.0014, 0),
        (6, 0, 2, -0.0014, 0),
        (3, 1, 0, 0.0014, 0),
        (5, 1, 0, -0.0014, 0),
        (13, 0, 0, 0.0013, 0),
        (20, -1, 0, 0.0013, 0),
        (3, 2, 0, 0.0011, 0),
        (4, -2, 2, -0.0011, 0),
        (1, 2, 0, -0.0010, 0),
        (22, -1, 0, -0.0009, 0),
        (0, 0, 4, -0.0008, 0),
        (6, 0, -2, 0.0008, 0),
        (2, 1, -2, 0.0008, 0),
        (0, 2, 0, 0.0007, 0),
        (0, -1, 2, 0.0007, 0),
        (2, 0, 4, 0.0007, 0),
        (0, -2, 2, -0.0006, 0),
        (2, 2, -2, -0.0006, 0),
        (24, 0, 0, 0.0006, 0),
        (4, 0, -4, 0.0005, 0),
        (2, 2, 0, 0.0005, 0),
        (1, -1, 0, -0.0004, 0),
    ]

    private static let paCoeffs2: [(d: Double, m: Double, f: Double, c: Double, t: Double)] = [
        (2, 0, 0, 0.4392, 0),
        (4, 0, 0, 0.0684, 0),
        (0, 1, 0, 0.0456, -0.00011),
        (2, -1, 0, 0.0426, -0.00011),
        (0, 0, 2, 0.0212, 0),
        (1, 0, 0, -0.0189, 0),
        (6, 0, 0, 0.0144, 0),
        (4, -1, 0, 0.0113, 0),
        (2, 0, 2, 0.0047, 0),
        (1, 1, 0, 0.0036, 0),
        (8, 0, 0, 0.0035, 0),
        (6, -1, 0, 0.0034, 0),
        (2, 0, -2, -0.0034, 0),
        (2, -2, 0, 0.0022, 0),
        (3, 0, 0, -0.0017, 0),
        (4, 0, 2, 0.0013, 0),
        (8, -1, 0, 0.0011, 0),
        (4, -2, 0, 0.0010, 0),
        (10, 0, 0, 0.0009, 0),
        (3, 1, 0, 0.0007, 0),
        (0, 2, 0, 0.0006, 0),
        (2, 1, 0, 0.0005, 0),
        (2, 2, 0, 0.0005, 0),
        (6, 0, 2, 0.0004, 0),
        (6, -2, 0, 0.0004, 0),
        (10, -1, 0, 0.0004, 0),
        (5, 0, 0, -0.0004, 0),
        (4, 0, -2, -0.0004, 0),
        (0, 1, 2, 0.0003, 0),
        (12, 0, 0, 0.0003, 0),
        (2, -1, 2, 0.0003, 0),
        (1, -1, 0, -0.0003, 0),
    ]

    private static let paCoeffs3: [(d: Double, m: Double, f: Double, c: Double, t: Double)] = [
        (2, 0, 0, 63.224, 0),
        (4, 0, 0, -6.990, 0),
        (2, -1, 0, 2.834, -0.0071),
        (6, 0, 0, 1.927, 0),
        (1, 0, 0, -1.263, 0),
        (8, 0, 0, -0.702, 0),
        (0, 1, 0, 0.696, -0.0017),
        (0, 0, 2, -0.690, 0),
        (4, -1, 0, -0.629, 0.0016),
        (2, 0, -2, -0.392, 0),
        (10, 0, 0, 0.297, 0),
        (6, -1, 0, 0.260, 0),
        (3, 0, 0, 0.201, 0),
        (2, 1, 0, -0.161, 0),
        (1, 1, 0, 0.157, 0),
        (12, 0, 0, -0.138, 0),
        (8, -1, 0, -0.127, 0),
        (2, 0, 2, 0.104, 0),
        (2, -2, 0, 0.104, 0),
        (5, 0, 0, -0.079, 0),
        (14, 0, 0, 0.068, 0),
        (10, -1, 0, 0.067, 0),
        (4, 1, 0, 0.054, 0),
        (12, -1, 0, -0.038, 0),
        (4, -2, 0, -0.038, 0),
        (7, 0, 0, 0.037, 0),
        (4, 0, 2, -0.037, 0),
        (16, 0, 0, -0.035, 0),
        (3, 1, 0, -0.030, 0),
        (1, -1, 0, 0.029, 0),
        (6, 1, 0, -0.025, 0),
        (0, 2, 0, 0.023, 0),
        (14, -1, 0, 0.023, 0),
        (2, 2, 0, -0.023, 0),
        (6, -2, 0, 0.022, 0),
        (2, -1, -2, -0.021, 0),
        (9, 0, 0, -0.020, 0),
        (18, 0, 0, 0.019, 0),
        (6, 0, 2, 0.017, 0),
        (0, -1, 2, 0.014, 0),
        (16, -1, 0, -0.014, 0),
        (4, 0, -2, 0.013, 0),
        (8, 1, 0, 0.012, 0),
        (11, 0, 0, 0.011, 0),
        (5, 1, 0, 0.010, 0),
        (20, 0, 0, -0.010, 0),
    ]

    private static let paCoeffs4: [(d: Double, m: Double, f: Double, c: Double, t: Double)] = [
        (2, 0, 0, -9.147, 0),
        (1, 0, 0, -0.841, 0),
        (0, 0, 2, 0.697, 0),
        (0, 1, 0, -0.656, 0.0016),
        (4, 0, 0, 0.355, 0),
        (2, -1, 0, 0.159, 0),
        (1, 1, 0, 0.127, 0),
        (4, -1, 0, 0.065, 0),
        (6, 0, 0, 0.052, 0),
        (2, 1, 0, 0.043, 0),
        (2, 0, 2, 0.031, 0),
        (2, 0, -2, -0.023, 0),
        (2, -2, 0, 0.022, 0),
        (2, 2, 0, 0.019, 0),
        (0, 2, 0, -0.016, 0),
        (6, -1, 0, 0.014, 0),
        (8, 0, 0, 0.010, 0),
    ]

    @inlinable
    public static func k(_ year: Double) -> Double {
        return 13.2555 * (year - 1999.97)
    }

    @inlinable
    public static func K(_ year: Double) -> Double {
        k(year)
    }

    @inlinable
    public static func meanPerigee(_ k: Double) -> Double {
        let t = k / 1325.55
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t
        return 2451534.6698 + 27.55454988 * k - 0.0006691 * t2 - 0.000001098 * t3 + 0.0000000052 * t4
    }

    @inlinable
    public static func MeanPerigee(_ k: Double) -> Double {
        meanPerigee(k)
    }

    @inlinable
    public static func meanApogee(_ k: Double) -> Double {
        return meanPerigee(k)
    }

    @inlinable
    public static func MeanApogee(_ k: Double) -> Double {
        meanApogee(k)
    }

    public static func truePerigee(_ k: Double) -> Double {
        let meanJD = meanPerigee(k)
        let t = k / 1325.55
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t

        let d = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(171.9179 + 335.9106046 * k - 0.0100383 * t2 - 0.00001156 * t3 + 0.000000055 * t4))
        let m = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(347.3477 + 27.1577721 * k - 0.0008130 * t2 - 0.0000010 * t3))
        let f = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(316.6109 + 364.5287911 * k - 0.0125053 * t2 - 0.0000148 * t3))

        var sigma = 0.0
        for coeff in paCoeffs1 {
            sigma += (coeff.c + t * coeff.t) * sin(d * coeff.d + m * coeff.m + f * coeff.f)
        }
        return meanJD + sigma
    }

    @inlinable
    public static func TruePerigee(_ k: Double) -> Double {
        truePerigee(k)
    }

    public static func trueApogee(_ k: Double) -> Double {
        let meanJD = meanApogee(k)
        let t = k / 1325.55
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t

        let d = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(171.9179 + 335.9106046 * k - 0.0100383 * t2 - 0.00001156 * t3 + 0.000000055 * t4))
        let m = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(347.3477 + 27.1577721 * k - 0.0008130 * t2 - 0.0000010 * t3))
        let f = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(316.6109 + 364.5287911 * k - 0.0125053 * t2 - 0.0000148 * t3))

        var sigma = 0.0
        for coeff in paCoeffs2 {
            sigma += (coeff.c + t * coeff.t) * sin(d * coeff.d + m * coeff.m + f * coeff.f)
        }
        return meanJD + sigma
    }

    @inlinable
    public static func TrueApogee(_ k: Double) -> Double {
        trueApogee(k)
    }

    public static func perigeeParallax(_ k: Double) -> Double {
        let t = k / 1325.55
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t

        let d = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(171.9179 + 335.9106046 * k - 0.0100383 * t2 - 0.00001156 * t3 + 0.000000055 * t4))
        let m = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(347.3477 + 27.1577721 * k - 0.0008130 * t2 - 0.0000010 * t3))
        let f = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(316.6109 + 364.5287911 * k - 0.0125053 * t2 - 0.0000148 * t3))

        var parallax = 3629.215
        for coeff in paCoeffs3 {
            parallax += (coeff.c + t * coeff.t) * cos(d * coeff.d + m * coeff.m + f * coeff.f)
        }
        return parallax / 3600.0
    }

    @inlinable
    public static func PerigeeParallax(_ k: Double) -> Double {
        perigeeParallax(k)
    }

    public static func apogeeParallax(_ k: Double) -> Double {
        let t = k / 1325.55
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t

        let d = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(171.9179 + 335.9106046 * k - 0.0100383 * t2 - 0.00001156 * t3 + 0.000000055 * t4))
        let m = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(347.3477 + 27.1577721 * k - 0.0008130 * t2 - 0.0000010 * t3))
        let f = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(316.6109 + 364.5287911 * k - 0.0125053 * t2 - 0.0000148 * t3))

        var parallax = 3245.251
        for coeff in paCoeffs4 {
            parallax += (coeff.c + t * coeff.t) * cos(d * coeff.d + m * coeff.m + f * coeff.f)
        }
        return parallax / 3600.0
    }

    @inlinable
    public static func ApogeeParallax(_ k: Double) -> Double {
        apogeeParallax(k)
    }
}

// MARK: - CAAMoonMaxDeclinations

public enum CAAMoonMaxDeclinations: Sendable {

    @inlinable
    public static func k(_ year: Double) -> Double {
        return 13.3686 * (year - 2000.03)
    }

    @inlinable
    public static func K(_ year: Double) -> Double {
        k(year)
    }

    @inlinable
    public static func meanGreatestDeclination(_ k: Double, _ bNortherly: Bool) -> Double {
        let t = k / 1336.86
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t
        if bNortherly {
            return 2451562.5897 + 27.321582241 * k + 0.00010069 * t2 - 0.000000143 * t3 + 0.00000000040 * t4
        } else {
            return 2451548.9289 + 27.321582241 * k + 0.00010069 * t2 - 0.000000143 * t3 + 0.00000000040 * t4
        }
    }

    @inlinable
    public static func MeanGreatestDeclination(_ k: Double, _ bNortherly: Bool) -> Double {
        meanGreatestDeclination(k, bNortherly)
    }

    @inlinable
    public static func meanGreatestDeclinationValue(_ k: Double) -> Double {
        let t = k / 1336.86
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t
        return 23.6961 - 0.013004 * t + 0.00017 * t2 + 0.0000035 * t3 - 0.00000028 * t4
    }

    @inlinable
    public static func MeanGreatestDeclinationValue(_ k: Double) -> Double {
        meanGreatestDeclinationValue(k)
    }

    public static func trueGreatestDeclination(_ k: Double, _ bNortherly: Bool) -> Double {
        let t = k / 1336.86
        let t2 = t * t
        let t3 = t2 * t

        var d = bNortherly ? 152.2029 : 345.6676
        d = CAACoordinateTransformation.mapTo0To360Range(d + (333.0705546 * k) - (0.0004214 * t2) + (0.00000011 * t3))
        var m = bNortherly ? 14.8591 : 1.3951
        m = CAACoordinateTransformation.mapTo0To360Range(m + (26.9281592 * k) - (0.0000355 * t2) - (0.00000010 * t3))
        var mdash = bNortherly ? 4.6881 : 186.2100
        mdash = CAACoordinateTransformation.mapTo0To360Range(mdash + (356.9562794 * k) + (0.0103066 * t2) + (0.00001251 * t3))
        var f = bNortherly ? 325.8867 : 145.1633
        f = CAACoordinateTransformation.mapTo0To360Range(f + (1.4467807 * k) - (0.0020690 * t2) - (0.00000215 * t3))
        let e = 1.0 - (0.002516 * t) - (0.0000074 * t2)

        let dRad = CAACoordinateTransformation.degreesToRadians(d)
        let mRad = CAACoordinateTransformation.degreesToRadians(m)
        let mdashRad = CAACoordinateTransformation.degreesToRadians(mdash)
        let fRad = CAACoordinateTransformation.degreesToRadians(f)

        let twoD = 2.0 * dRad
        let twoF = 2.0 * fRad
        let threeF = 3.0 * fRad
        let twoMdash = 2.0 * mdashRad
        let threeMdash = 3.0 * mdashRad

        var deltaJD = 0.0
        if bNortherly {
            deltaJD = (0.8975 * cos(fRad)) +
                (-0.4726 * sin(mdashRad)) +
                (-0.1030 * sin(twoF)) +
                (-0.0976 * sin(twoD - mdashRad)) +
                (-0.0462 * cos(mdashRad - fRad)) +
                (-0.0461 * cos(mdashRad + fRad)) +
                (-0.0438 * sin(twoD)) +
                (0.0162 * e * sin(mRad)) +
                (-0.0157 * cos(threeF)) +
                (0.0145 * sin(mdashRad + twoF)) +
                (0.0136 * cos(twoD - fRad)) +
                (-0.0095 * cos(twoD - mdashRad - fRad)) +
                (-0.0091 * cos(twoD - mdashRad + fRad)) +
                (-0.0089 * cos(twoD + fRad)) +
                (0.0075 * sin(twoMdash)) +
                (-0.0068 * sin(mdashRad - twoF)) +
                (0.0061 * cos(twoMdash - fRad)) +
                (-0.0047 * sin(mdashRad + threeF)) +
                (-0.0043 * e * sin(twoD - mRad - mdashRad)) +
                (-0.0040 * cos(mdashRad - twoF)) +
                (-0.0037 * sin(twoD - twoMdash)) +
                (0.0031 * sin(fRad)) +
                (0.0030 * sin(twoD + mdashRad)) +
                (-0.0029 * cos(mdashRad + twoF)) +
                (-0.0029 * e * sin(twoD - mRad)) +
                (-0.0027 * sin(mdashRad + fRad)) +
                (0.0024 * e * sin(mRad - mdashRad)) +
                (-0.0021 * sin(mdashRad - threeF)) +
                (0.0019 * sin(twoMdash + fRad)) +
                (0.0018 * cos(twoD - twoMdash - fRad)) +
                (0.0018 * sin(threeF)) +
                (0.0017 * cos(mdashRad + threeF)) +
                (0.0017 * cos(twoMdash)) +
                (-0.0014 * cos(twoD - mdashRad)) +
                (0.0013 * cos(twoD + mdashRad + fRad)) +
                (0.0013 * cos(mdashRad)) +
                (0.0012 * sin(threeMdash + fRad)) +
                (0.0011 * sin(twoD - mdashRad + fRad)) +
                (-0.0011 * cos(twoD - twoMdash)) +
                (0.0010 * cos(dRad + fRad)) +
                (0.0010 * e * sin(mRad + mdashRad)) +
                (-0.0009 * sin(twoD - twoF)) +
                (0.0007 * cos(twoMdash + fRad)) +
                (-0.0007 * cos(threeMdash + fRad))
        } else {
            deltaJD = (-0.8975 * cos(fRad)) +
                (-0.4726 * sin(mdashRad)) +
                (-0.1030 * sin(twoF)) +
                (-0.0976 * sin(twoD - mdashRad)) +
                (0.0541 * cos(mdashRad - fRad)) +
                (0.0516 * cos(mdashRad + fRad)) +
                (-0.0438 * sin(twoD)) +
                (0.0112 * e * sin(mRad)) +
                (0.0157 * cos(threeF)) +
                (0.0023 * sin(mdashRad + twoF)) +
                (-0.0136 * cos(twoD - fRad)) +
                (0.0110 * cos(twoD - mdashRad - fRad)) +
                (0.0091 * cos(twoD - mdashRad + fRad)) +
                (0.0089 * cos(twoD + fRad)) +
                (0.0075 * sin(twoMdash)) +
                (-0.0030 * sin(mdashRad - twoF)) +
                (-0.0061 * cos(twoMdash - fRad)) +
                (-0.0047 * sin(mdashRad + threeF)) +
                (-0.0043 * e * sin(twoD - mRad - mdashRad)) +
                (0.0040 * cos(mdashRad - twoF)) +
                (-0.0037 * sin(twoD - twoMdash)) +
                (-0.0031 * sin(fRad)) +
                (0.0030 * sin(twoD + mdashRad)) +
                (0.0029 * cos(mdashRad + twoF)) +
                (-0.0029 * e * sin(twoD - mRad)) +
                (-0.0027 * sin(mdashRad + fRad)) +
                (0.0024 * e * sin(mRad - mdashRad)) +
                (-0.0021 * sin(mdashRad - threeF)) +
                (-0.0019 * sin(twoMdash + fRad)) +
                (-0.0006 * cos(twoD - twoMdash - fRad)) +
                (-0.0018 * sin(threeF)) +
                (-0.0017 * cos(mdashRad + threeF)) +
                (0.0017 * cos(twoMdash)) +
                (0.0014 * cos(twoD - mdashRad)) +
                (-0.0013 * cos(twoD + mdashRad + fRad)) +
                (-0.0013 * cos(mdashRad)) +
                (0.0012 * sin(threeMdash + fRad)) +
                (0.0011 * sin(twoD - mdashRad + fRad)) +
                (0.0011 * cos(twoD - twoMdash)) +
                (0.0010 * cos(dRad + fRad)) +
                (0.0010 * e * sin(mRad + mdashRad)) +
                (-0.0009 * sin(twoD - twoF)) +
                (-0.0007 * cos(twoMdash + fRad)) +
                (-0.0007 * cos(threeMdash + fRad))
        }

        return meanGreatestDeclination(k, bNortherly) + deltaJD
    }

    @inlinable
    public static func TrueGreatestDeclination(_ k: Double, _ bNortherly: Bool) -> Double {
        trueGreatestDeclination(k, bNortherly)
    }

    public static func trueGreatestDeclinationValue(_ k: Double, _ bNortherly: Bool) -> Double {
        let t = k / 1336.86
        let t2 = t * t
        let t3 = t2 * t

        var d = bNortherly ? 152.2029 : 345.6676
        d = CAACoordinateTransformation.mapTo0To360Range(d + (333.0705546 * k) - (0.0004214 * t2) + (0.00000011 * t3))
        var m = bNortherly ? 14.8591 : 1.3951
        m = CAACoordinateTransformation.mapTo0To360Range(m + (26.9281592 * k) - (0.0000355 * t2) - (0.00000010 * t3))
        var mdash = bNortherly ? 4.6881 : 186.2100
        mdash = CAACoordinateTransformation.mapTo0To360Range(mdash + (356.9562794 * k) + (0.0103066 * t2) + (0.00001251 * t3))
        var f = bNortherly ? 325.8867 : 145.1633
        f = CAACoordinateTransformation.mapTo0To360Range(f + (1.4467807 * k) - (0.0020690 * t2) - (0.00000215 * t3))
        let e = 1.0 - (0.002516 * t) - (0.0000074 * t2)

        let dRad = CAACoordinateTransformation.degreesToRadians(d)
        let mRad = CAACoordinateTransformation.degreesToRadians(m)
        let mdashRad = CAACoordinateTransformation.degreesToRadians(mdash)
        let fRad = CAACoordinateTransformation.degreesToRadians(f)

        let twoD = 2.0 * dRad
        let twoF = 2.0 * fRad
        let threeF = 3.0 * fRad
        let twoMdash = 2.0 * mdashRad
        let threeMdash = 3.0 * mdashRad

        var deltaValue = 0.0
        if bNortherly {
            deltaValue = ( 5.1093 * sin(fRad)) +
                ( 0.2658 * cos(twoF)) +
                ( 0.1448 * sin(twoD - fRad)) +
                (-0.0322 * sin(threeF)) +
                ( 0.0133 * cos(twoD - twoF)) +
                ( 0.0125 * cos(twoD)) +
                (-0.0124 * sin(mdashRad - fRad)) +
                (-0.0101 * sin(mdashRad + twoF)) +
                ( 0.0097 * cos(fRad)) +
                (-0.0087 * e * sin(twoD + mRad - fRad)) +
                ( 0.0074 * sin(mdashRad + threeF)) +
                ( 0.0067 * sin(dRad + fRad)) +
                ( 0.0063 * sin(mdashRad - twoF)) +
                ( 0.0060 * e * sin(twoD - mRad - fRad)) +
                (-0.0057 * sin(twoD - mdashRad - fRad)) +
                (-0.0056 * cos(mdashRad + fRad)) +
                ( 0.0052 * cos(mdashRad + twoF)) +
                ( 0.0041 * cos(twoMdash + fRad)) +
                (-0.0040 * cos(mdashRad - threeF)) +
                ( 0.0038 * cos(twoMdash - fRad)) +
                (-0.0034 * cos(mdashRad - twoF)) +
                (-0.0029 * sin(twoMdash)) +
                ( 0.0029 * sin(threeMdash + fRad)) +
                (-0.0028 * e * cos(twoD + mRad - fRad)) +
                (-0.0028 * cos(mdashRad - fRad)) +
                (-0.0023 * cos(threeF)) +
                (-0.0021 * sin(twoD + fRad)) +
                ( 0.0019 * cos(mdashRad + threeF)) +
                ( 0.0018 * cos(dRad + fRad)) +
                ( 0.0017 * sin(twoMdash - fRad)) +
                ( 0.0015 * cos(threeMdash + fRad)) +
                ( 0.0014 * cos(twoD + twoMdash + fRad)) +
                (-0.0012 * sin(twoD - twoMdash - fRad)) +
                (-0.0012 * cos(twoMdash)) +
                (-0.0010 * cos(mdashRad)) +
                (-0.0010 * sin(twoF)) +
                ( 0.0006 * sin(mdashRad + fRad))
        } else {
            deltaValue = (-5.1093 * sin(fRad)) +
                ( 0.2658 * cos(twoF)) +
                (-0.1448 * sin(twoD - fRad)) +
                ( 0.0322 * sin(threeF)) +
                ( 0.0133 * cos(twoD - twoF)) +
                ( 0.0125 * cos(twoD)) +
                (-0.0015 * sin(mdashRad - fRad)) +
                ( 0.0101 * sin(mdashRad + twoF)) +
                (-0.0097 * cos(fRad)) +
                ( 0.0087 * e * sin(twoD + mRad - fRad)) +
                ( 0.0074 * sin(mdashRad + threeF)) +
                ( 0.0067 * sin(dRad + fRad)) +
                (-0.0063 * sin(mdashRad - twoF)) +
                (-0.0060 * e * sin(twoD - mRad - fRad)) +
                ( 0.0057 * sin(twoD - mdashRad - fRad)) +
                (-0.0056 * cos(mdashRad + fRad)) +
                (-0.0052 * cos(mdashRad + twoF)) +
                (-0.0041 * cos(twoMdash + fRad)) +
                (-0.0040 * cos(mdashRad - threeF)) +
                (-0.0038 * cos(twoMdash - fRad)) +
                ( 0.0034 * cos(mdashRad - twoF)) +
                (-0.0029 * sin(twoMdash)) +
                ( 0.0029 * sin(threeMdash + fRad)) +
                ( 0.0028 * e * cos(twoD + mRad - fRad)) +
                (-0.0028 * cos(mdashRad - fRad)) +
                ( 0.0023 * cos(threeF)) +
                ( 0.0021 * sin(twoD + fRad)) +
                ( 0.0019 * cos(mdashRad + threeF)) +
                ( 0.0018 * cos(dRad + fRad)) +
                (-0.0017 * sin(twoMdash - fRad)) +
                ( 0.0015 * cos(threeMdash + fRad)) +
                ( 0.0014 * cos(twoD + twoMdash + fRad)) +
                ( 0.0012 * sin(twoD - twoMdash - fRad)) +
                (-0.0012 * cos(twoMdash)) +
                ( 0.0010 * cos(mdashRad)) +
                (-0.0010 * sin(twoF)) +
                ( 0.0037 * sin(mdashRad + fRad))
        }

        return meanGreatestDeclinationValue(k) + deltaValue
    }

    @inlinable
    public static func TrueGreatestDeclinationValue(_ k: Double, _ bNortherly: Bool) -> Double {
        trueGreatestDeclinationValue(k, bNortherly)
    }
}

// MARK: - CAAMoonIlluminatedFraction

public enum CAAMoonIlluminatedFraction: Sendable {

    public static func geocentricElongation(objectAlpha: Double, objectDelta: Double, sunAlpha: Double, sunDelta: Double) -> Double {
        let objAlphaRad = CAACoordinateTransformation.degreesToRadians(objectAlpha * 15.0)
        let sunAlphaRad = CAACoordinateTransformation.degreesToRadians(sunAlpha * 15.0)
        let objDeltaRad = CAACoordinateTransformation.degreesToRadians(objectDelta)
        let sunDeltaRad = CAACoordinateTransformation.degreesToRadians(sunDelta)

        return CAACoordinateTransformation.radiansToDegrees(acos(sin(sunDeltaRad) * sin(objDeltaRad) + cos(sunDeltaRad) * cos(objDeltaRad) * cos(sunAlphaRad - objAlphaRad)))
    }

    @inlinable
    public static func GeocentricElongation(_ objectAlpha: Double, _ objectDelta: Double, _ sunAlpha: Double, _ sunDelta: Double) -> Double {
        geocentricElongation(objectAlpha: objectAlpha, objectDelta: objectDelta, sunAlpha: sunAlpha, sunDelta: sunDelta)
    }

    public static func phaseAngle(geocentricElongation: Double, earthObjectDistance: Double, earthSunDistance: Double) -> Double {
        let elRad = CAACoordinateTransformation.degreesToRadians(geocentricElongation)
        return CAACoordinateTransformation.mapTo0To360Range(CAACoordinateTransformation.radiansToDegrees(atan2(earthSunDistance * sin(elRad), earthObjectDistance - earthSunDistance * cos(elRad))))
    }

    @inlinable
    public static func PhaseAngle(_ geocentricElongation: Double, _ earthObjectDistance: Double, _ earthSunDistance: Double) -> Double {
        phaseAngle(geocentricElongation: geocentricElongation, earthObjectDistance: earthObjectDistance, earthSunDistance: earthSunDistance)
    }

    @inlinable
    public static func illuminatedFraction(phaseAngle: Double) -> Double {
        let pRad = CAACoordinateTransformation.degreesToRadians(phaseAngle)
        return (1.0 + cos(pRad)) / 2.0
    }

    @inlinable
    public static func IlluminatedFraction(_ phaseAngle: Double) -> Double {
        illuminatedFraction(phaseAngle: phaseAngle)
    }

    public static func positionAngle(alpha0: Double, delta0: Double, alpha: Double, delta: Double) -> Double {
        let a0 = CAACoordinateTransformation.hoursToRadians(alpha0)
        let a = CAACoordinateTransformation.hoursToRadians(alpha)
        let d0 = CAACoordinateTransformation.degreesToRadians(delta0)
        let d = CAACoordinateTransformation.degreesToRadians(delta)

        return CAACoordinateTransformation.mapTo0To360Range(CAACoordinateTransformation.radiansToDegrees(atan2(cos(d0) * sin(a0 - a), sin(d0) * cos(d) - cos(d0) * sin(d) * cos(a0 - a))))
    }

    @inlinable
    public static func PositionAngle(_ alpha0: Double, _ delta0: Double, _ alpha: Double, _ delta: Double) -> Double {
        positionAngle(alpha0: alpha0, delta0: delta0, alpha: alpha, delta: delta)
    }
}

// MARK: - CAADiameters

public enum CAADiameters: Sendable {

    @inlinable public static func SunSemidiameterA(_ delta: Double) -> Double { 959.63 / delta }
    @inlinable public static func MercurySemidiameterA(_ delta: Double) -> Double { 3.34 / delta }
    @inlinable public static func VenusSemidiameterA(_ delta: Double) -> Double { 8.41 / delta }
    @inlinable public static func MarsSemidiameterA(_ delta: Double) -> Double { 4.68 / delta }
    @inlinable public static func JupiterEquatorialSemidiameterA(_ delta: Double) -> Double { 98.47 / delta }
    @inlinable public static func JupiterPolarSemidiameterA(_ delta: Double) -> Double { 91.91 / delta }
    @inlinable public static func SaturnEquatorialSemidiameterA(_ delta: Double) -> Double { 83.33 / delta }
    @inlinable public static func SaturnPolarSemidiameterA(_ delta: Double) -> Double { 74.57 / delta }
    @inlinable public static func UranusSemidiameterA(_ delta: Double) -> Double { 34.28 / delta }
    @inlinable public static func NeptuneSemidiameterA(_ delta: Double) -> Double { 36.56 / delta }

    @inlinable public static func MercurySemidiameterB(_ delta: Double) -> Double { 3.36 / delta }
    @inlinable public static func VenusSemidiameterB(_ delta: Double) -> Double { 8.34 / delta }
    @inlinable public static func MarsSemidiameterB(_ delta: Double) -> Double { 4.68 / delta }
    @inlinable public static func JupiterEquatorialSemidiameterB(_ delta: Double) -> Double { 98.44 / delta }
    @inlinable public static func JupiterPolarSemidiameterB(_ delta: Double) -> Double { 92.06 / delta }
    @inlinable public static func SaturnEquatorialSemidiameterB(_ delta: Double) -> Double { 82.73 / delta }
    @inlinable public static func SaturnPolarSemidiameterB(_ delta: Double) -> Double { 73.82 / delta }
    @inlinable public static func UranusSemidiameterB(_ delta: Double) -> Double { 35.02 / delta }
    @inlinable public static func NeptuneSemidiameterB(_ delta: Double) -> Double { 33.50 / delta }
    @inlinable public static func PlutoSemidiameterB(_ delta: Double) -> Double { 2.07 / delta }

    @inlinable
    public static func ApparentAsteroidDiameter(_ delta: Double, _ d: Double) -> Double {
        (0.0013788 * d) / delta
    }

    public static func geocentricMoonSemidiameter(_ delta: Double) -> Double {
        return CAACoordinateTransformation.radiansToDegrees(asin(0.2725076 * 6378.14 / delta)) * 3600.0
    }

    @inlinable
    public static func GeocentricMoonSemidiameter(_ delta: Double) -> Double {
        geocentricMoonSemidiameter(delta)
    }

    public static func apparentSaturnPolarSemidiameterA(_ delta: Double, _ b: Double) -> Double {
        let cosB = cos(CAACoordinateTransformation.degreesToRadians(b))
        return SaturnPolarSemidiameterA(delta) * sqrt(1.0 - (0.19919731146620168 * cosB * cosB))
    }

    @inlinable
    public static func ApparentSaturnPolarSemidiameterA(_ delta: Double, _ b: Double) -> Double {
        apparentSaturnPolarSemidiameterA(delta, b)
    }

    public static func apparentSaturnPolarSemidiameterB(_ delta: Double, _ b: Double) -> Double {
        let cosB = cos(CAACoordinateTransformation.degreesToRadians(b))
        return SaturnPolarSemidiameterB(delta) * sqrt(1.0 - (0.20380025700102367 * cosB * cosB))
    }

    @inlinable
    public static func ApparentSaturnPolarSemidiameterB(_ delta: Double, _ b: Double) -> Double {
        apparentSaturnPolarSemidiameterB(delta, b)
    }

    public static func topocentricMoonSemidiameter(_ distanceDelta: Double, _ delta: Double, _ h: Double, _ latitude: Double, _ height: Double) -> Double {
        let hRad = CAACoordinateTransformation.hoursToRadians(h)
        let deltaRad = CAACoordinateTransformation.degreesToRadians(delta)
        let pi = asin(6378.14 / distanceDelta)
        let cosDelta = cos(deltaRad)
        let a = cosDelta * sin(hRad)
        let sinPi = sin(pi)
        let b = (cosDelta * cos(hRad)) - (CAAGlobe.rhoCosThetaPrime(latitude: latitude, height: height) * sinPi)
        let c = sin(deltaRad) - (CAAGlobe.rhoSinThetaPrime(latitude: latitude, height: height) * sinPi)
        let q = sqrt(a * a + b * b + c * c)

        let s = CAACoordinateTransformation.degreesToRadians(geocentricMoonSemidiameter(distanceDelta) / 3600.0)
        return CAACoordinateTransformation.radiansToDegrees(asin(sin(s) / q)) * 3600.0
    }

    @inlinable
    public static func TopocentricMoonSemidiameter(_ distanceDelta: Double, _ delta: Double, _ h: Double, _ latitude: Double, _ height: Double) -> Double {
        topocentricMoonSemidiameter(distanceDelta, delta, h, latitude, height)
    }

    public static func asteroidDiameter(_ h: Double, _ a: Double) -> Double {
        let x = 3.12 - (h / 5.0) - (0.217147 * log(a))
        return pow(10.0, x)
    }

    @inlinable
    public static func AsteroidDiameter(_ h: Double, _ a: Double) -> Double {
        asteroidDiameter(h, a)
    }
}

// MARK: - CAAEclipses

public enum CAAEclipses: Sendable {

    public static func calculate(_ k: Double, _ mdash: inout Double) -> CAASolarEclipseDetails {
        var intPart = 0.0
        let bSolarEclipse = modf(k, &intPart) == 0.0

        var details = CAASolarEclipseDetails()

        let t = k / 1236.85
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t
        let e = 1.0 - 0.002516 * t - 0.0000074 * t2

        let m = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(2.5534 + 29.10535670 * k - 0.0000014 * t2 - 0.00000011 * t3))
        mdash = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(201.5643 + 385.81693528 * k + 0.0107582 * t2 + 0.00001238 * t3 - 0.000000058 * t4))
        let omega = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(124.7746 - 1.56375588 * k + 0.0020672 * t2 + 0.00000215 * t3))

        let fVal = CAACoordinateTransformation.mapTo0To360Range(160.7108 + 390.67050284 * k - 0.0016118 * t2 - 0.00000227 * t3 + 0.00000001 * t4)
        details.F = fVal
        let fdashVal = fVal - 0.02665 * sin(omega)

        let f = CAACoordinateTransformation.degreesToRadians(fVal)
        let fdash = CAACoordinateTransformation.degreesToRadians(fdashVal)

        if abs(sin(f)) > 0.36 {
            return details
        }

        let a1 = CAACoordinateTransformation.degreesToRadians(CAACoordinateTransformation.mapTo0To360Range(299.77 + 0.107408 * k - 0.009173 * t2))
        details.TimeOfMaximumEclipse = CAAMoonPhases.meanPhase(k)

        var deltaJD = 0.0
        if bSolarEclipse {
            deltaJD += -0.4075 * sin(mdash) + 0.1721 * e * sin(m)
        } else {
            deltaJD += -0.4065 * sin(mdash) + 0.1727 * e * sin(m)
        }
        deltaJD += 0.0161 * sin(2.0 * mdash) -
            0.0097 * sin(2.0 * fdash) +
            0.0073 * e * sin(mdash - m) -
            0.0050 * e * sin(mdash + m) -
            0.0023 * sin(mdash - 2.0 * fdash) +
            0.0021 * e * sin(2.0 * m) +
            0.0012 * sin(mdash + 2.0 * fdash) +
            0.0006 * e * sin(2.0 * mdash + m) -
            0.0004 * sin(3.0 * mdash) -
            0.0003 * e * sin(m + 2.0 * fdash) +
            0.0003 * sin(a1) -
            0.0002 * e * sin(m - 2.0 * fdash) -
            0.0002 * e * sin(2.0 * mdash - m) -
            0.0002 * sin(omega)

        details.TimeOfMaximumEclipse += deltaJD

        let p = 0.2070 * e * sin(m) +
            0.0024 * e * sin(2.0 * m) -
            0.0392 * sin(mdash) +
            0.0116 * sin(2.0 * mdash) -
            0.0073 * e * sin(mdash + m) +
            0.0067 * e * sin(mdash - m) +
            0.0118 * sin(2.0 * fdash)

        let q = 5.2207 -
            0.0048 * e * cos(m) +
            0.0020 * e * cos(2.0 * m) -
            0.3299 * cos(mdash) -
            0.0060 * e * cos(mdash + m) +
            0.0041 * e * cos(mdash - m)

        let w = abs(cos(fdash))
        details.gamma = (p * cos(fdash) + q * sin(fdash)) * (1.0 - 0.0048 * w)
        details.u = 0.0059 + 0.0046 * e * cos(m) - 0.0182 * cos(mdash) + 0.0004 * cos(2.0 * mdash) - 0.0005 * cos(m + mdash)

        let fgamma = abs(details.gamma)
        if fgamma > (1.5433 + details.u) {
            return details
        }

        if fgamma < 0.9972 {
            if details.u < 0.0 {
                details.Flags = CAASolarEclipseDetails.TOTAL_ECLIPSE
            } else if details.u > 0.0047 {
                details.Flags = CAASolarEclipseDetails.ANNULAR_ECLIPSE
            } else {
                let wVal = 0.00464 * sqrt(1.0 - (details.gamma * details.gamma))
                if details.u < wVal {
                    details.Flags = CAASolarEclipseDetails.ANNULAR_TOTAL_ECLIPSE
                } else {
                    details.Flags = CAASolarEclipseDetails.ANNULAR_ECLIPSE
                }
            }
            details.Flags |= CAASolarEclipseDetails.CENTRAL_ECLIPSE
        } else if fgamma > 0.9972 && fgamma < (1.5433 + details.u) {
            if fgamma > 0.9972 && fgamma < (0.9972 + abs(details.u)) {
                if details.u < 0.0 {
                    details.Flags = CAASolarEclipseDetails.TOTAL_ECLIPSE
                } else if details.u > 0.0047 {
                    details.Flags = CAASolarEclipseDetails.ANNULAR_ECLIPSE
                } else {
                    let wVal = 0.00464 * sqrt(1.0 - (details.gamma * details.gamma))
                    if details.u < wVal {
                        details.Flags = CAASolarEclipseDetails.ANNULAR_TOTAL_ECLIPSE
                    } else {
                        details.Flags = CAASolarEclipseDetails.ANNULAR_ECLIPSE
                    }
                }
            } else {
                details.Flags = CAASolarEclipseDetails.PARTIAL_ECLIPSE
                details.GreatestMagnitude = (1.5433 + details.u - fgamma) / (0.5461 + 2.0 * details.u)
            }
            details.Flags |= CAASolarEclipseDetails.NON_CENTRAL_ECLIPSE
        }

        return details
    }

    public static func calculateSolar(_ k: Double) -> CAASolarEclipseDetails {
        var mdash = 0.0
        return calculate(k, &mdash)
    }

    @inlinable
    public static func CalculateSolar(_ k: Double) -> CAASolarEclipseDetails {
        calculateSolar(k)
    }

    public static func calculateLunar(_ k: Double) -> CAALunarEclipseDetails {
        var mdash = 0.0
        let solarDetails = calculate(k, &mdash)

        var details = CAALunarEclipseDetails()
        details.bEclipse = solarDetails.Flags != 0
        details.F = solarDetails.F
        details.gamma = solarDetails.gamma
        details.TimeOfMaximumEclipse = solarDetails.TimeOfMaximumEclipse
        details.u = solarDetails.u

        if details.bEclipse {
            details.PenumbralRadii = 1.2848 + details.u
            details.UmbralRadii = 0.7403 - details.u
            let fgamma = abs(details.gamma)
            details.PenumbralMagnitude = (1.5573 + details.u - fgamma) / 0.5450
            details.UmbralMagnitude = (1.0128 - details.u - fgamma) / 0.5450

            let p = 1.0128 - details.u
            let t = 0.4678 - details.u
            let n = 0.5458 + 0.0400 * cos(mdash)

            let gamma2 = details.gamma * details.gamma
            let p2 = p * p
            if p2 >= gamma2 {
                details.PartialPhaseSemiDuration = 60.0 / n * sqrt(p2 - gamma2)
            }
            let t2 = t * t
            if t2 >= gamma2 {
                details.TotalPhaseSemiDuration = 60.0 / n * sqrt(t2 - gamma2)
            }
            let h = 1.5573 + details.u
            let h2 = h * h
            if h2 >= gamma2 {
                details.PartialPhasePenumbraSemiDuration = 60.0 / n * sqrt(h2 - gamma2)
            }
        }
        return details
    }

    @inlinable
    public static func CalculateLunar(_ k: Double) -> CAALunarEclipseDetails {
        calculateLunar(k)
    }
}

// MARK: - CAAPhysicalMoon

public enum CAAPhysicalMoon: Sendable {

    private static func calculateOpticalLibration(
        jd: Double, lambda: Double, beta: Double,
        ldash: inout Double, bdash: inout Double,
        ldash2: inout Double, bdash2: inout Double,
        epsilon: inout Double, omega: inout Double, deltaU: inout Double,
        sigma: inout Double, I: inout Double, rho: inout Double
    ) {
        let lambdaRad = CAACoordinateTransformation.degreesToRadians(lambda)
        let betaRad = CAACoordinateTransformation.degreesToRadians(beta)
        let cosBetaRad = cos(betaRad)
        let sinBetaRad = sin(betaRad)
        I = CAACoordinateTransformation.degreesToRadians(1.54242)
        let cosI = cos(I)
        let sinI = sin(I)
        deltaU = CAACoordinateTransformation.degreesToRadians(CAANutation.nutationInLongitude(jd: jd) / 3600.0)
        let f = CAACoordinateTransformation.degreesToRadians(CAAMoon.argumentOfLatitude(jd))
        let twoF = 2.0 * f
        omega = CAACoordinateTransformation.degreesToRadians(CAAMoon.meanLongitudeAscendingNode(jd))
        epsilon = CAANutation.meanObliquityOfEcliptic(jd: jd) + (CAANutation.nutationInObliquity(jd: jd) / 3600.0)

        let w = lambdaRad - deltaU - omega
        let sinW = sin(w)
        let a = atan2((sinW * cosBetaRad * cosI) - (sinBetaRad * sinI), cos(w) * cosBetaRad)
        let cosA = cos(a)
        let sinA = sin(a)
        ldash = CAACoordinateTransformation.mapTo0To360Range(CAACoordinateTransformation.radiansToDegrees(a) - CAACoordinateTransformation.radiansToDegrees(f))
        if ldash > 180.0 { ldash -= 360.0 }
        bdash = asin(-(sinW * cosBetaRad * sinI) - (sinBetaRad * cosI))

        let t = (jd - 2451545.0) / 36525.0
        let k1 = CAACoordinateTransformation.degreesToRadians(119.75 + 131.849 * t)
        let k2 = CAACoordinateTransformation.degreesToRadians(72.56 + 20.186 * t)

        let m = CAACoordinateTransformation.degreesToRadians(CAAEarth.sunMeanAnomaly(jd))
        let mdash = CAACoordinateTransformation.degreesToRadians(CAAMoon.meanAnomaly(jd))
        let twoMdash = 2.0 * mdash
        let d = CAACoordinateTransformation.degreesToRadians(CAAMoon.meanElongation(jd))
        let twoD = 2.0 * d
        let e = CAAEarth.eccentricity(jd)

        rho = (-0.02752 * cos(mdash)) +
            (-0.02245 * sin(f)) +
            (0.00684 * cos(mdash - twoF)) +
            (-0.00293 * cos(twoF)) +
            (-0.00085 * cos(twoF - twoD)) +
            (-0.00054 * cos(mdash - twoD)) +
            (-0.00020 * sin(mdash + f)) +
            (-0.00020 * cos(mdash + twoF)) +
            (-0.00020 * cos(mdash - f)) +
            (0.00014 * cos(mdash + twoF - twoD))

        sigma = (-0.02816 * sin(mdash)) +
            (0.02244 * cos(f)) +
            (-0.00682 * sin(mdash - twoF)) +
            (-0.00279 * sin(twoF)) +
            (-0.00083 * sin(twoF - twoD)) +
            (0.00069 * sin(mdash - twoD)) +
            (0.00040 * cos(mdash + f)) +
            (-0.00025 * sin(twoMdash)) +
            (-0.00023 * sin(mdash + twoF)) +
            (0.00020 * cos(mdash - f)) +
            (0.00019 * sin(mdash - f)) +
            (0.00013 * sin(mdash + twoF - twoD)) +
            (-0.00010 * cos(mdash - 3.0 * f))

        let tau = (0.02520 * e * sin(m)) +
            (0.00473 * sin(twoMdash - twoF)) +
            (-0.00467 * sin(mdash)) +
            (0.00396 * sin(k1)) +
            (0.00276 * sin(twoMdash - twoD)) +
            (0.00196 * sin(omega)) +
            (-0.00183 * cos(mdash - f)) +
            (0.00115 * sin(mdash - twoD)) +
            (-0.00096 * sin(mdash - d)) +
            (0.00046 * sin(twoF - twoD)) +
            (-0.00039 * sin(mdash - f)) +
            (-0.00032 * sin(mdash - m - d)) +
            (0.00027 * sin(twoMdash - m - twoD)) +
            (0.00023 * sin(k2)) +
            (-0.00014 * sin(twoD)) +
            (0.00014 * cos(twoMdash - twoF)) +
            (-0.00012 * sin(mdash - twoF)) +
            (-0.00012 * sin(twoMdash)) +
            (0.00011 * sin(twoMdash - 2.0 * m - twoD))

        ldash2 = -tau + (rho * cosA) + (sigma * sinA * tan(bdash))
        bdash = CAACoordinateTransformation.radiansToDegrees(bdash)
        bdash2 = (sigma * cosA) - (rho * sinA)
    }

    private static func calculateHelper(
        jd: Double,
        lambda: inout Double, beta: inout Double,
        epsilon: inout Double,
        equatorial: inout CAA2DCoordinate
    ) -> CAAPhysicalMoonDetails {
        var details = CAAPhysicalMoonDetails()
        lambda = CAAMoon.eclipticLongitude(jd)
        beta = CAAMoon.eclipticLatitude(jd)

        var omega = 0.0
        var deltaU = 0.0
        var sigma = 0.0
        var iVal = 0.0
        var rho = 0.0
        calculateOpticalLibration(
            jd: jd, lambda: lambda, beta: beta,
            ldash: &details.ldash, bdash: &details.bdash,
            ldash2: &details.ldash2, bdash2: &details.bdash2,
            epsilon: &epsilon, omega: &omega, deltaU: &deltaU,
            sigma: &sigma, I: &iVal, rho: &rho
        )
        let epsilonRad = CAACoordinateTransformation.degreesToRadians(epsilon)
        details.l = details.ldash + details.ldash2
        details.b = details.bdash + details.bdash2
        let bRad = CAACoordinateTransformation.degreesToRadians(details.b)

        let v = omega + deltaU + CAACoordinateTransformation.degreesToRadians(sigma) / sin(iVal)
        let iRho = iVal + CAACoordinateTransformation.degreesToRadians(rho)
        let sinIRho = sin(iRho)
        let x = sinIRho * sin(v)
        let y = sinIRho * cos(v) * cos(epsilonRad) - cos(iRho) * sin(epsilonRad)
        let w = atan2(x, y)

        equatorial = CAACoordinateTransformation.ecliptic2Equatorial(lambda: lambda, beta: beta, epsilon: epsilon)
        let alpha = CAACoordinateTransformation.hoursToRadians(equatorial.x)
        details.P = CAACoordinateTransformation.radiansToDegrees(asin(sqrt(x * x + y * y) * cos(alpha - w) / cos(bRad)))
        return details
    }

    public static func calculateGeocentric(_ jd: Double) -> CAAPhysicalMoonDetails {
        var lambda = 0.0
        var beta = 0.0
        var epsilon = 0.0
        var eq = CAA2DCoordinate()
        return calculateHelper(jd: jd, lambda: &lambda, beta: &beta, epsilon: &epsilon, equatorial: &eq)
    }

    @inlinable
    public static func CalculateGeocentric(_ jd: Double) -> CAAPhysicalMoonDetails {
        calculateGeocentric(jd)
    }

    public static func calculateTopocentric(_ jd: Double, _ longitude: Double, _ latitude: Double) -> CAAPhysicalMoonDetails {
        let lonRad = CAACoordinateTransformation.degreesToRadians(longitude)
        let latRad = CAACoordinateTransformation.degreesToRadians(latitude)
        let cosLat = cos(latRad)
        let sinLat = sin(latRad)

        var lambda = 0.0
        var beta = 0.0
        var epsilon = 0.0
        var eq = CAA2DCoordinate()
        var details = calculateHelper(jd: jd, lambda: &lambda, beta: &beta, epsilon: &epsilon, equatorial: &eq)

        let r = CAAMoon.radiusVector(jd)
        let pi = CAAMoon.radiusVectorToHorizontalParallax(r)
        let alpha = CAACoordinateTransformation.hoursToRadians(eq.x)
        let delta = CAACoordinateTransformation.degreesToRadians(eq.y)
        let cosDelta = cos(delta)
        let sinDelta = sin(delta)

        let ast = CAASidereal.apparentGreenwichSiderealTime(jd)
        let h = CAACoordinateTransformation.hoursToRadians(ast) - lonRad - alpha
        let cosH = cos(h)

        let q = atan2(cosLat * sin(h), (cosDelta * sinLat) - (sinDelta * cosLat * cosH))
        let z = acos((sinDelta * sinLat) + (cosDelta * cosLat * cosH))
        let pidash = pi * (sin(z) + 0.0084 * sin(2.0 * z))

        let pRad = CAACoordinateTransformation.degreesToRadians(details.P)
        let deltaL = -pidash * sin(q - pRad) / cos(CAACoordinateTransformation.degreesToRadians(details.b))
        details.l += deltaL
        let deltaB = pidash * cos(q - pRad)
        details.b += deltaB
        let deltaP = deltaL * sin(CAACoordinateTransformation.degreesToRadians(details.b)) - (pidash * sin(q) * tan(delta))
        details.P += deltaP
        return details
    }

    @inlinable
    public static func CalculateTopocentric(_ jd: Double, _ longitude: Double, _ latitude: Double) -> CAAPhysicalMoonDetails {
        calculateTopocentric(jd, longitude, latitude)
    }

    public static func calculateSelenographicPositionOfSun(_ jd: Double, _ bHighPrecision: Bool = true) -> CAASelenographicMoonDetails {
        let r = CAAEarth.radiusVector(jd, bHighPrecision) * 149597970.0
        let delta = CAAMoon.radiusVector(jd)
        let lambda0 = CAASun.apparentEclipticLongitude(jd, bHighPrecision)
        let lambda = CAAMoon.eclipticLongitude(jd)
        let beta = CAAMoon.eclipticLatitude(jd)

        let lambdah = CAACoordinateTransformation.mapTo0To360Range(
            lambda0 + 180.0 + (delta / r * 57.296 * cos(CAACoordinateTransformation.degreesToRadians(beta)) * sin(CAACoordinateTransformation.degreesToRadians(lambda0 - lambda)))
        )
        let betah = delta / r * beta

        var details = CAASelenographicMoonDetails()
        var omega = 0.0
        var deltaU = 0.0
        var sigma = 0.0
        var iVal = 0.0
        var rho = 0.0
        var ldash0 = 0.0
        var bdash0 = 0.0
        var ldash20 = 0.0
        var bdash20 = 0.0
        var epsilon = 0.0

        calculateOpticalLibration(
            jd: jd, lambda: lambdah, beta: betah,
            ldash: &ldash0, bdash: &bdash0,
            ldash2: &ldash20, bdash2: &bdash20,
            epsilon: &epsilon, omega: &omega, deltaU: &deltaU,
            sigma: &sigma, I: &iVal, rho: &rho
        )

        details.l0 = ldash0 + ldash20
        details.b0 = bdash0 + bdash20
        details.c0 = CAACoordinateTransformation.mapTo0To360Range(450.0 - details.l0)
        return details
    }

    @inlinable
    public static func CalculateSelenographicPositionOfSun(_ jd: Double, _ bHighPrecision: Bool = true) -> CAASelenographicMoonDetails {
        calculateSelenographicPositionOfSun(jd, bHighPrecision)
    }

    public static func altitudeOfSun(_ jd: Double, _ longitude: Double, _ latitude: Double, _ bHighPrecision: Bool = true) -> Double {
        var selenographicDetails = calculateSelenographicPositionOfSun(jd, bHighPrecision)
        let latRad = CAACoordinateTransformation.degreesToRadians(latitude)
        let lonRad = CAACoordinateTransformation.degreesToRadians(longitude)
        selenographicDetails.b0 = CAACoordinateTransformation.degreesToRadians(selenographicDetails.b0)
        selenographicDetails.c0 = CAACoordinateTransformation.degreesToRadians(selenographicDetails.c0)

        return CAACoordinateTransformation.radiansToDegrees(asin((sin(selenographicDetails.b0) * sin(latRad)) +
            (cos(selenographicDetails.b0) * cos(latRad) * sin(selenographicDetails.c0 + lonRad))))
    }

    @inlinable
    public static func AltitudeOfSun(_ jd: Double, _ longitude: Double, _ latitude: Double, _ bHighPrecision: Bool = true) -> Double {
        altitudeOfSun(jd, longitude, latitude, bHighPrecision)
    }

    private static func sunriseSunsetHelper(_ jd: Double, _ longitude: Double, _ latitude: Double, _ bSunrise: Bool, _ bHighPrecision: Bool) -> Double {
        var jdResult = jd
        let latRad = CAACoordinateTransformation.degreesToRadians(latitude)
        var h = 0.0
        repeat {
            h = altitudeOfSun(jdResult, longitude, latitude, bHighPrecision)
            let deltaJD = h / (12.19075 * cos(latRad))
            if bSunrise {
                jdResult -= deltaJD
            } else {
                jdResult += deltaJD
            }
        } while abs(h) > 0.001
        return jdResult
    }

    public static func timeOfSunrise(_ jd: Double, _ longitude: Double, _ latitude: Double, _ bHighPrecision: Bool = true) -> Double {
        return sunriseSunsetHelper(jd, longitude, latitude, true, bHighPrecision)
    }

    @inlinable
    public static func TimeOfSunrise(_ jd: Double, _ longitude: Double, _ latitude: Double, _ bHighPrecision: Bool = true) -> Double {
        timeOfSunrise(jd, longitude, latitude, bHighPrecision)
    }

    public static func timeOfSunset(_ jd: Double, _ longitude: Double, _ latitude: Double, _ bHighPrecision: Bool = true) -> Double {
        return sunriseSunsetHelper(jd, longitude, latitude, false, bHighPrecision)
    }

    @inlinable
    public static func TimeOfSunset(_ jd: Double, _ longitude: Double, _ latitude: Double, _ bHighPrecision: Bool = true) -> Double {
        timeOfSunset(jd, longitude, latitude, bHighPrecision)
    }
}
