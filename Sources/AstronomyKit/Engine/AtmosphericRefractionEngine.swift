//
//  AtmosphericRefractionEngine.swift
//  AstronomyKit
//
//  Pure Swift atmospheric refraction calculation (Bennett & NOAA formulas).
//  Replaces CAARefraction from AAplus.
//

import Foundation

public enum AtmosphericRefractionEngine: Sendable {

    public static func refractionFromTrue(altitude: Double, pressure: Double, temperature: Double) -> Double {
        if altitude > 85.0 {
            return 0.0
        } else if altitude > 84.0 {
            let correction = (pressure / 1010.0) * (283.0 / (273.0 + temperature))
            return correction * 0.10177457991197518 / 60.0 * (85.0 - altitude)
        } else if altitude > 5.49398 {
            let correction = (pressure / 1010.0) * (283.0 / (273.0 + temperature))
            let h = SphericalTrigonometry.degreesToRadians(altitude)
            let tanH = tan(h)
            let tanH3 = tanH * tanH * tanH
            let tanH5 = tanH3 * tanH * tanH
            return correction * ((58.1 / tanH) - (0.07 / tanH3) + (0.000086 / tanH5)) / 3600.0
        } else if altitude > -0.575 {
            let correction = (pressure / 1010.0) * (283.0 / (273.0 + temperature))
            let poly = 1735.0 + altitude * (-518.2 + (altitude * (103.4 + altitude * (-12.79 + (altitude * 0.711)))))
            return correction * poly / 3600.0
        } else {
            let correction = (pressure / 1010.0) * (283.0 / (273.0 + temperature))
            let h = SphericalTrigonometry.degreesToRadians(altitude)
            return correction * (-20.774 / tan(h)) / 3600.0
        }
    }

    public static func refractionFromApparent(altitude: Double, pressure: Double, temperature: Double) -> Double {
        var trueAltitude = altitude
        var bContinue = true
        var refraction = 0.0
        var iterations = 0
        while bContinue && iterations < 100 {
            iterations += 1
            refraction = refractionFromTrue(altitude: trueAltitude, pressure: pressure, temperature: temperature)
            let newTrueAltitude = altitude - refraction
            bContinue = abs(newTrueAltitude - trueAltitude) > 0.00001
            if bContinue {
                trueAltitude = newTrueAltitude
            }
        }
        return refraction
    }

    /// Direct calculation of atmospheric refraction from apparent altitude using Saemundsson's (1986) formula.
    /// Accurate to within 0.1 arcsecond down to the horizon.
    /// - Parameters:
    ///   - apparentAltitude: Apparent altitude in degrees.
    ///   - pressure: Atmospheric pressure in millibars (default: 1010.0).
    ///   - temperature: Air temperature in Celsius (default: 10.0).
    /// - Returns: Refraction in degrees to subtract from apparent altitude to obtain airless true altitude.
    public static func saemundssonRefraction(apparentAltitude: Double, pressure: Double = 1010.0, temperature: Double = 10.0) -> Double {
        guard apparentAltitude >= -5.0 else { return 0.0 }
        let h = apparentAltitude
        let denom = tan(SphericalTrigonometry.degreesToRadians(h + (10.3 / (h + 5.11))))
        guard abs(denom) > 1e-12 else { return 0.0 }
        let rArcmin = 1.02 / denom
        let weatherFactor = (pressure / 1010.0) * (283.0 / (273.0 + temperature))
        return (rArcmin * weatherFactor) / 60.0
    }
}

// MARK: - Backward-Compatibility Adapter for CAARefraction

public enum CAARefraction: Sendable {
    @inlinable public static func RefractionFromTrue(_ Altitude: Double, _ Pressure: Double, _ Temperature: Double) -> Double {
        AtmosphericRefractionEngine.refractionFromTrue(altitude: Altitude, pressure: Pressure, temperature: Temperature)
    }
    @inlinable public static func RefractionFromApparent(_ Altitude: Double, _ Pressure: Double, _ Temperature: Double) -> Double {
        AtmosphericRefractionEngine.refractionFromApparent(altitude: Altitude, pressure: Pressure, temperature: Temperature)
    }
}
