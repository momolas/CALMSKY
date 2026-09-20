//
//  RiseTransitSetEngine.swift
//  AstronomyKit
//
//  Pure Swift implementation of Meeus Chapter 15: Rise, Transit, and Set times,
//  and polynomial interpolation.
//

import Foundation

// MARK: - CAAInterpolate

public enum CAAInterpolate: Sendable {

    @inlinable
    public static func interpolate(_ n: Double, _ y1: Double, _ y2: Double, _ y3: Double) -> Double {
        let a = y2 - y1
        let b = y3 - y2
        let c = y1 + y3 - 2.0 * y2
        return y2 + (n / 2.0 * (a + b + n * c))
    }

    @inlinable
    public static func Interpolate(_ n: Double, _ y1: Double, _ y2: Double, _ y3: Double) -> Double {
        interpolate(n, y1, y2, y3)
    }

    @inlinable
    public static func interpolate(_ n: Double, _ y1: Double, _ y2: Double, _ y3: Double, _ y4: Double, _ y5: Double) -> Double {
        let a = y2 - y1
        let b = y3 - y2
        let c = y4 - y3
        let d = y5 - y4
        let e = b - a
        let f = c - b
        let g = d - c
        let h = f - e
        let j = g - f
        let k = j - h
        let n2 = n * n
        let n3 = n2 * n
        let n4 = n3 * n

        return y3 + n * ((b + c) / 2.0 - (h + j) / 12.0) +
            n2 * (f / 2.0 - k / 24.0) +
            n3 * ((h + j) / 12.0) +
            n4 * (k / 24.0)
    }

    @inlinable
    public static func Interpolate(_ n: Double, _ y1: Double, _ y2: Double, _ y3: Double, _ y4: Double, _ y5: Double) -> Double {
        interpolate(n, y1, y2, y3, y4, y5)
    }
}

// MARK: - CAARiseTransitSet

public enum CAARiseTransitSet: Sendable {

    @inlinable
    public static func constraintM(_ m: inout Double) {
        while m > 1.0 { m -= 1.0 }
        while m < 0.0 { m += 1.0 }
    }

    @inlinable
    public static func calculateTransit(_ alpha2: Double, _ theta0: Double, _ longitude: Double) -> Double {
        var m0 = ((alpha2 * 15.0) + longitude - theta0) / 360.0
        constraintM(&m0)
        return m0
    }

    @inlinable
    public static func calculateRiseSet(m0: Double, cosH0: Double, details: inout CAARiseTransitSetDetails, m1: inout Double, m2: inout Double) {
        m1 = 0
        m2 = 0
        if cosH0 > -1.0 && cosH0 < 1.0 {
            details.bRiseValid = true
            details.bSetValid = true
            details.bTransitAboveHorizon = true

            let h0 = CAACoordinateTransformation.radiansToDegrees(acos(cosH0))
            m1 = m0 - h0 / 360.0
            m2 = m0 + h0 / 360.0
            constraintM(&m1)
            constraintM(&m2)
        } else if cosH0 < 1.0 {
            details.bTransitAboveHorizon = true
        }
    }

    public static func correctRAValuesForInterpolation(_ alpha1: inout Double, _ alpha2: inout Double, _ alpha3: inout Double) {
        alpha1 = CAACoordinateTransformation.mapTo0To24Range(alpha1)
        alpha2 = CAACoordinateTransformation.mapTo0To24Range(alpha2)
        alpha3 = CAACoordinateTransformation.mapTo0To24Range(alpha3)

        if abs(alpha2 - alpha1) > 12.0 {
            if alpha2 > alpha1 { alpha1 += 24.0 } else { alpha2 += 24.0 }
        }
        if abs(alpha3 - alpha2) > 12.0 {
            if alpha3 > alpha2 { alpha2 += 24.0 } else { alpha3 += 24.0 }
        }
        if abs(alpha2 - alpha1) > 12.0 {
            if alpha2 > alpha1 { alpha1 += 24.0 } else { alpha2 += 24.0 }
        }
        if abs(alpha3 - alpha2) > 12.0 {
            if alpha3 > alpha2 { alpha2 += 24.0 } else { alpha3 += 24.0 }
        }
    }

    @inlinable
    public static func CorrectRAValuesForInterpolation(_ alpha1: inout Double, _ alpha2: inout Double, _ alpha3: inout Double) {
        correctRAValuesForInterpolation(&alpha1, &alpha2, &alpha3)
    }

    private static func calculateRiseHelper(
        details: inout CAARiseTransitSetDetails,
        theta0: Double, deltaT: Double,
        alpha1: Double, delta1: Double,
        alpha2: Double, delta2: Double,
        alpha3: Double, delta3: Double,
        longitude: Double, latitude: Double, latitudeRad: Double, h0: Double,
        m1: inout Double
    ) {
        for _ in 0..<2 {
            if details.bRiseValid {
                _ = CAACoordinateTransformation.mapTo0To360Range(theta0 + 360.985647 * m1)
                let n = m1 + (deltaT / 86400.0)
                let alpha = CAAInterpolate.interpolate(n, alpha1, alpha2, alpha3)
                let delta = CAAInterpolate.interpolate(n, delta1, delta2, delta3)
                let h = theta0 + 360.985647 * m1 - longitude - (alpha * 15.0)
                let horizontal = CAACoordinateTransformation.equatorial2Horizontal(
                    alpha: h / 15.0,
                    delta: delta,
                    latitude: latitude
                )
                let deltaM = (horizontal.y - h0) / (360.0 * cos(CAACoordinateTransformation.degreesToRadians(delta)) * cos(latitudeRad) * sin(CAACoordinateTransformation.degreesToRadians(h)))
                m1 += deltaM
                if m1 < 0.0 || m1 >= 1.0 {
                    details.bRiseValid = false
                }
            }
        }
    }

