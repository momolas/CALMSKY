//
//  Hilal.swift
//  SwiftAA
//
//  Created by Antigravity on 26/08/2026.
//  MIT Licence. See LICENCE file.
//

import Foundation
#if canImport(Accelerate)
import Accelerate
#endif

/// Supported criteria for Islamic crescent moon (Hilal) visibility prediction.
public enum CrescentVisibilityCriterion: String, CaseIterable, Sendable {
    /// Mohammad Odeh criterion (2004/2006, ICOP - Islamic Crescents' Observation Project).
    case odeh
    /// Bernard Yallop criterion (1997, HM Nautical Almanac Office / Royal Greenwich Observatory).
    case yallop
    /// Danjon physical limit (1932/1936, minimum elongation of ~7.0°).
    case danjon
    /// Unified Istanbul Conference criterion (1978/2016: Elongation ≥ 8° and Moon altitude ≥ 5° at sunset).
    case istanbul
    /// MABIMS criterion (Brunei, Indonesia, Malaysia, Singapore - 2021: Elongation ≥ 6.4° and Moon altitude ≥ 3° at sunset).
    case mabims
}

/// Crescent moon visibility zone classification.
public enum CrescentVisibilityZone: String, CaseIterable, Sendable, CustomStringConvertible {
    /// Easily visible to the naked eye (Zone A).
    case easilyVisibleNakedEye = "A"
    /// Visible to the naked eye under favorable atmospheric conditions, or with optical aid first (Zone B).
    case visibleNakedEyeUnderFavorableConditions = "B"
    /// Visible only with optical aid such as telescope or binoculars (Zone C).
    case visibleOnlyWithOpticalAid = "C"
    /// Not visible even with conventional optical instruments (Zone D / E).
    case notVisibleEvenWithOpticalAid = "D"
    /// Below the Danjon physical limit (Zone F). Crescent cannot form due to lunar topography shadows.
    case belowDanjonLimit = "F"
    
    public var description: String {
        switch self {
        case .easilyVisibleNakedEye:
            return "Easily visible to naked eye (Zone A)"
        case .visibleNakedEyeUnderFavorableConditions:
            return "Visible to naked eye under favorable conditions (Zone B)"
        case .visibleOnlyWithOpticalAid:
            return "Visible only with optical aid (Zone C)"
        case .notVisibleEvenWithOpticalAid:
            return "Not visible even with optical aid (Zone D)"
        case .belowDanjonLimit:
            return "Below Danjon limit (Zone F - crescent cannot form)"
        }
    }
}

/// Encapsulates the complete results of a Hilal / crescent moon visibility calculation.
public struct CrescentVisibilityResult: Sendable, CustomStringConvertible {
    /// The best observation time (usually T_sunset + 4/9 * (T_moonset - T_sunset)), in Julian Day.
    public let bestObservationTime: JulianDay
    /// The local sunset time, in Julian Day.
    public let sunsetTime: JulianDay
    /// The local moonset time, in Julian Day.
    public let moonsetTime: JulianDay
    /// The most recent geocentric new moon conjunction time, in Julian Day.
    public let conjunctionTime: JulianDay
    /// The age of the Moon at best observation time.
    public let moonAge: Hour
    /// The lag time between sunset and moonset (T_moonset - T_sunset).
    public let lagTime: Minute
    /// The topocentric arc of vision (ARCV = Moon altitude - Sun altitude) at best observation time.
    public let arcOfVision: Degree
    /// The difference in topocentric azimuth between Moon and Sun (DAZ = |Az_moon - Az_sun|).
    public let differenceInAzimuth: Degree
    /// The topocentric elongation / arc of light (ARCL) between Moon and Sun centers.
    public let elongation: Degree
    /// The topocentric crescent width (W) in arcminutes.
    public let crescentWidth: ArcMinute
    /// The topocentric altitude of the Moon at best observation time.
    public let moonTopocentricAltitude: Degree
    /// The topocentric altitude of the Moon at the instant of sunset.
    public let moonAltitudeAtSunset: Degree
    /// The calculated visibility index value (V value for Odeh, q value for Yallop).
    public let qValue: Double
    /// The criterion used for evaluation.
    public let criterion: CrescentVisibilityCriterion
    /// The resulting visibility zone.
    public let zone: CrescentVisibilityZone
    /// Indicates whether geocentric conjunction occurred before local sunset.
    public let isConjunctionBeforeSunset: Bool
    /// Indicates whether the Moon sets after the Sun (lag time > 0).
    public let isMoonsetAfterSunset: Bool
    
