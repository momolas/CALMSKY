//
//  AtmosphericRefractionEngine.swift
//  AstronomyKit
//
//  Pure Swift atmospheric refraction calculation (Bennett & NOAA formulas).
//  Replaces CAARefraction from AAplus.
//

import Foundation

public enum AtmosphericRefractionEngine: Sendable {

    @inlinable
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

    @inlinable
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
    @inlinable
    public static func saemundssonRefraction(apparentAltitude: Double, pressure: Double = 1010.0, temperature: Double = 10.0) -> Double {
        guard apparentAltitude >= -5.0, apparentAltitude.isFinite else { return 0.0 }
        let h = apparentAltitude
        let denom = tan(SphericalTrigonometry.degreesToRadians(h + (10.3 / (h + 5.11))))
        guard abs(denom) > 1e-12 else { return 0.0 }
        let rArcmin = 1.02 / denom
        let weatherFactor = (pressure / 1010.0) * (283.0 / (273.0 + temperature))
        return (rArcmin * weatherFactor) / 60.0
    }

    /// Computes the phase refractive index excess (n - 1) of moist air according to the BIPM standard (Ciddor 1996, 2002).
    /// Accounts for wavelength, atmospheric pressure, temperature, CO2 concentration, and relative humidity.
    /// - Parameters:
    ///   - pressureHPa: Atmospheric pressure in hectopascals / millibars (default: 1013.25).
    ///   - temperatureC: Air temperature in Celsius (default: 15.0).
    ///   - params: Ciddor atmospheric and spectral parameters.
    /// - Returns: Phase refractive index excess (n - 1).
    @inlinable
    public static func ciddorRefractivity(
        pressureHPa: Double = 1013.25,
        temperatureC: Double = 15.0,
        params: CiddorParameters = .visual
    ) -> Double {
        guard pressureHPa > 0, pressureHPa.isFinite, temperatureC.isFinite else { return 0.0 }
        let lambda = max(0.2, min(2.5, params.wavelengthMicrometers)) // Valid optical / NIR range (0.2 - 2.5 µm)
        let sigma = 1.0 / lambda
        let sigma2 = sigma * sigma

        // 1. Refractivity of standard dry air with 450 ppm CO2 (Peck & Reeder 1972, Ciddor 1996)
        let k0 = 238.0185
        let k1 = 5792105.0
        let k2 = 57.362
        let k3 = 167909.0
        let nAsMinus1Times1e8 = (k1 / (k0 - sigma2)) + (k3 / (k2 - sigma2))
        let nAsMinus1 = nAsMinus1Times1e8 * 1e-8

        // CO2 scaling factor
        let co2Factor = 1.0 + 0.534e-6 * (params.co2Ppm - 450.0)
        let nAxsMinus1 = nAsMinus1 * co2Factor

        // 2. Refractivity of standard water vapor (Ciddor 1996)
        let w0 = 295.235
        let w1 = 2.6422
        let w2 = -0.032380
        let w3 = 0.004028
        let nWsMinus1Times1e8 = 1.022 * (w0 + w1 * sigma2 + w2 * sigma2 * sigma2 + w3 * sigma2 * sigma2 * sigma2)
        let nWsMinus1 = nWsMinus1Times1e8 * 1e-8

        // 3. Thermodynamic properties of ambient air
        let tK = temperatureC + 273.15
        let pPa = pressureHPa * 100.0 // Pa

        // Saturation water vapor pressure (Davis 1992 equation in Pa)
        let logPsv = 1.2378847e-5 * tK * tK - 1.9121316e-2 * tK + 33.93711047 - 6343.1645 / tK
        let psv = exp(logPsv)
        let enhancement = 1.00062 + 3.14e-8 * pPa + 5.6e-7 * temperatureC * temperatureC
        let rhFraction = max(0.0, min(100.0, params.relativeHumidity)) / 100.0
        let pw = rhFraction * enhancement * psv // Water vapor partial pressure in Pa
        let pa = max(0.0, pPa - pw) // Dry air partial pressure in Pa

        // Compressibility factor Z (Ciddor 1996)
        let a0 = 1.58123e-6, a1 = -2.9331e-8, a2 = 1.1043e-10
        let b0 = 5.707e-6, b1 = -2.051e-8
        let c0 = 1.9898e-4, c1 = -2.376e-6
        let d = 1.83e-11, e = -0.765e-8
        let tc = temperatureC

        let pwOverP = pPa > 0 ? (pw / pPa) : 0.0
        let pwOverP2 = pwOverP * pwOverP
        let z = 1.0 - (pPa / tK) * (
            (a0 + a1 * tc + a2 * tc * tc)
            + (b0 + b1 * tc) * pwOverP
            + (c0 + c1 * tc) * pwOverP2
        ) + ((pPa * pPa) / (tK * tK)) * (d + e * pwOverP2)

        // Molar masses and densities
        let rGas = 8.314462618 // J / (mol * K)
        let ma = (0.0289635 + 12.011e-6 * (params.co2Ppm - 400.0) * 1e-6) // Dry air molar mass
        let mw = 0.018015 // Water vapor molar mass

        let rhoA = (pa * ma) / (z * rGas * tK)
        let rhoW = (pw * mw) / (z * rGas * tK)

        // Standard densities (at standard state)
        let zStd = 0.9995922115
        let rhoAxs = (101325.0 * ma) / (zStd * rGas * 288.15)
        let rhoWs = 0.00985938

        // Composite refractivity (Ciddor Eq. 5)
        let nMinus1 = (rhoA / rhoAxs) * nAxsMinus1 + (rhoW / rhoWs) * nWsMinus1
        return nMinus1
    }

