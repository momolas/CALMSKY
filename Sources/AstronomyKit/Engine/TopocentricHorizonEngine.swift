//
//  TopocentricHorizonEngine.swift
//  AstronomyKit
//
//  Pure Swift continuous topocentric horizon engine for Rise, Transit, and Set.
//  Replaces Meeus Ch. 15 3-point parabolic interpolation with continuous vector
//  altitude detection, observer elevation horizon dip, and Brent numerical root-finding.
//

import Foundation

/// Result details for topocentric rise, transit, and set calculation.
public struct TopocentricHorizonResult: Sendable, Hashable {
    public var riseJD: Double?
    public var transitJD: Double?
    public var setJD: Double?
    public var isRiseValid: Bool { riseJD != nil }
    public var isTransitValid: Bool { transitJD != nil }
    public var isSetValid: Bool { setJD != nil }
    public var isCircumpolarAbove: Bool
    public var isCircumpolarBelow: Bool
    public var maxAltitudeDeg: Double
    public var minAltitudeDeg: Double

    public init(
        riseJD: Double? = nil,
        transitJD: Double? = nil,
        setJD: Double? = nil,
        isCircumpolarAbove: Bool = false,
        isCircumpolarBelow: Bool = false,
        maxAltitudeDeg: Double = 0.0,
        minAltitudeDeg: Double = 0.0
    ) {
        self.riseJD = riseJD
        self.transitJD = transitJD
        self.setJD = setJD
        self.isCircumpolarAbove = isCircumpolarAbove
        self.isCircumpolarBelow = isCircumpolarBelow
        self.maxAltitudeDeg = maxAltitudeDeg
        self.minAltitudeDeg = minAltitudeDeg
    }
}

/// Continuous vector topocentric horizon engine for celestial rise, transit, and set.
public enum TopocentricHorizonEngine: Sendable {

    /// Computes the angular depression of the geometric horizon (dip of the horizon) in degrees
    /// due to observer elevation above sea level, accounting for terrestrial atmospheric refraction.
    ///
    /// Formula: dip ≈ 1.76' × √(h_meters) / 60.0 degrees.
    /// - Parameter altitudeMeters: Observer elevation in meters above sea level.
    /// - Returns: Depression angle in degrees (always >= 0).
    public static func horizonDip(altitudeMeters: Double) -> Double {
        guard altitudeMeters.isFinite && altitudeMeters > 0.0 else { return 0.0 }
        return (1.76 / 60.0) * sqrt(altitudeMeters)
    }

    /// Computes the effective target geometric altitude for rising and setting,
    /// adjusted for the depression of the horizon.
    ///
    /// - Parameters:
    ///   - standardAltitudeDeg: Nominal altitude at sea level (e.g. -0.8333° for Sun, -0.5667° for stars/planets).
    ///   - altitudeMeters: Observer elevation in meters.
    /// - Returns: Adjusted target altitude in degrees.
    public static func targetRiseSetAltitude(standardAltitudeDeg: Double, altitudeMeters: Double = 0.0) -> Double {
        standardAltitudeDeg - horizonDip(altitudeMeters: altitudeMeters)
    }

