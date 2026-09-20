//
//  AtmosphericAirMass.swift
//  SwiftAA
//
//  Created for SwiftAA.
//  MIT Licence. See LICENCE file.
//

import Foundation

/// Methods to compute relative optical air mass and astronomical observation windows.
public struct AtmosphericAirMass: Sendable {
    
    /// Computes the relative optical air mass using Pickering's (2002) formula.
    /// Air mass is normalized to 1.0 at the zenith (true altitude = 90°).
    /// - Parameter trueAltitude: The true geometric altitude of the celestial body above the horizon.
    /// - Returns: Relative air mass $X$ (e.g. 1.0 at zenith, ~38 near horizon). Returns `.infinity` for altitude $\le -1^\circ$.
    public static func pickeringAirMass(trueAltitude: Degree) -> Double {
        let h = trueAltitude.value
        guard h > -0.5 else { return .infinity }
        // Pickering (2002) formula: 1 / sin(h + 244 / (165 + 47 * h^1.1))
        let sinArg = (h + 244.0 / (165.0 + 47.0 * pow(max(h, 0.0), 1.1))) * .pi / 180.0
        return 1.0 / sin(sinArg)
    }

    /// Computes the relative optical air mass using Rozenberg's (1966) formula.
    /// - Parameter trueAltitude: The true geometric altitude of the celestial body.
    /// - Returns: Relative air mass.
    public static func rozenbergAirMass(trueAltitude: Degree) -> Double {
        let h = trueAltitude.value
        guard h > -0.5 else { return .infinity }
        let sinH = sin(h * .pi / 180.0)
        return 1.0 / (sinH + 0.025 * exp(-11.0 * sinH))
    }
}

/// Criteria for assessing night-sky observability of a target.
public struct ObservationWindow: Sendable, Codable, Hashable {
    /// True if the target is above the minimum altitude (e.g. 30°)
    public let isTargetElevated: Bool
    /// True if the Sun is below astronomical twilight (-18°)
    public let isAstronomicalNight: Bool
    /// True if both conditions are met
    public var isOptimal: Bool { isTargetElevated && isAstronomicalNight }
    /// Optical air mass of the target at that moment
    public let airMass: Double
    
    public init(isTargetElevated: Bool, isAstronomicalNight: Bool, airMass: Double) {
        self.isTargetElevated = isTargetElevated
        self.isAstronomicalNight = isAstronomicalNight
        self.airMass = airMass
    }
}

public extension HorizontalCoordinates {
    
    /// Calculate current relative air mass for these horizontal coordinates.
    var airMass: Double {
        return AtmosphericAirMass.pickeringAirMass(trueAltitude: self.altitude)
    }
    
    /// Checks the observation conditions for a target given sun altitude.
    /// - Parameters:
    ///   - sunAltitude: Current altitude of the Sun.
    ///   - minTargetAltitude: Minimum altitude for observation (default 30°).
    /// - Returns: ObservationWindow assessment.
    func observationWindow(sunAltitude: Degree, minTargetAltitude: Degree = Degree(30.0)) -> ObservationWindow {
        let elevated = self.altitude >= minTargetAltitude
        let darkNight = sunAltitude <= Degree(-18.0)
        return ObservationWindow(
            isTargetElevated: elevated,
            isAstronomicalNight: darkNight,
            airMass: self.airMass
        )
    }
}
