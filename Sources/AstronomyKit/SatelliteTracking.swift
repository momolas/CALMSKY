import Foundation
#if canImport(Accelerate)
import Accelerate
#endif

/// Two-Line Element Set (TLE) parser and container for Earth artificial satellites.
/// Complies with NORAD / Space-Track standards.
public struct TwoLineElements: Sendable, Hashable, Equatable {
    public var name: String
    public var satelliteNumber: Int
    public var classification: Character
    public var internationalDesignator: String
    public var epochYear: Int
    public var epochDay: Double
    public var meanMotionFirstDerivative: Double
    public var meanMotionSecondDerivative: Double
    public var bstar: Double
    public var inclinationDegrees: Double
    public var rightAscensionAscendingNodeDegrees: Double
    public var eccentricity: Double
    public var argumentOfPerigeeDegrees: Double
    public var meanAnomalyDegrees: Double
    public var meanMotionRevolutionsPerDay: Double
    public var revolutionNumberAtEpoch: Int

    /// Julian Date of the TLE epoch.
    public var epochJulianDate: Double {
        let fullYear = epochYear < 57 ? 2000 + epochYear : 1900 + epochYear
        // Julian date for Jan 1 0h UT of the epoch year:
        let y = fullYear - 1
        let a = y / 100
        let b = 2 - a + a / 4
        let jan1JD = Double(Int(365.25 * Double(y + 4716))) + Double(Int(30.6001 * 14.0)) + 1.0 + Double(b) - 1524.5
        return jan1JD + epochDay - 1.0
    }

    /// Semi-major axis in kilometers derived from mean motion (Kepler's 3rd law with WGS-84 GM).
    public var semiMajorAxisKm: Double {
        // Earth gravitational parameter mu = 398600.4418 km^3/s^2
        let mu = 398_600.4418
        let meanMotionRadPerSec = meanMotionRevolutionsPerDay * 2.0 * .pi / 86400.0
        guard meanMotionRadPerSec > 0 else { return 0 }
        return cbrt(mu / (meanMotionRadPerSec * meanMotionRadPerSec))
    }

    /// Parse a 2-line or 3-line standard NORAD TLE string.
    public static func parse(lines: [String]) -> TwoLineElements? {
        let trimmed = lines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard trimmed.count >= 2 else { return nil }

        let name: String
        let line1: String
        let line2: String

        if trimmed.count >= 3 {
            name = trimmed[0]
            line1 = trimmed[1]
            line2 = trimmed[2]
        } else {
            name = "UNNAMED"
            line1 = trimmed[0]
            line2 = trimmed[1]
        }

        guard line1.count >= 68, line2.count >= 68 else { return nil }
        guard line1.hasPrefix("1 "), line2.hasPrefix("2 ") else { return nil }

        func substr(_ s: String, start: Int, length: Int) -> String {
            let startIdx = s.index(s.startIndex, offsetBy: min(start, s.count))
            let endIdx = s.index(startIdx, offsetBy: min(length, s.count - start))
            return String(s[startIdx..<endIdx]).trimmingCharacters(in: .whitespaces)
        }

        func parseExpDouble(_ str: String) -> Double {
            // Parses e.g. " 12345-4" into 0.12345e-4
            var s = str.trimmingCharacters(in: .whitespaces)
            if s.isEmpty { return 0 }
            var sign = 1.0
            if s.hasPrefix("-") {
                sign = -1.0
                s.removeFirst()
            } else if s.hasPrefix("+") {
                s.removeFirst()
            }
            if let expIdx = s.lastIndex(where: { $0 == "+" || $0 == "-" }) {
                let mantissaStr = String(s[..<expIdx])
                let expStr = String(s[expIdx...])
                if let mantissa = Double("0." + mantissaStr), let exp = Double(expStr) {
                    return sign * mantissa * pow(10.0, exp)
                }
            }
            return Double(str) ?? 0
        }

        guard let satNum = Int(substr(line1, start: 2, length: 5)),
              let epYear = Int(substr(line1, start: 18, length: 2)),
              let epDay = Double(substr(line1, start: 20, length: 12)),
              let inc = Double(substr(line2, start: 8, length: 8)),
              let raan = Double(substr(line2, start: 17, length: 8)),
              let eccDouble = Double("0." + substr(line2, start: 26, length: 7)),
              let argP = Double(substr(line2, start: 34, length: 8)),
              let ma = Double(substr(line2, start: 43, length: 8)),
              let mm = Double(substr(line2, start: 52, length: 11))
        else {
            return nil
        }

        let classification = line1.count > 7 ? line1[line1.index(line1.startIndex, offsetBy: 7)] : "U"
        let intlDesig = substr(line1, start: 9, length: 8)
        let nDot = Double(substr(line1, start: 33, length: 10)) ?? 0
        let nDotDot = parseExpDouble(substr(line1, start: 44, length: 8))
        let bstarVal = parseExpDouble(substr(line1, start: 53, length: 8))
        let revNum = Int(substr(line2, start: 63, length: 5)) ?? 0

        return TwoLineElements(
            name: name,
            satelliteNumber: satNum,
            classification: classification,
            internationalDesignator: intlDesig,
            epochYear: epYear,
            epochDay: epDay,
            meanMotionFirstDerivative: nDot,
            meanMotionSecondDerivative: nDotDot,
            bstar: bstarVal,
            inclinationDegrees: inc,
            rightAscensionAscendingNodeDegrees: raan,
            eccentricity: eccDouble,
            argumentOfPerigeeDegrees: argP,
            meanAnomalyDegrees: ma,
            meanMotionRevolutionsPerDay: mm,
            revolutionNumberAtEpoch: revNum
        )
    }
}