    /// Finds a root of `f(x) = 0` on the interval `[a, b]` using Brent's method
    /// (combining bisection, secant, and inverse quadratic interpolation).
    ///
    /// - Parameters:
    ///   - a: Lower bound of the search interval.
    ///   - b: Upper bound of the search interval.
    ///   - tol: Convergence tolerance on the independent variable `x`.
    ///   - maxIter: Maximum number of iterations.
    ///   - f: Objective function to evaluate.
    /// - Returns: The estimated root `x` where `f(x) ≈ 0`, or `nil` if interval does not bracket a root.
    public static func brentRoot(
        a: Double,
        b: Double,
        tol: Double = 1.0e-7,
        maxIter: Int = 60,
        f: (Double) -> Double
    ) -> Double? {
        guard a.isFinite && b.isFinite else { return nil }

        var aVal = a
        var bVal = b
        var fa = f(aVal)
        var fb = f(bVal)

        // Check if either endpoint is already a root
        if abs(fa) < 1.0e-12 { return aVal }
        if abs(fb) < 1.0e-12 { return bVal }

        // Root must be bracketed: f(a) and f(b) must have opposite signs
        guard (fa > 0 && fb < 0) || (fa < 0 && fb > 0) else {
            return nil
        }

        var cVal = aVal
        var fc = fa
        var dVal = bVal - aVal
        var eVal = dVal

        for _ in 0..<maxIter {
            if (fb > 0 && fc > 0) || (fb < 0 && fc < 0) {
                cVal = aVal
                fc = fa
                dVal = bVal - aVal
                eVal = dVal
            }

            if abs(fc) < abs(fb) {
                aVal = bVal
                bVal = cVal
                cVal = aVal
                fa = fb
                fb = fc
                fc = fa
            }

            let tol1 = 2.0 * Double.ulpOfOne * abs(bVal) + 0.5 * tol
            let xm = 0.5 * (cVal - bVal)

            if abs(xm) <= tol1 || abs(fb) < 1.0e-12 {
                return bVal
            }

            if abs(eVal) >= tol1 && abs(fa) > abs(fb) {
                let s = fb / fa
                var pVal: Double
                var qVal: Double

                if abs(aVal - cVal) < 1.0e-12 {
                    // Linear interpolation (secant method)
                    pVal = 2.0 * xm * s
                    qVal = 1.0 - s
                } else {
                    // Inverse quadratic interpolation
                    qVal = fa / fc
                    let r = fb / fc
                    pVal = s * (2.0 * xm * qVal * (qVal - r) - (bVal - aVal) * (r - 1.0))
                    qVal = (qVal - 1.0) * (r - 1.0) * (s - 1.0)
                }

                if pVal > 0 {
                    qVal = -qVal
                } else {
                    pVal = -pVal
                }

                if 2.0 * pVal < min(3.0 * xm * qVal - abs(tol1 * qVal), abs(eVal * qVal)) {
                    eVal = dVal
                    dVal = pVal / qVal
                } else {
                    dVal = xm
                    eVal = dVal
                }
            } else {
                dVal = xm
                eVal = dVal
            }

            aVal = bVal
            fa = fb

            if abs(dVal) > tol1 {
                bVal += dVal
            } else {
                bVal += (xm > 0 ? tol1 : -tol1)
            }
            fb = f(bVal)
        }

        return bVal
    }

    /// Evaluates the topocentric geometric altitude in degrees for an object with fixed equatorial coordinates (e.g. Star).
    public static func altitudeForFixedEquatorial(
        alphaHours: Double,
        deltaDeg: Double,
        jd: Double,
        geoCoords: GeographicCoordinates
    ) -> Double {
        let theta0Deg = CAASidereal.apparentGreenwichSiderealTime(jd) * 15.0
        let localSiderealDeg = theta0Deg - geoCoords.longitude.value
        let hDeg = localSiderealDeg - (alphaHours * 15.0)

        let hRad = SphericalTrigonometry.degreesToRadians(hDeg)
        let latRad = SphericalTrigonometry.degreesToRadians(geoCoords.latitude.value)
        let decRad = SphericalTrigonometry.degreesToRadians(deltaDeg)

        let sinAlt = sin(latRad) * sin(decRad) + cos(latRad) * cos(decRad) * cos(hRad)
        let clampedSinAlt = max(-1.0, min(1.0, sinAlt))
        return SphericalTrigonometry.radiansToDegrees(asin(clampedSinAlt))
    }

