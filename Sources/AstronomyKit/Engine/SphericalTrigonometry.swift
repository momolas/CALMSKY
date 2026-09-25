//
//  SphericalTrigonometry.swift
//  AstronomyKit
//
//  Pure Swift celestial coordinate transformations and spherical trigonometry.
//  Replaces CAACoordinateTransformation from AAplus.
//

import Foundation

public enum SphericalTrigonometry: Sendable {

    @inlinable
    public static var pi: Double { .pi }

    @inlinable
    public static func degreesToRadians(_ degrees: Double) -> Double {
        degrees * (Double.pi / 180.0)
    }

    @inlinable
    public static func radiansToDegrees(_ radians: Double) -> Double {
        radians * (180.0 / Double.pi)
    }

    @inlinable
    public static func radiansToHours(_ radians: Double) -> Double {
        radians * (12.0 / Double.pi)
    }

    @inlinable
    public static func hoursToRadians(_ hours: Double) -> Double {
        hours * (Double.pi / 12.0)
    }

    @inlinable
    public static func degreesToHours(_ degrees: Double) -> Double {
        degrees / 15.0
    }

    @inlinable
    public static func hoursToDegrees(_ hours: Double) -> Double {
        hours * 15.0
    }

    @inlinable
    public static func mapTo0To360Range(_ degrees: Double) -> Double {
        var value = degrees.truncatingRemainder(dividingBy: 360.0)
        if value < 0 {
            value += 360.0
        }
        return value
    }

    @inlinable
    public static func mapTo0To24Range(_ hourAngle: Double) -> Double {
        var value = hourAngle.truncatingRemainder(dividingBy: 24.0)
        if value < 0 {
            value += 24.0
        }
        return value
    }

    @inlinable
    public static func mapTo0To2PIRange(_ angle: Double) -> Double {
        let twoPI = 2.0 * Double.pi
        var value = angle.truncatingRemainder(dividingBy: twoPI)
        if value < 0 {
            value += twoPI
        }
        return value
    }

    @inlinable
    public static func mapToMinus90To90Range(_ degrees: Double) -> Double {
        var value = mapTo0To360Range(degrees)
        if value > 270 {
            value -= 360
        } else if value > 90 {
            value = 180 - value
        }
        return value
    }

    @inlinable
    public static func mapToMinus180To180Range(_ degrees: Double) -> Double {
        var value = mapTo0To360Range(degrees)
        if value > 180 {
            value -= 360
        }
        return value
    }

    @inlinable
    public static func dmsToDegrees(_ degrees: Double, _ minutes: Double, _ seconds: Double, bPositive: Bool = true) -> Double {
        let value = degrees + (minutes / 60.0) + (seconds / 3600.0)
        return bPositive ? value : -value
    }

    @inlinable
    public static func dmsToDegrees(degrees: Double, minutes: Double, seconds: Double, bPositive: Bool = true) -> Double {
        dmsToDegrees(degrees, minutes, seconds, bPositive: bPositive)
    }

    // MARK: - Celestial Coordinate Conversions

    @inlinable
    public static func equatorialToEcliptic(alpha: Double, delta: Double, epsilon: Double) -> CAA2DCoordinate {
        let a = hoursToRadians(alpha)
        let d = degreesToRadians(delta)
        let eps = degreesToRadians(epsilon)

        let cosEps = cos(eps)
        let sinEps = sin(eps)
        let sinAlpha = sin(a)
        var lambda = radiansToDegrees(atan2((sinAlpha * cosEps) + (tan(d) * sinEps), cos(a)))
        if lambda < 0 {
            lambda += 360.0
        }
        let beta = radiansToDegrees(asin((sin(d) * cosEps) - (cos(d) * sinEps * sinAlpha)))
        return CAA2DCoordinate(lambda, beta)
    }

    @inlinable
    public static func equatorialToEcliptic(_ alpha: Double, _ delta: Double, _ epsilon: Double) -> CAA2DCoordinate {
        equatorialToEcliptic(alpha: alpha, delta: delta, epsilon: epsilon)
    }

    @inlinable
    public static func eclipticToEquatorial(lambda: Double, beta: Double, epsilon: Double) -> CAA2DCoordinate {
        let l = degreesToRadians(lambda)
        let b = degreesToRadians(beta)
        let eps = degreesToRadians(epsilon)

        let cosEps = cos(eps)
        let sinEps = sin(eps)
        let sinLambda = sin(l)
        var alpha = radiansToHours(atan2((sinLambda * cosEps) - (tan(b) * sinEps), cos(l)))
        if alpha < 0 {
            alpha += 24.0
        }
        let delta = radiansToDegrees(asin((sin(b) * cosEps) + (cos(b) * sinEps * sinLambda)))
        return CAA2DCoordinate(alpha, delta)
    }