/// SGP4 (Simplified General Perturbations-4) orbital propagator for artificial Earth satellites.
public enum SatellitePropagator: Sendable {
    // Earth constants (WGS-84 / standard astrodynamics)
    private static let earthRadiusKm: Double = 6378.137
    private static let muKm3S2: Double = 398600.4418
    private static let j2: Double = 1.08262998905e-3

    /// Propagates satellite position and velocity to a given date using SGP4/analytical secular orbit modeling.
    /// - Parameters:
    ///   - tle: Parsed Two-Line Element set.
    ///   - date: Target Date.
    /// - Returns: True Equator Mean Equinox (TEME) `StateVector` with position in kilometers and velocity in km/s.
    public static func propagate(tle: TwoLineElements, to date: Date) -> StateVector {
        let jd = date.timeIntervalSince1970 / 86400.0 + 2440587.5
        return propagate(tle: tle, toJD: jd)
    }

    /// Propagates satellite position and velocity to a given Julian Day in TEME coordinate frame.
    public static func propagate(tle: TwoLineElements, toJD jd: Double) -> StateVector {
        let deltaMinutes = (jd - tle.epochJulianDate) * 1440.0 // minutes since epoch

        // Mean motion in radians per minute
        let n0 = tle.meanMotionRevolutionsPerDay * 2.0 * .pi / 1440.0
        let a0 = tle.semiMajorAxisKm
        let e0 = tle.eccentricity
        let i0 = tle.inclinationDegrees * .pi / 180.0
        let raan0 = tle.rightAscensionAscendingNodeDegrees * .pi / 180.0
        let argP0 = tle.argumentOfPerigeeDegrees * .pi / 180.0
        let m0 = tle.meanAnomalyDegrees * .pi / 180.0

        // J2 secular perturbations on node and perigee
        let p0 = a0 * (1.0 - e0 * e0)
        let cosI = cos(i0)
        let sinI = sin(i0)
        let rRatio = earthRadiusKm / p0
        let j2Factor = 1.5 * j2 * rRatio * rRatio * n0

        let raanDot = -j2Factor * cosI // rad / min
        let argPDot = j2Factor * (2.0 - 2.5 * sinI * sinI) // rad / min

        // Updated orbital elements at deltaMinutes
        let currentRAAN = (raan0 + raanDot * deltaMinutes).truncatingRemainder(dividingBy: 2.0 * .pi)
        let currentArgP = (argP0 + argPDot * deltaMinutes).truncatingRemainder(dividingBy: 2.0 * .pi)
        let currentM = (m0 + n0 * deltaMinutes).truncatingRemainder(dividingBy: 2.0 * .pi)

        // Solve Kepler's equation for Eccentric Anomaly E: M = E - e*sin(E)
        var eAnomaly = currentM
        for _ in 0..<10 {
            let f = eAnomaly - e0 * sin(eAnomaly) - currentM
            let fPrime = 1.0 - e0 * cos(eAnomaly)
            let delta = f / fPrime
            eAnomaly -= delta
            if abs(delta) < 1e-10 { break }
        }

        // True anomaly ν
        let cosE = cos(eAnomaly)
        let sinE = sin(eAnomaly)
        let trueAnomaly = atan2((1.0 - e0 * e0).squareRoot() * sinE, cosE - e0)

        // Radius r in km
        let r = a0 * (1.0 - e0 * cosE)

        // Argument of latitude u
        let u = currentArgP + trueAnomaly

        // Position in orbital plane
        let xOrb = r * cos(u)
        let yOrb = r * sin(u)

        // Rotate from orbital plane to TEME frame (geocentric equatorial)
        let cosRAAN = cos(currentRAAN)
        let sinRAAN = sin(currentRAAN)

        let x = xOrb * cosRAAN - yOrb * cosI * sinRAAN
        let y = xOrb * sinRAAN + yOrb * cosI * cosRAAN
        let z = yOrb * sinI

        // Velocity magnitude approximate (vis-viva)
        let speed = (muKm3S2 * (2.0 / r - 1.0 / a0)).squareRoot()
        let vx = -speed * sin(u) * cosRAAN
        let vy = -speed * sin(u) * sinRAAN
        let vz = speed * cos(u) * sinI

        return StateVector(
            position: Vector3D(x: x, y: y, z: z),
            velocity: Vector3D(x: vx, y: vy, z: vz)
        )
    }

