//
//  PlanetaryEngines.swift
//  AstronomyKit
//  NASA JPL Keplerian Planetary Elements & Secular Rates (Caltech / JPL).
//  Pedagogical / schematic orbit formulation.
//  Note: High-precision ephemerides strictly use numerical integration (DE442s / Tetrad).
//

import Foundation

public typealias CAAPlanet = KPCAAPlanet
public typealias CAAPlanetStrict = KPCAAPlanetStrict

// MARK: - NASA JPL Keplerian Planet Formulation (Schematic / Pedagogical)

/// Represents a celestial body whose orbit is parameterized using mean Keplerian elements and secular rates.
///
/// - Important: This analytical formulation is provided solely for educational and lightweight schematic orbits.
///   It is **strictly excluded** from AstronomyKit's ephemeris resolution engine. High-precision ephemerides strictly use
///   numerical integration (offline NASA JPL DE442s baseline or online streaming Tetrad / Triad).
public struct NASAJPLKeplerianPlanet: Sendable {
    public let a0: Double
    public let aDot: Double
    public let e0: Double
    public let eDot: Double
    public let i0: Double       // degrees
    public let iDot: Double     // degrees/century
    public let L0: Double       // degrees
    public let LDot: Double     // degrees/century
    public let varpi0: Double   // degrees
    public let varpiDot: Double // degrees/century
    public let omega0: Double   // degrees (longitude of ascending node)
    public let omegaDot: Double // degrees/century

    // Additional secular perturbation terms for outer planets (Jupiter through Neptune, Table 2b)
    public let b: Double
    public let c: Double
    public let s: Double
    public let f: Double

    public init(
        a0: Double, aDot: Double,
        e0: Double, eDot: Double,
        i0: Double, iDot: Double,
        L0: Double, LDot: Double,
        varpi0: Double, varpiDot: Double,
        omega0: Double, omegaDot: Double,
        b: Double = 0.0, c: Double = 0.0, s: Double = 0.0, f: Double = 0.0
    ) {
        self.a0 = a0; self.aDot = aDot
        self.e0 = e0; self.eDot = eDot
        self.i0 = i0; self.iDot = iDot
        self.L0 = L0; self.LDot = LDot
        self.varpi0 = varpi0; self.varpiDot = varpiDot
        self.omega0 = omega0; self.omegaDot = omegaDot
        self.b = b; self.c = c; self.s = s; self.f = f
    }

    /// Computes heliocentric ecliptic coordinates (longitude in degrees [0, 360), latitude in degrees [-90, 90], radius in AU)
    /// referred to the J2000 mean ecliptic and equinox.
    public func coordinatesJ2000(jd: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        let T = (jd - 2451545.0) / 36525.0

        let a = a0 + aDot * T
        let e = e0 + eDot * T
        let I = (i0 + iDot * T) * .pi / 180.0
        let L = L0 + LDot * T
        let varpi = varpi0 + varpiDot * T
        let Omega = (omega0 + omegaDot * T) * .pi / 180.0

        let w = (varpi - (omega0 + omegaDot * T)) * .pi / 180.0

        var M = L - varpi
        if b != 0.0 || c != 0.0 || s != 0.0 {
            let fT = f * T * .pi / 180.0
            M += b * T * T + c * cos(fT) + s * sin(fT)
        }

        // Normalize M to [-180, 180] degrees
        var mNorm = M.truncatingRemainder(dividingBy: 360.0)
        if mNorm > 180.0 { mNorm -= 360.0 }
        if mNorm < -180.0 { mNorm += 360.0 }
        let mRad = mNorm * .pi / 180.0

        // Solve Kepler's equation M = E - e*sin(E) using Newton-Raphson iteration
        var E = mRad + e * sin(mRad)
        for _ in 0..<12 {
            let deltaM = mRad - (E - e * sin(E))
            let deltaE = deltaM / (1.0 - e * cos(E))
            E += deltaE
            if abs(deltaE) < 1e-12 { break }
        }

        // Coordinates in orbital plane
        let xPrime = a * (cos(E) - e)
        let yPrime = a * sqrt(max(0.0, 1.0 - e * e)) * sin(E)

        // Rotate into J2000 ecliptic frame
        let cosW = cos(w)
        let sinW = sin(w)
        let cosOmega = cos(Omega)
        let sinOmega = sin(Omega)
        let cosI = cos(I)
        let sinI = sin(I)

        let x = (cosW * cosOmega - sinW * sinOmega * cosI) * xPrime + (-sinW * cosOmega - cosW * sinOmega * cosI) * yPrime
        let y = (cosW * sinOmega + sinW * cosOmega * cosI) * xPrime + (-sinW * sinOmega + cosW * cosOmega * cosI) * yPrime
        let z = (sinW * sinI) * xPrime + (cosW * sinI) * yPrime

        let r = sqrt(x * x + y * y + z * z)
        var lon = atan2(y, x) * 180.0 / .pi
        if lon < 0.0 { lon += 360.0 }
        let lat = atan2(z, sqrt(x * x + y * y)) * 180.0 / .pi

        return (longitude: lon, latitude: lat, radius: r)
    }