    @inlinable
    public static func eclipticToEquatorial(_ lambda: Double, _ beta: Double, _ epsilon: Double) -> CAA2DCoordinate {
        eclipticToEquatorial(lambda: lambda, beta: beta, epsilon: epsilon)
    }

    @inlinable
    public static func equatorialToHorizontal(localHourAngle: Double, delta: Double, latitude: Double) -> CAA2DCoordinate {
        let h = hoursToRadians(localHourAngle)
        let d = degreesToRadians(delta)
        let lat = degreesToRadians(latitude)

        let cosLat = cos(lat)
        let cosH = cos(h)
        let sinLat = sin(lat)
        var azimuth = radiansToDegrees(atan2(sin(h), (cosH * sinLat) - (tan(d) * cosLat)))
        if azimuth < 0 {
            azimuth += 360.0
        }
        let altitude = radiansToDegrees(asin((sinLat * sin(d)) + (cosLat * cos(d) * cosH)))
        return CAA2DCoordinate(azimuth, altitude)
    }

    @inlinable
    public static func horizontalToEquatorial(azimuth: Double, altitude: Double, latitude: Double) -> CAA2DCoordinate {
        let a = degreesToRadians(azimuth)
        let alt = degreesToRadians(altitude)
        let lat = degreesToRadians(latitude)

        let cosLat = cos(lat)
        let sinLat = sin(lat)
        var localHourAngle = radiansToHours(atan2(sin(a), (cos(a) * sinLat) + (tan(alt) * cosLat)))
        if localHourAngle < 0 {
            localHourAngle += 24.0
        }
        let delta = radiansToDegrees(asin((sinLat * sin(alt)) - (cosLat * cos(alt) * cos(a))))
        return CAA2DCoordinate(localHourAngle, delta)
    }

    @inlinable
    public static func equatorialToGalactic(alpha: Double, delta: Double) -> CAA2DCoordinate {
        let a = 192.25 - hoursToDegrees(alpha)
        let aRad = degreesToRadians(a)
        let d = degreesToRadians(delta)

        var l = radiansToDegrees(atan2(sin(aRad), (cos(aRad) * sin(degreesToRadians(27.4))) - (tan(d) * cos(degreesToRadians(27.4)))))
        l = 303.0 - l
        if l >= 360.0 {
            l -= 360.0
        }
        l = mapTo0To360Range(l)

        let b = radiansToDegrees(asin((sin(d) * sin(degreesToRadians(27.4))) + (cos(d) * cos(degreesToRadians(27.4)) * cos(aRad))))
        return CAA2DCoordinate(l, b)
    }

    @inlinable
    public static func galacticToEquatorial(l: Double, b: Double) -> CAA2DCoordinate {
        let lMinus123 = degreesToRadians(l - 123.0)
        let bRad = degreesToRadians(b)

        var alpha = radiansToDegrees(atan2(sin(lMinus123), (cos(lMinus123) * sin(degreesToRadians(27.4))) - (tan(bRad) * cos(degreesToRadians(27.4)))))
        alpha += 12.25
        if alpha < 0 {
            alpha += 360.0
        }
        alpha = mapTo0To360Range(alpha)
        alpha = degreesToHours(alpha)

        let delta = radiansToDegrees(asin((sin(bRad) * sin(degreesToRadians(27.4))) + (cos(bRad) * cos(degreesToRadians(27.4)) * cos(lMinus123))))
        return CAA2DCoordinate(alpha, delta)
    }
}

// MARK: - Backward-Compatibility Adapter for CAACoordinateTransformation

public enum CAACoordinateTransformation: Sendable {
    @inlinable public static var pi: Double { SphericalTrigonometry.pi }
    @inlinable public static func PI() -> Double { SphericalTrigonometry.pi }

    @inlinable public static func degreesToRadians(_ degrees: Double) -> Double { SphericalTrigonometry.degreesToRadians(degrees) }
    @inlinable public static func DegreesToRadians(_ degrees: Double) -> Double { SphericalTrigonometry.degreesToRadians(degrees) }