    private static func calculateSetHelper(
        details: inout CAARiseTransitSetDetails,
        theta0: Double, deltaT: Double,
        alpha1: Double, delta1: Double,
        alpha2: Double, delta2: Double,
        alpha3: Double, delta3: Double,
        longitude: Double, latitude: Double, latitudeRad: Double, h0: Double,
        m2: inout Double
    ) {
        for _ in 0..<2 {
            if details.bSetValid {
                let n = m2 + (deltaT / 86400.0)
                let alpha = CAAInterpolate.interpolate(n, alpha1, alpha2, alpha3)
                let delta = CAAInterpolate.interpolate(n, delta1, delta2, delta3)
                let h = theta0 + 360.985647 * m2 - longitude - (alpha * 15.0)
                let horizontal = CAACoordinateTransformation.equatorial2Horizontal(
                    alpha: h / 15.0,
                    delta: delta,
                    latitude: latitude
                )
                let deltaM = (horizontal.y - h0) / (360.0 * cos(CAACoordinateTransformation.degreesToRadians(delta)) * cos(latitudeRad) * sin(CAACoordinateTransformation.degreesToRadians(h)))
                m2 += deltaM
                if m2 < 0.0 || m2 >= 1.0 {
                    details.bSetValid = false
                }
            }
        }
    }

    private static func calculateTransitHelper(
        details: inout CAARiseTransitSetDetails,
        theta0: Double, deltaT: Double,
        alpha1: Double, alpha2: Double, alpha3: Double,
        longitude: Double,
        m0: inout Double
    ) {
        for _ in 0..<2 {
            if details.bTransitValid {
                let theta1 = CAACoordinateTransformation.mapTo0To360Range(theta0 + 360.985647 * m0)
                let n = m0 + (deltaT / 86400.0)
                let alpha = CAAInterpolate.interpolate(n, alpha1, alpha2, alpha3)
                var h = CAACoordinateTransformation.mapTo0To360Range(theta1 - longitude - (alpha * 15.0))
                if h > 180.0 { h -= 360.0 }
                let deltaM = -h / 360.0
                m0 += deltaM
                if m0 < 0.0 || m0 >= 1.0 {
                    details.bTransitValid = false
                }
            }
        }
    }

    public static func calculate(
        jd: Double,
        alpha1: Double, delta1: Double,
        alpha2: Double, delta2: Double,
        alpha3: Double, delta3: Double,
        longitude: Double, latitude: Double, h0: Double
    ) -> CAARiseTransitSetDetails {
        var details = CAARiseTransitSetDetails()
        details.bRiseValid = false
        details.bSetValid = false
        details.bTransitValid = true
        details.bTransitAboveHorizon = false

        let theta0 = CAASidereal.apparentGreenwichSiderealTime(jd) * 15.0
        let deltaT = CAADynamicalTime.deltaT(jd)

        let delta2Rad = CAACoordinateTransformation.degreesToRadians(delta2)
        let latitudeRad = CAACoordinateTransformation.degreesToRadians(latitude)
        let h0Rad = CAACoordinateTransformation.degreesToRadians(h0)

        let cosH0 = (sin(h0Rad) - sin(latitudeRad) * sin(delta2Rad)) / (cos(latitudeRad) * cos(delta2Rad))

        var m0 = calculateTransit(alpha2, theta0, longitude)
        var m1 = 0.0
        var m2 = 0.0
        calculateRiseSet(m0: m0, cosH0: cosH0, details: &details, m1: &m1, m2: &m2)

        var a1 = alpha1
        var a2 = alpha2
        var a3 = alpha3
        correctRAValuesForInterpolation(&a1, &a2, &a3)

        calculateTransitHelper(details: &details, theta0: theta0, deltaT: deltaT, alpha1: a1, alpha2: a2, alpha3: a3, longitude: longitude, m0: &m0)
        calculateRiseHelper(details: &details, theta0: theta0, deltaT: deltaT, alpha1: a1, delta1: delta1, alpha2: a2, delta2: delta2, alpha3: a3, delta3: delta3, longitude: longitude, latitude: latitude, latitudeRad: latitudeRad, h0: h0, m1: &m1)
        calculateSetHelper(details: &details, theta0: theta0, deltaT: deltaT, alpha1: a1, delta1: delta1, alpha2: a2, delta2: delta2, alpha3: a3, delta3: delta3, longitude: longitude, latitude: latitude, latitudeRad: latitudeRad, h0: h0, m2: &m2)

        details.Rise = details.bRiseValid ? (m1 * 24.0) : 0.0
        details.Set = details.bSetValid ? (m2 * 24.0) : 0.0
        details.Transit = details.bTransitValid ? (m0 * 24.0) : 0.0

        return details
    }

    @inlinable
    public static func Calculate(
        _ jd: Double,
        _ alpha1: Double, _ delta1: Double,
        _ alpha2: Double, _ delta2: Double,
        _ alpha3: Double, _ delta3: Double,
        _ longitude: Double, _ latitude: Double, _ h0: Double
    ) -> CAARiseTransitSetDetails {
        calculate(
            jd: jd,
            alpha1: alpha1, delta1: delta1,
            alpha2: alpha2, delta2: delta2,
            alpha3: alpha3, delta3: delta3,
            longitude: longitude, latitude: latitude, h0: h0
        )
    }
}