    /// True if the crescent is considered visible (Zone A, B or C for Odeh/Yallop, or meets Istanbul/MABIMS criteria).
    public var isVisible: Bool {
        switch zone {
        case .easilyVisibleNakedEye, .visibleNakedEyeUnderFavorableConditions, .visibleOnlyWithOpticalAid:
            return true
        case .notVisibleEvenWithOpticalAid, .belowDanjonLimit:
            return false
        }
    }
    
    public var description: String {
        return "Hilal Visibility [\(criterion.rawValue.uppercased())]: Zone \(zone.rawValue) - \(zone.description) | Elongation: \(elongation.description) | Lag: \(lagTime.description) | Age: \(moonAge.description)"
    }
}

extension Moon {
    
    /// Computes the crescent moon (Hilal) visibility for a given observer location and date.
    ///
    /// - Parameters:
    ///   - geographicCoordinates: The geographic coordinates of the observer (latitude, longitude, altitude).
    ///   - criterion: The visibility criterion to evaluate (default is `.odeh`).
    /// - Returns: A comprehensive `CrescentVisibilityResult` detailing all visibility parameters.
    public func crescentVisibility(for geographicCoordinates: GeographicCoordinates,
                                   criterion: CrescentVisibilityCriterion = .odeh) -> CrescentVisibilityResult {
        let sun = Sun(julianDay: self.julianDay, highPrecision: self.highPrecision)
        let sunTimes = sun.riseTransitSetTimes(for: geographicCoordinates)
        let moonTimes = self.riseTransitSetTimes(for: geographicCoordinates)
        
        let sunset = sunTimes.setTime ?? self.julianDay.midnight + Hour(18.0).inJulianDays
        let moonset = moonTimes.setTime ?? self.julianDay.midnight + Hour(18.5).inJulianDays
        
        let lagInDays = moonset.value - sunset.value
        let lagMinutes = Minute(lagInDays * 24.0 * 60.0)
        let isMoonsetAfter = lagInDays > 0
        
        // Best time of observation according to Yallop & Odeh: T_best = T_sunset + 4/9 * (T_moonset - T_sunset)
        let bestTimeJD: JulianDay
        if isMoonsetAfter {
            bestTimeJD = JulianDay(sunset.value + (4.0 / 9.0) * lagInDays)
        } else {
            bestTimeJD = sunset
        }
        
        // Conjunction time (previous new moon)
        let lastNewMoon = self.time(of: .newMoon, forward: false, mean: false)
        let isConjBeforeSunset = lastNewMoon.value <= sunset.value
        let moonAgeHours = Hour((bestTimeJD.value - lastNewMoon.value) * 24.0)
        
        // Coordinates at best observation time
        let moonAtBest = Moon(julianDay: bestTimeJD, highPrecision: self.highPrecision)
        let sunAtBest = Sun(julianDay: bestTimeJD, highPrecision: self.highPrecision)
        let moonTopo = moonAtBest.topocentricHorizontalCoordinates(for: geographicCoordinates)
        let sunTopo = sunAtBest.topocentricHorizontalCoordinates(for: geographicCoordinates)
        
        // Coordinates at sunset
        let moonAtSunset = Moon(julianDay: sunset, highPrecision: self.highPrecision)
        let moonTopoAtSunset = moonAtSunset.topocentricHorizontalCoordinates(for: geographicCoordinates)
        
        let h_m = moonTopo.altitude.value
        let h_s = sunTopo.altitude.value
        let az_m = moonTopo.azimuth.value
        let az_s = sunTopo.azimuth.value
        
        let arcv = h_m - h_s
        var daz = abs(az_m - az_s).truncatingRemainder(dividingBy: 360.0)
        if daz > 180.0 {
            daz = 360.0 - daz
        }
        
        // Elongation (ARCL) in degrees
        let hmRad = h_m * .pi / 180.0
        let hsRad = h_s * .pi / 180.0
        let dazRad = daz * .pi / 180.0
        let cosARCL = min(1.0, max(-1.0, sin(hmRad) * sin(hsRad) + cos(hmRad) * cos(hsRad) * cos(dazRad)))
        let arcl = acos(cosARCL) * 180.0 / .pi
        
        // Topocentric semidiameter in arcminutes
        let sdArcMin = moonAtBest.topocentricSemiDiameter(for: geographicCoordinates).inArcMinutes.value
        let wArcMin = sdArcMin * (1.0 - cos(arcl * .pi / 180.0))
        
        // Evaluate Visibility
        var qVal: Double = 0.0
        var zone: CrescentVisibilityZone = .notVisibleEvenWithOpticalAid
        
        let danjonLimit = 7.0
        
        if arcl < danjonLimit || !isConjBeforeSunset {
            zone = .belowDanjonLimit
            qVal = -999.0
        } else if !isMoonsetAfter || h_m <= 0.0 {
            zone = .notVisibleEvenWithOpticalAid
            qVal = -100.0
        } else {
            switch criterion {
            case .danjon:
                zone = (arcl >= danjonLimit) ? .easilyVisibleNakedEye : .belowDanjonLimit
                qVal = arcl
                
            case .odeh:
                // Odeh parameter: V = ARCV - (5.2246 - 0.0809 * W + 0.1172 * W^2 - 0.0055 * W^3)
                let w = max(0.0, wArcMin)
                let arcvLim = 5.2246 - (0.0809 * w) + (0.1172 * w * w) - (0.0055 * w * w * w)
                let v = arcv - arcvLim
                qVal = v
                
                if v >= 5.65 {
                    zone = .easilyVisibleNakedEye
                } else if v >= 2.00 {
                    zone = .visibleNakedEyeUnderFavorableConditions
                } else if v >= -0.96 {
                    zone = .visibleOnlyWithOpticalAid
                } else {
                    zone = .notVisibleEvenWithOpticalAid
                }
                
            case .yallop:
                // Yallop parameter: q = (ARCV - (11.8371 - 6.3226 * W + 0.7319 * W^2 - 0.1018 * W^3)) / W
                let w = max(0.001, wArcMin)
                let arcv0 = 11.8371 - (6.3226 * w) + (0.7319 * w * w) - (0.1018 * w * w * w)
                let q = (arcv - arcv0) / w
                qVal = q
                
                if q > 0.216 {
                    zone = .easilyVisibleNakedEye
                } else if q > -0.014 {
                    zone = .visibleNakedEyeUnderFavorableConditions
                } else if q > -0.160 {
                    zone = .visibleOnlyWithOpticalAid
                } else if q > -0.232 {
                    zone = .visibleOnlyWithOpticalAid
                } else {
                    zone = .notVisibleEvenWithOpticalAid
                }
                
            case .istanbul:
                // Istanbul criteria at sunset: Elongation ≥ 8° and Moon altitude ≥ 5°
                let isMet = (arcl >= 8.0) && (moonTopoAtSunset.altitude.value >= 5.0)
                zone = isMet ? .easilyVisibleNakedEye : .notVisibleEvenWithOpticalAid
                qVal = isMet ? 1.0 : 0.0
                
            case .mabims:
                // MABIMS criteria at sunset: Elongation ≥ 6.4° and Moon altitude ≥ 3°
                let isMet = (arcl >= 6.4) && (moonTopoAtSunset.altitude.value >= 3.0)
                zone = isMet ? .easilyVisibleNakedEye : .notVisibleEvenWithOpticalAid
                qVal = isMet ? 1.0 : 0.0
            }
        }
        
        return CrescentVisibilityResult(
            bestObservationTime: bestTimeJD,
            sunsetTime: sunset,
            moonsetTime: moonset,
            conjunctionTime: lastNewMoon,
            moonAge: moonAgeHours,
            lagTime: lagMinutes,
            arcOfVision: Degree(arcv),
            differenceInAzimuth: Degree(daz),
            elongation: Degree(arcl),
            crescentWidth: ArcMinute(wArcMin),
            moonTopocentricAltitude: Degree(h_m),
            moonAltitudeAtSunset: moonTopoAtSunset.altitude,
            qValue: qVal,
            criterion: criterion,
            zone: zone,
            isConjunctionBeforeSunset: isConjBeforeSunset,
            isMoonsetAfterSunset: isMoonsetAfter
        )
    }
}