    @inlinable public static func radiansToDegrees(_ radians: Double) -> Double { SphericalTrigonometry.radiansToDegrees(radians) }
    @inlinable public static func RadiansToDegrees(_ radians: Double) -> Double { SphericalTrigonometry.radiansToDegrees(radians) }

    @inlinable public static func radiansToHours(_ radians: Double) -> Double { SphericalTrigonometry.radiansToHours(radians) }
    @inlinable public static func RadiansToHours(_ radians: Double) -> Double { SphericalTrigonometry.radiansToHours(radians) }

    @inlinable public static func hoursToRadians(_ hours: Double) -> Double { SphericalTrigonometry.hoursToRadians(hours) }
    @inlinable public static func HoursToRadians(_ hours: Double) -> Double { SphericalTrigonometry.hoursToRadians(hours) }

    @inlinable public static func degreesToHours(_ degrees: Double) -> Double { SphericalTrigonometry.degreesToHours(degrees) }
    @inlinable public static func DegreesToHours(_ degrees: Double) -> Double { SphericalTrigonometry.degreesToHours(degrees) }

    @inlinable public static func hoursToDegrees(_ hours: Double) -> Double { SphericalTrigonometry.hoursToDegrees(hours) }
    @inlinable public static func HoursToDegrees(_ hours: Double) -> Double { SphericalTrigonometry.hoursToDegrees(hours) }

    @inlinable public static func mapTo0To360Range(_ degrees: Double) -> Double { SphericalTrigonometry.mapTo0To360Range(degrees) }
    @inlinable public static func MapTo0To360Range(_ degrees: Double) -> Double { SphericalTrigonometry.mapTo0To360Range(degrees) }

    @inlinable public static func mapTo0To24Range(_ hourAngle: Double) -> Double { SphericalTrigonometry.mapTo0To24Range(hourAngle) }
    @inlinable public static func MapTo0To24Range(_ hourAngle: Double) -> Double { SphericalTrigonometry.mapTo0To24Range(hourAngle) }

    @inlinable public static func mapTo0To2PIRange(_ angle: Double) -> Double { SphericalTrigonometry.mapTo0To2PIRange(angle) }
    @inlinable public static func MapTo0To2PIRange(_ angle: Double) -> Double { SphericalTrigonometry.mapTo0To2PIRange(angle) }

    @inlinable public static func mapToMinus90To90Range(_ degrees: Double) -> Double { SphericalTrigonometry.mapToMinus90To90Range(degrees) }
    @inlinable public static func MapToMinus90To90Range(_ degrees: Double) -> Double { SphericalTrigonometry.mapToMinus90To90Range(degrees) }

    @inlinable public static func mapToMinus180To180Range(_ degrees: Double) -> Double { SphericalTrigonometry.mapToMinus180To180Range(degrees) }
    @inlinable public static func MapToMinus180To180Range(_ degrees: Double) -> Double { SphericalTrigonometry.mapToMinus180To180Range(degrees) }

    @inlinable public static func dmsToDegrees(_ degrees: Double, _ minutes: Double, _ seconds: Double, bPositive: Bool = true) -> Double {
        SphericalTrigonometry.dmsToDegrees(degrees, minutes, seconds, bPositive: bPositive)
    }
    @inlinable public static func dmsToDegrees(degrees: Double, minutes: Double, seconds: Double, bPositive: Bool = true) -> Double {
        SphericalTrigonometry.dmsToDegrees(degrees: degrees, minutes: minutes, seconds: seconds, bPositive: bPositive)
    }
    @inlinable public static func DMSToDegrees(_ degrees: Double, _ minutes: Double, _ seconds: Double, _ bPositive: Bool = true) -> Double {
        SphericalTrigonometry.dmsToDegrees(degrees, minutes, seconds, bPositive: bPositive)
    }

    @inlinable public static func equatorialToEcliptic(alpha: Double, delta: Double, epsilon: Double) -> CAA2DCoordinate {
        SphericalTrigonometry.equatorialToEcliptic(alpha: alpha, delta: delta, epsilon: epsilon)
    }
    @inlinable public static func equatorialToEcliptic(_ alpha: Double, _ delta: Double, _ epsilon: Double) -> CAA2DCoordinate {
        SphericalTrigonometry.equatorialToEcliptic(alpha: alpha, delta: delta, epsilon: epsilon)
    }
    @inlinable public static func Equatorial2Ecliptic(_ Alpha: Double, _ Delta: Double, _ Epsilon: Double) -> CAA2DCoordinate {
        SphericalTrigonometry.equatorialToEcliptic(alpha: Alpha, delta: Delta, epsilon: Epsilon)
    }