    /// Computes high-precision astronomical refraction in degrees using the BIPM Ciddor (1996) model
    /// with smooth Auer-Standish / Saemundsson boundary layer scaling across all altitudes.
    /// - Parameters:
    ///   - apparentAltitude: Apparent altitude in degrees.
    ///   - pressureHPa: Atmospheric pressure in hPa/mbar (default: 1010.0).
    ///   - temperatureC: Air temperature in Celsius (default: 10.0).
    ///   - params: Ciddor atmospheric and spectral parameters.
    /// - Returns: Atmospheric refraction in degrees.
    @inlinable
    public static func ciddorRefraction(
        apparentAltitude: Double,
        pressureHPa: Double = 1010.0,
        temperatureC: Double = 10.0,
        params: CiddorParameters = .visual
    ) -> Double {
        guard apparentAltitude >= -5.0, apparentAltitude.isFinite else { return 0.0 }
        if apparentAltitude > 89.999 { return 0.0 }

        let nMinus1 = ciddorRefractivity(
            pressureHPa: pressureHPa,
            temperatureC: temperatureC,
            params: params
        )
        guard nMinus1 > 0 else { return 0.0 }

        let h = apparentAltitude
        let hRad = SphericalTrigonometry.degreesToRadians(h)
        let zRad = (Double.pi / 2.0) - hRad // Zenith angle

        // Reference standard refractivity at 1010 hPa, 10°C, 550nm
        let refNMinus1 = 0.00028279

        if h >= 15.0 {
            // High altitude: Laplace expansion with scale-height beta = 0.001254
            let tanZ = tan(zRad)
            let tanZ3 = tanZ * tanZ * tanZ
            let beta = 0.001254
            let rRad = nMinus1 * (1.0 - beta) * tanZ - nMinus1 * (beta - nMinus1 / 2.0) * tanZ3
            return SphericalTrigonometry.radiansToDegrees(rRad)
        } else if h <= 10.0 {
            // Low altitude down to horizon: Saemundsson / Auer-Standish mapping scaled by Ciddor refractivity
            let denom = tan(SphericalTrigonometry.degreesToRadians(h + (10.3 / (h + 5.11))))
            guard abs(denom) > 1e-12 else { return 0.0 }
            let rArcminStandard = 1.02 / denom
            let scaling = nMinus1 / refNMinus1
            return (rArcminStandard * scaling) / 60.0
        } else {
            // Transition zone (10° to 15°): Smooth cosine blending
            let tanZ = tan(zRad)
            let tanZ3 = tanZ * tanZ * tanZ
            let beta = 0.001254
            let rHighDeg = SphericalTrigonometry.radiansToDegrees(nMinus1 * (1.0 - beta) * tanZ - nMinus1 * (beta - nMinus1 / 2.0) * tanZ3)

            let denom = tan(SphericalTrigonometry.degreesToRadians(h + (10.3 / (h + 5.11))))
            let rLowDeg = ((1.02 / denom) * (nMinus1 / refNMinus1)) / 60.0

            let weight = (h - 10.0) / 5.0 // [0, 1]
            let smoothWeight = 0.5 - 0.5 * cos(weight * Double.pi)
            return (1.0 - smoothWeight) * rLowDeg + smoothWeight * rHighDeg
        }
    }