    /// Computes heliocentric ecliptic coordinates for the equinox of date.
    public func coordinatesDate(jd: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        let j2000 = coordinatesJ2000(jd: jd)
        let T = (jd - 2451545.0) / 36525.0
        let precLon = (5028.796195 * T + 1.1054348 * T * T) / 3600.0
        var lonDate = (j2000.longitude + precLon).truncatingRemainder(dividingBy: 360.0)
        if lonDate < 0.0 { lonDate += 360.0 }
        return (longitude: lonDate, latitude: j2000.latitude, radius: j2000.radius)
    }
}

// MARK: - NASA JPL Solar System Planets (Table 1 & Table 2b)

public enum NASAJPLPlanets: Sendable {
    public static let mercury = NASAJPLKeplerianPlanet(
        a0: 0.38709927, aDot: 0.00000037,
        e0: 0.20563593, eDot: 0.00001906,
        i0: 7.00497902, iDot: -0.00594749,
        L0: 252.25032350, LDot: 149472.67411175,
        varpi0: 77.45779628, varpiDot: 0.16047689,
        omega0: 48.33076593, omegaDot: -0.12534081
    )

    public static let venus = NASAJPLKeplerianPlanet(
        a0: 0.72333566, aDot: 0.00000390,
        e0: 0.00677672, eDot: -0.00004107,
        i0: 3.39467605, iDot: -0.00078890,
        L0: 181.97909950, LDot: 58517.81538729,
        varpi0: 131.60246718, varpiDot: 0.00268329,
        omega0: 76.67984255, omegaDot: -0.27769418
    )

    public static let earth = NASAJPLKeplerianPlanet(
        a0: 1.00000261, aDot: 0.00000562,
        e0: 0.01671123, eDot: -0.00004392,
        i0: -0.00001531, iDot: -0.01294668,
        L0: 100.46457166, LDot: 35999.37244981,
        varpi0: 102.93768193, varpiDot: 0.32327364,
        omega0: 0.0, omegaDot: 0.0
    )

    public static let mars = NASAJPLKeplerianPlanet(
        a0: 1.52371034, aDot: 0.00001847,
        e0: 0.09339410, eDot: 0.00007882,
        i0: 1.84969142, iDot: -0.00813131,
        L0: -4.55343205, LDot: 19140.30268499,
        varpi0: -23.94362959, varpiDot: 0.44441088,
        omega0: 49.55953891, omegaDot: -0.29257343
    )

    public static let jupiter = NASAJPLKeplerianPlanet(
        a0: 5.20288700, aDot: -0.00011607,
        e0: 0.04838624, eDot: -0.00013253,
        i0: 1.30439695, iDot: -0.00183714,
        L0: 34.39644051, LDot: 3034.74612775,
        varpi0: 14.72847983, varpiDot: 0.21252668,
        omega0: 100.47390909, omegaDot: 0.20469106
    )

    public static let saturn = NASAJPLKeplerianPlanet(
        a0: 9.53667594, aDot: -0.00125060,
        e0: 0.05386179, eDot: -0.00050991,
        i0: 2.48599187, iDot: 0.00193609,
        L0: 49.95424423, LDot: 1222.49362201,
        varpi0: 92.59887831, varpiDot: -0.41897216,
        omega0: 113.66242448, omegaDot: -0.28867794
    )