    @inlinable public static func eclipticToEquatorial(lambda: Double, beta: Double, epsilon: Double) -> CAA2DCoordinate {
        SphericalTrigonometry.eclipticToEquatorial(lambda: lambda, beta: beta, epsilon: epsilon)
    }
    @inlinable public static func eclipticToEquatorial(_ lambda: Double, _ beta: Double, _ epsilon: Double) -> CAA2DCoordinate {
        SphericalTrigonometry.eclipticToEquatorial(lambda: lambda, beta: beta, epsilon: epsilon)
    }
    @inlinable public static func ecliptic2Equatorial(lambda: Double, beta: Double, epsilon: Double) -> CAA2DCoordinate {
        SphericalTrigonometry.eclipticToEquatorial(lambda: lambda, beta: beta, epsilon: epsilon)
    }
    @inlinable public static func ecliptic2Equatorial(_ lambda: Double, _ beta: Double, _ epsilon: Double) -> CAA2DCoordinate {
        SphericalTrigonometry.eclipticToEquatorial(lambda: lambda, beta: beta, epsilon: epsilon)
    }
    @inlinable public static func Ecliptic2Equatorial(_ Lambda: Double, _ Beta: Double, _ Epsilon: Double) -> CAA2DCoordinate {
        SphericalTrigonometry.eclipticToEquatorial(lambda: Lambda, beta: Beta, epsilon: Epsilon)
    }

    @inlinable public static func equatorialToHorizontal(localHourAngle: Double, delta: Double, latitude: Double) -> CAA2DCoordinate {
        SphericalTrigonometry.equatorialToHorizontal(localHourAngle: localHourAngle, delta: delta, latitude: latitude)
    }
    @inlinable public static func equatorialToHorizontal(alpha: Double, delta: Double, latitude: Double) -> CAA2DCoordinate {
        SphericalTrigonometry.equatorialToHorizontal(localHourAngle: alpha, delta: delta, latitude: latitude)
    }
    @inlinable public static func equatorial2Horizontal(alpha: Double, delta: Double, latitude: Double) -> CAA2DCoordinate {
        SphericalTrigonometry.equatorialToHorizontal(localHourAngle: alpha, delta: delta, latitude: latitude)
    }
    @inlinable public static func equatorial2Horizontal(_ LocalHourAngle: Double, _ Delta: Double, _ Latitude: Double) -> CAA2DCoordinate {
        SphericalTrigonometry.equatorialToHorizontal(localHourAngle: LocalHourAngle, delta: Delta, latitude: Latitude)
    }
    @inlinable public static func Equatorial2Horizontal(_ LocalHourAngle: Double, _ Delta: Double, _ Latitude: Double) -> CAA2DCoordinate {
        SphericalTrigonometry.equatorialToHorizontal(localHourAngle: LocalHourAngle, delta: Delta, latitude: Latitude)
    }

    @inlinable public static func horizontalToEquatorial(azimuth: Double, altitude: Double, latitude: Double) -> CAA2DCoordinate {
        SphericalTrigonometry.horizontalToEquatorial(azimuth: azimuth, altitude: altitude, latitude: latitude)
    }
    @inlinable public static func Horizontal2Equatorial(_ A: Double, _ h: Double, _ Latitude: Double) -> CAA2DCoordinate {
        SphericalTrigonometry.horizontalToEquatorial(azimuth: A, altitude: h, latitude: Latitude)
    }

    @inlinable public static func equatorialToGalactic(alpha: Double, delta: Double) -> CAA2DCoordinate {
        SphericalTrigonometry.equatorialToGalactic(alpha: alpha, delta: delta)
    }
    @inlinable public static func Equatorial2Galactic(_ Alpha: Double, _ Delta: Double) -> CAA2DCoordinate {
        SphericalTrigonometry.equatorialToGalactic(alpha: Alpha, delta: Delta)
    }

    @inlinable public static func galacticToEquatorial(l: Double, b: Double) -> CAA2DCoordinate {
        SphericalTrigonometry.galacticToEquatorial(l: l, b: b)
    }
    @inlinable public static func Galactic2Equatorial(_ l: Double, _ b: Double) -> CAA2DCoordinate {
        SphericalTrigonometry.galacticToEquatorial(l: l, b: b)
    }
}