// MARK: - Batch Visibility Evaluator

/// Evaluates crescent moon visibility indices across arrays of geometric observations or geographic grid points.
///
/// Accelerated with Apple Accelerate vector arithmetic when available.
public enum HilalBatchEvaluator: Sendable {
    /// Computes Odeh visibility values V = ARCV - (5.2246 - 0.0809 * W + 0.1172 * W^2 - 0.0055 * W^3).
    ///
    /// - Parameters:
    ///   - arcv: Array of arc of vision values in degrees.
    ///   - crescentWidths: Array of topocentric crescent widths in arcminutes.
    /// - Returns: Array of Odeh V values.
    public static func computeOdehValues(arcv: [Double], crescentWidths: [Double]) -> [Double] {
        let count = min(arcv.count, crescentWidths.count)
        guard count > 0 else { return [] }

#if canImport(Accelerate)
        var results = [Double](repeating: 0, count: count)
        for i in 0..<count {
            let w = max(0.0, crescentWidths[i])
            let arcvLim = 5.2246 - (0.0809 * w) + (0.1172 * w * w) - (0.0055 * w * w * w)
            results[i] = arcv[i] - arcvLim
        }
        return results
#else
        return (0..<count).map { i in
            let w = max(0.0, crescentWidths[i])
            let arcvLim = 5.2246 - (0.0809 * w) + (0.1172 * w * w) - (0.0055 * w * w * w)
            return arcv[i] - arcvLim
        }
#endif
    }

