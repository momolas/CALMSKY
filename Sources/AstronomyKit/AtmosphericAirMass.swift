//
//  AtmosphericAirMass.swift
//  SwiftAA
//
//  Created for SwiftAA.
//  MIT Licence. See LICENCE file.
//

import Foundation

/// Air mass computation models available in modern astronomical observational planning.
public enum AirMassModel: Sendable, Codable, Hashable {
    /// Pickering (2002) formula, accurate down to the horizon (~38 at horizon).
    case pickering
    /// Kasten & Young (1989) formula, standard international model.
    case kastenYoung
    /// Rozenberg (1966) formula.
    case rozenberg
}

/// Methods to compute relative optical air mass and astronomical observation windows.
public struct AtmosphericAirMass: Sendable {
    
    /// Computes the relative optical air mass using Pickering's (2002) formula.
    /// Air mass is normalized to 1.0 at the zenith (true altitude = 90°).
    /// - Parameter trueAltitude: The true geometric altitude of the celestial body above the horizon.
    /// - Returns: Relative air mass $X$ (e.g. 1.0 at zenith, ~38 near horizon). Returns `.infinity` for altitude $\le -0.5^\circ$.
    @inlinable
    public static func pickeringAirMass(trueAltitude: Degree) -> Double {
        let h = trueAltitude.value
        guard h > -0.5 else { return .infinity }
        // Pickering (2002) formula: 1 / sin(h + 244 / (165 + 47 * h^1.1))
        let sinArg = (h + 244.0 / (165.0 + 47.0 * pow(max(h, 0.0), 1.1))) * (Double.pi / 180.0)
        return 1.0 / sin(sinArg)
    }

    /// Computes the relative optical air mass using the Kasten & Young (1989) international standard formula.
    /// Air mass is normalized to 1.0 at the zenith (true altitude = 90°).
    /// - Parameter trueAltitude: The true geometric altitude of the celestial body above the horizon.
    /// - Returns: Relative air mass $X$. Returns `.infinity` for altitude $\le -0.5^\circ$.
    @inlinable
    public static func kastenYoungAirMass(trueAltitude: Degree) -> Double {
        let h = trueAltitude.value
        guard h > -0.5 else { return .infinity }
        // Kasten & Young (1989): 1 / (sin(h) + 0.50572 * (h + 6.07995)^(-1.6364))
        let sinH = sin(h * (Double.pi / 180.0))
        let denom = sinH + 0.50572 * pow(max(h + 6.07995, 0.001), -1.6364)
        return 1.0 / denom
    }

    /// Computes the relative optical air mass using Rozenberg's (1966) formula.
    /// - Parameter trueAltitude: The true geometric altitude of the celestial body.
    /// - Returns: Relative air mass.
    @inlinable
    public static func rozenbergAirMass(trueAltitude: Degree) -> Double {
        let h = trueAltitude.value
        guard h > -0.5 else { return .infinity }
        let sinH = sin(h * (Double.pi / 180.0))
        return 1.0 / (sinH + 0.025 * exp(-11.0 * sinH))
    }

    /// Computes the relative optical air mass using the specified model.
    /// - Parameters:
    ///   - trueAltitude: The true geometric altitude of the celestial body.
    ///   - model: The air mass model to apply (default: `.pickering`).
    /// - Returns: Relative air mass.
    @inlinable
    public static func airMass(trueAltitude: Degree, model: AirMassModel = .pickering) -> Double {
        switch model {
        case .pickering:
            return pickeringAirMass(trueAltitude: trueAltitude)
        case .kastenYoung:
            return kastenYoungAirMass(trueAltitude: trueAltitude)
        case .rozenberg:
            return rozenbergAirMass(trueAltitude: trueAltitude)
        }
    }
}

/// Criteria for assessing night-sky observability of a target.
public struct ObservationWindow: Sendable, Codable, Hashable {
    /// True if the target is above the minimum altitude (e.g. 30°)
    public let isTargetElevated: Bool
    /// True if the Sun is below astronomical twilight (-18°)
    public let isAstronomicalNight: Bool
    /// True if both conditions are met
    @inlinable public var isOptimal: Bool { isTargetElevated && isAstronomicalNight }
    /// Optical air mass of the target at that moment
    public let airMass: Double
    
    @inlinable
    public init(isTargetElevated: Bool, isAstronomicalNight: Bool, airMass: Double) {
        self.isTargetElevated = isTargetElevated
        self.isAstronomicalNight = isAstronomicalNight
        self.airMass = airMass
    }
}

public extension HorizontalCoordinates {
    
    /// Calculate current relative air mass for these horizontal coordinates using the default Pickering model.
    @inlinable
    var airMass: Double {
        AtmosphericAirMass.pickeringAirMass(trueAltitude: self.altitude)
    }

    /// Calculate relative air mass for these horizontal coordinates using the chosen model.
    @inlinable
    func airMass(model: AirMassModel = .pickering) -> Double {
        AtmosphericAirMass.airMass(trueAltitude: self.altitude, model: model)
    }
    
    /// Checks the observation conditions for a target given sun altitude.
    /// - Parameters:
    ///   - sunAltitude: Current altitude of the Sun.
    ///   - minTargetAltitude: Minimum altitude for observation (default 30°).
    ///   - airMassModel: Desired air mass calculation model (default: `.pickering`).
    /// - Returns: ObservationWindow assessment.
    @inlinable
    func observationWindow(
        sunAltitude: Degree,
        minTargetAltitude: Degree = Degree(30.0),
        airMassModel: AirMassModel = .pickering
    ) -> ObservationWindow {
        let elevated = self.altitude >= minTargetAltitude
        let darkNight = sunAltitude <= Degree(-18.0)
        return ObservationWindow(
            isTargetElevated: elevated,
            isAstronomicalNight: darkNight,
            airMass: self.airMass(model: airMassModel)
        )
    }
}