    /// Computes the apparent altitude from true "airless" altitude using Ciddor refraction.
    /// - Parameters:
    ///   - trueAltitude: True geometric altitude in degrees.
    ///   - pressureHPa: Atmospheric pressure in hPa/mbar (default: 1010.0).
    ///   - temperatureC: Air temperature in Celsius (default: 10.0).
    ///   - params: Ciddor atmospheric and spectral parameters.
    /// - Returns: Apparent altitude in degrees.
    @inlinable
    public static func apparentAltitudeFromTrue(
        trueAltitude: Double,
        pressureHPa: Double = 1010.0,
        temperatureC: Double = 10.0,
        params: CiddorParameters = .visual
    ) -> Double {
        guard trueAltitude.isFinite else { return trueAltitude }
        var apparent = trueAltitude
        for _ in 0..<10 {
            let r = ciddorRefraction(
                apparentAltitude: apparent,
                pressureHPa: pressureHPa,
                temperatureC: temperatureC,
                params: params
            )
            let next = trueAltitude + r
            if abs(next - apparent) < 1e-8 {
                return next
            }
            apparent = next
        }
        return apparent
    }
}

/// Environmental and spectral configuration for the BIPM Ciddor (1996/2002) refractive index model.
public struct CiddorParameters: Sendable, Hashable {
    /// Wavelength in micrometers (default 0.55 µm = 550 nm, visible green / V-band)
    public var wavelengthMicrometers: Double
    /// Carbon dioxide concentration in parts per million (default 450 ppm)
    public var co2Ppm: Double
    /// Relative humidity in percentage [0, 100] (default 50%)
    public var relativeHumidity: Double

    @inlinable
    public init(
        wavelengthMicrometers: Double = 0.55,
        co2Ppm: Double = 450.0,
        relativeHumidity: Double = 50.0
    ) {
        self.wavelengthMicrometers = wavelengthMicrometers
        self.co2Ppm = co2Ppm
        self.relativeHumidity = relativeHumidity
    }

    /// Preset for visible visual observation (550 nm, 450 ppm CO2, 50% RH)
    public static let visual = CiddorParameters(wavelengthMicrometers: 0.55)
    /// Preset for Hydrogen-Alpha astrophotography (656.28 nm)
    public static let hAlpha = CiddorParameters(wavelengthMicrometers: 0.65628)
    /// Preset for Oxygen-III narrow band filter (500.7 nm)
    public static let oIII = CiddorParameters(wavelengthMicrometers: 0.5007)
    /// Preset for Near-Infrared J-band (1.25 µm)
    public static let nearInfraredJ = CiddorParameters(wavelengthMicrometers: 1.25)
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