    public static let uranus = NASAJPLKeplerianPlanet(
        a0: 19.18916464, aDot: -0.00196176,
        e0: 0.04725744, eDot: -0.00004397,
        i0: 0.77263783, iDot: -0.00242939,
        L0: 313.23810451, LDot: 428.48202785,
        varpi0: 170.95427630, varpiDot: 0.40805281,
        omega0: 74.01692503, omegaDot: 0.04240589
    )

    public static let neptune = NASAJPLKeplerianPlanet(
        a0: 30.06992276, aDot: 0.00026291,
        e0: 0.00859048, eDot: 0.00005105,
        i0: 1.77004347, iDot: 0.00035372,
        L0: -55.12002969, LDot: 218.45945325,
        varpi0: 44.96476227, varpiDot: -0.32241464,
        omega0: 131.78422574, omegaDot: -0.00508664
    )

    public static let pluto = NASAJPLKeplerianPlanet(
        a0: 39.48168677, aDot: -0.00076912,
        e0: 0.24880766, eDot: 0.00006465,
        i0: 17.14175, iDot: 0.003075,
        L0: 238.92881, LDot: 145.20780515,
        varpi0: 224.06676, varpiDot: -0.040629,
        omega0: 110.30347, omegaDot: -0.011834
    )

    /// Joint evaluation of heliocentric ecliptic coordinates (longitude in degrees [0, 360), latitude in degrees [-90, 90], radius in AU)
    /// for equinox of date. Evaluates Kepler's equation and frame rotations in a single pass.
    @inlinable
    public static func coordinates(for planet: KPCAAPlanet, jd: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        switch planet {
        case .KPCAAPlanetMercury: return mercury.coordinatesDate(jd: jd)
        case .KPCAAPlanetVenus: return venus.coordinatesDate(jd: jd)
        case .KPCAAPlanetEarth: return earth.coordinatesDate(jd: jd)
        case .KPCAAPlanetMars: return mars.coordinatesDate(jd: jd)
        case .KPCAAPlanetJupiter: return jupiter.coordinatesDate(jd: jd)
        case .KPCAAPlanetSaturn: return saturn.coordinatesDate(jd: jd)
        case .KPCAAPlanetUranus: return uranus.coordinatesDate(jd: jd)
        case .KPCAAPlanetNeptune: return neptune.coordinatesDate(jd: jd)
        case .KPCAAPlanetPluto: return pluto.coordinatesDate(jd: jd)
        case .KPCAAPlanetUndefined: return (0.0, 0.0, 0.0)
        }
    }

    /// Joint evaluation of heliocentric ecliptic coordinates for J2000 equinox.
    @inlinable
    public static func coordinatesJ2000(for planet: KPCAAPlanet, jd: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        switch planet {
        case .KPCAAPlanetMercury: return mercury.coordinatesJ2000(jd: jd)
        case .KPCAAPlanetVenus: return venus.coordinatesJ2000(jd: jd)
        case .KPCAAPlanetEarth: return earth.coordinatesJ2000(jd: jd)
        case .KPCAAPlanetMars: return mars.coordinatesJ2000(jd: jd)
        case .KPCAAPlanetJupiter: return jupiter.coordinatesJ2000(jd: jd)
        case .KPCAAPlanetSaturn: return saturn.coordinatesJ2000(jd: jd)
        case .KPCAAPlanetUranus: return uranus.coordinatesJ2000(jd: jd)
        case .KPCAAPlanetNeptune: return neptune.coordinatesJ2000(jd: jd)
        case .KPCAAPlanetPluto: return pluto.coordinatesJ2000(jd: jd)
        case .KPCAAPlanetUndefined: return (0.0, 0.0, 0.0)
        }
    }
}

// MARK: - CAAEarth

public enum CAAEarth: Sendable {
    @inlinable
    public static func eccentricity(_ jd: Double) -> Double {
        let t = (jd - 2451545.0) / 36525.0
        return 0.01671123 - (0.00004392 * t)
    }

    @inlinable
    public static func Eccentricity(_ jd: Double) -> Double { eccentricity(jd) }

    @inlinable
    public static func sunMeanAnomaly(_ jd: Double) -> Double {
        let t = (jd - 2451545.0) / 36525.0
        let t2 = t * t
        let t3 = t2 * t
        var val = (357.5291092 + (35999.0502909 * t) - (0.0001536 * t2) + (t3 / 24490000.0)).truncatingRemainder(dividingBy: 360.0)
        if val < 0.0 { val += 360.0 }
        return val
    }