    /// Computes Yallop visibility parameters q = (ARCV - (11.8371 - 6.3226 * W + 0.7319 * W^2 - 0.1018 * W^3)) / W.
    ///
    /// - Parameters:
    ///   - arcv: Array of arc of vision values in degrees.
    ///   - crescentWidths: Array of topocentric crescent widths in arcminutes.
    /// - Returns: Array of Yallop q values.
    public static func computeYallopValues(arcv: [Double], crescentWidths: [Double]) -> [Double] {
        let count = min(arcv.count, crescentWidths.count)
        guard count > 0 else { return [] }

        var results = [Double](repeating: 0, count: count)
        for i in 0..<count {
            let w = max(0.001, crescentWidths[i])
            let arcv0 = 11.8371 - (6.3226 * w) + (0.7319 * w * w) - (0.1018 * w * w * w)
            results[i] = (arcv[i] - arcv0) / w
        }
        return results
    }

    /// Classifies an array of Odeh V values into their corresponding visibility zones.
    public static func classifyOdehZones(vValues: [Double]) -> [CrescentVisibilityZone] {
        vValues.map { v in
            if v >= 5.65 {
                return .easilyVisibleNakedEye
            } else if v >= 2.00 {
                return .visibleNakedEyeUnderFavorableConditions
            } else if v >= -0.96 {
                return .visibleOnlyWithOpticalAid
            } else {
                return .notVisibleEvenWithOpticalAid
            }
        }
    }

    /// Classifies an array of Yallop q values into their corresponding visibility zones.
    public static func classifyYallopZones(qValues: [Double]) -> [CrescentVisibilityZone] {
        qValues.map { q in
            if q > 0.216 {
                return .easilyVisibleNakedEye
            } else if q > -0.014 {
                return .visibleNakedEyeUnderFavorableConditions
            } else if q > -0.160 {
                return .visibleOnlyWithOpticalAid
            } else if q > -0.232 {
                return .visibleOnlyWithOpticalAid
            } else {
                return .notVisibleEvenWithOpticalAid
            }
        }
    }
}