    /// Solves for topocentric Rise, Transit, and Set across a nominal 24-hour day using continuous vector altitude
    /// sampling and Brent root-finding.
    ///
    /// - Parameters:
    ///   - centerJD: Reference midnight Julian Day (0h UT).
    ///   - targetAltitudeDeg: Effective target altitude for rising/setting (adjusted for dip).
    ///   - altitudeAt: Closure returning the topocentric altitude in degrees at any Julian Day.
    /// - Returns: `TopocentricHorizonResult` containing the events and circumpolar status.
    public static func solve(
        centerJD: Double,
        targetAltitudeDeg: Double,
        altitudeAt: (Double) -> Double
    ) -> TopocentricHorizonResult {
        guard centerJD.isFinite else { return TopocentricHorizonResult() }

        // 1. Scan altitude profile across a 28-hour window [-2h, +26h] with 30-minute steps
        let sampleStepDays = 0.5 / 24.0 // 30 minutes
        let startJD = centerJD - 2.0 / 24.0
        let endJD = centerJD + 26.0 / 24.0

        var samples: [(jd: Double, alt: Double)] = []
        var currentScanJD = startJD
        var maxAlt = -Double.infinity
        var maxAltJD = centerJD
        var minAlt = Double.infinity

        while currentScanJD <= endJD + 1e-6 {
            let alt = altitudeAt(currentScanJD)
            samples.append((jd: currentScanJD, alt: alt))
            if alt > maxAlt {
                maxAlt = alt
                maxAltJD = currentScanJD
            }
            if alt < minAlt {
                minAlt = alt
            }
            currentScanJD += sampleStepDays
        }

        // 2. Refine transit (culmination / maximum altitude) using golden-section / Brent minimization on -altitude
        var transitJD: Double?
        if maxAltJD >= centerJD - 1.0 / 24.0 && maxAltJD <= centerJD + 25.0 / 24.0 {
            let tLeft = max(startJD, maxAltJD - 1.5 / 24.0)
            let tRight = min(endJD, maxAltJD + 1.5 / 24.0)
            transitJD = goldenSectionMax(a: tLeft, b: tRight, f: altitudeAt)
        }

        // 3. Circumpolar checks
        if minAlt > targetAltitudeDeg {
            // Never dips below target: circumpolar above (e.g. Midnight Sun)
            return TopocentricHorizonResult(
                transitJD: transitJD,
                isCircumpolarAbove: true,
                isCircumpolarBelow: false,
                maxAltitudeDeg: maxAlt,
                minAltitudeDeg: minAlt
            )
        }

        if maxAlt < targetAltitudeDeg {
            // Never reaches target: circumpolar below (e.g. Polar Night)
            return TopocentricHorizonResult(
                transitJD: transitJD,
                isCircumpolarAbove: false,
                isCircumpolarBelow: true,
                maxAltitudeDeg: maxAlt,
                minAltitudeDeg: minAlt
            )
        }

        // 4. Bracket detection and Brent root-finding for Rise and Set
        var riseJD: Double?
        var setJD: Double?

        for i in 0..<(samples.count - 1) {
            let s1 = samples[i]
            let s2 = samples[i + 1]

            let diff1 = s1.alt - targetAltitudeDeg
            let diff2 = s2.alt - targetAltitudeDeg

            if (diff1 <= 0.0 && diff2 >= 0.0) && riseJD == nil {
                // Rising through target altitude
                if let root = brentRoot(a: s1.jd, b: s2.jd, tol: 1e-7, f: { altitudeAt($0) - targetAltitudeDeg }) {
                    if root >= centerJD - 0.5 / 24.0 && root <= centerJD + 24.5 / 24.0 {
                        riseJD = root
                    }
                }
            } else if (diff1 >= 0.0 && diff2 <= 0.0) && setJD == nil {
                // Setting through target altitude
                if let root = brentRoot(a: s1.jd, b: s2.jd, tol: 1e-7, f: { altitudeAt($0) - targetAltitudeDeg }) {
                    if root >= centerJD - 0.5 / 24.0 && root <= centerJD + 24.5 / 24.0 {
                        setJD = root
                    }
                }
            }
        }

        return TopocentricHorizonResult(
            riseJD: riseJD,
            transitJD: transitJD,
            setJD: setJD,
            isCircumpolarAbove: false,
            isCircumpolarBelow: false,
            maxAltitudeDeg: maxAlt,
            minAltitudeDeg: minAlt
        )
    }

    /// Golden-section maximum finder on interval `[a, b]`.
    private static func goldenSectionMax(
        a: Double,
        b: Double,
        tol: Double = 1e-7,
        f: (Double) -> Double
    ) -> Double {
        let r = (sqrt(5.0) - 1.0) / 2.0 // ≈ 0.6180339887
        var x1 = b - r * (b - a)
        var x2 = a + r * (b - a)
        var f1 = f(x1)
        var f2 = f(x2)
        var left = a
        var right = b

        while abs(right - left) > tol {
            if f1 < f2 {
                left = x1
                x1 = x2
                f1 = f2
                x2 = left + r * (right - left)
                f2 = f(x2)
            } else {
                right = x2
                x2 = x1
                f2 = f1
                x1 = right - r * (right - left)
                f1 = f(x1)
            }
        }

        return 0.5 * (left + right)
    }
}