    @inlinable
    public static func SunMeanAnomaly(_ jd: Double) -> Double { sunMeanAnomaly(jd) }

    @inlinable
    public static func coordinatesDate(jd: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        NASAJPLPlanets.earth.coordinatesDate(jd: jd)
    }

    @inlinable
    public static func coordinatesJ2000(jd: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        NASAJPLPlanets.earth.coordinatesJ2000(jd: jd)
    }

    @inlinable
    public static func eclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.earth.coordinatesDate(jd: jd).longitude
    }
    @inlinable public static func EclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLongitude(jd, bHighPrecision) }

    @inlinable
    public static func eclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.earth.coordinatesDate(jd: jd).latitude
    }
    @inlinable public static func EclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLatitude(jd, bHighPrecision) }

    @inlinable
    public static func radiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.earth.coordinatesDate(jd: jd).radius
    }
    @inlinable public static func RadiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { radiusVector(jd, bHighPrecision) }

    @inlinable
    public static func eclipticLongitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.earth.coordinatesJ2000(jd: jd).longitude
    }
    @inlinable public static func EclipticLongitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLongitudeJ2000(jd, bHighPrecision) }

    @inlinable
    public static func eclipticLatitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.earth.coordinatesJ2000(jd: jd).latitude
    }
    @inlinable public static func EclipticLatitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLatitudeJ2000(jd, bHighPrecision) }
}

// MARK: - CAAMercury

public enum CAAMercury: Sendable {
    @inlinable
    public static func coordinatesDate(jd: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        NASAJPLPlanets.mercury.coordinatesDate(jd: jd)
    }

    @inlinable
    public static func coordinatesJ2000(jd: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        NASAJPLPlanets.mercury.coordinatesJ2000(jd: jd)
    }

    @inlinable
    public static func eclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.mercury.coordinatesDate(jd: jd).longitude
    }
    @inlinable public static func EclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLongitude(jd, bHighPrecision) }

    @inlinable
    public static func eclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.mercury.coordinatesDate(jd: jd).latitude
    }
    @inlinable public static func EclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLatitude(jd, bHighPrecision) }

    @inlinable
    public static func radiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.mercury.coordinatesDate(jd: jd).radius
    }
    @inlinable public static func RadiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { radiusVector(jd, bHighPrecision) }

    @inlinable
    public static func eclipticLongitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.mercury.coordinatesJ2000(jd: jd).longitude
    }
    @inlinable public static func EclipticLongitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLongitudeJ2000(jd, bHighPrecision) }

    @inlinable
    public static func eclipticLatitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.mercury.coordinatesJ2000(jd: jd).latitude
    }
    @inlinable public static func EclipticLatitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLatitudeJ2000(jd, bHighPrecision) }
}

// MARK: - CAAVenus

public enum CAAVenus: Sendable {
    @inlinable
    public static func coordinatesDate(jd: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        NASAJPLPlanets.venus.coordinatesDate(jd: jd)
    }

    @inlinable
    public static func coordinatesJ2000(jd: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        NASAJPLPlanets.venus.coordinatesJ2000(jd: jd)
    }

    @inlinable
    public static func eclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.venus.coordinatesDate(jd: jd).longitude
    }
    @inlinable public static func EclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLongitude(jd, bHighPrecision) }

    @inlinable
    public static func eclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.venus.coordinatesDate(jd: jd).latitude
    }
    @inlinable public static func EclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLatitude(jd, bHighPrecision) }

    @inlinable
    public static func radiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.venus.coordinatesDate(jd: jd).radius
    }
    @inlinable public static func RadiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { radiusVector(jd, bHighPrecision) }

    @inlinable
    public static func eclipticLongitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.venus.coordinatesJ2000(jd: jd).longitude
    }
    @inlinable public static func EclipticLongitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLongitudeJ2000(jd, bHighPrecision) }

    @inlinable
    public static func eclipticLatitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.venus.coordinatesJ2000(jd: jd).latitude
    }
    @inlinable public static func EclipticLatitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLatitudeJ2000(jd, bHighPrecision) }
}

// MARK: - CAAMars

public enum CAAMars: Sendable {
    @inlinable
    public static func coordinatesDate(jd: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        NASAJPLPlanets.mars.coordinatesDate(jd: jd)
    }