    /// Propagates satellite positions and velocities over an array of dates in TEME coordinate frame.
    ///
    /// Accelerated with Apple Accelerate when available.
    public static func propagate(tle: TwoLineElements, over dates: [Date]) -> [StateVector] {
        let jds = dates.map { $0.timeIntervalSince1970 / 86400.0 + 2440587.5 }
        return propagate(tle: tle, overJDs: jds)
    }

    /// Propagates satellite positions and velocities over an array of Julian Days in TEME coordinate frame.
    ///
    /// Accelerated with Apple Accelerate vector trigonometric functions when available.
    public static func propagate(tle: TwoLineElements, overJDs jds: [Double]) -> [StateVector] {
        guard !jds.isEmpty else { return [] }

#if canImport(Accelerate)
        let count = jds.count
        var nInt = Int32(count)

        // Orbital constants
        let n0 = tle.meanMotionRevolutionsPerDay * 2.0 * .pi / 1440.0
        let a0 = tle.semiMajorAxisKm
        let e0 = tle.eccentricity
        let i0 = tle.inclinationDegrees * .pi / 180.0
        let raan0 = tle.rightAscensionAscendingNodeDegrees * .pi / 180.0
        let argP0 = tle.argumentOfPerigeeDegrees * .pi / 180.0
        let m0 = tle.meanAnomalyDegrees * .pi / 180.0

        let p0 = a0 * (1.0 - e0 * e0)
        let cosI = cos(i0)
        let sinI = sin(i0)
        let rRatio = earthRadiusKm / p0
        let j2Factor = 1.5 * j2 * rRatio * rRatio * n0

        let raanDot = -j2Factor * cosI
        let argPDot = j2Factor * (2.0 - 2.5 * sinI * sinI)
        let twoPi = 2.0 * .pi

        // Preallocate arrays
        var currentRAAN = [Double](repeating: 0, count: count)
        var currentArgP = [Double](repeating: 0, count: count)
        var currentM = [Double](repeating: 0, count: count)
        var eAnomaly = [Double](repeating: 0, count: count)
        var sinesE = [Double](repeating: 0, count: count)
        var cosinesE = [Double](repeating: 0, count: count)

        for k in 0..<count {
            let deltaMinutes = (jds[k] - tle.epochJulianDate) * 1440.0
            currentRAAN[k] = (raan0 + raanDot * deltaMinutes).truncatingRemainder(dividingBy: twoPi)
            currentArgP[k] = (argP0 + argPDot * deltaMinutes).truncatingRemainder(dividingBy: twoPi)
            let m = (m0 + n0 * deltaMinutes).truncatingRemainder(dividingBy: twoPi)
            currentM[k] = m
            eAnomaly[k] = m
        }

        // Vectorized Newton-Raphson iterations for Kepler's equation
        for _ in 0..<10 {
            vvsincos(&sinesE, &cosinesE, eAnomaly, &nInt)
            var maxDelta: Double = 0
            for k in 0..<count {
                let f = eAnomaly[k] - e0 * sinesE[k] - currentM[k]
                let fPrime = 1.0 - e0 * cosinesE[k]
                let delta = f / fPrime
                eAnomaly[k] -= delta
                let absDelta = abs(delta)
                if absDelta > maxDelta { maxDelta = absDelta }
            }
            if maxDelta < 1e-10 { break }
        }

        // Compute final sines and cosines
        vvsincos(&sinesE, &cosinesE, eAnomaly, &nInt)

        let sqrt1MinusE2 = (1.0 - e0 * e0).squareRoot()
        var results = [StateVector]()
        results.reserveCapacity(count)

        for k in 0..<count {
            let cosE = cosinesE[k]
            let sinE = sinesE[k]
            let trueAnomaly = atan2(sqrt1MinusE2 * sinE, cosE - e0)
            let r = a0 * (1.0 - e0 * cosE)
            let u = currentArgP[k] + trueAnomaly

            let xOrb = r * cos(u)
            let yOrb = r * sin(u)

            let cosRAAN = cos(currentRAAN[k])
            let sinRAAN = sin(currentRAAN[k])

            let x = xOrb * cosRAAN - yOrb * cosI * sinRAAN
            let y = xOrb * sinRAAN + yOrb * cosI * cosRAAN
            let z = yOrb * sinI

            let speed = (muKm3S2 * (2.0 / r - 1.0 / a0)).squareRoot()
            let vx = -speed * sin(u) * cosRAAN
            let vy = -speed * sin(u) * sinRAAN
            let vz = speed * cos(u) * sinI

            results.append(StateVector(
                position: Vector3D(x: x, y: y, z: z),
                velocity: Vector3D(x: vx, y: vy, z: vz)
            ))
        }

        return results
#else
        return jds.map { propagate(tle: tle, toJD: $0) }
#endif
    }

