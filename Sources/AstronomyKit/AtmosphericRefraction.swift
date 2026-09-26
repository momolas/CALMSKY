//
//  Refraction.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 02/10/2016.
//  MIT Licence. See LICENCE file.
//

import Foundation

/// Compute the atmospheric refraction from the apparent altitude of a celestial body h0 that has been already measured,
/// and from which one must substract R to find the true altitude h.
///
/// - parameter h0:          The apparent altitude
/// - parameter pressure:    The atmospheric pressure at Earth's surface
/// - parameter temperature: The air temperature at Earth's surface
///
/// - returns: The refraction amplitude, in arcminutes.
@inlinable
public func refraction(fromApparentAltitude h0: Degree, pressure: Millibar = 1010, temperature: Celsius = 10) -> ArcMinute {
    // AA returns a value in Degrees
    Degree(CAARefraction.RefractionFromApparent(h0.value, pressure, temperature)).inArcMinutes
}

/// Compute the atmospheric refraction from the true "airless" altitude of a celestial body h that has been already
/// calculated, and from which one must add R to find the apparent altitude h0.
///
/// - parameter h:           The true altitude
/// - parameter pressure:    The atmospheric pressure at Earth's surface
/// - parameter temperature: The air temperature at Earth's surface
///
/// - returns: The refraction amplitude, in arcminutes.
@inlinable
public func refraction(fromTrueAltitude h: Degree, pressure: Millibar = 1010, temperature: Celsius = 10) -> ArcMinute {
    // AA returns a value in Degrees
    Degree(CAARefraction.RefractionFromTrue(h.value, pressure, temperature)).inArcMinutes
}

/// Compute modern atmospheric refraction from apparent altitude using the BIPM Ciddor (1996/2002) model.
///
/// - Parameters:
///   - h0: The measured apparent altitude.
///   - pressure: The atmospheric pressure at Earth's surface in Millibar / hPa (default: 1010).
///   - temperature: The air temperature at Earth's surface in Celsius (default: 10).
///   - parameters: Environmental and spectral parameters (wavelength, CO2, humidity).
/// - Returns: The refraction amplitude, in arcminutes.
@inlinable
public func refractionCiddor(
    fromApparentAltitude h0: Degree,
    pressure: Millibar = 1010,
    temperature: Celsius = 10,
    parameters: CiddorParameters = .visual
) -> ArcMinute {
    let deg = AtmosphericRefractionEngine.ciddorRefraction(
        apparentAltitude: h0.value,
        pressureHPa: pressure,
        temperatureC: temperature,
        params: parameters
    )
    return Degree(deg).inArcMinutes
}

/// Compute modern atmospheric refraction from true "airless" altitude using the BIPM Ciddor (1996/2002) model.
///
/// - Parameters:
///   - h: The geometric airless true altitude.
///   - pressure: The atmospheric pressure at Earth's surface in Millibar / hPa (default: 1010).
///   - temperature: The air temperature at Earth's surface in Celsius (default: 10).
///   - parameters: Environmental and spectral parameters (wavelength, CO2, humidity).
/// - Returns: The refraction amplitude, in arcminutes.
@inlinable
public func refractionCiddor(
    fromTrueAltitude h: Degree,
    pressure: Millibar = 1010,
    temperature: Celsius = 10,
    parameters: CiddorParameters = .visual
) -> ArcMinute {
    let appAlt = AtmosphericRefractionEngine.apparentAltitudeFromTrue(
        trueAltitude: h.value,
        pressureHPa: pressure,
        temperatureC: temperature,
        params: parameters
    )
    return Degree(appAlt - h.value).inArcMinutes
}

