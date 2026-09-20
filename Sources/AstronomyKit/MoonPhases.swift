//
//  MoonPhases.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Foundation

/// The eight conventional lunar phases based on Moon-Sun elongation.
public enum LunarPhase: String, CaseIterable, Sendable, Identifiable, Codable {
    case newMoon
    case waxingCrescent
    case firstQuarter
    case waxingGibbous
    case fullMoon
    case waningGibbous
    case lastQuarter
    case waningCrescent

    public var id: String { rawValue }

    /// Standard English name.
    public var name: String {
        switch self {
        case .newMoon: return "New Moon"
        case .waxingCrescent: return "Waxing Crescent"
        case .firstQuarter: return "First Quarter"
        case .waxingGibbous: return "Waxing Gibbous"
        case .fullMoon: return "Full Moon"
        case .waningGibbous: return "Waning Gibbous"
        case .lastQuarter: return "Last Quarter"
        case .waningCrescent: return "Waning Crescent"
        }
    }

    /// Astronomical emoji representation.
    public var symbol: String {
        switch self {
        case .newMoon: return "🌑"
        case .waxingCrescent: return "🌒"
        case .firstQuarter: return "🌓"
        case .waxingGibbous: return "🌔"
        case .fullMoon: return "🌕"
        case .waningGibbous: return "🌖"
        case .lastQuarter: return "🌗"
        case .waningCrescent: return "🌘"
        }
    }

    /// Whether the Moon's illuminated disk is currently growing.
    public var isWaxing: Bool {
        switch self {
        case .waxingCrescent, .firstQuarter, .waxingGibbous: return true
        default: return false
        }
    }

    /// Creates a LunarPhase from the Moon-Sun ecliptic longitude difference (0° ..< 360°).
    public init(elongation: Degree) {
        let reduced = elongation.reduced.value
        switch reduced {
        case 337.5...360.0, 0.0..<22.5:
            self = .newMoon
        case 22.5..<67.5:
            self = .waxingCrescent
        case 67.5..<112.5:
            self = .firstQuarter
        case 112.5..<157.5:
            self = .waxingGibbous
        case 157.5..<202.5:
            self = .fullMoon
        case 202.5..<247.5:
            self = .waningGibbous
        case 247.5..<292.5:
            self = .lastQuarter
        default:
            self = .waningCrescent
        }
    }
}

// MARK: - MoonPhase (4 Quarters) Extensions

public extension MoonPhase {
    var name: String {
        switch self {
        case .newMoon: return "New Moon"
        case .firstQuarter: return "First Quarter"
        case .fullMoon: return "Full Moon"
        case .lastQuarter: return "Last Quarter"
        }
    }

    var symbol: String {
        switch self {
        case .newMoon: return "🌑"
        case .firstQuarter: return "🌓"
        case .fullMoon: return "🌕"
        case .lastQuarter: return "🌗"
        }
    }

    /// Fractional offset to the lunation index k in Meeus algorithm.
    var kOffset: Double {
        switch self {
        case .newMoon: return 0.0
        case .firstQuarter: return 0.25
        case .fullMoon: return 0.50
        case .lastQuarter: return 0.75
        }
    }
}

/// A timed occurrence of a primary lunar phase (quarter).
public struct MoonPhaseEvent: Sendable, Hashable, Codable, Identifiable {
    public var id: Double { julianDay.value }
    public let phase: MoonPhase
    public let julianDay: JulianDay

    public init(phase: MoonPhase, julianDay: JulianDay) {
        self.phase = phase
        self.julianDay = julianDay
    }
}

// MARK: - Moon Phase Calculations

public extension Moon {
    /// The current phase category of the Moon (one of the eight classical phases).
    var lunarPhase: LunarPhase {
        let sun = Sun(julianDay: self.julianDay, highPrecision: self.highPrecision)
        let moonLon = self.eclipticCoordinates.celestialLongitude
        let sunLon = sun.eclipticCoordinates.celestialLongitude
        let elongation = (moonLon - sunLon).reduced
        return LunarPhase(elongation: elongation)
    }

    /// Computes the exact Julian Day of the next occurrence of the specified primary phase.
    ///
    /// - Parameters:
    ///   - phase: The primary phase to predict.
    ///   - jd: The reference epoch after which to search.
    /// - Returns: The exact Julian Day of the event.
    static func nextPhase(_ phase: MoonPhase, after jd: JulianDay) -> JulianDay {
        let year = jd.date.fractionalYear
        let baseK = floor(CAAMoonPhases.K(year))
        var searchK = baseK - 2
        while true {
            let k = searchK + phase.kOffset
            let trueJD = JulianDay(CAAMoonPhases.TruePhase(k))
            if trueJD.value > jd.value + 0.0001 {
                return trueJD
            }
            searchK += 1
        }
    }

    /// Computes all primary lunar phases occurring within a date range.
    ///
    /// - Parameters:
    ///   - startJD: The start of the time interval.
    ///   - endJD: The end of the time interval.
    /// - Returns: An array of `MoonPhaseEvent` ordered chronologically.
    static func phases(from startJD: JulianDay, to endJD: JulianDay) -> [MoonPhaseEvent] {
        guard startJD <= endJD else { return [] }
        let startYear = startJD.date.fractionalYear
        let endYear = endJD.date.fractionalYear
        let minK = floor(CAAMoonPhases.K(startYear)) - 2
        let maxK = ceil(CAAMoonPhases.K(endYear)) + 2

        var events: [MoonPhaseEvent] = []
        for intK in stride(from: Int(minK), through: Int(maxK), by: 1) {
            for phase in MoonPhase.allCases {
                let k = Double(intK) + phase.kOffset
                let eventJD = JulianDay(CAAMoonPhases.TruePhase(k))
                if eventJD >= startJD && eventJD <= endJD {
                    events.append(MoonPhaseEvent(phase: phase, julianDay: eventJD))
                }
            }
        }
        return events.sorted { $0.julianDay < $1.julianDay }
    }
}