    @inlinable
    public static func coordinatesJ2000(jd: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        NASAJPLPlanets.mars.coordinatesJ2000(jd: jd)
    }

    @inlinable
    public static func eclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.mars.coordinatesDate(jd: jd).longitude
    }
    @inlinable public static func EclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLongitude(jd, bHighPrecision) }

    @inlinable
    public static func eclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.mars.coordinatesDate(jd: jd).latitude
    }
    @inlinable public static func EclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLatitude(jd, bHighPrecision) }

    @inlinable
    public static func radiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.mars.coordinatesDate(jd: jd).radius
    }
    @inlinable public static func RadiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { radiusVector(jd, bHighPrecision) }

    @inlinable
    public static func eclipticLongitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.mars.coordinatesJ2000(jd: jd).longitude
    }
    @inlinable public static func EclipticLongitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLongitudeJ2000(jd, bHighPrecision) }

    @inlinable
    public static func eclipticLatitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.mars.coordinatesJ2000(jd: jd).latitude
    }
    @inlinable public static func EclipticLatitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLatitudeJ2000(jd, bHighPrecision) }
}

// MARK: - CAAJupiter

public enum CAAJupiter: Sendable {
    @inlinable
    public static func coordinatesDate(jd: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        NASAJPLPlanets.jupiter.coordinatesDate(jd: jd)
    }

    @inlinable
    public static func coordinatesJ2000(jd: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        NASAJPLPlanets.jupiter.coordinatesJ2000(jd: jd)
    }

    @inlinable
    public static func eclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.jupiter.coordinatesDate(jd: jd).longitude
    }
    @inlinable public static func EclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLongitude(jd, bHighPrecision) }

    @inlinable
    public static func eclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.jupiter.coordinatesDate(jd: jd).latitude
    }
    @inlinable public static func EclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLatitude(jd, bHighPrecision) }

    @inlinable
    public static func radiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.jupiter.coordinatesDate(jd: jd).radius
    }
    @inlinable public static func RadiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { radiusVector(jd, bHighPrecision) }

    @inlinable
    public static func eclipticLongitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.jupiter.coordinatesJ2000(jd: jd).longitude
    }
    @inlinable public static func EclipticLongitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLongitudeJ2000(jd, bHighPrecision) }

    @inlinable
    public static func eclipticLatitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.jupiter.coordinatesJ2000(jd: jd).latitude
    }
    @inlinable public static func EclipticLatitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLatitudeJ2000(jd, bHighPrecision) }
}

// MARK: - CAASaturn

public enum CAASaturn: Sendable {
    @inlinable
    public static func coordinatesDate(jd: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        NASAJPLPlanets.saturn.coordinatesDate(jd: jd)
    }

    @inlinable
    public static func coordinatesJ2000(jd: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        NASAJPLPlanets.saturn.coordinatesJ2000(jd: jd)
    }

    @inlinable
    public static func eclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.saturn.coordinatesDate(jd: jd).longitude
    }
    @inlinable public static func EclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLongitude(jd, bHighPrecision) }

    @inlinable
    public static func eclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.saturn.coordinatesDate(jd: jd).latitude
    }
    @inlinable public static func EclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLatitude(jd, bHighPrecision) }

    @inlinable
    public static func radiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.saturn.coordinatesDate(jd: jd).radius
    }
    @inlinable public static func RadiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { radiusVector(jd, bHighPrecision) }

    @inlinable
    public static func eclipticLongitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.saturn.coordinatesJ2000(jd: jd).longitude
    }
    @inlinable public static func EclipticLongitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLongitudeJ2000(jd, bHighPrecision) }

    @inlinable
    public static func eclipticLatitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.saturn.coordinatesJ2000(jd: jd).latitude
    }
    @inlinable public static func EclipticLatitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLatitudeJ2000(jd, bHighPrecision) }
}

// MARK: - CAAUranus

public enum CAAUranus: Sendable {
    @inlinable
    public static func coordinatesDate(jd: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        NASAJPLPlanets.uranus.coordinatesDate(jd: jd)
    }

    @inlinable
    public static func coordinatesJ2000(jd: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        NASAJPLPlanets.uranus.coordinatesJ2000(jd: jd)
    }