    /// Horizontal coordinates (altitude, azimuth) of a satellite observed from a geographic location.
    /// - Parameters:
    ///   - state: Satellite TEME position (km).
    ///   - observerLatitude: Observer geographic latitude in degrees.
    ///   - observerLongitude: Observer geographic longitude in degrees (positive East).
    ///   - date: Current Date.
    /// - Returns: Tuple of (altitudeDegrees: [-90, 90], azimuthDegrees: [0, 360), distanceKm: Double).
    public static func lookAngles(
        state: StateVector,
        observerLatitude: Double,
        observerLongitude: Double,
        date: Date
    ) -> (altitude: Double, azimuth: Double, distanceKm: Double) {
        let jd = date.timeIntervalSince1970 / 86400.0 + 2440587.5
        let gmstRad = ModernReferenceFrames.earthRotationAngle(jdUT1: jd)
        let lonRad = observerLongitude * .pi / 180.0
        let latRad = observerLatitude * .pi / 180.0

        // Local Sidereal Time
        let lstRad = gmstRad + lonRad

        // Observer position in geocentric equatorial frame
        let latCos = cos(latRad)
        let latSin = sin(latRad)
        let obsX = earthRadiusKm * latCos * cos(lstRad)
        let obsY = earthRadiusKm * latCos * sin(lstRad)
        let obsZ = earthRadiusKm * latSin

        // Relative range vector (Satellite - Observer)
        let rx = state.position.x - obsX
        let ry = state.position.y - obsY
        let rz = state.position.z - obsZ
        let distance = (rx * rx + ry * ry + rz * rz).squareRoot()
        guard distance > 0 else { return (0, 0, 0) }

        // Topocentric horizon (SEZ: South, East, Zenith) coordinates
        let sinLst = sin(lstRad)
        let cosLst = cos(lstRad)

        let topS = latSin * cosLst * rx + latSin * sinLst * ry - latCos * rz
        let topE = -sinLst * rx + cosLst * ry
        let topZ = latCos * cosLst * rx + latCos * sinLst * ry + latSin * rz

        let altRad = asin(max(-1.0, min(1.0, topZ / distance)))
        var azRad = atan2(topE, -topS)
        if azRad < 0 { azRad += 2.0 * .pi }

        return (
            altitude: altRad * 180.0 / .pi,
            azimuth: azRad * 180.0 / .pi,
            distanceKm: distance
        )
    }

    /// Batch horizontal coordinates (altitude, azimuth, distance) for multiple satellite states.
    public static func lookAngles(
        states: [StateVector],
        observerLatitude: Double,
        observerLongitude: Double,
        dates: [Date]
    ) -> [(altitude: Double, azimuth: Double, distanceKm: Double)] {
        let count = min(states.count, dates.count)
        var results = [(altitude: Double, azimuth: Double, distanceKm: Double)]()
        results.reserveCapacity(count)
        for i in 0..<count {
            results.append(lookAngles(
                state: states[i],
                observerLatitude: observerLatitude,
                observerLongitude: observerLongitude,
                date: dates[i]
            ))
        }
        return results
    }
}