    @inlinable
    public static func eclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.uranus.coordinatesDate(jd: jd).longitude
    }
    @inlinable public static func EclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLongitude(jd, bHighPrecision) }

    @inlinable
    public static func eclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.uranus.coordinatesDate(jd: jd).latitude
    }
    @inlinable public static func EclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLatitude(jd, bHighPrecision) }

    @inlinable
    public static func radiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.uranus.coordinatesDate(jd: jd).radius
    }
    @inlinable public static func RadiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { radiusVector(jd, bHighPrecision) }

    @inlinable
    public static func eclipticLongitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.uranus.coordinatesJ2000(jd: jd).longitude
    }
    @inlinable public static func EclipticLongitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLongitudeJ2000(jd, bHighPrecision) }

    @inlinable
    public static func eclipticLatitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.uranus.coordinatesJ2000(jd: jd).latitude
    }
    @inlinable public static func EclipticLatitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLatitudeJ2000(jd, bHighPrecision) }
}

// MARK: - CAANeptune

public enum CAANeptune: Sendable {
    @inlinable
    public static func coordinatesDate(jd: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        NASAJPLPlanets.neptune.coordinatesDate(jd: jd)
    }

    @inlinable
    public static func coordinatesJ2000(jd: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        NASAJPLPlanets.neptune.coordinatesJ2000(jd: jd)
    }

    @inlinable
    public static func eclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.neptune.coordinatesDate(jd: jd).longitude
    }
    @inlinable public static func EclipticLongitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLongitude(jd, bHighPrecision) }

    @inlinable
    public static func eclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.neptune.coordinatesDate(jd: jd).latitude
    }
    @inlinable public static func EclipticLatitude(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLatitude(jd, bHighPrecision) }

    @inlinable
    public static func radiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.neptune.coordinatesDate(jd: jd).radius
    }
    @inlinable public static func RadiusVector(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { radiusVector(jd, bHighPrecision) }

    @inlinable
    public static func eclipticLongitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.neptune.coordinatesJ2000(jd: jd).longitude
    }
    @inlinable public static func EclipticLongitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLongitudeJ2000(jd, bHighPrecision) }

    @inlinable
    public static func eclipticLatitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double {
        NASAJPLPlanets.neptune.coordinatesJ2000(jd: jd).latitude
    }
    @inlinable public static func EclipticLatitudeJ2000(_ jd: Double, _ bHighPrecision: Bool = true) -> Double { eclipticLatitudeJ2000(jd, bHighPrecision) }
}

// MARK: - CAAPluto

public enum CAAPluto: Sendable {
    @inlinable
    public static func coordinatesDate(jd: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        NASAJPLPlanets.pluto.coordinatesDate(jd: jd)
    }

    @inlinable
    public static func coordinatesJ2000(jd: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        NASAJPLPlanets.pluto.coordinatesJ2000(jd: jd)
    }

    @inlinable
    public static func eclipticLongitude(_ jd: Double) -> Double {
        NASAJPLPlanets.pluto.coordinatesDate(jd: jd).longitude
    }
    @inlinable public static func EclipticLongitude(_ jd: Double) -> Double { eclipticLongitude(jd) }

    @inlinable
    public static func eclipticLatitude(_ jd: Double) -> Double {
        NASAJPLPlanets.pluto.coordinatesDate(jd: jd).latitude
    }
    @inlinable public static func EclipticLatitude(_ jd: Double) -> Double { eclipticLatitude(jd) }

    @inlinable
    public static func radiusVector(_ jd: Double) -> Double {
        NASAJPLPlanets.pluto.coordinatesDate(jd: jd).radius
    }
    @inlinable public static func RadiusVector(_ jd: Double) -> Double { radiusVector(jd) }

    @inlinable
    public static func eclipticLongitudeJ2000(_ jd: Double) -> Double {
        NASAJPLPlanets.pluto.coordinatesJ2000(jd: jd).longitude
    }
    @inlinable public static func EclipticLongitudeJ2000(_ jd: Double) -> Double { eclipticLongitudeJ2000(jd) }

    @inlinable
    public static func eclipticLatitudeJ2000(_ jd: Double) -> Double {
        NASAJPLPlanets.pluto.coordinatesJ2000(jd: jd).latitude
    }
    @inlinable public static func EclipticLatitudeJ2000(_ jd: Double) -> Double { eclipticLatitudeJ2000(jd) }
}

